// macOS notification plugin for OpenCode.
//
// Sends system notifications via terminal-notifier (brew package) for events
// that require user attention or signal completion. Notifications include
// project context (directory name) and session title for disambiguation
// when running multiple OpenCode sessions.
//
// Smart notification behavior:
//   - If Ghostty is frontmost: suppress system notifications (user is already looking)
//   - Exception: subagent launches always show a TUI toast for in-context awareness
//
// Notification triggers:
//   - permission.asked  → "Question needs your answer in <session>" (system notification, only if Ghostty not focused)
//   - session.created   → "<agentName> subagent launched" (TUI toast, always)
//   - question.asked    → "New question asked in <session>" (system notification, only if Ghostty not focused)
//   - session.idle      → "All tasks complete in <session>" (system notification, only if Ghostty not focused)

import { execFile } from "child_process"
import type { Plugin } from "@opencode-ai/plugin"

/**
 * Check if Ghostty is the frontmost application using osascript.
 * Returns true if Ghostty has focus, false otherwise or on error.
 */
async function isGhosttyFrontmost(): Promise<boolean> {
  try {
    const result = await Bun.$`osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true'`
    return result.stdout.toString().trim() === "Ghostty"
  } catch {
    return false
  }
}

function sendNotification(title: string, message: string) {
  execFile(
    "terminal-notifier",
    ["-title", title, "-message", message, "-sound", "default", "-activate", "com.mitchellh.ghostty"],
    (err) => {
      if (err) {
        console.warn(`[notifications] failed to send notification: ${err.message}`)
      }
    },
  )
}

/**
 * Send a notification only if Ghostty is NOT the frontmost app.
 * If Ghostty is focused, the user is already looking at the TUI.
 */
async function sendNotificationIfNotFocused(title: string, message: string) {
  if (await isGhosttyFrontmost()) return
  sendNotification(title, message)
}

export const NotificationsPlugin: Plugin = async ({ directory, client }) => {
  // Track active subagent sessions to know when "all tasks are done".
  let activeSubagents = 0

  // Track which sessions are subagents (have a parentID) so we only
  // notify "All tasks complete" when the root/parent session goes idle,
  // not when individual subagents finish.
  const subagentSessions = new Set<string>()

  // Cache session titles to avoid repeated API calls.
  const sessionTitles = new Map<string, string>()

  const dirname = directory.split("/").pop() ?? "OpenCode"

  async function getSessionTitle(sessionID: string): Promise<string> {
    const cached = sessionTitles.get(sessionID)
    if (cached) return cached

    try {
      const res = await client.session.get({ path: { id: sessionID } })
      const title = res.data?.title ?? "OpenCode"
      sessionTitles.set(sessionID, title)
      return title
    } catch {
      return "OpenCode"
    }
  }

  /**
   * Send a system notification, but only if Ghostty is not focused.
   */
  function notify(sessionID: string | undefined, message: string) {
    const title = `Agent - ${dirname}`
    if (!sessionID) {
      sendNotificationIfNotFocused(title, `${message} in OpenCode`)
      return
    }
    getSessionTitle(sessionID).then((sessionName) => {
      sendNotificationIfNotFocused(title, `${message} in ${sessionName}`)
    })
  }

  /**
   * Show a TUI toast message inside the terminal.
   * Always shown regardless of Ghostty focus state.
   */
  function showToast(message: string) {
    client.tui.showToast({ body: { message, variant: "info" } })
  }

  return {
    event: async ({ event }) => {
      const type = event.type
      const properties = event.properties ?? {}

      switch (type) {
        // A permission question needs user input — notify so they notice
        // even if the terminal is not in the foreground.
        case "permission.asked": {
          const sessionID = properties.sessionID as string | undefined
          notify(sessionID, "Question needs your answer")
          break
        }

        // Track subagent lifecycle for "all tasks done" detection.
        case "session.created": {
          const info = properties.info ?? properties
          if (info?.parentID) {
            activeSubagents++
            subagentSessions.add(info.id)
          }
          // Cache session title from the event if available.
          if (info?.id && info?.title) {
            sessionTitles.set(info.id, info.title)
          }
          if (!info?.parentID) return
          // Always show TUI toast for subagent launches (in-context awareness).
          const agentName = info.agent ?? "Subagent"
          showToast(`${agentName} subagent launched`)
          break
        }

        // A question was asked by the agent.
        case "question.asked": {
          const sessionID = properties.sessionID as string | undefined
          notify(sessionID, "New question asked")
          break
        }

        case "session.idle": {
          const sessionID = properties.sessionID as string | undefined
          if (sessionID && subagentSessions.has(sessionID)) {
            // Subagent completed — just decrement, no notification.
            subagentSessions.delete(sessionID)
            if (activeSubagents > 0) {
              activeSubagents--
            }
          } else {
            // Root/parent session completed — notify if there were subagents.
            if (activeSubagents > 0) {
              activeSubagents = 0
            }
            notify(sessionID, "All tasks complete")
          }
          break
        }

        case "session.deleted": {
          // Reset counter and clean up tracking on session cleanup.
          const sessionID = properties.sessionID as string | undefined
          if (sessionID) subagentSessions.delete(sessionID)
          if (activeSubagents > 0) {
            activeSubagents = Math.max(0, activeSubagents - 1)
          }
          break
        }
      }
    },
  }
}

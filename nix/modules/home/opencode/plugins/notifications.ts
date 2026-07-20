// macOS notification plugin for OpenCode.
//
// Sends system notifications via terminal-notifier (brew package) for events
// that require user attention or signal completion. This complements the
// in-app toasts with persistent system notifications that appear even when
// the terminal is not in the foreground.
//
// Notification triggers:
//   - permission.asked  → "Question needs your answer"
//   - session.idle      → "All tasks complete" (when no active subagents)

import { execFile } from "child_process"
import type { Plugin } from "@opencode-ai/plugin"

function sendNotification(title: string, message: string) {
  execFile(
    "terminal-notifier",
    ["-title", title, "-message", message, "-sound", "default"],
    (err) => {
      if (err) {
        console.warn(`[notifications] failed to send notification: ${err.message}`)
      }
    },
  )
}

export const NotificationsPlugin: Plugin = async () => {
  // Track active subagent sessions to know when "all tasks are done".
  let activeSubagents = 0

  return {
    event: async ({ event }) => {
      const type = event.type
      const properties = event.properties ?? {}

      switch (type) {
        // A permission question needs user input — notify so they notice
        // even if the terminal is not in the foreground.
        case "permission.asked": {
          sendNotification("OpenCode", "Question needs your answer")
          break
        }

        // Track subagent lifecycle for "all tasks done" detection.
        case "session.created": {
          const info = properties.info ?? properties
          if (info?.parentID) {
            activeSubagents++
          }
          if (!info?.parentID) return
          const agentName = info.agent ?? "Subagent"
          sendNotifiction(`${agentName} subagent launched`)
          break
        }

        case "session.idle": {
          // Only fire "all done" when the session goes idle AND there are
          // no active subagents remaining.
          if (activeSubagents > 0) {
            activeSubagents = Math.max(0, activeSubagents - 1)
          }
          if (activeSubagents === 0) {
            sendNotification("OpenCode", "All tasks complete")
          }
          break
        }

        case "session.deleted": {
          // Reset counter on session cleanup.
          if (activeSubagents > 0) {
            activeSubagents = Math.max(0, activeSubagents - 1)
          }
          break
        }
      }
    },
  }
}

// Subagent launch notification plugin for OpenCode.
//
// Shows an in-app toast every time a subagent session is created via the
// Task tool on behalf of a primary agent. Subagent sessions are regular
// `session.created` events whose `info.parentID` is set (unlike root/user
// sessions) and whose `info.agent` carries the resolved subagent name.

import type { Plugin } from "@opencode-ai/plugin"

export const SubagentLaunchPlugin: Plugin = async ({ client }) => {
  return {
    event: async ({ event }) => {
      if (event.type !== "session.created") return

      const info = event.properties?.info ?? event.properties
      if (!info?.parentID) return

      const agentName = info.agent ?? "Subagent"
      await client.tui.showToast({
        body: { message: `${agentName} subagent launched`, variant: "info" },
      })
    },
  }
}

{ ... }:

let
  # OpenCode agent-oriented configuration.
  #
  # Goal: keep the primary agents' (build, plan) conversation threads focused
  # on orchestration and summaries by having them delegate research,
  # multi-file exploration, and web-fetch/lookup work to subagents instead of
  # doing that work inline.
  #
  # This is expressed as a Nix attrset and serialized with `builtins.toJSON`
  # rather than checked in as a static `.jsonc` file (matching the inline
  # config pattern used by `fish.nix`). JSONC comments are lost in the
  # generated output, so intent is documented here instead, where the config
  # is actually authored and reviewed.

  # Shared delegation prompt, applied to both `build` and `plan` primary
  # agents so their delegation behavior stays in sync without duplicating
  # the instruction text.
  delegatePrompt = ''
    When a task requires researching across multiple files, exploring
    the codebase, or fetching/searching the web for documentation,
    delegate that work to a subagent via the Task tool instead of
    performing it inline. Use `explore` or `general` for codebase
    research and file exploration, `scout` for dependency/library
    source inspection, and `web-research` for web fetches and web
    searches. Keep the main conversation thread focused on
    orchestration and summarizing subagent results.
  '';

  # Only allow delegation to the intended subagents. "*" = deny first,
  # then specific allows — last matching rule wins per OpenCode's
  # permission evaluation order. Shared by both `build` and `plan`.
  delegateTaskPermission = {
    "*" = "deny";
    explore = "allow";
    scout = "allow";
    general = "allow";
    web-research = "allow";
  };

  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";

    agent = {
      build = {
        # Instruct the primary agent to prefer delegating non-trivial work
        # (research, multi-file exploration, web lookups) to subagents rather
        # than performing it inline. This is advisory/prompt-driven — OpenCode
        # has no config primitive to mechanically force tool calls into
        # subagents.
        prompt = delegatePrompt;
        permission.task = delegateTaskPermission;
      };

      # The `plan` primary agent gets the same delegation behavior as
      # `build`, for parity across primary agents.
      plan = {
        prompt = delegatePrompt;
        permission.task = delegateTaskPermission;
      };

      # Custom subagent for general web research. The built-in `scout`
      # subagent is scoped to dependency/library source inspection (cloning
      # and inspecting upstream repos), not general web browsing or
      # documentation lookups, so a dedicated subagent is needed here.
      web-research = {
        description = "Performs web searches and fetches web pages/documentation on behalf of the primary agent.";
        mode = "subagent";
        permission = {
          webfetch = "allow";
          websearch = "allow";
          edit = "deny";
          bash = "deny";
        };
      };
    };
  };

  # Subagent-launch toast plugin: shows a toast every time a subagent session
  # is created (i.e. a session launched via the Task tool on behalf of a
  # primary agent), naming the subagent type/name that was launched.
  # OpenCode has no dedicated "task launched" event — subagent sessions are
  # regular `session.created` events whose `info.parentID` is set (unlike
  # root/user sessions) and whose `info.agent` carries the resolved subagent
  # name. Kept as a separate plugin file from `rtk.ts` (managed by `rtk.nix`'s
  # activation script) since OpenCode loads all files in the plugins
  # directory independently.
  subagentLaunchPlugin = ''
    export const SubagentLaunchPlugin = async ({ client }) => {
      return {
        event: async ({ event }) => {
          if (event.type !== "session.created") return
          const info = event.properties?.info ?? event.properties
          if (!info?.parentID) return
          await client.tui.showToast({
            body: { message: `''${info.agent ?? "Subagent"} Subagent launched`, variant: "info" },
          })
        },
      }
    }
  '';
in
{
  xdg.configFile."opencode/opencode.jsonc".text = builtins.toJSON opencodeConfig;
  xdg.configFile."opencode/plugins/subagent-launch.ts".text = subagentLaunchPlugin;
}

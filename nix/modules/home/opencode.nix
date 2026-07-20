{ pkgs, ... }:

let
  # OpenCode agent-oriented configuration.
  #
  # Architecture:
  #   - Agent config (opencode.jsonc): generated inline as a Nix attrset,
  #     serialized with `builtins.toJSON`. Comments live here since JSONC
  #     loses them on serialization.
  #   - Plugins (.ts files): sourced from nix/modules/home/opencode/plugins/
  #     and deployed via xdg.configFile. Edit the source files directly —
  #     Nix just copies them to ~/.config/opencode/plugins/.
  #   - Agents (.md files): sourced from nix/modules/home/opencode/agents/
  #     and deployed via xdg.configFile. Each file defines one subagent
  #     with frontmatter (model, permissions) and a prompt body.
  #
  # Source directory layout:
  #   nix/modules/home/opencode/
  #   ├── plugins/
  #   │   ├── subagent-launch.ts   — toast on subagent launch
  #   │   └── notifications.ts     — macOS system notifications
  #   └── agents/
  #       ├── thinking.md          — deep reasoning subagent
  #       ├── code-reviewer.md     — tech-specific code reviewer
  #       └── research-summarizer.md — research consolidation subagent

  opencodeSource = ./opencode;

  # Shared delegation prompt, applied to both `build` and `plan` primary
  # agents so their delegation behavior stays in sync without duplicating
  # the instruction text.
  #
  # Philosophy: primary agents are ORCHESTRATORS only. They delegate ALL
  # non-trivial work to subagents and keep their conversation thread
  # focused on coordination and summarizing results. The only work a
  # primary agent should do inline is: (1) answering direct user questions
  # that require no tool use, (2) final assembly of subagent results into
  # a response, and (3) simple single-step operations.
  delegatePrompt = ''
    You are an orchestration agent. Delegate ALL work to subagents via the
    Task tool. Never perform research, exploration, analysis, web fetching,
    or multi-step reasoning inline. Keep your conversation thread focused
    on coordinating subagents and summarizing their results.

    Subagent mapping:
    - Codebase exploration, file reading, grep/search across files → `explore`
    - Dependency/library source inspection → `scout`
    - General multi-step tasks, file editing, code changes → `general`
    - Web searches, documentation lookups, URL fetching → `web-research`
    - Complex reasoning, architectural decisions, structured analysis → `thinking`
    - Tech-specific code review, correctness, patterns, edge cases → `code-reviewer`
    - Consolidating research findings into concise summaries → `research-summarizer`

    The only exceptions for inline work:
    - Direct answers to simple user questions (no tools needed)
    - Final assembly of subagent results into a coherent response
    - Simple single-step operations (e.g., running a single command)

    When in doubt, delegate. A subagent that wasn't needed is cheaper than
    a bloated primary conversation thread.
  '';

  # Only allow delegation to the intended subagents. "*" = deny first,
  # then specific allows — last matching rule wins per OpenCode's
  # permission evaluation order. Shared by both `build` and `plan`.
  delegateTaskPermission = {
    "*" = "deny";
    explore = "allow";
    scout = "allow";
    general = "allow";
    "web-research" = "allow";
    thinking = "allow";
    "code-reviewer" = "allow";
    "research-summarizer" = "allow";
  };

  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";

    agent = {
      build = {
        # Primary orchestrator agent. Delegates ALL non-trivial work to
        # subagents via the Task tool. Only handles direct user questions
        # and final assembly of subagent results inline.
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
        # Model: inherits from primary by default. To override, uncomment
        # and set a specific model, e.g.:
        #   model = "headroom/claude-sonnet-4-6";
        permission = {
          webfetch = "allow";
          websearch = "allow";
          edit = "deny";
          bash = "deny";
        };
      };

      # Thinking subagent: deep reasoning and structured analysis.
      # Definition lives in nix/modules/home/opencode/agents/thinking.md — this
      # entry only adds config that can't be expressed in frontmatter
      # (or needs to override the .md file).
      thinking = {
        description = "Deep reasoning and analysis. Use for complex planning, architectural decisions, and structured thinking.";
        mode = "subagent";
        # Model: inherits from primary by default. To override, uncomment
        # and set a specific model, e.g.:
        #   model = "headroom/claude-opus-4-6";
        permission = {
          read = "allow";
          grep = "allow";
          glob = "allow";
          list = "allow";
          edit = "deny";
          bash = "deny";
          webfetch = "deny";
          websearch = "deny";
        };
      };
    };
  };
in
{
  # Agent config (JSONC) — generated from the Nix attrset above.
  xdg.configFile."opencode/opencode.jsonc".text = builtins.toJSON opencodeConfig;

  # Plugins — deployed from source files. Edit the .ts files in
  # nix/modules/home/opencode/plugins/ directly; Nix copies them on build.
  xdg.configFile."opencode/plugins/subagent-launch.ts".source =
    "${opencodeSource}/plugins/subagent-launch.ts";
  xdg.configFile."opencode/plugins/notifications.ts".source =
    "${opencodeSource}/plugins/notifications.ts";

  # Agent prompt files — deployed from source .md files. These define
  # the system prompt and frontmatter for custom subagents.
  xdg.configFile."opencode/agents/thinking.md".source = "${opencodeSource}/agents/thinking.md";
  xdg.configFile."opencode/agents/code-reviewer.md".source =
    "${opencodeSource}/agents/code-reviewer.md";
  xdg.configFile."opencode/agents/research-summarizer.md".source =
    "${opencodeSource}/agents/research-summarizer.md";
}

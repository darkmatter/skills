{ agent-skills }:
{ lib, personalAgentSkillsPath ? null, ... }:
{
  imports = [
    agent-skills.homeManagerModules.default
  ];

  programs.agent-skills = lib.mkMerge [
    {
      sources.darkmatter = {
        path = ./skills;
        idPrefix = "darkmatter";
      };

      skills.enableAll = [ "darkmatter" ];

      targets.agents.enable = true;
      targets.claude.enable = true;
      targets.codex.enable = true;
    }
    (lib.mkIf (personalAgentSkillsPath != null) {
      sources.personal = {
        path = personalAgentSkillsPath;
        idPrefix = "personal";
      };

      skills.enableAll = [ "personal" ];
    })
  ];

  # NOTE: OpenCode skill install inconsistency — personal skills from
  # `personalAgentSkillsPath` flow into Claude/Codex/agents targets via
  # `programs.agent-skills` above, but the OpenCode xdg.configFile block
  # below only symlinks the team-wide `skills/` directory.  Merging two
  # source directories into a single symlink target is not possible with
  # xdg.configFile.  To get personal skills into OpenCode, either:
  #   (a) add a second xdg.configFile entry per personal skill (requires
  #       enumerating skill names), or
  #   (b) replace the directory symlink with a generation script that
  #       creates per-skill symlinks from both sources.
  # Until resolved, personal skills are available in Claude/Codex but
  # not in OpenCode.
  xdg.configFile = {
    "opencode/AGENTS.md".source = ./presets/base/AGENTS.md;
    "opencode/opencode.jsonc".source = ./presets/opencode/opencode.jsonc;
    "opencode/tui.json".source = ./presets/opencode/tui.json;
    "opencode/package.json".source = ./presets/opencode/package.json;
    "opencode/agents".source = ./presets/opencode/agents;
    "opencode/commands".source = ./presets/opencode/commands;
    "opencode/plugins".source = ./presets/opencode/plugins;
    "opencode/tools".source = ./presets/opencode/tools;
    "opencode/themes".source = ./presets/opencode/themes;
    "opencode/modes".source = ./presets/opencode/modes;
    "opencode/skills".source = ./skills;
  };
}

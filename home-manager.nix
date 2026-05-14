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

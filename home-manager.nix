{ agent-skills }:
{ lib, pkgs, config, personalAgentSkillsPath ? null, personalOpencodeSettings ? { }, ... }:
let
  # Each subdirectory is one skill. Non-directory entries (.DS_Store,
  # README.md, etc) are skipped so they don't get wrapped as SKILL.md.
  readSkills = path:
    let
      entries = builtins.readDir path;
      onlyDirs = lib.filterAttrs (_: type: type == "directory") entries;
    in
    lib.mapAttrs' (name: _: lib.nameValuePair name (path + "/${name}")) onlyDirs;

  teamSkills = readSkills ./skills;
  personalSkills =
    if personalAgentSkillsPath != null then readSkills personalAgentSkillsPath else { };
in
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

  # opencode.json is written as a mutable copy (not an HM symlink) via
  # home.activation so opencode can modify it at runtime. We still use
  # programs.opencode for everything else (tui, context, commands, etc.).
  programs.opencode = {
    enable = lib.mkDefault true;
    # Note: this also installs pkgs.opencode into home.packages. Override
    # with `programs.opencode.package = ...` if you manage the binary
    # elsewhere, or set `programs.opencode.enable = false` to skip the
    # whole module (configs included). We can't set `package = null`
    # here due to an upstream HM bug in the warnings block (calls
    # versionAtLeast on a null version).
    # settings is intentionally NOT set — opencode.json is written by
    # home.activation.opencodeJson below so opencode can write back to it.

    tui = {
      diff_style = "auto";
      mouse = true;
    };

    context = ./presets/base/AGENTS.md;
    commands = ./presets/opencode/commands;
    agents = ./presets/opencode/agents;
    tools = ./presets/opencode/tools;
    themes = ./presets/opencode/themes;

    # Per-skill entries merge team + personal sources into a single
    # opencode/skills directory, which fixes the prior limitation
    # documented in this module's history.
    skills = teamSkills // personalSkills;
  };


  # Entries the canonical programs.opencode module does not yet
  # support. `recursive = true` keeps the parent directory real so
  # opencode can drop files alongside the managed symlinks.
  # xdg.configFile = {
  #   "opencode/plugins" = {
  #     source = ./presets/opencode/plugins;
  #     recursive = true;
  #   };
  # };
}

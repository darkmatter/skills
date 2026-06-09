{ agent-skills }:
{ lib, pkgs, personalAgentSkillsPath ? null, opencodeConfigOverlays ? [ ], ... }:
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

  baseOpencodeSettings = import ./presets/opencode/opencode.nix;
  opencodeSettings = lib.foldl' (
    previous: overlay:
      lib.recursiveUpdate previous (overlay previous)
  ) baseOpencodeSettings opencodeConfigOverlays;
  opencodeJson = builtins.toJSON opencodeSettings;
  opencodeJsonFile = pkgs.writeText "darkmatter-opencode.jsonc" opencodeJson;
  opencodeJsonHash = builtins.hashString "sha256" opencodeJson;
  jsonFormat = pkgs.formats.json {};

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

  # opencode.jsonc is written as a mutable copy (not an HM symlink) via
  # home.activation so opencode can modify it at runtime. We still use
  # programs.opencode for everything else (tui, context, commands, etc.).
  programs.opencode = {
    enable = true;
    # Note: this also installs pkgs.opencode into home.packages. Override
    # with `programs.opencode.package = ...` if you manage the binary
    # elsewhere, or set `programs.opencode.enable = false` to skip the
    # whole module (configs included). We can't set `package = null`
    # here due to an upstream HM bug in the warnings block (calls
    # versionAtLeast on a null version).
    # settings is intentionally NOT set — opencode.jsonc is written by
    # home.activation.opencodeJson below so opencode can write back to it.

    # tui = {
    #   diff_style = "auto";
    #   mouse = true;
    #   theme = "aura";
    # };

    context = ./presets/base/AGENTS.md;
    commands = ./presets/opencode/commands;
    agents = ./presets/opencode/agents;
    themes = ./presets/opencode/themes;

    # Per-skill entries merge team + personal sources into a single
    # opencode/skills directory, which fixes the prior limitation
    # documented in this module's history.
    skills = teamSkills // personalSkills;
  };

  home.activation.opencodeJson = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    _oc_src="${opencodeJsonFile}"
    _oc_dst="$HOME/.config/opencode/opencode.json"
    _oc_marker="$HOME/.config/opencode/.opencode-json.source-hash"
    _oc_hash="${opencodeJsonHash}"

    mkdir -p "$(dirname "$_oc_dst")"

    _oc_file_hash() {
      ${pkgs.coreutils}/bin/sha256sum "$1" | cut -d ' ' -f 1
    }

    if [ -L "$_oc_dst" ]; then
      rm -f "$_oc_dst"
      cp -f "$_oc_src" "$_oc_dst"
      printf '%s\n' "$_oc_hash" > "$_oc_marker"
    elif [ ! -e "$_oc_dst" ]; then
      cp -f "$_oc_src" "$_oc_dst"
      printf '%s\n' "$_oc_hash" > "$_oc_marker"
    else
      _oc_current_hash="$(_oc_file_hash "$_oc_dst")"
      _oc_previous_hash=""
      if [ -f "$_oc_marker" ]; then
        _oc_previous_hash="$(cat "$_oc_marker")"
      fi

      if [ "$_oc_current_hash" = "$_oc_hash" ]; then
        printf '%s\n' "$_oc_hash" > "$_oc_marker"
      elif [ -n "$_oc_previous_hash" ] && [ "$_oc_current_hash" = "$_oc_previous_hash" ]; then
        cp -f "$_oc_src" "$_oc_dst"
        printf '%s\n' "$_oc_hash" > "$_oc_marker"
      else
        _oc_backup="$_oc_dst.bak.$(${pkgs.coreutils}/bin/date +%Y%m%d%H%M%S)"
        mv -f "$_oc_dst" "$_oc_backup"
        cp -f "$_oc_src" "$_oc_dst"
        printf '%s\n' "$_oc_hash" > "$_oc_marker"
      fi
    fi
  '';

  # tools = ./presets/opencode/tools is intentionally NOT set here.
  #
  # programs.opencode.tools installs files as Nix-store symlinks, but Bun
  # (opencode's runtime) resolves `node_modules` from the *canonical* path of
  # each file. Since symlinks resolve into /nix/store, it can't find
  # ~/.config/opencode/node_modules and the import of @opencode-ai/plugin/tool
  # fails with a ResolveMessage error, crashing every opencode session.
  #
  # Fix: copy the source files as real (non-symlinked) files via activation so
  # Bun resolves node_modules from ~/.config/opencode/ instead.
  home.activation.opencodeTools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    _oc_src="${toString ./presets/opencode/tools}"
    _oc_dst="$HOME/.config/opencode/tools"
    mkdir -p "$_oc_dst"
    for _f in "$_oc_src"/*.ts; do
      _name=$(basename "$_f")
      cp -Lf "$_f" "$_oc_dst/$_name"
    done
    touch "$_oc_dst/.gitkeep"
  '';

  home.activation.opencodePlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    _oc_src="${toString ./presets/opencode/plugins}"
    _oc_dst="$HOME/.config/opencode/plugins"
    mkdir -p "$_oc_dst"
    for _entry in "$_oc_src"/*; do
      _name=$(basename "$_entry")
      [ "$_name" = ".DS_Store" ] && continue
      # Files/dirs copied from the nix store are read-only; make them writable
      # before removal so rm -rf can traverse and delete subdirectories.
      chmod -Rf u+w "$_oc_dst/$_name" 2>/dev/null || true
      rm -rf "$_oc_dst/$_name"
      cp -Rf "$_entry" "$_oc_dst/$_name"
      # Ensure the copy is writable so future activations can remove it.
      chmod -Rf u+w "$_oc_dst/$_name" 2>/dev/null || true
    done
    touch "$_oc_dst/.gitkeep"
  '';

  # oh-my-openagent.json is written as a regular writable file, but reset from
  # the curated preset on every activation. This lets the plugin mutate it at
  # runtime without preserving drift across rebuilds.
  home.activation.ohMyOpenagentJson = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    _oma_src="${toString ./presets/opencode/oh-my-openagent.jsonc}"
    _oma_dst="$HOME/.config/opencode/oh-my-openagent.json"

    mkdir -p "$(dirname "$_oma_dst")"
    rm -f "$_oma_dst"
    cp -f "$_oma_src" "$_oma_dst"
    chmod u+w "$_oma_dst"
  '';
}

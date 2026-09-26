{
  description = "Darkmatter shared agent skills catalog";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    agent-skills.url = "github:Kyure-A/agent-skills-nix";
    flake-skills.url = "github:papercomputeco/flake-skills";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{
      flake-parts,
      agent-skills,
      flake-skills,
      nixpkgs,
      ...
    }:
    let
      # Shared instruction topics, discovered from docs/agents/ so the
      # registry cannot drift from the directory. Each file is one topic,
      # named <order>-<topic>.md: the numeric prefix sets the bundle order
      # (attrNames and attrValues sort alphabetically, so the order must
      # live in the filename), and the suffix is the topic name downstream
      # repos import via inputs.darkmatter-skills.agentsMd.<topic>. A new
      # file is importable and bundled automatically; a misnamed file or a
      # duplicate topic name fails evaluation.
      agentsMdTopics =
        let
          dir = ./docs/agents;
          fileNames = builtins.filter (name: builtins.substring 0 1 name != ".") (
            builtins.attrNames (builtins.readDir dir)
          );
          parsed = map (fileName: {
            parts = builtins.match "([0-9]+)-([a-z0-9-]+)\\.md" fileName;
            inherit fileName;
          }) fileNames;
          invalid = map (p: p.fileName) (builtins.filter (p: p.parts == null) parsed);
          topics = map (p: {
            order = nixpkgs.lib.toInt (builtins.head p.parts);
            name = builtins.elemAt p.parts 1;
            path = dir + ("/" + p.fileName);
          }) parsed;
          names = map (t: t.name) topics;
          duplicates = builtins.filter (
            name: builtins.length (builtins.filter (n: n == name) names) > 1
          ) names;
        in
        if invalid != [ ] then
          throw "docs/agents: topic files must be named <number>-<topic>.md, got: ${toString invalid}"
        else if duplicates != [ ] then
          throw "docs/agents: duplicate topic names: ${toString (nixpkgs.lib.unique duplicates)}"
        else
          nixpkgs.lib.sort (a: b: a.order < b.order || (a.order == b.order && a.name < b.name)) topics;
      topicTexts = map (topic: builtins.readFile topic.path) agentsMdTopics;

      flake = flake-parts.lib.mkFlake { inputs = inputs; } {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ];

        imports = [
          inputs.treefmt-nix.flakeModule
          ./nix/flake/modules/flake-parts/sops-nix.nix
        ];

        flake = {
          # Downstream interface: topic name -> source path. Consumers read a
          # chosen subset and concatenate it with their own text.
          agentsMd = builtins.listToAttrs (
            map (topic: nixpkgs.lib.nameValuePair topic.name topic.path) agentsMdTopics
          );

          homeManagerModules.default = import ./nix/home-manager.nix { inherit agent-skills; };
          homeManagerModules.shared = import ./nix/home-manager.nix { inherit agent-skills; };
        };

        perSystem =
          { pkgs, lib, ... }:
          let
            # docs/AGENTS.md — every topic in one file. Generated and
            # committed because the Home Manager module, install-base.sh,
            # and the evals harness consume it as a plain file, not a
            # derivation. Refresh with:
            #   cp "$(nix build --no-link --print-out-paths .#agents-md-shared)" docs/AGENTS.md
            sharedAgentsMd = pkgs.writeText "AGENTS.md" (
              lib.concatStringsSep "\n" (
                [
                  "<!-- Generated file — do not edit. nix build .#agents-md-shared renders it from the docs/agents/ topics. -->"
                ]
                ++ topicTexts
              )
            );

            # The committed root AGENTS.md — every topic plus this repo's own
            # section. Fully generated; refresh with:
            #   cp "$(nix build --no-link --print-out-paths .#agents-md)" AGENTS.md
            agentsMdFile = pkgs.writeText "AGENTS.md" (
              lib.concatStringsSep "\n" (
                [
                  "<!-- Generated file — do not edit. nix build .#agents-md renders it from docs/agents/ (shared topics) and docs/AGENTS.repo.md (this repo). -->"
                ]
                ++ topicTexts
                ++ [ (builtins.readFile ./docs/AGENTS.repo.md) ]
              )
            );
          in
          {
            packages.agents-md = agentsMdFile;
            packages.agents-md-shared = sharedAgentsMd;

            # Fails when either committed file (AGENTS.md, docs/AGENTS.md)
            # drifts from the topics — a topic edit without a refresh.
            checks.agents-md = pkgs.runCommand "check-agents-md" { } ''
              diff -u ${./AGENTS.md} ${agentsMdFile}
              diff -u ${./docs/AGENTS.md} ${sharedAgentsMd}
              touch $out
            '';

            treefmt = {
              projectRootFile = "flake.nix";
              settings = {
                global.excludes = [
                  "skills/writing-skills/anthropic-best-practices.md"
                ];
              };
              programs = {
                oxfmt.enable = true;
                nixf-diagnose.enable = true;
                nixfmt.enable = true;
                shellcheck.enable = true;
                beautysh.enable = true;
              };
            };
          };
      };

      skillsFlake = flake-skills.lib.mkSkillsFlake {
        inherit (inputs) nixpkgs;
        skillsSrc = ./skills;
      };

      # flake-parts and mkSkillsFlake each populate the top-level `packages`
      # per system; `//` would keep only one side, so union per system.
      packages =
        let
          mergePerSystem = _system: values: nixpkgs.lib.foldl' nixpkgs.lib.mergeAttrs { } values;
        in
        nixpkgs.lib.zipAttrsWith mergePerSystem [
          (flake.packages or { })
          (skillsFlake.packages or { })
        ];
    in
    flake // skillsFlake // { inherit packages; };
}

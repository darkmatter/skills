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
      # attrNames sorts filenames, so zero-padded prefixes define bundle order.
      agentsMdTopics =
        let
          dir = ./docs/agents;
          entries = builtins.readDir dir;
          files = builtins.filter (name: entries.${name} == "regular") (builtins.attrNames entries);
          parse =
            file:
            let
              parts = builtins.match "[0-9]+-([a-z0-9-]+)\\.md" file;
            in
            if parts == null then
              throw "docs/agents: topic files must be named <number>-<topic>.md, got: ${file}"
            else
              {
                name = builtins.head parts;
                path = dir + "/${file}";
              };
          topics = map parse files;
          names = map (topic: topic.name) topics;
        in
        if builtins.length names != builtins.length (nixpkgs.lib.unique names) then
          throw "docs/agents: topic names must be unique"
        else
          topics;
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

            # Structure, relative links, catalog parity, and the CLI
            # regression tests. lychee runs offline over owned Markdown only;
            # vendored .gitmodules trees are excluded by the CLI.
            checks.skills =
              pkgs.runCommand "check-skills"
                {
                  nativeBuildInputs = [
                    pkgs.bash
                    pkgs.lychee
                    pkgs.python3
                  ];
                  # lychee builds its HTTP client even in --offline mode and
                  # aborts when it cannot find a CA bundle in the sandbox.
                  SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
                }
                ''
                  cd ${./.}
                  bash scripts/validate-skill.sh
                  python3 scripts/test_validate_skill.py
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

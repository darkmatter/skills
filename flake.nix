{
  description = "Darkmatter shared agent skills catalog";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    agent-skills.url = "github:Kyure-A/agent-skills-nix";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{ flake-parts, agent-skills, ... }:
    flake-parts.lib.mkFlake { inputs = inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      imports = [
        inputs.treefmt-nix.flakeModule
        ./flake/modules/flake-parts/sops-nix.nix
      ];

      flake = {
        homeManagerModules.default = import ./home-manager.nix { inherit agent-skills; };
        homeManagerModules.shared = import ./home-manager.nix { inherit agent-skills; };
      };

      perSystem =
        { pkgs, ... }:
        {
          # `nix run github:darkmatter/skills#install [-- --check] [<repo>]`
          # renders docs/AGENTS.md into a repo's AGENTS.md (creating it and a
          # CLAUDE.md shim when missing). The script resolves the source via
          # DARKMATTER_AGENTS_MD because the flake source is not a checkout it
          # can locate relative to its own path.
          apps.install = {
            type = "app";
            program = toString (
              pkgs.writeShellScript "darkmatter-install" ''
                export DARKMATTER_AGENTS_MD=${./docs/AGENTS.md}
                exec ${pkgs.bash}/bin/bash ${./scripts/render-agents.sh} "$@"
              ''
            );
          };

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
}

{
  description = "Darkmatter shared agent skills catalog";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    agent-skills.url = "github:Kyure-A/agent-skills-nix";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ flake-parts, agent-skills, ... }:
    flake-parts.lib.mkFlake { inputs = inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      imports = [
        ./flake/modules/flake-parts/sops-nix.nix
      ];

      flake = {
        homeManagerModules.default = import ./home-manager.nix { inherit agent-skills; };
        homeManagerModules.shared  = import ./home-manager.nix { inherit agent-skills; };
      };
    };
}

# Skill hydration builds a derivation during evaluation. Keep this check native
# and outside flake outputs so all-system inventory does not require cross builds.
let
  flake = builtins.getFlake (toString ../.);
  pkgs = flake.inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
  home = flake.inputs.agent-skills.inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs = {
      personalAgentSkillsPath = null;
      opencodeConfigOverlays = [ ];
    };
    modules = [
      flake.homeManagerModules.default
      {
        home.username = "skills-check";
        home.homeDirectory =
          if pkgs.stdenv.hostPlatform.isDarwin then "/Users/skills-check" else "/home/skills-check";
        home.stateVersion = "25.11";
      }
    ];
  };
in
home.activationPackage.drvPath

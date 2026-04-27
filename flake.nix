{
  description = "Darkmatter shared agent skills catalog";

  inputs = {
    agent-skills.url = "github:Kyure-A/agent-skills-nix";
  };

  outputs = { agent-skills, ... }:
    {
      homeManagerModules.default = import ./home-manager.nix { inherit agent-skills; };
      homeManagerModules.shared = import ./home-manager.nix { inherit agent-skills; };
    };
}

# Flake-parts wrapper for Mic92/sops-nix.
#
# Upstream sops-nix only ships nixosModules / darwinModules / homeManagerModules
# / packages — no flake-parts module — so we expose them here and add a
# username-agnostic `sops` devShell that other flake-parts repos can import.
{ inputs, ... }:
{
  flake = {
    nixosModules.sops  = inputs.sops-nix.nixosModules.sops;
    darwinModules.sops = inputs.sops-nix.darwinModules.sops;
    homeModules.sops   = inputs.sops-nix.homeManagerModules.sops;
  };

  perSystem = { pkgs, system, config, ... }: {
    # Re-export the GPG key import hook so downstream devShells can
    # depend on it without re-deriving the inputs path.
    packages.sops-import-keys-hook =
      inputs.sops-nix.packages.${system}.sops-import-keys-hook;

    # `nix develop` with no attribute resolves to `default`.
    devShells.default = config.devShells.sops;

    devShells.sops = pkgs.mkShell {
      packages = [
        pkgs.sops
        pkgs.age
        pkgs.ssh-to-age
        inputs.sops-nix.packages.${system}.sops-import-keys-hook
      ];
      shellHook = ''
        # Everything resolves through $HOME so this works for any user.
        export SOPS_AGE_KEY_FILE="''${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"
        if [ ! -f "$SOPS_AGE_KEY_FILE" ] && [ -f "$HOME/.ssh/id_ed25519" ]; then
          echo "sops-nix devShell: no age key at $SOPS_AGE_KEY_FILE"
          echo "Derive once with:"
          echo "  mkdir -p \"\$(dirname \"\$SOPS_AGE_KEY_FILE\")\""
          echo "  ssh-to-age -private-key -i \$HOME/.ssh/id_ed25519 > \"\$SOPS_AGE_KEY_FILE\""
        fi
      '';
    };
  };
}

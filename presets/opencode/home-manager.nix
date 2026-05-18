{ lib, ... }:
{
  programs.opencode.settings = import ./opencode.nix;
}

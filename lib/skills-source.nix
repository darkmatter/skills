{
  lib,
  pkgs,
  skillsDir,
  submodules ? import ./skill-submodules.nix,
}:
let
  inherit (pkgs) fetchFromGitHub runCommand;

  fetchSubmodule =
    {
      type,
      owner,
      repo,
      rev,
      hash,
      ...
    }:
    if type != "github" then
      throw "skills-source: unsupported submodule fetch type '${type}'"
    else
      fetchFromGitHub {
        inherit
          owner
          repo
          rev
          hash
          ;
      };

  submoduleOverlays = lib.map (
    entry:
    let
      submoduleSrc = fetchSubmodule entry.fetch;
    in
    ''
      chmod -R u+w "$out/${entry.path}" 2>/dev/null || true
      rm -rf "$out/${entry.path}"
      mkdir -p "$(dirname "$out/${entry.path}")"
      cp -r ${submoduleSrc} "$out/${entry.path}"
    ''
  ) submodules;

in
runCommand "darkmatter-skills-with-submodules" { } ''
  cp -r ${skillsDir} "$out"
  chmod -R u+w "$out"
  ${lib.concatStringsSep "\n  " submoduleOverlays}
''

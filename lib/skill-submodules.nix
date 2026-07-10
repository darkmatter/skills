# Pinned git submodule references for skills that ship upstream source trees.
# Bump `rev` (and `hash`) when updating submodules in the parent repo:
#   git submodule status skills/alchemy/reference/alchemy-effect
[
  {
    path = "alchemy/reference/alchemy-effect";
    fetch = {
      type = "github";
      owner = "alchemy-run";
      repo = "alchemy-effect";
      rev = "7d7f33d40a044205f254a884fcd47d4cf3b259c6";
      hash = "sha256-7uOTQP8ciuzJGZC2xyxEGPsisperJjzW++h5+x90GII=";
    };
  }
  {
    path = "effect-typescript/reference/effect";
    fetch = {
      type = "github";
      owner = "Effect-TS";
      repo = "effect";
      rev = "7e00169ae0a98d0619dc75857ce0a771e7c83da6";
      hash = "sha256-T0hUqsQ333WA/r20BgCbiLuygsd7xblDTR0C1eTlcLo=";
    };
  }
]

# Darkmatter omp — sticky rules (always-apply)

Hard requirements for the unattended github-executor agent. omp keeps these in
context for the entire session (they do not scroll away).

- NEVER run destructive or irreversible commands. Non-exhaustive: `rm -rf /` or
  `rm -rf ~`, recursive deletes outside the working tree, writes to block devices
  or `/dev/*`, `dd` onto disks, `mkfs`, fork bombs (`:(){ :|:& };:`), shutdown /
  reboot, `git push --force` to shared branches, history rewrites on shared
  branches, and piping untrusted network output into a shell (`curl … | sh`).
- NEVER read, print, or commit secrets, private keys, credentials, tokens, or
  local environment files (`.env`, `*.pem`, `id_*`, SOPS-decrypted output).
- Operate only within the checked-out worktree; do not touch files outside it.
- Make the smallest correct change; preserve unrelated user changes.
- Prefer reversible actions. When unsure whether an action is safe, stop and ask
  in a comment instead of proceeding.

# Land and activate the rule

Read after reconciling and editing the note's canonical sources. Publication,
local synchronization, and agent discovery are separate completion gates.

## 1. Map the consumers before publishing

Build a small rollout matrix: source repo, intended consumer, selected input or
install mechanism, effective instruction/skill path, verification method.
Discover this from the invoking project, local skills checkout, active Home
Manager configuration, and configured agent settings. Include project overrides
and configured remote/sandbox consumers; do not equate every possible agent with
every configured agent. Preserve the invoking project's identity throughout.

For an org rule, inspect the skills catalog and shared instruction exports;
include every agent enabled by the actual home configuration. For a local rule,
verify agents in that project and keep the rule out of global installs. Update
Home Manager only if that branch changes a consumed input or its configuration;
otherwise record why it is unchanged.

## 2. Validate the source, then land every changed repo

- Preserve dirty worktrees, staged files, and unrelated unpushed commits. If
  needed, create an isolated worktree from remote `main`; commit and publish only
  this note's changes. Use fast-forward synchronization, not reset, stash, rebase,
  or force-push over user work.
- Run each changed repo's documented checks. In darkmatter/skills, validate each
  edited skill with `scripts/validate-skill.sh skills/<name>` and update its
  catalog entry. If shared instruction topics changed, regenerate both bundled
  instruction files with the flake's `agents-md` / `agents-md-shared` outputs;
  run the generated-instruction drift check. Follow the current flake comments
  for output paths rather than hand-editing generated instructions.
- For a configured Centaur overlay, respect `.agents/skills.manifest` curation:
  workstation-dependent publishing/setup skills stay out. If an eligible skill
  changes, regenerate with `scripts/sync-sandbox-skills.sh` and verify `--check`.
  Verify unconditional policy through the supported instruction export, not by
  adding an unusable skill to the sandbox. Repair missing distribution wiring
  without inventing a new curation set.
- In each changed adhere repo, run its documented `adhere validate` invocation.
  Exercise the changed rule on representative compliant and violating files via
  its supported lint path. Observe the distinction; do not substitute wording
  validation for enforcement proof. Report unavailable judge credentials rather
  than treating a skipped contradiction check as green.
- Open a narrow PR, satisfy CI/review gates, and merge with a merge commit into
  `main`. Respect the repo's approval policy; branch push, open PR, and auto-merge
  registration are not landing evidence. Never bypass required checks or publish
  unrelated commits. If there is no diff, make no empty commit or PR.
- Record the resulting remote `main` SHA and verify it contains the intended
  change for every touched repo, including standards and consumer-rule copies.
  If the source cannot land, finish other independent work and report the exact
  gate; do not call the rollout complete.

## 3. Refresh the local source and copied rules

Fetch and safely fast-forward the canonical skills checkout, the invoking
project checkout recorded at intake, and any local standards/consumer checkout
agents actually read. Preserve local edits and feature-branch identity. If a
checkout cannot advance without switching branches or reconciling unrelated
work, leave it intact and name that blocker; an isolated publishing worktree
does not prove the requested local checkout was refreshed.

Standards installs are owned copies, not live subscriptions. For intended local
consumers, compare imported rules with the landed upstream version, reconcile
local exceptions, and land those consumer edits through step 2. Use the actual
`adhere install` interface; never blanket `--force` across edited copies. Run
`adhere postinstall` when that project's instruction composition requires it,
and verify the generated instruction block. A standards SHA alone does not
prove a project enforces its new rule.

## 4. Refresh the active Home Manager input chain

Find the configuration that owns this machine's active generation, its host/user
selector, and the input chain reaching darkmatter/skills. Follow `follows`,
overrides, and intermediate flakes; a lock update in an unused checkout has no
effect. For example, the shared darkmatter/nix flake calls its skills input
`darkmatter-agents`, but a host may consume that flake through another input.

Update only the relevant input(s) after their upstream changes reach `main`
(e.g. `nix flake update darkmatter-agents` in a flake with that input). Inspect
the resulting lock graph and prove its effective skills revision contains the
landed change. Avoid an unrelated all-input upgrade or permanent local-path
substitution. If an intermediate flake's lock changes, validate and land it
first, then refresh the host's matching input. Land host lock/config edits too
if that configuration is version-controlled and its normal policy permits it.

Build the actual Home Manager/NixOS/Darwin target, then use the host repo's
supported switch command. For standalone Home Manager this is commonly
`home-manager switch --flake <config-root>#<target>`; discover the real command
and selector instead of guessing. Observe successful activation and the new
active generation. Preserve mutable client settings, existing personal skills,
and secrets. A built generation without a successful switch is not applied.

## 5. Prove each configured agent sees the result

For each row of the rollout matrix, inspect the effective installed file and
prove that it resolves to the intended revision/content, including reference
files and generated always-on instructions. Check discovery and precedence,
not just file existence: a stale project skill, plugin, or user override can
shadow a correct global installation.

Use the agent's supported skill listing or a fresh minimal session in the
intended project to prove it discovers the changed skill/instructions. For a
manual skill, confirm invocation without actually replaying publication. Reload
only through supported non-destructive mechanisms. Already-running contexts may
retain old prompts; report which agents were freshly verified and which need a
new session. Do not terminate users' sessions or claim universal hot reload.

Common targets from the shared skills Home Manager module are Claude, Codex,
OpenCode, and the generic `~/.agents/skills` tree; the actual host configuration
and harness discovery paths are authoritative, including OMP if configured.
For a configured remote overlay, observe a fresh agent there as well; remote
unavailability is a named rollout blocker, not local-install proof.

Completion requires every changed repo on remote `main`, all local checkouts
agents read current (including the invoking project), the active home's effective
skills input containing the change, successful activation where needed, and
fresh discovery/enforcement evidence for every configured consumer. If any gate
is blocked, report partially applied and name the missing proof; do not claim
fully live. Repeat runs repair stale distribution but create no duplicate rule,
skill, or commit.

# MOD-06 output - env-sync exact 1-to-1 layout (comments included)

**Trigger:** agent-authored framework change (AI-assisted: yes). Per
`concepts/ai-amplification/prompt.md`.
**Date:** 2026-11-11 · **Ref:** AIOS-1

## AI change risk summary

- **AI-assisted:** yes.
- **Blast radius:** `scripts/env-sync.sh`, its new regression suite, and the
  `env-sync` skill docs. Values cannot change silently: every write still
  compares SHA-256 value fingerprints before/after, backs up every target, and
  restores all backups on mismatch. The deliberate behaviour change is that
  **comments and blank lines are now part of the 1-to-1 contract**: a target
  whose comment text, blank lines, or line count differs from `.env.example` is
  drift, and `apply` regenerates it from the reference skeleton. A target-only
  comment is therefore dropped on rewrite (the same rule already applied when a
  key moved). The live `system-news` trio was **not** written by this change; a
  byte-identical copy was used for the end-to-end proof. Applying to the live
  project remains an explicit operator step with a persistent backup.
- **New file:** `scripts/env-sync-test.sh` (self-contained, dummy values only,
  56 checks, cleans its temp dir).
- **Edited files:** `scripts/env-sync.sh` (layout gate, `layout` reporting,
  target-discovery exclusions), `skills/env-sync/skill.md`,
  `skills/env-sync/reference.md`, `CHANGELOG.md`, `README.md`,
  `skills/README.md`, `skills/ai-director/reference.md` (one row each).
- **Not edited:** `.cursorrules`, `templates/cursorrules.template`,
  `skills/SKILL_DEPENDENCIES.md`, `scripts/framework-verify.sh` (protected). The
  registry wording in `.cursorrules` remains valid but does not spell out the
  comment rule; propagating it needs owner approval.

## Root cause

`file_aligned` compared only key positions and the target key set. A target
could have every key on its canonical line while its comments, blank lines, or
total line count differed, and `verify` still printed `PASS`; `apply` skipped
the file as "already aligned". With explanatory comment blocks added to
`.env.example` (the reported AI block after `AI_API_KEY`), the reference's key
lines moved but a target that did not receive those comments could still be
declared aligned once its key lines happened to match, and the promised
"identical line count / 1-to-1 layout" was not enforced. Reproduced on a
fixture: editing one reference comment with the keys already aligned gave
`ALIGNED ... verify: PASS` before the fix.

## Fix

1. **Full skeleton gate.** `layout_drift TARGET` counts non-key reference lines
   that are not byte-identical at the same line number plus the absolute
   line-count difference. `file_aligned` now requires `layout_drift == 0` in
   addition to the existing key-position and no-extra-key checks.
2. **Reporting.** Per-file summaries in `status` / `verify` / `apply` now show
   `layout:N`; `ALIGNED` requires `layout 0`. The apply plan includes the count
   (`rewrite (missing X, misplaced Y, layout Z)`).
3. **Idempotency.** After `apply`, non-key lines equal the reference, so a
   second run reports "already aligned - nothing to write" and leaves the file
   byte-identical.
4. **Target discovery.** `.keep`, `.save`, `.old`, `.backup`, `.dist` copies are
   no longer treated as targets (a stray `.env.prd.keep` previously entered the
   table).
5. **Regression suite.** `scripts/env-sync-test.sh` proves the reported case,
   comment-only drift, commented-out assignment drift, missing/extra trailing
   lines, dry-run no-write, undeclared-key abort, duplicate reference key, CRLF
   rejection, backup value drift, file mode, reference immutability, and
   idempotency.

## Verification evidence

| Claim | Tag | Evidence |
|-------|-----|----------|
| Reported scenario resolves to 1-to-1 | measured | Copy of the live `system-news` trio (`.env.example` / `.env.dev` / `.env.prd`, 124/118/118 lines before): `apply` rewrote 2 files, 126 values preserved, all three files 124 lines / 63 keys; masked skeleton diff empty for both targets |
| Comment-only drift is caught | measured | One reference comment edited with keys still aligned: `verify` exit 1, `layout 1`; `apply` restored the reference comment and left the value untouched |
| Idempotent | measured | Second `apply` on the copy: "already aligned - nothing to write"; file hash unchanged |
| Values preserved | measured | `verify --backup` PASS on the live-copy backup (126 values); the suite also asserts a sentinel value survives |
| Commented-out assignment normalized | measured | `# CADDY_HTTP_PORT=46133` in the target replaced by the reference's commented line; suite check |
| Fail-closed | measured | Duplicate ref key → exit 2; CRLF target → exit 1; undeclared key → `apply` ABORTED with target hash unchanged; suite checks |
| Regression suite | measured | `bash scripts/env-sync-test.sh` → `PASS (56 checks)` |
| Framework verification | measured | `framework-verify` all checks passed; `skill-functional-verify` PASS; `bash -n` both scripts; `git diff --check` clean |
| Live project untouched | measured | Only `tmp/livecopy2` (workspace copy) was written; `system-news` was read-only |

## Recommendation

merge_ok

**Deliberate trade-off:** a target-only comment is not preserved when the file
needs a rewrite; shared comments belong in `.env.example`. This is the only way
to keep the line-for-line guarantee and idempotency. The live `system-news` files
still show drift (their reference gained the AI comment block after the last
alignment); run `@env-sync apply` there with a persistent backup when ready.

## Follow-ups (non-blocking)

1. Apply the fixed skill to `/mnt/work/Projects/system-news` with a persistent
   backup (`--backup-dir tmp/env-sync-backup-20261111`), then `verify` and
   `verify --backup`.
2. Optionally add the `env-sync` regression case to `scripts/framework-verify.sh`
   (protected) so CI runs `scripts/env-sync-test.sh` automatically.
3. Propagate the updated skill to consumers on the next deploy (NEXT P13 / P1).

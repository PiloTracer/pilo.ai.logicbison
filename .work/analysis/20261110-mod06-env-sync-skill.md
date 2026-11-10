# MOD-06 output — env-sync skill + script (AIOS-1)

**Trigger:** agent-authored framework change (AI-assisted: yes). Per
`concepts/ai-amplification/prompt.md`.
**Date:** 2026-11-10 · **Ref:** AIOS-1

## AI change risk summary

- **AI-assisted:** yes.
- **Blast radius:** the change is a new skill + a new standalone script plus
  registry rows. Existing values cannot change silently (fingerprints are
  compared before/after every write, and backups are restored on mismatch).
  The deliberate semantic change is that a key missing from a target is now
  materialized as an empty assignment (`KEY=`) instead of a comment, so an
  unset variable can become empty (operator decision 2026-11-10) - this can
  alter runtime defaults. No application code, compose file, database, or
  deployment path is touched.
- **New files (self-contained, deleting them reverts the feature):**
  - `skills/env-sync/skill.md`, `skills/env-sync/reference.md` — both under the
    skill soft budget; skill passes `skill-functional-verify`.
  - `scripts/env-sync.sh` — bash 3.2 / POSIX-awk, executable; no new dependency
    (SHA-256 via `sha256sum`, `shasum`, or `openssl`).
- **Surgical edits (existing files, one row/line each):**
  - `skills/README.md` — registry row.
  - `skills/SKILL_DEPENDENCIES.md` — status/verify verb rows + one env-sync
    verb note.
  - `README.md` — 23 → 24 skill prose + skills-at-a-glance row.
  - `skills/ai-director/reference.md` — registry row + count header.
  - `skills/ai-director/skill.md` — one intent-table row.
  - `CHANGELOG.md` — one `[Unreleased]` Added entry.
- **Protected edits (owner-approved in-message, 2026-11-10: "follow your best
  recommendation"):**
  - `skills/SKILL_DEPENDENCIES.md` — verb rows required by `framework-verify`
    ("skill not in SKILL_DEPENDENCIES.md matrix").
  - `.cursorrules` § Skills row (project-protected).
  - `templates/cursorrules.template` § Skills row (framework-protected).
- **Deliberately not edited:**
  - `scripts/framework-verify.sh` — no regression smoke added for the new
    script. The skill ships a reproducible test recipe in
    `reference.md § 6` instead.

## Boundary / reviewability notes

- The script's contract is one screen of user-facing behaviour — `status`
  (read-only table), `verify` (strict gate), `apply` (backup → generate →
  verify → atomic replace → verify → restore-on-fail). Every write is guarded
  by a value-fingerprint comparison; the reference file is never written.
- The layout model now materializes a missing key as `KEY=` (or `export KEY=`)
  on its canonical line: every reference key is a real, greppable assignment.
  The accepted trade-off is *unset* → *empty*; `apply` backs up first, and the
  preservation check only permits added keys when they are empty.
- The reference owns the full key set. A target-only key is a hard error until
  it is promoted into `.env.example` with a comment; there is no trailing extras
  block, so every file has the same number of lines and the same key-to-line
  map. Environment-only keys are empty where unused.
- Each registry edit is a single table row or count token — reviewable as one
  hunk per file.

## Churn risk

- **Low.** No existing skill's protocol was altered; no shared script was
  modified; the new script is opt-in. Docs-only registry edits are isolated.
- **Medium-low** on the operator's `.env*` data when `apply` is used: the first
  run will rewrite the comments/layout of every misaligned target (values
  untouched). Backups make this reversible with one `cp -p` per file.

## Verification evidence

| Claim | Tag | Evidence |
|-------|-----|----------|
| Existing values preserved on the system-news trio | measured | copy + live apply: 122 key values compared (61 per file); independent Python check `LIVE INDEPENDENT: PASS`; `verify --backup` PASS against both the placeholder-state and the original pre-apply backup |
| Same line for every key | measured | `.env.example`, `.env.dev`, `.env.prd`: 114 lines / 61 keys each; identical key sets; independent check asserts every key line matches |
| Missing keys materialized as empty | measured | `.env.dev` 10 added keys, `.env.prd` 7, all `KEY=`; `verify` reports `missing 0`; status shows `ok:N empty`; independent check asserts added values are empty |
| Environment-only keys promoted | measured | `CADDY_HTTP_PORT` / `CADDY_HTTPS_PORT` added to `.env.example` with a two-line comment (lines 22–25), empty in the template, set in dev/prd; all three files identical |
| Idempotent | measured | second `apply` → "already aligned - nothing to write"; file hashes unchanged |
| Fail-closed (no writes) | measured | duplicate reference key → exit 2; CRLF target → exit 1; unterminated quote → exit 1; missing reference → exit 2; live files hashed before/after read-only runs identical |
| Aligned file with custom comment is not rewritten | measured | custom line 1 kept; `apply` reported nothing to write |
| File mode preserved | measured | `.env*` stayed mode `600` after apply |
| Reference never modified | measured | SHA-256 before/after apply identical in copy and live project |
| Live system-news apply | measured | final unify with `--backup-dir tmp/env-sync-backup-20261110-before-unify`: 2 files rewritten, 122 values verified; `verify` PASS (`missing 0`, `undeclared 0`); `verify --backup` PASS vs the pre-unify backup; all three files 114 lines / 61 keys; modes stayed 600 |
| Undeclared key hard stop | measured | synthetic `NEW_ONLY_IN_DEV`: `status`/`verify` report `undeclared 1`, `apply` aborts with "reference incomplete"; nothing written |
| `bash -n` syntax | measured | exit 0 |
| Skill structural/contract checks | measured | `skill-functional-verify.py` PASS |
| Registry counts | measured | derived skill count 24; `framework-verify` prose guard run |

## Recommendation

merge_ok

## Follow-ups (non-blocking)

1. **Optional regression smoke** — add an `env-sync` fixture case to
   `scripts/framework-verify.sh` (protected) so CI catches script regressions;
   the reproducible recipe is already in `skills/env-sync/reference.md § 6`.
2. **Decide on the live backup retention** — pre-apply states are kept
   (git-ignored): `tmp/env-sync-backup-20261110` (original values),
   `tmp/env-sync-backup-20261110-empty` (placeholder state),
   `tmp/env-sync-backup-20261110-before-unify` (unified-reference state), and
   `tmp/env-sync-reference-backup-20261110` (pre-edit `.env.example`). Keep until
   the system-news stack passes, then remove all four.

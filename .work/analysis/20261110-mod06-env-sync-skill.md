# MOD-06 output — env-sync skill + script (AIOS-1)

**Trigger:** agent-authored framework change (AI-assisted: yes). Per
`concepts/ai-amplification/prompt.md`.
**Date:** 2026-11-10 · **Ref:** AIOS-1

## AI change risk summary

- **AI-assisted:** yes.
- **Blast radius:** the change is a new skill + a new standalone script plus
  registry rows. If the script is wrong, the worst case is a mis-ordered `.env*`
  file; it cannot silently change a value (value fingerprints are compared
  before/after every write) and it restores the backups on any mismatch.
  No application code, compose file, database, or deployment path is touched.
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
- The layout model is deliberately conservative: a missing key becomes a
  comment placeholder (`# env-sync: KEY not set in this file`), not `KEY=`,
  because an empty assignment changes runtime semantics from *unset* to *empty*.
- Target-only keys are preserved in one shared trailing block so they also
  align; they are reported for the operator to promote or delete.
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
| Values preserved on the system-news trio | measured | `env-sync apply` on a byte-identical copy: 105 key values compared; independent Python check `VALUES+ALIGNMENT: PASS`; `verify --backup` PASS |
| Same line for every reference key | measured | `.env.dev` / `.env.prd` both 114 lines (110 reference + extras block); independent check asserts each key line == reference line |
| Target-only keys preserved and aligned | measured | `CADDY_HTTP_PORT` / `CADDY_HTTPS_PORT` at lines 113–114 in both files; synthetic `ONLY_DEV_KEY` placeholder in the other file |
| Idempotent | measured | second `apply` → "already aligned - nothing to write"; file hashes unchanged |
| Fail-closed (no writes) | measured | duplicate reference key → exit 2; CRLF target → exit 1; unterminated quote → exit 1; missing reference → exit 2; live files hashed before/after read-only runs identical |
| Aligned file with custom comment is not rewritten | measured | custom line 1 kept; `apply` reported nothing to write |
| File mode preserved | measured | `.env*` stayed mode `600` after apply |
| Reference never modified | measured | SHA-256 before/after apply identical in copy and live project |
| Live system-news apply | measured | `apply --backup-dir /mnt/work/Projects/system-news/tmp/env-sync-backup-20261110`: 2 files rewritten, 105 values unchanged; `verify` PASS; `verify --backup` PASS; independent Python check PASS; `.env.example` SHA-256 unchanged; modes stayed 600; 0 lost/changed/misaligned keys |
| `bash -n` syntax | measured | exit 0 |
| Skill structural/contract checks | measured | `skill-functional-verify.py` PASS |
| Registry counts | measured | derived skill count 24; `framework-verify` prose guard run |

## Recommendation

merge_ok

## Follow-ups (non-blocking)

1. **Optional regression smoke** — add an `env-sync` fixture case to
   `scripts/framework-verify.sh` (protected) so CI catches script regressions;
   the reproducible recipe is already in `skills/env-sync/reference.md § 6`.
2. **Decide on the live backup retention** — the pre-apply originals are at
   `/mnt/work/Projects/system-news/tmp/env-sync-backup-20261110` (git-ignored);
   keep until the system-news stack passes, then remove.

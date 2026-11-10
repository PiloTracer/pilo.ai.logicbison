# env-sync — reference

Detailed contract for `@env-sync` and `scripts/env-sync.sh`: layout model,
side-by-side table legend, safety guarantees, exit codes, failure handling, and
the test recipe used to prove value preservation.

---

## 1. Layout model

`.env.example` (or `--ref FILE`) is the canonical line layout. For every target
`.env*` file, a rewrite produces:

1. **Reference lines, in order.** Comments and blank lines are copied from the
   reference. Each reference key line is replaced by the target's own original
   line for that key — prefix (`export `) and everything after `=` (inline
   comment included) are kept exactly.
2. **Empty assignment for a missing key.** A reference key absent from the
   target becomes, at the same line number:

   ```text
   KEY=
   ```

   (with `export ` retained when the reference line exports it). The key is now
   a real assignment, so every reference key can be grepped in every file.
   Caveat: this can change runtime behaviour from *unset* to *empty*; the
   operator chose this over comment placeholders (2026-11-10), and `apply` backs
   up first. Existing values are never modified.
3. **No extras block.** The reference must already contain every key used by any
   `.env*` file. A key found only in a target is a hard error: `apply` aborts,
   `status`/`verify` report it. Add it to `.env.example` first, with a comment
   explaining where it is enabled or disabled (environment-only keys must exist
   in every file, empty where unused), then re-run. This is what keeps the total
   line count and the key-to-line map identical in every file.

Consequences:

- Every key is on the same line number in every file, present as a real
  assignment (`set` or `empty`) — no comment placeholders, no trailing block.
- All files have the same total line count and the same key set.
- A file that is already structurally aligned is **not rewritten**, so custom
  local comments survive when no key needs to move.

### What is preserved

| Item | Preserved? |
|------|-----------|
| Existing value text after `=` | **Yes, byte-for-byte** (verified by SHA-256 before/after) |
| Missing key | Added as an empty assignment (`KEY=`); this can flip *unset* → *empty* (operator decision) |
| `export ` prefix per line | Yes, copied with the target's line |
| Inline comment on a value line | Yes (part of the value line) |
| File mode | Yes (`chmod` to the original mode before the atomic rename) |
| `.env.example` / reference file | Never written |
| Custom comments in a file that needs a rewrite | No — regenerated from the reference; the drift report lists the file |
| Custom comments in an already-aligned file | Yes — file is skipped |

### What is rejected (no writes)

| Finding | Why it must stop |
|---------|------------------|
| Reference missing or with no `KEY=value` line | No layout authority |
| Key present only in a target (undeclared) | The reference must own the key set; add it there with a comment first |
| Duplicate key in one file | Ambiguous value |
| Line that is not blank / comment / `KEY=value` | Cannot place it safely |
| Unterminated quote or trailing `\` | Multiline value; a line rewrite would corrupt it |
| CRLF line endings | Stripping `\r` would alter the value; convert to LF first |
| Key with spaces / non `[A-Za-z0-9_]` chars | Not a portable env key; likely a typo |

---

## 2. Side-by-side table legend

`status` prints one row per reference key. Columns: `KEY`,
`REF` (the reference line), one column per target file, `VALUES`.

| Cell | Meaning |
|------|---------|
| `ok:12 set` | Key exists on canonical line 12; value non-empty |
| `ok:12 empty` | Canonical line, empty value (`KEY=`) — preserved as-is |
| `at:9 set` | Key exists but on line 9; must move to the reference line |
| `--` | Key not set in this file (drift; `apply` materializes `KEY=`) |
| `VALUES same` | Every file that has the key has an identical value fingerprint |
| `VALUES diff` | At least two present values differ (expected across environments) |
| `VALUES n/a` | Fewer than two files have the key — nothing to compare |

Values are never printed. `same`/`diff` is computed from SHA-256 fingerprints of
the extracted values; it is a comparison aid, not a reversible encoding.

Per-file summary rows:

```text
  .env.dev           ALIGNED (missing 0, misplaced 0, undeclared 0)
  .env.prd           DRIFT   (missing 7, misplaced 3, undeclared 0)
```

`ALIGNED` means every reference key is a real assignment on its canonical line,
no unexpected assignment exists, and the file has the reference's exact line
count. Empty (`KEY=`) counts as present. `UNDECLARED` keys are listed below the
summary and fail `verify`.

---

## 3. CLI

```text
env-sync.sh status|compare|diff   [--dir PATH] [--ref FILE] [--files "A B"]
env-sync.sh verify|check          [--dir PATH] [--ref FILE] [--files "A B"]
env-sync.sh verify --backup DIR   [--dir PATH]
env-sync.sh apply|sync|fix        [--dir PATH] [--ref FILE] [--files "A B"]
                                  [--backup-dir PATH] [--dry-run]
env-sync.sh help
```

| Flag | Default | Notes |
|------|---------|-------|
| `--dir PATH` | current directory | Project root that holds the `.env*` files |
| `--ref FILE` | `<dir>/.env.example` | Relative paths resolve against `--dir` |
| `--files "A B"` | every regular `<dir>/.env*` | Exact basenames, space-separated; excludes the reference |
| `--backup-dir PATH` | `$TMPDIR/env-sync-backup.XXXXXX` | Created mode 700; keep it outside version control |
| `--backup PATH` | — | `verify` alias that selects a backup dir |
| `--dry-run` | off | `apply` validates and prints the plan; writes nothing |

Default target discovery excludes the reference and backup/temp suffixes
(`*.bak`, `*.orig`, `*.rej`, `*.swp`, `*.tmp`, `*~`, `.env-sync*`) and considers
only regular files at the top level of `--dir` (symlinks are not followed).

### Exit codes

| Code | Meaning |
|------|---------|
| `0` | pass / aligned / no-op |
| `1` | drift (`verify`), invalid input, aborted, or restored after failure |
| `2` | usage error, missing/unparseable reference, no hashing tool |

`status` renders the drift table but exits `0`; use `verify` as the gate.

---

## 4. Safety model

`apply` runs these gates in order, and **writes nothing** if any pre-write gate
fails:

1. **Parse** the reference and every target; any issue stops the run. A key
   present only in a target is an undeclared-key error and also stops the run
   before any write.
2. **Plan** — compute which files need a rewrite and how many keys are missing /
   misplaced.
3. **Backup** every target with `cp -p` into the backup dir (mode 700), and
   record a SHA-256 manifest.
4. **Generate** into a private work dir and parse the generated file; it must be
   valid.
5. **Compare value fingerprints** (original map vs generated map) — every
   original key must survive with the same SHA-256; an added key is allowed only
   when it is a missing reference key and its assignment is empty.
6. **Alignment check** on the generated file before the move.
7. **Atomic replace** in the target directory (`.env-sync-tmp.<pid>/` on the
   same filesystem), preserving the original mode.
8. **Post-write verify** — parse, value fingerprints, alignment. Any failure
   restores **all** changed files from the backup and exits `1`.
9. **Backup integrity** — re-hash the backup copies against the manifest.

`verify --backup DIR` re-runs the value comparison between each backup file and
its current counterpart; it is the independent audit of an earlier apply.

### Restoring manually

```bash
cp -p <backup-dir>/.env.dev /path/to/project/.env.dev
```

Backups are full copies, so restoring is a single `cp -p` per file; modes are
preserved.

---

## 5. Edge cases

| Situation | Behaviour |
|-----------|-----------|
| Only the reference exists | `status`/`verify` report zero targets; `apply` is a no-op |
| A target is already aligned with custom comments | Skipped (no write); comments kept |
| A key exists only in `.env.prd` | Hard error until it is added to `.env.example` with a comment; then it is empty in the other files |
| Value is empty (`KEY=`) | Preserved; `VALUES` shows `empty` |
| Value contains `=`, spaces, `$`, quotes, `#`, tabs | Preserved byte-for-byte; hash-compared |
| `export KEY=value` | Preserved with its `export ` prefix |
| Reference has trailing comments after the last key | Extra-key block is appended after them; line numbers account for the full reference |
| `.env` symlink | Not followed by default (regular files only); name the real file with `--files` |
| Apply interrupted | Backup dir remains; work/temp dirs are cleaned by the EXIT trap |

---

## 6. Test recipe (reproducible)

```bash
# 1. Copy the real env trio and keep pristine originals
mkdir -p /tmp/envtest/orig /tmp/envtest/proj
cp -p .env.example .env.dev .env.prd /tmp/envtest/orig/
cp -p .env.example .env.dev .env.prd /tmp/envtest/proj/

# 2. Read-only look
bash scripts/env-sync.sh status --dir /tmp/envtest/proj

# 3. Apply with a durable backup, then prove values survived
bash scripts/env-sync.sh apply --dir /tmp/envtest/proj --backup-dir /tmp/envtest/backup
bash scripts/env-sync.sh verify --dir /tmp/envtest/proj
bash scripts/env-sync.sh verify --backup /tmp/envtest/backup --dir /tmp/envtest/proj

# 4. Independent check (does not use env-sync): values and line numbers
python3 - <<'PY'
import re, pathlib
def parse(p):
    out = {}
    for i, l in enumerate(p.read_text().splitlines(), 1):
        m = re.match(r'^(?:export[ \t]+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$', l)
        if m: out[m.group(1)] = (i, m.group(2))
    return out
base = pathlib.Path('/tmp/envtest')
ref = parse(base/'proj/.env.example')
for name in ('.env.dev', '.env.prd'):
    old, new = parse(base/'orig'/name), parse(base/'proj'/name)
    assert all(new.get(k, (0, ''))[1] == v[1] for k, v in old.items()), name
    for k in ref:
        assert k in new, (name, k, 'missing')
        assert new[k][0] == ref[k][0], (name, k, 'line')
    for k in set(new) - set(old):
        assert new[k][1] == '', (name, k, 'added non-empty')
print('values + alignment + empty materialization: PASS')
PY
```

Negative checks worth running before trusting a change:

```bash
# duplicate key in the reference -> exit 2, writes nothing
# CRLF / unterminated quote in a target -> exit 1, writes nothing
# target-only key -> apply aborts, verify FAIL (add it to .env.example first)
# tamper one value after apply -> verify --backup reports VALUE DRIFT
```

---

## 7. Security notes

- Values never reach stdout/stderr, the table, or the report. Only key names,
  line numbers, `set`/`empty`, and hashes of values (used for equality) exist in
  temporary maps.
- Generated files, work files, and backups contain raw values. `apply` uses a
  `mktemp -d` work dir (mode 700), a private staging dir inside the project, and
  a backup dir with mode 700; the default backup location is outside the repo.
- Do **not** point `--backup-dir` at a tracked path. Add `tmp/env-sync/` to
  `.gitignore` if the operator wants durable backups inside the project.
- Never `source` or `cat` `.env*`; this skill neither needs nor does.

---

## 8. Failure handling for the agent

| Script result | Agent action |
|---------------|--------------|
| `status` drift | Show the summary; propose `apply` only if the operator asked |
| `verify` exit 1 | Treat as a gate failure; list the drifting files; do not claim aligned |
| `apply` aborted pre-write | Quote the issue line; for undeclared keys, add them to `.env.example` with a comment first, then rerun; nothing was written |
| `apply` FAIL (restored) | Report `FAIL (restored)` with the backup path; do not retry blindly |
| `verify --backup` VALUE DRIFT | A value changed after apply; investigate, do not overwrite the backup |
| Reference invalid | Blocked: the operator must repair `.env.example` (layout authority) first |

---
name: env-sync
description: >-
  Make every `.env*` file consistent by aligning its keys to the `.env.example`
  reference: each variable sits on the same line number in every file, every
  current value is preserved byte-for-byte, and the operator gets a side-by-side
  comparison. Use when the user invokes @env-sync, says "make .env files
  consistent", "align the env files", "sync .env vars", "compare .env files side
  by side", "env drift", or asks to reconcile `.env`, `.env.dev`, `.env.prd`
  with `.env.example`. Backed by `scripts/env-sync.sh`
  (`status` / `verify` / `apply`).
---

# env-sync

Keep every `.env*` file in one canonical line layout without ever touching a
value. **`.env.example` is the layout authority** — one reference, many target
files, identical key line numbers, and a side-by-side comparison the operator can
read without exposing secrets.

**Tool-agnostic** (Cursor, Claude Code, opencode, Codex, DSH). **Pairs with:**
`dev-stack` (`.env` creation), `session-control` (repo hygiene), project
`.gitignore` / protected-file rules.

**Canonical path:** `.ai/skills/env-sync/skill.md` · **Detailed contract, exit
codes, test recipe:** `reference.md`

**Hard rules:**

- **Values are immutable.** `apply` reorders/inserts/pads lines only. It never
  rewrites the text after `=` and never edits the reference file. Before and
  after every write, SHA-256 fingerprints of every key value must match; a
  mismatch aborts and restores the backups.
- **Never print or read values into chat.** No `cat`, `source`, or value diff.
  `status`/`verify` report line numbers, `set`/`empty`, and same/diff
  fingerprints only. `.cursorrules` § Data Privacy applies.
- **Missing key → empty assignment** (`KEY=`) on its canonical line (operator
  decision 2026-11-10). Every reference key is present in every file, so the
  layout is greppable and strictly aligned. Caveat: this can change runtime
  semantics from *unset* to *empty*; `apply` backs up first and is the only
  writer, and existing values are still never modified.
- **Back up before writing.** Default backup dir is outside the repo
  (`$TMPDIR/env-sync-backup.*`, mode 700, copies keep the original mode). Use
  `--backup-dir` when the operator needs the backup to survive a reboot.
- **Fail closed, never guess.** Refuse (no writes) on a broken reference,
  duplicate keys, multiline/continued values, unparsable lines, or CRLF input.
  Report the exact line and stop.
- **The reference owns the key set.** A key present in any target but absent
  from `.env.example` is a hard error: `apply` aborts, `status`/`verify` report
  it. Add it to `.env.example` first, with a comment explaining where it is
  enabled or disabled (environment-only keys must exist in every file, empty
  where unused). This is what guarantees **identical line counts and identical
  key-to-line maps** in every file — no trailing extras block.
- **`status`/`verify` are read-only. `apply` is the only writer** and is itself
  the same-message permission to modify `.env*` files (which are protected
  files). Never rewrite `.env*` outside an explicit `apply` invocation.
- **Operator handoff:** every response that ends a turn follows the [Operator
  handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — terse
  output; approvals under `**Needs your approval:**` citing `path:L<n>`;
  questions numbered under `**Needs your answer:**`; exactly one
  `**Next step:**`; one line when nothing is needed (Form A). Decisions and
  questions never mixed; empty sections omitted.

---

## Parse invocation

Normalize the user message to **verb** + optional **directory**.

| User says | Verb | Action |
|-----------|------|--------|
| `@env-sync` **status** · **compare** · **diff** | status | [Status protocol](#status-protocol) — read-only side-by-side table |
| `@env-sync` **verify** · **check** | verify | [Verify protocol](#verify-protocol) — strict pass/fail, exit 1 on drift |
| `@env-sync` **apply** · **sync** · **fix** | apply | [Apply protocol](#apply-protocol) — backup, rewrite layout, verify |
| `@env-sync` **apply** `--dry-run` | apply | Plan only; report what would change, write nothing |
| `@env-sync` (no verb) | status | Default to the read-only comparison |

**Target:** an optional path after the verb (`@env-sync status - /path/to/project`)
becomes `--dir /path/to/project`. Without it, use the current repository root.

**Aliases:** `compare`/`diff` → status; `check` → verify; `sync`/`fix` → apply.

---

## Step 0 — Resolve the script and modes

Run from the project root (or pass `--dir`):

```bash
# fat-client / self-hosted (self-hosted alias: .ai/scripts → scripts/)
bash .ai/scripts/env-sync.sh <verb> [--dir PATH]

# thin-client (no local .ai/): use the framework source
bash "${AGENT_OS_SOURCE}/scripts/env-sync.sh" <verb> [--dir PATH]
```

| Mode | Writes | Use when |
|------|--------|----------|
| `status` | nothing | Operator wants the side-by-side picture; first step of any invocation |
| `verify` | nothing | CI/pre-commit gate, or after `apply` |
| `apply` | target `.env*` files | Operator asked to make the files consistent |

Exit codes: `0` pass, `1` drift / aborted / restored, `2` usage or reference
error. `status` exits `0` even when the table shows drift — use `verify` for a
gate.

---

## Status protocol

1. Run `env-sync.sh status` (add `--dir` when the user named a path).
2. Report the return code; do not paste the table if it is huge — summarize the
   file rows and link/copy the table.
3. Explain the column legend once (it is in `reference.md`):

| Cell | Meaning |
|------|---------|
| `ok:N` | key is on canonical line `N` |
| `at:N` | key exists but sits on line `N` (must move) |
| `--` | key is not set in that file (drift; `apply` materializes `KEY=`) |
| `set` / `empty` | value is non-empty / empty — the value itself is never shown |
| `VALUES same/diff/n/a` | value fingerprints across files that have the key |

4. Flag anything that needs a decision: missing keys (they become `KEY=` on
   apply), **undeclared keys** (must be promoted into `.env.example` with a
   comment first), and any `INVALID` file. Do not propose value edits.

---

## Apply protocol

**Order:** A1 preflight → A2 review/dry-run → A3 backup + apply → A4 verify →
A5 backup proof → A6 report.

### A1 — Preflight (mandatory)

1. Confirm the reference exists (`.env.example` unless `--ref`).
2. Run `status` first and read the file/issue rows.
3. If the reference itself is invalid, **stop** with the blocked shape — do not
   guess a layout.
4. If a target is invalid (duplicate key, multiline value, CRLF, unparsable
   line), **stop** with the exact `path:L<n>` and the fix. Do not edit the file
   to make it parse unless the operator asked for that separately.
5. If `status` reports **undeclared** keys (present in a target, absent from the
   reference), **stop before `apply`**. Add each key to `.env.example` with a
   comment explaining where it is enabled/disabled, then re-run. Never accept a
   trailing extras block: line counts and key lines must stay identical.

### A2 — Review gate

- If the operator has not seen the drift yet, show the summary counts and,
  when the change is non-trivial, run `apply --dry-run` first (no writes).
- `apply --dry-run` is safe: it validates and prints per-file counts only.

### A3 — Backup + apply

```bash
bash .ai/scripts/env-sync.sh apply --dir <path> --backup-dir <persistent-dir>
```

- Omit `--backup-dir` to use the OS temp dir; pass one under the project's
  git-ignored `tmp/` when the backup must survive (never under version control;
  backups contain the original secrets).
- Apply is idempotent: an already-aligned file is skipped and reported as such.

### A4 — Verify (mandatory)

```bash
bash .ai/scripts/env-sync.sh verify --dir <path>
```

If `verify` fails after a successful apply, treat the apply as failed: report
the file, the backup path, and the restore command
(`cp -p <backup>/<file> <dir>/<file>`). The script already restores
automatically on its own post-write mismatch.

### A5 — Backup proof

```bash
bash .ai/scripts/env-sync.sh verify --backup <backup-dir> --dir <path>
```

This compares each backup to the current file key-by-key and confirms values
are unchanged and the layout is aligned. Include the result in the report.

### A6 — Report

```markdown
## env-sync applied - <project>

**Directory:** <path> · **Reference:** .env.example (<N> keys, <L> lines)
**Result:** PASS | FAIL (restored)
**Layout:** <L> lines, <N> keys - identical in every file

| File | Before | After | Values |
|------|--------|-------|--------|
| .env.dev | missing 10, misplaced 48 | aligned (10 empty) | 51 unchanged |
| .env.prd | missing 7, misplaced 51 | aligned (7 empty) | 54 unchanged |

**Undeclared keys:** none (the reference owns the key set)
**Backup:** <path> (mode 600 copies, 700 dir)
**Proof:** `verify` PASS; `verify --backup` PASS
```

End with the Operator handoff close per the contract.

---

## Verify protocol

1. `env-sync.sh verify [--dir PATH]` — strict alignment check.
2. `env-sync.sh verify --backup DIR [--dir PATH]` — prove the values in the
   current files match the pre-apply backup (the audit mode).
3. Report per-file `ALIGNED` / `DRIFT` plus the `verify: PASS|FAIL` line. Exit
   `1` on any drift or invalid input; surface that code, do not hide it.

Use `verify` in CI after `apply`; `status` remains the human comparison view.

---

## Blocked / failure shape

When the skill stops before writing:

```markdown
## @env-sync <verb> - blocked

**Required:** <valid reference | parseable target | LF endings>
**Detected:** <path:L<n> — <issue>>
**Run first:** `<exact command>` (or fix the line above)
**Wrote:** nothing
```

When apply fails and restores, say `FAIL (restored)` and cite the backup path;
never claim success from a partial layout.

---

## Anti-patterns

- Editing a value (or an `.env.example` placeholder) to make files "match".
- Printing raw values, `cat`-ing `.env*`, `source`-ing them, or diffing values.
- Leaving a key absent from a file when the operator asked for a full layout — apply materializes `KEY=`.
- Running `apply` without a backup or without a post-write `verify`.
- Expecting `apply` to rewrite `.env.example` (it never does) or adding an environment-only key to a target without promoting it to the reference first.
- Leaving a target-only key out of `.env.example`, or accepting an extras block that breaks the identical line count.
- Continuing after a `duplicate` / `multiline` / `CRLF` finding.
- Claiming aligned without `verify` output as evidence.

---

## Integration

| Situation | Use |
|-----------|-----|
| New `.env` from `.env.example` | Create it, then `@env-sync apply` to align |
| `.env.dev` / `.env.prd` drift after adding a variable | `@env-sync status` → `apply` → `verify` |
| Pre-commit / CI env gate | `@env-sync verify` (exit 1 blocks) |
| Suspect a bad apply | `@env-sync verify --backup <dir>` |
| `dev-stack` init-env produced files | `@env-sync status` before starting the stack |

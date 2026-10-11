# MOD-06 — Windows/Linux/macOS/BSD portability (12-item matrix)

**Change ref:** AIOS-1 · **Date:** 2026-10-09 · **Concept:** MOD-06 AI amplification
**Trigger:** agent-authored changes to change-safety scripts, hooks, and CI.

## AI change risk summary

- **AI-assisted:** yes — all edits authored by an agent under `@ai-director`; verification is mechanical and reproducible.
- **Boundaries crossed:** 5 — `scripts/` (verifier layer), `hooks/` (commit-time enforcement), `templates/` + `.cursorrules` (shipped contract), `.github/workflows/` (CI), repo-root config (`.gitattributes`, `.editorconfig`).
- **New cross-boundary deps:** one new file, `scripts/lib/portability.sh`, sourced by 6 scripts. It is a *soft* dependency: every call site guards on `[[ -f … ]]` and falls back to an inline resolver, so a relocated or sandboxed copy still runs. Verified by the existing change-safety self-tests, which copy scripts into a tmp sandbox — that test caught the unguarded first version.
- **Test isolation:** ok — `bash scripts/framework-verify.sh` (exit 0, all checks passed) exercises the new preflight, the LF guard, the gate-verify/readiness-verify awk changes (including the `★` weight path), and the hook behaviour, all in `mktemp -d` sandboxes. `scripts/skill-functional-verify.py` PASS. `touch-scope-verify` pass; `blast-radius-check` warn (all files in declared scope).
- **Human architectural review:** required — the interpreter-resolution contract and the "WSL2 only, no native Windows" decision are policy, not mechanics. Owner invoked this change explicitly and approved the protected-surface edits in the same message.
- **Blast radius:** a defect in interpreter resolution or the LF guard would either (a) silently disable a change-safety gate — the exact failure class this change removes, since `[ -x ]` guards could make `pre-commit` exit 0 with no output, or (b) reject every commit on LF-mandatory files. The blast radius is contained to *local* enforcement plus CI; no application runtime, data, or deployment path is touched. The highest-risk single edit is `framework-verify.sh` section 0, because a false negative there weakens every downstream gate.

## Recommendation

**merge_with_conditions** — the change is verified and behaviour-preserving on Linux, but two items are policy decisions that need the owner on record.

## Conditions if merge_with_conditions

- **Must confirm the Windows support decision.** This change makes WSL2 the supported Windows path and documents native Windows / Git Bash as unsupported. It does **not** add `rsync` removal or `cygpath` path hardening, which Git Bash support would require. If Git Bash is ever needed, that is a separate scoped change.
- **Must not claim executable bits are fixed.** Item 7 replaced `[ -x ]` with `[ -f ]` so the gates no longer *depend* on the POSIX exec bit; NTFS and DrvFs still cannot store one. Any future doc must not imply `chmod` works on Windows.
- **Must add tests if the fallback resolver is refactored.** The inline `portable_find_python` fallback in `deploy-basic.sh`, `install-opencode-config.sh`, and `blast-radius-check.sh` duplicates the library version; if `lib/portability.sh` gains behaviour, the fallbacks can drift silently.
- **Must re-run `install-git-hooks.sh` after the renormalize commit.** `.gitattributes` does not repair an already-installed CRLF hook, because the installer `cp`s the worktree source into `.git/hooks/`.
- **Must not add blanket `* text=auto eol=lf`** without owner sign-off: this framework deploys into consumer repos and would force LF on third-party files.

## Notes on item state

All 12 matrix items are implemented. Items 1, 2, 4, 5, 6, 9, 10, 11, 12 are complete and fully verifiable.
Item 3 (hook re-install) is complete but is a **recurring operator step**, not a one-time fix.
Items 7 and 8 are complete as *mitigations*: `[ -f ]` removes the dependency on a mode bit that Windows cannot store, and execution-probing correctly rejects the Microsoft Store `python3` alias stub — verified against a simulated stub that passes `command -v` but exits 49.

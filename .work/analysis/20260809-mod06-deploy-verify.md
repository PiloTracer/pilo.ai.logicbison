# MOD-06 — deploy-skills verification + arg-normalization session (2026-08-09)

## Scope of AI-generated change

| File | Change |
|------|--------|
| `scripts/cursorrules-verify.sh` | **New** shared verifier: `.cursorrules` checks (AGENT_OS_SOURCE reachability, gate-table script-path baking, sister-framework cells) + `--fix` repairs; normalized arg parsing |
| `scripts/deploy-basic.sh` | Unified arg normalizer (`update` ≡ `--update`, `-`/`--` separators dropped, path any position); status delegates `.cursorrules` checks to `cursorrules-verify.sh`; `--update` delegates repairs (`--fix --thin`); post-deploy verification block; fixed false "resolved" sister-cell report (template pattern `default` vs `default:` mismatch) |
| `scripts/deploy-files.sh` | Unified arg normalizer + `copy` verb; implemented `status` mode (was doc-only); post-deploy verification via `cursorrules-verify.sh` (update = `--fix`, else read-only) |
| `scripts/deploy-repo.sh` | Unified arg normalizer — fixes silent deploy into a directory literally named `-`; archive mode resolves target to absolute before `cd` (relative targets previously extracted into a missing dir) |
| `scripts/framework-verify.sh` | New regression smokes 2g (arg-form equivalence, `-` safety, relative archive) and 2h (cursorrules-verify detect → `--fix` → deploy `update` repair cycle) |
| `skills/deploy-basic/skill.md`, `skills/deploy-files/skill.md`, `skills/deploy-repo/skill.md` | Parse tables + status/update prose aligned with implemented behavior (arg equivalence, status reality, sister-cell repair) |
| `.work/touch-scope` | Declared scope for this session |

## AI change risk summary

- AI-assisted: yes (agent-designed and agent-written diff across 10 files)
- Blast radius: **high** — four protected deploy scripts changed (`deploy-basic.sh`, `deploy-files.sh`, `deploy-repo.sh`, `framework-verify.sh`). If the new arg normalizer misclassified a token, deploys would error out (safe failure: exit 2 with usage), never deploy to a wrong target — the previous behavior (deploy into a directory literally named `-`) was the unsafe one. If `cursorrules-verify.sh --fix` were wrong, it could mis-edit a consumer `.cursorrules`; mitigations: repairs are idempotent, in-place, regex-scoped to exact tokens/paths (`\Q...\E` quoting), and exercised end-to-end in smokes (stale source, unbaked paths, open + stale sister cells, moved-tree scenario).

## Verification evidence (all measured)

- `bash scripts/framework-verify.sh` → **exit 0** (includes new smokes 2g + 2h)
- `python3 scripts/skill-functional-verify.py` → **PASS**
- `bash scripts/touch-scope-verify.sh` → **pass** (all changed files in declared scope)
- `bash scripts/blast-radius-check.sh` → **risk: high, verdict warn** — protected deploy scripts touched; authorized by owner's task request this session (matches v0.5.2 precedent); all files in declared scope
- Equivalence: `deploy-basic.sh <path> update` ≡ `<path> --update` ≡ `update <path>` — byte-identical resulting `.cursorrules` (measured with `cmp`)
- Moved-tree scenario: synthetic master+sisters moved to a new parent → verifier flags 5 FAIL classes (stale pointer, stale script prefix, 3 stale sister cells) → `deploy-basic update` repairs all → post-verify PASS (measured)
- Pre-existing bugs found by the new verification: sister-cell substitution never matched the template (`default:` vs `default` — script printed "resolved" without substituting); `deploy-repo archive` relative-target extraction; `-` separator as target dir

## Known limitations (residual risk)

- Sister-cell repair fills/re-points only cells in the standard template shape (token with `default` note, or absolute baked path); hand-customized cells are reported `[info] custom cell value` and left untouched.
- Gate-table path validation covers the known framework command basenames (documented in `cursorrules-verify.sh`); prose example paths are intentionally not validated.
- `cursorrules-verify.sh` on the self-hosted framework repo itself is not meaningful (layout detection assumes a consumer target); documented in usage.

## Recommendation

merge_ok

## Conditions if merge_with_conditions

n/a

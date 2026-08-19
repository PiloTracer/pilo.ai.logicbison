# MOD-06 — deploy dir-rename + sister-framework naming support

**Date:** 2026-08-19 · **Trigger:** MOD-06 `ai-amplification/prompt.md` (agent-authored code: `scripts/`) · **Ref:** AIOS-1

## AI change risk summary
- AI-assisted: yes
- Boundaries crossed: 0 — framework self-contained (all touched files live in `scripts/`, `templates/`, `skills/`, plus the repo's own `.cursorrules`; no app modules)
- New cross-boundary deps: none — the one new artifact (`scripts/sister-discovery.sh`) is sourced by `deploy-basic.sh` + `cursorrules-verify.sh` inside the same `scripts/` boundary; `install-opencode-config.sh` mirrors the logic in python with a keep-in-sync comment
- Test isolation: ok — `bash scripts/framework-verify.sh` (new section 2i + lib unit asserts) fails only when discovery is wrong; `skill-functional-verify.py` + `touch-scope-verify.sh` cover docs/scope
- Human architectural review: optional — single-boundary, script-level change; the naming rule and fallbacks are documented in `.cursorrules` § Frameworks registry
- Blast radius: if discovery is wrong, thin-client targets get an unfilled `REPLACE:AI_*_PATH` token → runtime auto-discover falls through → cross-framework routing degrades to `[degraded: <framework> not installed]`; no data loss, no destructive ops, deploy scripts are invoked manually/agent-driven (not on an automated critical path); worst case is a mislabeled "not installed" + a manual cell fill

## Recommendation
merge_ok — reason: behavior verified live (pre-change deploy smoke from the renamed `pilo.ai.logicbison` source: `AGENT_OS_SOURCE` baked + `cursorrules-verify: PASS`; post-change framework-verify 2i covers renamed-source + family-named sister and legacy `.ai` + `.ai.ui`; fallback when no sister exists is unchanged from prior behavior)

## Design (assumption ledger)
- Confirmed: `@deploy*` already handle the source-dir rename — `AI_ROOT` is derived from the script location at runtime; live smoke showed `AGENT_OS_SOURCE=/mnt/work/Projects/pilo.ai.logicbison` baked and reachable (measured, 2026-08-19).
- Confirmed: six sisters currently exist on disk under legacy names (`.ai.ui`, `.ai.biz`, `.ai.soc`, `.ai.cto`, `.ai.flutter`, `.ai.mlt`, each with `skills/README.md`) — measured, `ls /mnt/work/Projects/`.
- Inference: family naming rule (source basename with `<fw>` inserted before its last dot-segment, e.g. `pilo.ai.logicbison` → `pilo.ai.ui.logicbison`) is deterministic and covers the declared future convention (`pilo.ai.*.logicbison`); a framework slot (ui/biz/soc/cto/flutter/mlt) in second-to-last position is replaced so sister-framework sources resolve their own siblings; `.ai`-prefixed sources (`.ai`, `.ai.biz`, …) resolve `.ai.<fw>` directly (they carry no family prefix/tail); legacy `.ai.<fw>` stays as fallback; custom dir names remain a documented manual cell fill (user's option b — no grilling prompt, auto-discovery first, manual config as the transparent fallback; deploy output lists what it checked).
- Unknown: whether/when the operator renames the sisters (nothing on disk yet under `pilo.ai.*`); the change is behavior-neutral today (only legacy names exist, so today's output is unchanged).
- Environment: the six sibling repos sit on a read-only mount in this session (`/mnt/work` ro, only `pilo.ai.logicbison` rw) — per-sibling writes are delivered as manual direction files at `docs/homogenization/` (`biz.md` … `ui.md`), written from measured sibling state; no apply script.

## Conditions if merge_with_conditions
- Must add tests: done — framework-verify 2i (renamed-source + family/legacy smokes + unit asserts).

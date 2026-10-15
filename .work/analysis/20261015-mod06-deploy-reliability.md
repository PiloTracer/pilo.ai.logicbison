# MOD-06 — deploy reliability: marker gates, force tokens, source-dir portability

**Change ref:** AIOS-1 · **Date:** 2026-10-15 · **Concept:** MOD-06 AI amplification
**Trigger:** agent-authored changes to deploy/verify scripts and skill docs across 4 framework repos, from `.work/feedback/20261015-deploy-configure-cohabitate.md/` (owner invoked `@ai-director`, approved with `y`).

## AI change risk summary

- **AI-assisted:** yes — all edits authored by an agent under `@ai-director`; every behavioural claim below is backed by a command run in this session with its exit code read (no untested claims).
- **Boundaries crossed:** 4 framework source repos, 8 files — `pilo.ai.ui.logicbison` (`scripts/ui-deploy-basic.sh`, `scripts/cursorrules-verify.sh`, `templates/cursorrules.ui.template`, `templates/cursorrules.ui.snippet.template`, `skills/ui-deploy-basic/skill.md`), `pilo.ai.logicbison` (`scripts/cursorrules-verify.sh`, `scripts/deploy-basic.sh`, `skills/deploy-basic/skill.md`), `pilo.ai.soc.logicbison` (`scripts/soc-deploy-basic.sh`), `pilo.ai.flutter.logicbison` (`scripts/deploy-basic.sh`, `scripts/deploy-files.sh`, `scripts/deploy-verify.sh`, 2 skill.md). No consumer repo was modified (pilo-mail used read-only as the regression target; copies only in `mktemp` sandboxes).
- **New cross-repo dependency:** the shared `confirm-overwrite-cursorrules` token (AO + UI deploy force paths) and the `AI_FLUTTER_SOURCE` env override (mirrors existing `AI_SOURCE` / `AI_UI_ROOT` / `SOC_SOURCE`). Both are additive; no existing invocation signature changed — no test, automation, or prior doc used force mode without the token (grep-verified before the change).
- **Test isolation:** all functional runs used `mktemp -d` targets; the only real-world target (`/mnt/work/Projects/pilo-mail`) was verified **read-only**; `--fix` was exercised against a copy (empty diff on the already-correct file). `framework-verify.sh` PASS in all four repos; `bootstrap-test.sh` PASS in UI.
- **Human architectural review:** not required beyond the owner's `y` — changes are guardrails and labels, not new architecture. One judgement call recorded here: the AO verifier's first parser fix (column-anchored to registry id rows) produced false classifications on the real target and was reverted mid-session to whole-file extraction + example-line exclusion; the real-target re-run is the evidence, not the intent.
- **Blast radius:** a defect here can (a) FAIL every thin-client verify run (false STALE / missing-block), (b) block a legitimate force overwrite, or (c) allow a wholesale `.cursorrules` replace that silently destroys sister blocks — class (c) is exactly what the token guard removes. No application runtime, data, or deployment path is touched.

## Recommendation

**merge** — verified against the audit's own failing cases (pilo-mail) and each repo's full self-verification; changes are uncommitted by owner request.

## Evidence (observed, this session)

| Claim | Evidence |
|---|---|
| AO registry parser fixed (F-07b) | `cursorrules-verify.sh /mnt/work/Projects/pilo-mail` → PASS; `.ai.biz` backticked cell resolves `[ok]`; example `/path/to/.ai.ui` no longer false-FAILs |
| AO F-07a + F-06 visible | same run: heading-renamed → warn; `.ai.biz` declared-but-no-`.work.biz/` → warn |
| AO force guard | `--force` on existing file → exit 1 BLOCKED + lost-content list; with `confirm-overwrite-cursorrules` → overwrite exit 0; default mode → skip, file byte-identical |
| UI marker gate (F-04) | thin target without block → verify exit 1; `--fix` appends marked block; re-run idempotent (markers stay 1/1) |
| UI merge-not-skip (F-01/02) | deploy into target with existing `.cursorrules` → markers present, verify PASS |
| UI force token (F-09) | `force` without token → exit 1 blocked; with token → overwrite exit 0, markers 1/1; `update` after → idempotent |
| SOC F-13 labels | three-way labels observed: installed+declared, installed+not-declared (mlt mentions stripped), declared+not-installed (isolated work_root) |
| Flutter override | valid `AI_FLUTTER_SOURCE` ≡ derived; bogus value → exit 1 `error: AI_FLUTTER_SOURCE is not a directory` |
| No regressions | `framework-verify` ×4 exit 0; UI `bootstrap-test.sh` exit 0 |

## Conditions

- **Must not claim the structural registry fix (F-07a option 2) is done** — the heading check only warns on rename; a machine-checkable registry block remains deferred.
- **Must keep the example-line exclusion honest** — `(\(e\.g\.|\(i\.e\.` filtering is heuristic; a consumer who writes a real pointer after "e.g." would be under-reported (info-level, not FAIL).
- **SOC force mode was deliberately not token-gated** — out of the approved scope (audit rated SOC "nothing urgent"); if SOC's force ever wholesale-replaces `.cursorrules`, apply the same token pattern.

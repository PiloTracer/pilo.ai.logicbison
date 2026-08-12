# MOD-06 — plan-foundation stack-grill gap resolution (AI-assisted)

**Date:** 2026-08-12 · **Session type:** opencode agent session (AI-assisted: **yes** — operator requested the change via agent, no `human-only` declaration)
**Diff summary:** `skills/plan-foundation/reference.md` (~+160 lines) and `skills/plan-foundation/skill.md` (~+8 lines). Added: Recommendation protocol section; `p1-nfr` (D5) + `p1-data-model` (D7) interactions; `p2-database` + `p2-data-services` interactions; GATE p1/p2/p5 checklist items; binding-order + greenfield-protocol text; 3 anti-patterns.

---

## AI change risk summary

- **AI-assisted:** yes
- **Boundaries crossed:** 1 — `skills/` (plan-foundation skill pair only; no templates, scripts, standards, or .work/ carriers touched)
- **New cross-boundary deps:** none (docs-only; no code imports, no shared models, no DB)
- **Test isolation:** ok — `python3 scripts/skill-functional-verify.py` (fences + same-file/cross-file anchors, plan-foundation now in `ANCHOR_CLEAN` hard-fail set); `bash scripts/framework-verify.sh` (full suite); `bash scripts/touch-scope-verify.sh`
- **Human architectural review:** optional — change is process-documentation contract; the Recommendation protocol encodes behavior the operator explicitly requested (evidence-derived recommendations). Reviewer attention recommended for the protocol's wording (rules 4–5) since it binds future greenfield grills.
- **Blast radius:** if wrong, greenfield foundations across all adopters would produce stack choices not derived from operator answers, or gate checklists that misreport D5/D7 completeness. Mitigated by: gate checklists are new checklist items (strict, not lenient — a missed grill now fails GATE p1 rather than passing), and the framework-verify suite passes.

## Recommendation

merge_ok — with conditions

## Conditions if merge_with_conditions

- Operator reads the Recommendation protocol rules (especially 4: conflict surfacing, 5: `none` must be earned) in this output and confirms they match intent before close; no test additions needed (no code changed).
- Follow-up (deferred, not blocking): CHANGELOG.md entry for this change on next release cycle; NEXT.md "Done" row on session close per operator preference.
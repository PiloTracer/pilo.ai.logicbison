# UNKNOWNS - planning registry

> **This is a template file.** In your adopter repo it is created by **`@plan-foundation`** (P0), extended by **`@plan-master`** (planning gaps), and appended by **`@code-implementation`** (`U*` rows when tasks become blocked). In this framework repo it stays as a demo skeleton.

**Updated:** 2026-07-05 · **Maintained by:** plan-foundation / plan-master

| ID | Question / blocker | Blocks | Owner | Status |
|----|-------------------|--------|-------|--------|
| U1 | Cross-skill same-file anchor hygiene: `skill-functional-verify.py` now flags 18 pre-existing broken `#anchor` links (mostly heading-hyphen-count mismatches, a few pointing at content moved to `reference.md` without an updated prefix) across `code-implementation`, `code-repair`, `db-migration`, `feature-spec`, `plan-master`, `plan-repair`, `plan-verify`, `session-control` — reported as non-blocking `DEBT` in the tool's output. Root cause: the v0.4.3 "skill trim" (commit `e77ffcf`) moved content to `reference.md` without normalizing internal links; `skill-functional-verify.py` had no same-file-anchor or fence-balance check until this session. `plan-foundation` was fully repaired and is now in the tool's `ANCHOR_CLEAN` hard-fail set. | Doc hygiene / next skills-cleanup session | owner | Open |
| U2 | `plan-foundation` greenfield protocol step ordering: `p0-probe` (step 3) is instructed to record into `ASSUMPTIONS.md` / `RISK_REGISTRY.md` / `UNKNOWNS.md`, but registry creation is step 5 ("may start at step 2 if convenient, but must exist before GATE p0") — the guarantee is too weak for a hard dependency. Consider moving registry creation to before `p0-probe`, or making step 3 explicit that it creates the registries on first write if missing. | GATE p0 / greenfield protocol clarity | owner | Open |

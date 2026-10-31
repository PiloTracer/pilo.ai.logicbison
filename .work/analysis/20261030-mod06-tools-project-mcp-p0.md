## AI change risk summary

- **AI-assisted:** yes (owner-approved P0 remediation; no `human-only` declaration)
- **Boundaries crossed:** 3 — deploy scripts (`scripts/`), consumer config (`opencode.json*`, `.opencode/mcp/`), skill/documentation layer (`skills/`, `.quick/`)
- **New cross-boundary deps:** `deploy-basic.sh` / `deploy-files.sh` now read the MCP artifact from the framework source and write it to the consumer root; `install-opencode-config.sh` now reads the MCP file's existence to decide registration. Both are intentional and covered by verifier smoke tests.
- **Test isolation:** ok — `framework-verify.sh` sections 2c/2d/2e assert (a) server at consumer root, (b) executable interpreter, (c) `SERVER_VERSION = "1.1.0"`, (d) `python` → probed interpreter repair, (e) no `.ai/.opencode` leak. `skill-functional-verify.py` PASS.
- **Human architectural review:** optional — reason: no new runtime service, no data model, no network hop; the change is registration/deployment plumbing.
- **Blast radius:** if the copy or interpreter logic is wrong, a consumer's opencode/Cursor/Claude/DSH registration points at a missing or non-executable server; code work is unaffected (skills and builds do not depend on MCP). No secrets or data are touched. Worst case is a broken MCP entry, recoverable by `@project-query-setup install` / `deploy --force`.

## Recommendation

merge_ok — verifier green (measured), no data path, no secret handling change. Residual: Windows `py -3` path is covered by the interpreter probe but not smoke-tested on Windows here (`unknown`); refresh of an existing 1.0.0 consumer copy remains the separate `update` verb (F4).

## Conditions if merge_with_conditions

None.

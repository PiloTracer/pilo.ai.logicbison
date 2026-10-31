# tools-project MCP integration — Agent OS readiness audit

What: whether this Agent OS framework can use the tools-project MCP as documented, and what the tools-project documentation gets wrong.
**Status:** Final — audit + P0 remediation, 2026-10-30. F1–F3 were fixed the same day; findings below record the pre-fix state.
**Needs:** decision on the remaining P1 work (F4–F8); see §Remediation status.

---

## Verdict

**Was not ready — the MCP was registered but could not work end to end on this host.** Three blockers, all measured:

1. The registration launches `python`, which does not exist here; the template generates the same command for every new consumer.
2. The framework's server copy is `1.0.0` (5 tools, no `--self-check`); the canonical tools-project copy is `1.1.0` (8 tools), so ticket detail, comments and screenshots are unavailable.
3. Both bootstrap paths register `.opencode/mcp/project-mcp/mcp_server.py` without ever placing a file at that path (thin), or place it under `.ai/.opencode/…` (fat), so opencode starts a missing server until `@project-query-setup install` is run.

The setup skill still targets `1.0.0`; tools-project's own SPEC already lists its `1.1.0` update as an external deliverable (R21) and it has not been done. The tools-project docs are otherwise accurate and well-structured; two P2 features are described as deployed and one snippet breaks on the documented local key-file form.

---

## Remediation status (2026-10-30, after this audit)

| Finding | Status | Change and evidence |
|---------|--------|---------------------|
| **F1** interpreter | **Fixed** | `opencode.json.template` no longer hardcodes an interpreter; `install-opencode-config.sh` builds the command from the bash execution probe, repairs a bare `python`/`python3`/`py` alias to the probed interpreter, and adds the registration only when the client file exists. `opencode.json` now uses `python3`. Verified by `framework-verify` 2c/2d (fresh install + sync repair). |
| **F2** stale copy | **Fixed** | `.opencode/mcp/project-mcp/mcp_server.py` refreshed from `tools-project/api/app/client/mcp_server.py`: `SERVER_VERSION = "1.1.0"`, 8 tools, `--self-check` green. Stdio `initialize` + `tools/list` returns 8 tools (measured). |
| **F3** deploy placement | **Fixed** | `deploy-basic` copies the client file to the consumer root before scaffold; `deploy-files` copies it to the consumer root and excludes it from the `.ai/` tree; `--update` and `--force` refresh a differing copy (framework-owned artifact). `install-opencode-config` registers only when the file is present, so no broken default. Verified by `framework-verify` 2c/2e, including the update-refresh case. |
| **F6** DSH | **Documented (partial)** | `reference.md` §2b now covers opencode / Cursor / Claude Code / DSH / Codex; `skill.md` detects DSH profiles and has a Branch D that prints the `dsh-mcp-client` entry. Applying it to `~/.dsh/profiles/<profile>/cordis.patch.yml` is operator-level (outside the repo). |
| **F4** | **Partially fixed** | Claude Code detection now covers `.mcp.json` + `enabledMcpjsonServers`; the `${path}` validation bug is fixed. Still open: `update` verb, UA header, `--self-check` gate. |
| **F5, F7, F8** | **Open** | Doc mirror, consuming workflow, verifier registry checks. P1. |

`framework-verify.sh` result after the change: all checks passed, including the new MCP assertions.

---

## Evidence base

| Item | Result | Tag |
|------|--------|-----|
| Host interpreters | `python` absent; `python3` = 3.10.12 | measured |
| Framework server copy (pre-fix) | 9,233 B, `1.0.0`, 5 tools, no `--self-check` (silent exit 0); now `1.1.0`, 8 tools | measured |
| Canonical server | 22,417 B, `1.1.0`, 8 tools, `--self-check` works | measured |
| Local API (`:8300`) | `0.1.3`; 104 OpenAPI paths; 1.1.0 data routes present (401), capabilities + `/client/mcp_server.py` absent (404) | measured |
| Hosted API (`project.cloudsys.win`) | 502 during the audit window; later 200 on `projects` / ticket detail / activities and 404 on `capabilities` | measured |
| Outbound `deploy-files` | server lands at `<target>/.ai/.opencode/mcp/project-mcp/mcp_server.py` | measured |
| Fresh `install-opencode-config` (pre-fix) | wrote `["python", ".opencode/mcp/project-mcp/mcp_server.py"]`; now writes the probed interpreter | measured |
| tools-project git HEAD | `0a017a6` (clean tree) | measured |

---

## Framework findings

### F1 — P0: the MCP command cannot start (`python`)

- `opencode.json:L60` and `opencode.json.template:L25` both register `python`.
- `scripts/install-opencode-config.sh:L227-238` contains an execution-probe interpreter resolver, but the branch is dead: it runs only when `"tools-project" not in mcp`, and the template already defines the entry.
- `--sync-paths` deliberately preserves `mcp` (`scripts/install-opencode-config.sh:L293-294`), so existing consumers are never repaired either.
- Measured in a temp repo: a fresh install writes `["python", …]`; `command -v python` returns nothing.
- This directly contradicts the canonical setup doc, which requires `python3` (`LLM-2-API_SETUP.md:L117`, `L228`).

**Required:** template uses a resolved `python3`/`sys.executable`; repair existing `opencode.json` entries; add a verifier check that the registered interpreter executes.

### F2 — P0: the shipped server copy is stale (`1.0.0`, 5 tools)

- `.opencode/mcp/project-mcp/mcp_server.py` advertises `1.0.0` and 5 tools; it lacks `get_ticket_detail`, `list_ticket_activities`, `get_attachment` and `--self-check` (it exits 0 with no output — measured).
- Canonical `tools-project/api/app/client/mcp_server.py` is `1.1.0`, 8 tools, Cloudflare-safe UA, working `--self-check`.
- If the agent is supposed to read ticket evidence, this copy cannot do it, even against a 1.1.0 API.

**Required:** refresh the copy from the canonical file, record its version, and make the refresh a checked step (see F8).

### F3 — P0: deploy never puts the server where the registration points

- `scripts/deploy-basic.sh:L397` creates `opencode.json` (with the MCP block) but no deploy step copies `mcp_server.py`.
- Outbound `deploy-files` appends `.ai` to the target (`scripts/deploy-files.sh:L104-107`), so the tracked server lands at `<target>/.ai/.opencode/mcp/project-mcp/mcp_server.py` — measured.
- The generated command is root-relative (`.opencode/mcp/project-mcp/mcp_server.py`), so in fat-client mode it points outside `.ai/`; in thin-client mode the file is absent entirely.
- `framework-verify` only asserts the `mcp` key survives (`scripts/framework-verify.sh:L255-260`) and never checks that the command resolves.

**Required:** one canonical location (recommend consumer-root `.opencode/`), copied by deploy or omitted from the generated config until `@project-query-setup install` creates it; add a doctor/verify check.

### F4 — P1: `project-query-setup` is a `1.0.0` skill; tools-project's R21 is open

- No `update` mode (`skills/project-query-setup/skill.md:L30-38`).
- The Claude branch validation is broken: `${path}` is expanded by the shell, not Python, so `open('.claude/mcp.json')` becomes `open('')` (`skill.md:L245`). This is exactly the `${path}` bug tools-project flagged (`20261030-SPEC-amendment-01.md:L502`; verification `20261030-amendment-01-verification.md:L100`).
- Connectivity test sends no `User-Agent` (`skill.md:L106-115`), which the docs say is a mandatory `403 Error 1010` on the hosted instance.
- Copy source is a machine-specific absolute path (`skill.md:L140-143`), and no served-file fallback exists.
- Checklist and reporting have no version, tool-count, UA or `--self-check` gate (`skill.md:L274-288`); help still says "5 tools" (`skill.md:L349`).
- Reference docs point at paths that do not exist (F5).

**Required:** add `update`; use the served file when available with a portable fallback; send UA; run `--version`/`--self-check`; report server version + tool count; fix `${path}`; replace 5-tool text with the capability matrix (5 vs 8, gated by API).

### F5 — P1: the referenced contract is not in this repo

- `skill.md:L306-307` and `L366-367` point to `.work/docs/agent-query-api.md` and `.work/docs/tutorials/LLM-2-API_SETUP.md`; neither exists (`.work/docs/` holds only README scaffolds; `.work/docs/integration/` is empty).
- `skills/project-query-setup/reference.md:L7` points at an absolute tools-project path instead.
- This violates the framework's own integration-cache rule (`.cursorrules:L163`: cache vendor docs under `.work/docs/integration/` with a `MANIFEST.txt`).

**Required:** mirror the three relevant docs (`agent-query-api.md`, `LLM-2-API_SETUP.md`, `AGENT_TICKET_CONTEXT.md`) under `.work/docs/integration/tools-project/` + `MANIFEST.txt`, and update every reference. Deploy them to consumers with the skill.

### F6 — P1: this runtime (DSH) has no MCP registration

- `opencode.json` only configures opencode. The DeepSeek Harness web profile (`~/.dsh/profiles/web/cordis.yml` + `cordis.patch.yml`) has no MCP entry, and `dsh-mcp-client` is available in the global dsh package.
- Consequence: agents running in this GUI cannot call any tools-project tool today, regardless of F1–F3.

**Required:** decide whether DSH is supported (decision 2). If yes, add a documented `dsh-mcp-client` profile entry and a skill branch; if no, state opencode-only explicitly.

### F7 — P1: no consuming skill uses the 1.1.0 tools

- `get_ticket_detail`, `list_ticket_activities` and `get_attachment` appear nowhere in `skills/`; only `project-query-setup` references the five 1.0.0 tools.
- The `AGENT_TICKET_CONTEXT.md` workflow (ticket → comments → screenshot → fix → verify commit) has no Agent OS entry point; `session-control` S3c only checks that the server file exists.

**Required:** add a ticket-context protocol (new mode or skill) and reference it from `code-repair`/`session-control` as an optional live-evidence step; keep it non-blocking.

### F8 — P2: no verification of the integration

- `framework-verify` checks only `mcp` preservation; it never checks interpreter, file path, server version or self-check.
- `MCP_REGISTRY` records an approval from 2026-07-02 (`.work/context/MCP_REGISTRY.md:L5`) with no version or last-verified date.

**Required:** verify (a) `python3` executes, (b) registered path exists, (c) `--version` equals the expected `1.1.0`, (d) optional `--self-check` when the API is reachable; record version/date in the registry.

---

## tools-project documentation feedback

### D1 — P1: P2 features are described as deployed

- `LLM-2-API_SETUP.md:L181-195` labels the served-file download "After 1.1.0" and says it "works once a 1.1.0 build is deployed".
- `agent-query-api.md:L229-233` presents `/v1/agent/client/mcp_server.py` as available.
- Both capabilities and the served file are explicitly P2 (`20261030-SPEC-amendment-01.md:L732`), and both routes return 404 on the local 1.1.0 build (measured).
- The SPEC's own acceptance step 4 depends on those P2 routes (`20261030-SPEC-amendment-01.md:L539-546`).

**Fix:** mark Part E and the route as "not implemented (P2)" until they ship; keep "copy from the canonical repository" as the only working refresh path, and say it is machine-specific (D5).

### D2 — P1: the version-gating claim does not match the server

- `agent-query-api.md:L226-227` and `L259-260` say clients hide newer tools on an older API.
- The 1.1.0 server exposes a static 8-tool list (`api/app/client/mcp_server.py:L90`, `L488-492`) and `--self-check` lists all 8 even when `/capabilities` is 404 (measured). Nothing is hidden.
- `LLM-2-API_SETUP.md:L145-148` ("five tools on 1.0.0") and the quick reference `L33` therefore mislead anyone who copies the 1.1.0 server: they see eight tools on every deployment, and the three 1.1.0 ones fail on an old API.

**Fix:** implement the lazy capability gate, or change the docs to "the 1.1.0 server always lists eight; the three new tools return 404 on a 1.0.0 API".

### D3 — P1: `/openapi.json info.version` cannot identify 1.1.0

- `agent-query-api.md:L373`, `LLM-2-API_SETUP.md:L226` and `AGENT_TICKET_CONTEXT.md:L189` tell readers to check `info.version` to distinguish 1.0.0 from 1.1.0.
- Measured: the local build has the 1.1.0 ticket/activity/attachment routes but still reports `0.1.3`, and `/v1/agent/capabilities` is absent.

**Fix:** probe a 1.1.0 route (404 = old) or expose `agent_api_version` in `/healthz`; until capabilities ships, do not claim `info.version` is a version handshake.

### D4 — P1: the update snippet breaks on the documented local key-file form

- `agent-query-api.md:L270-273` builds the URL with `head -n1 ~/.tools-project-key | cut -d= -f2-`.
- The setup tutorial explicitly allows omitting `BASE_URL` for a local instance (`LLM-2-API_SETUP.md:L65`); then line 1 is the key, and the URL becomes `tools_project_…/v1/agent/client/mcp_server.py`.
- The same page already has the correct pattern at `L62` and `L184`.

**Fix:** use `BASE=$(grep '^BASE_URL=' …); BASE=${BASE:-http://localhost:8300}`.

### D5 — P1: the copy path is machine-specific

- `LLM-2-API_SETUP.md:L193` requires `/mnt/work/Projects/tools-project/...`, which only exists on this workstation; external readers cannot follow the primary setup path.
- There is no public canonical URL for `mcp_server.py` while the served endpoint is P2.

**Fix:** publish a raw/artifact URL (or state "internal only"), and give a portable fallback (`TOOLS_PROJECT_SRC` / `AI_SOURCE` env or a git clone command).

### D6 — P2: small consistency gaps

- `--self-check` is said to print `agent_api_version` (`LLM-2-API_SETUP.md:L157-158`); against a 404 capabilities it prints "unavailable" and exits 0.
- The tutorial lists opencode / Claude Code / Cursor but gives no Codex config example; DSH (this harness) is absent from the supported list, although the Agent OS README names Codex.
- The doc set is otherwise strong: event names/call sites, 10 s timeout / 3 attempts / 2 s backoff, HMAC-over-raw-body, in-memory 24 h idempotency, and external-refs no-dedupe all match the code (verified in `api/app/services/webhook_dispatcher.py`, `api/app/routers/integrations.py`, `api/app/routers/external_refs.py`). `reference/API.md` matches the live 104-path OpenAPI map; no broken relative links found.

---

## Minimum remediation sequence

1. **F1** interpreter (template + live config + repair path) and **F3** deploy placement — without these nothing starts.
2. **F2** refresh the server copy to `1.1.0`; add a version check so staleness is visible.
3. **F4** skill update: `update` mode, UA, `${path}` fix, `--self-check`, version/tool-count report, 8-tool matrix.
4. **F5** mirror the three tools-project docs under `.work/docs/integration/tools-project/` + MANIFEST; fix references.
5. **F7** one consuming workflow for ticket evidence; **F8** verifier checks.
6. **F6** DSH support decision and, if approved, the profile entry.
7. **D1–D5** corrections in tools-project docs (owner: tools-project).

Estimated: P0 ≈ 0.5–1 day; P1 ≈ 1 day; docs ≈ 0.5 day. *(estimated)*

---

## Decisions needed

1. **Approve the P1 skill/document work** (F4 + F5) — `update` verb, UA header, `${path}` fix, `--self-check`, doc mirror under `.work/docs/integration/tools-project/`. Yes / no.
2. **Doc source:** (a) mirror the tools-project docs into `.work/docs/integration/tools-project/` (recommended, matches `.cursorrules:L163`), or (b) keep external links only.
3. **DSH profile rollout:** apply the documented `dsh-mcp-client` entry per machine (operator), or leave DSH registration to each operator's own agent?

## Open questions

1. Should the framework ship the MCP server by default in deploy, or only create it through `@project-query-setup install`? (Current behavior: deploy ships the file; registration is conditional on it.)
2. Who owns refreshing the framework's MCP copy when tools-project publishes a new `agent_api_version` — a manual `update` verb, or a periodic check?

---

## Pizote deployment verification (2026-10-30)

`@deploy-basic update /mnt/work/Projects/pizote` (thin client):

| Check | Result |
|-------|--------|
| MCP artifact | refreshed to 22,417 B, `1.1.0`, 8 tools (mode `100755`); tracked |
| opencode | `opencode.json` → `["python3", ".opencode/mcp/project-mcp/mcp_server.py"]`; `skills.paths[0]` = framework source |
| Cursor | `.cursor/mcp.json` → same command/args (pre-existing, still valid) |
| stdio handshake | `initialize` → `tools-project-agent 1.1.0`; `tools/list` → 8 tools |
| live tools | `get_ticket_detail("PZT-T-2")` → counts `{activities:1, attachments:1, linked_commits:2}`; `list_ticket_activities` → 1 item; `get_attachment` → `text` + `image` block (483,040 base64 chars) |
| hosted API | `projects`, detail and activities = 200; `capabilities` = 404 (P2, expected) |
| Claude Code | **registered** — `.mcp.json` has `tools-project`; `.claude/settings.local.json` enables it; `claude mcp list` → `tools-project … ✔ Connected` |
| DSH | machine-level profile entry; not part of the repo, not applied here |
| Skills | thin client loads updated `project-query-setup` from `AGENT_OS_SOURCE`; `.cursorrules` has the registration row |
| Other tracked changes | `.mcp.json` (Claude registration) + `.work/context/MCP_REGISTRY.md` (approval row); no commit requested |

---

## Verification limits

- The hosted instance returned **502** throughout the audit; every "verified live" claim in the tools-project docs about the hosted deployment is **unverified** here.
- Local API payloads were not exercised with a valid superuser key (the workstation key belongs to the hosted instance); 1.1.0 routes were confirmed by 401-vs-404 probing and by code.
- tools-project files were not modified; the framework changes are limited to F1–F3 + the DSH documentation.

## Next action

Review the P1 items in §Decisions needed 1–2 and reply with the chosen scope.

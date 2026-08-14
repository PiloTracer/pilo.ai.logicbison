---
name: project-query-setup
description: >-
  Optional integration: guide through tools-project API key creation, MCP server
  registration, and connectivity test. OS-aware (tailors guidance per framework).
---

# project-query-setup

**Purpose:** Guide user through connecting their coding agent to tools-project, and teach it to query tasks, tickets, projects, and clients for context-aware work.

**Deploy to:** Any Agent OS framework (`.ai`, `.ai.ui`, `.ai.biz`, `.ai.soc`) — optional integration.

**Tutorial companion:** `.work/docs/tutorials/LLM-2-API_SETUP.md` (step-by-step setup walkthrough)

---

## Hard rules

1. **Optional integration.** This skill is never required. The user must explicitly ask to set it up or the director must ask first.
2. **Read-only.** The API provides read-only access. No mutations, no writes, no data modification.
3. **Key security.** Never log the API key. Never store it in shell history. `/tmp` is forbidden for key material. The `~/.tools-project-key` file must be `chmod 600`.
4. **Verify before claiming done.** Run a live query to the API and show the actual response. Never claim "connected" without evidence.
5. **Operator handoff:** every response that ends a turn follows the [Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — terse output; approvals under `**Needs your approval:**` citing `path:L<n>`; questions numbered under `**Needs your answer:**`; exactly one `**Next step:**` command; one line when nothing is needed (Form A). Decisions and questions never mixed; empty sections omitted.

---

## Modes

| Invocation | Mode |
|-----------|------|
| `@project-query-setup install` | Full guided setup: generate key → create file → test → register MCP |
| `@project-query-setup status` | Check if connected (key file exists? API reachable? MCP tools listed?) |
| `@project-query-setup key` | Guide the user through web UI → key creation → `~/.tools-project-key` |
| `@project-query-setup test` | Verify connectivity by listing projects |
| `@project-query-setup register-mcp` | Register MCP server in consuming project's coding-agent config |
| `@project-query-setup help` | Show available tools and usage patterns for this OS |
| `@project-query-setup` (no verb) | Default to `status` mode |

---

## Install protocol

### Step 1 — Detect OS context

Read the current OS identity from START_HERE.md or `.cursorrules`:

| Detected | OS | What it can do |
|----------|----|----------------|
| `.ai/` skills | Engineering OS | Query tasks/tickets for code work, build commit messages, verify HANDOFF vs live state, load project context before new features |
| `.ai.ui/` skills | UI Design OS | Check which tickets need UI work, get client/project context for screen design, search for existing components |
| `.ai.biz/` skills | Business OS | List all projects/clients for portfolio review, identify clients needing attention, find content to share |
| `.ai.soc/` skills | Security OS | Find tickets flagged for security review, check task status for pen test findings, search for vulnerability patterns |

Store this in an `OS_CONTEXT` variable for tailoring the rest of the protocol.

### Step 2 — Prerequisites gate

Check and report:

1. Is `python3` available? (required for MCP server)
2. Is there a running tools-project instance?
   - Local: try `curl -s http://localhost:8300/healthz`
   - Remote: ask user for URL
3. Can the user reach the web UI?
   - Local: `http://localhost:18513/settings/api-keys`
   - Remote: `https://<user-provided-url>/settings/api-keys`

If any prerequisite fails, stop and tell the user what to fix.

### Step 3 — Key creation (web UI)

Guide the user:

```
1. Open: <URL>/settings/api-keys
2. Click "+ New key"
3. Enter a label (e.g. "My laptop", "Agent OS integration")
4. Click "Create"
5. COPY the key now — it starts with "tools_project_"
```

Wait for the user to confirm they have the key. Do NOT ask them to paste it into chat.

### Step 4 — Create the key file

Tell the user to create `~/.tools-project-key` with their key:

```bash
# For local tools-project (no BASE_URL):
echo "tools_project_YOUR_KEY_HERE" > ~/.tools-project-key
chmod 600 ~/.tools-project-key

# For remote tools-project:
printf 'BASE_URL=https://project.cloudsys.win\ntools_project_YOUR_KEY_HERE\n' > ~/.tools-project-key
chmod 600 ~/.tools-project-key
```

**Critical:** Ask the user to replace `YOUR_KEY_HERE` with the actual key they copied. If the user is willing to paste the key into the conversation and asks you to write the file, run the command for them — but never log, display, or store the key value anywhere else. Always `chmod 600`.

### Step 5 — Test connectivity

Run a live query and show the result:

```bash
curl -s http://localhost:8300/v1/agent/projects \
  -H "X-Api-Key: $(head -n2 ~/.tools-project-key | tail -n1)"
```

For remote:
```bash
BASE_URL=$(grep BASE_URL= ~/.tools-project-key | cut -d= -f2-)
KEY=$(tail -n1 ~/.tools-project-key)
curl -s "$BASE_URL/v1/agent/projects" -H "X-Api-Key: $KEY"
```

Expected: `{ "ok": true, "data": [...] }` with project names. Show the actual output.

If `401 Unauthorized` — the key is wrong or revoked. Go back to Step 3.
If `403 Forbidden` — the user is not a superuser. Tell them to contact their admin.
If `Connection refused` — API is not running. Stop and tell user.

### Step 6 — Deploy MCP server

**Detect which coding agent config files exist in this project:**

```bash
for cfg in opencode.json .cursor/mcp.json .claude/settings.json .claude/mcp.json codex.json; do
  test -f "$cfg" && echo "FOUND: $cfg"
done
test -f .cursor/mcp.json && echo "CURSOR_MCP=yes" || true
test -f .claude/settings.json && echo "CLAUDE_CONFIG=yes" || true
test -f .claude/mcp.json && echo "CLAUDE_MCP=yes" || true
test -f opencode.json && echo "OPENCODE=yes" || true
```

**Copy the MCP server file (all branches):**

```bash
mkdir -p .opencode/mcp/project-mcp
cp /mnt/work/Projects/tools-project/.opencode/mcp/project-mcp/mcp_server.py \
   .opencode/mcp/project-mcp/
```

**Check for previously approved registrations:**

```bash
test -f .work/context/MCP_REGISTRY.md && echo "REGISTRY_EXISTS=yes" || echo "REGISTRY_EXISTS=no"
```

If `REGISTRY_EXISTS=yes`, read `.work/context/MCP_REGISTRY.md` and check whether a registration matching this config file + server already exists. If it does **and** the MCP server path hasn't changed, skip the confirmation prompt — proceed directly to the matching branch.

**Operator confirmation gate (mandatory before modifying any coding-agent config):**

Before applying Branch A, B, or C, present this prompt to the operator:

> **MCP registration is about to modify your coding-agent config.**
>
> - Config file to modify: `<detected config file>`
> - Server to register: `tools-project`
> - Command: `python3 .opencode/mcp/project-mcp/mcp_server.py`
>
> Proceed with registration? (yes/no)

Present this gate as a Form B Operator handoff close: the approval enumerated under `**Needs your approval:**` citing `path:L<n>` of the config file to modify, ending with one `**Next step:**` command — per SKILL_DEPENDENCIES.md.

Wait for the operator's explicit `yes`. Do **not** proceed on silence, "maybe", or any non-affirmative response. If the operator says `no`, stop Step 6 and skip to the completion checklist (items 5 and 6 will be `skip`).

**Record the approval (after successful registration):**

After the MCP block is written and validated, append to `.work/context/MCP_REGISTRY.md`:

```bash
mkdir -p .work/context
if ! test -f .work/context/MCP_REGISTRY.md; then
  echo "# MCP Registry — approved registrations" > .work/context/MCP_REGISTRY.md
  echo "" >> .work/context/MCP_REGISTRY.md
  echo "| Config file | Server | Approved | MCP server path |" >> .work/context/MCP_REGISTRY.md
  echo "|-------------|--------|----------|-----------------|" >> .work/context/MCP_REGISTRY.md
fi
echo "| <config-file> | tools-project | $(date +%Y-%m-%d) | .opencode/mcp/project-mcp/mcp_server.py |" >> .work/context/MCP_REGISTRY.md
```

This record prevents re-prompting on subsequent `install` or `register-mcp` runs — the skill reads the registry and skips confirmation for already-approved entries.

**Branch A — `opencode.json` exists:**
Register in opencode format (after confirmation):

```bash
python3 << 'PYEOF'
import json
with open('opencode.json') as f:
    cfg = json.load(f)
cfg.setdefault('mcp', {})['tools-project'] = {
    "type": "local",
    "command": ["python3", ".opencode/mcp/project-mcp/mcp_server.py"],
    "enabled": True
}
with open('opencode.json', 'w') as f:
    json.dump(cfg, f, indent=2)
    f.write('\n')
PYEOF
python3 -c "import json; json.load(open('opencode.json')); print('opencode.json: valid')"
```

**Branch B — `.cursor/mcp.json` exists (Cursor agent):**
Register in Cursor MCP format:

```bash
python3 << 'PYEOF'
import json, os
path = '.cursor/mcp.json'
cfg = json.load(open(path)) if os.path.exists(path) else {}
cfg.setdefault('mcpServers', {})['tools-project'] = {
    "command": "python3",
    "args": [".opencode/mcp/project-mcp/mcp_server.py"],
    "transport": "stdio"
}
os.makedirs('.cursor', exist_ok=True)
with open(path, 'w') as f:
    json.dump(cfg, f, indent=2)
    f.write('\n')
PYEOF
python3 -c "import json; json.load(open('.cursor/mcp.json')); print('.cursor/mcp.json: valid')"
```

**Branch C — `.claude/settings.json` or `.claude/mcp.json` exists (Claude Code):**
Register in Claude Code MCP format:

```bash
python3 << 'PYEOF'
import json, os
path = '.claude/mcp.json' if os.path.exists('.claude/mcp.json') else '.claude/settings.json'
os.makedirs('.claude', exist_ok=True)
cfg = json.load(open(path)) if os.path.exists(path) else {}
cfg.setdefault('mcpServers', {})['tools-project'] = {
    "command": "python3",
    "args": [".opencode/mcp/project-mcp/mcp_server.py"],
    "type": "stdio"
}
with open(path, 'w') as f:
    json.dump(cfg, f, indent=2)
    f.write('\n')
PYEOF
python3 -c "import json; json.load(open('${path}')); print('${path}: valid')"
```

**Branch D — No known agent config detected (no confirmation needed — no files modified):**
Output the MCP registration details so the operator's own coding agent can register itself:

> ⓘ **MCP server ready — registration needed for your coding agent.**
>
> The MCP server file has been copied to `.opencode/mcp/project-mcp/mcp_server.py`.  
> However, no known coding-agent config file was detected in this project.
>
> **Provide the following details to your coding agent and ask it to register the MCP server in its config:**
>
> ```
> Server name:   tools-project
> Type:          local (stdio transport)
> Command:       python3 .opencode/mcp/project-mcp/mcp_server.py
> Key file:      ~/.tools-project-key (chmod 600)
> ```
>
> Your agent knows its own config format — it will register the server correctly.  
> Common agent config locations:
> - **opencode:** `opencode.json` → `"mcp"` block
> - **Cursor:** `.cursor/mcp.json` → `"mcpServers"` block
> - **Claude Code:** `.claude/mcp.json` or `.claude/settings.json` → `"mcpServers"` block
> - **Other:** check your tool's MCP integration docs

End the Branch D output with the Operator handoff close (Form B — the registration hand-off to the operator's agent enumerated under `**Needs your approval:**` — + one `**Next step:**` command) per SKILL_DEPENDENCIES.md.

### Step 7 — Verify with completion checklist

Run each check and report the result:

| # | Check | How | Result |
|---|-------|-----|--------|
| 1 | Key file exists | `test -f ~/.tools-project-key` | pass / fail |
| 2 | Permissions 600 | `stat -c '%a' ~/.tools-project-key` shows `600` | pass / fail |
| 3 | API reachable | `curl -s <url>/healthz` returns 200 | pass / fail |
| 4 | Auth works | `curl -s <url>/v1/agent/projects -H "X-Api-Key: $(tail -n1 ~/.tools-project-key)"` returns projects | pass / fail |
| 5 | MCP server file present | `test -f .opencode/mcp/project-mcp/mcp_server.py` (or consuming project) | pass / skip |
| 6 | MCP registered in coding agent config | Check the detected agent config for `tools-project` entry (opencode: `mcp.tools-project`, Cursor/Claude: `mcpServers.tools-project`) | pass / skip |
| 7 | python3 available | `which python3` | pass / fail |

End the checklist report with the Operator handoff close (Form A `Next: …` when all pass, or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**` when any check needs operator action) per SKILL_DEPENDENCIES.md.

### Step 8 — Show OS-specific usage patterns

```
Connected to tools-project. Found N projects.

Your {OS_NAME} agents can now:

  {OS-specific capabilities from the table in Step 1}

To use this from any skill, add this prerequisite line
to the skill's preamble:

  Prerequisites: tools-project MCP server registered
  (provides list_projects, get_project_context,
  get_task_info, get_ticket_info, search_entities tools)

Reference: .work/docs/agent-query-api.md
Tutorial:  .work/docs/tutorials/LLM-2-API_SETUP.md
```

End the install summary with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per SKILL_DEPENDENCIES.md.

---

## Status protocol

Run `~/.tools-project-key` check and a live query. Report:

```
Key file:    {present/missing} ({path})
Permissions: {chmod} (should be 600)
API:         {reachable/unreachable} {url}
Auth:        {ok / 401 / 403}
Projects:    {count} accessible
MCP tools:   {count} registered ({names})
```

End the status report with the Operator handoff close (Form A `Next: …` when all green, or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**` when the operator must fix something) per SKILL_DEPENDENCIES.md.

---

## Key protocol (standalone)

Same as Steps 3-4 from Install protocol. Lighter — no MCP registration, no API test (user runs `test` or `status` after).

End the key report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per SKILL_DEPENDENCIES.md.

---

## Test protocol

Same as Step 5 from Install protocol. Returns a yes/no + response snippet.

End the test report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per SKILL_DEPENDENCIES.md.

---

## Help protocol

Show the 5 MCP tools available and their descriptions. Then show one domain-specific example for the current OS:

| OS | Example |
|----|---------|
| Engineering | "What's the status of ticket TPR-T-12?" → `get_ticket_info(ref="TPR-T-12")` |
| UI Design | "What projects need UI work?" → `list_projects` + `get_task_info(status="todo")` |
| Business | "Which clients need attention?" → `list_projects` + `get_project_context()` per project |
| Security | "Find tickets related to rate limiting" → `search_entities(q="rate limit")` |

End the help output with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per SKILL_DEPENDENCIES.md.

---

## Reference

| Doc | Path |
|-----|------|
| Full API + MCP guide | `.work/docs/agent-query-api.md` |
| Step-by-step tutorial | `.work/docs/tutorials/LLM-2-API_SETUP.md` |
| Feature SPEC | `.work/features/agent-query-api/20260701-SPEC.md` |
| MCP server source | `.opencode/mcp/project-mcp/mcp_server.py` |

---

## Anti-patterns to refuse

- Claiming "connected" without a live API response
- Writing the key file without `chmod 600` after
- Asking the user to paste their API key into chat
- Storing the key in `/tmp` or any non-`~/.tools-project-key` location
- Logging the key value in any output
- Registering MCP in the framework's own config (it belongs in the consuming project's coding-agent config)
- Burying operator actions/questions in prose instead of the closing Operator handoff block

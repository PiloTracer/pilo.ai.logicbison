# Deploy .ai (Agent OS) Into a Target Project

Two modes: **fat-client** (`deploy-files` — vendored `.ai/` in target, works offline) and **thin-client** (`deploy-basic` — only `.cursorrules` + `.work/` + `DOCS_TECH_STACK.md` in target; skills/standards/concepts/docs/scripts load from source at runtime via an `AGENT_OS_SOURCE` pointer).

## Thin-client — recommended when you share one source across many repos

### In-place (you are inside the target project)

```text
@deploy-basic
# from /mnt/work/Projects/tools-project → creates ./.cursorrules, ./.work/, ./DOCS_TECH_STACK.md
# skills/standards/concepts/docs/scripts are NOT copied; the agent loads them
# from $AGENT_OS_SOURCE at runtime.
# Source must be reachable from the target; if not auto-discovered, supply it.
```

### Outbound (you are in the Agent OS source directory)

```text
@deploy-basic - /absolute/path/to/my-project
# from /mnt/work/Projects/.ai → bootstraps /absolute/path/to/my-project
# Same effect as in-place; only the cwd differs.
```

No-overwrite by default. Re-sync the source pointer + rules-aware-merge the small local surface:

```text
@deploy-basic update
```

**First bootstrap (chicken-and-egg):** before the target has `.cursorrules`, no skill can load there yet. Bootstrap from the source dir or invoke the shell directly in the target:

```bash
bash /mnt/work/Projects/.ai/scripts/deploy-basic.sh /mnt/work/Projects/tools-project
# (or, from inside the target:)
bash /mnt/work/Projects/.ai/scripts/deploy-basic.sh .
```

## Fat-client — full vendored .ai in target (works offline)

### In-place (you are inside the target project)

```text
@deploy-files
# from /mnt/work/Projects/tools-project → creates ./.ai/, ./.work/, ./.cursorrules
# source defaults to the script's own .ai; supply it if asked:
#   "source is /mnt/work/Projects/.ai"
#   "skills at /mnt/work/Projects/.ai/skills"
```

No-overwrite by default. Rules-aware merge of existing-but-differing files:

```text
@deploy-files update
```

### Outbound (run from the source Agent OS repo)

```text
@deploy-files copy - /absolute/path/to/my-project
# Creates /absolute/path/to/my-project/.ai/ (excludes .git, .github, .gitignore, .cursorrules)
# no-overwrite by default; add --force for legacy idempotent overwrite
```

If the path already includes `.ai`:

```text
@deploy-files copy - /absolute/path/to/my-project/.ai
```

## Check deploy status

```text
@deploy-basic status
@deploy-files status
```

## Next steps in the target project

```text
# In-place @deploy-basic / @deploy-files already scaffolded .work/ + .cursorrules:
@session-control start

# Outbound `deploy-files copy - <path>` needs the scaffold step first:
@project-bootstrap init
@session-control start

# Thin-client: verify source is reachable before invoking any skill:
test -d "$(grep -oE 'AGENT_OS_SOURCE=[^ ]*' .cursorrules | head -1 | cut -d= -f2-)"
```

## Coding-agent setup (after deploy)

Agent OS is **tool-agnostic** — skills are markdown; each agent needs its own config surface:

| Agent | File | Bootstrap action |
|-------|------|------------------|
| opencode | `opencode.json` | Auto-created from `opencode.json.template` when missing (`install-opencode-config.sh` runs from bootstrap / deploy). **Review paths** after fat vs thin deploy. |
| Cursor | `.cursorrules` | Created by scaffold. Optional MCP: `.cursor/mcp.json` via `@project-query-setup`. |
| Claude Code | `.claude/mcp.json` | MCP via `@project-query-setup`. Skills follow `.cursorrules` or manual skill path config. |
| Codex / other | per tool | Mirror `.cursorrules` content + skill directory paths in the tool's config format. |

**opencode path cheat sheet:**

| Deploy mode | `skills.paths` should include | `instructions` entry points |
|-------------|------------------------------|----------------------------|
| Fat-client (`deploy-files`) | `.ai/skills` | `.ai/START_HERE.md`, `.ai/PROCESS_ROUTER.md` |
| Thin-client (`deploy-basic`) | `$AGENT_OS_SOURCE/skills` (absolute) | same prefix for START_HERE / PROCESS_ROUTER |
| Self-hosted (this repo) | `./skills` | `./START_HERE.md` |

Sister frameworks (`.ai.ui`, `.ai.biz`, `.ai.soc`) are added to `opencode.json` automatically when present as siblings on disk.

**After source moves (`@deploy-basic update`):**

- `.cursorrules` `AGENT_OS_SOURCE` is re-synced automatically.
- `opencode.json` framework paths are updated via `--sync-paths` (custom MCP preserved).
- Run `@deploy-basic status` to confirm `opencode skills.paths[0]` shows **ok** not **STALE**.

## Examples

```text
# Thin-client outbound (from source):
@deploy-basic - /home/user/work/ecommerce-platform
# Thin-client in-place (from target):
@deploy-basic
@deploy-basic update

# Fat-client outbound (from source):
@deploy-files copy - /home/user/work/ecommerce-platform
@deploy-files copy - /home/user/work/ecommerce-platform/.ai
```

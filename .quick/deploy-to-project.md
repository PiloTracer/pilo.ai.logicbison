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

## Full repo — with .git and .github

### Clone (full git mirror — requires origin remote)

```text
@deploy-repo clone - /absolute/path/to/destination
# Full git clone preserving history, branches, tags
```

### Archive (snapshot — no remote needed, includes .github/ and .cursorrules)

```text
@deploy-repo archive - /absolute/path/to/destination
# git archive extract — everything except .git directory
```

## Check deploy status

```text
@deploy-basic status
@deploy-files status
@deploy-repo status
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
@deploy-repo clone - /home/user/work/mirror
@deploy-repo archive - /home/user/work/internal-admin
```

# `.ai.mlt` (MLT Agent OS) — upgrade directions for the deploy skills

**Status:** Ready · **Needs:** none · **Repo:** `/mnt/work/Projects/.ai.mlt` (clean git)

Goal: make the deploy skills produce targets whose `.cursorrules` discover all six sisters under both namings — same as the current framework.

## Current state (measured 2026-08-19)

- `scripts/mlt-deploy-basic.sh` (176 L): thin bootstrap; substitutes `REPLACE_BASICSOURCE` → `TRAINER_MLT_SOURCE` (the source env var) + project tokens; template = `templates/cursorrules.template`. **No sister logic anywhere** (zero hits for `sister`/`.ai.ui`/`AI_UI_PATH` in `scripts/`).
- `scripts/mlt-cursorrules-verify.sh` (219 L): checks MLT layouts + a single grep heuristic (`:191-197`); **no sister cells**.
- **No `mlt-deploy-files.sh` / `mlt-deploy-repo.sh` scripts** — those skills exist in `skills/` but have no backing script (deploy-files/deploy-repo are skill-only).
- `.cursorrules`: **no Frameworks registry** (natural insertion point: after the `**Free-text:**` line, `:30`).
- `templates/cursorrules.template`: tiny (~31 L) placeholder-style; **no registry, no `AI_*_PATH` tokens**.
- `scripts/framework-verify.sh` (200 L): structural checks; no sister checks.

## Steps

### 1. Copy the discovery lib
```bash
cp /mnt/work/Projects/pilo.ai.logicbison/scripts/sister-discovery.sh scripts/sister-discovery.sh
```

### 2. `.cursorrules` — add the Frameworks registry (Layer 1, required)
Insert right after the `**Free-text:** …` line (line 30):

```markdown
### Frameworks registry (cross-framework discovery)

Sister frameworks are siblings on disk; `.ai.<fw>` (legacy) / `pilo.ai.<fw>.logicbison` (family) naming — see path resolution below. `.ai.mlt` is this framework (self-hosted).

| Framework | Director | Path | Bootstrap artifact |
|-----------|----------|------|--------------------|
| `.ai.mlt` (MLT Agent OS) | `@mlt-director` | *this directory* | `skills/README.md` |
| `.ai` (Agent OS) | `@ai-director` | `../.ai` | `../.ai/skills/README.md` |
| `.ai.biz` (Business OS) | `@biz-director` | `../.ai.biz` | `../.ai.biz/skills/README.md` |
| `.ai.cto` (CTO Professor OS) | `@cto-director` | `../.ai.cto` | `../.ai.cto/skills/README.md` |
| `.ai.flutter` (Flutter Agent OS) | `@flutter-director` | `../.ai.flutter` | `../.ai.flutter/skills/README.md` |
| `.ai.soc` (Social OS) | `@soc-director` | `../.ai.soc` | `../.ai.soc/skills/README.md` |
| `.ai.ui` (UI Design OS) | `@ui-director` | `../.ai.ui` | `../.ai.ui/skills/README.md` |

**Path resolution:** (1) use a filled path cell; empty → fall through. (2) Auto-discover: parent = `S/..` with S = this repo (self-hosted) or `$TRAINER_MLT_SOURCE` (thin); sister = `<S basename with <fw> inserted before its last .segment>` (e.g. `pilo.ai.ui.logicbison` for a `pilo.ai.logicbison` source; `.ai`-prefixed sources resolve `.ai.<fw>` directly), else legacy `.ai.<fw>`; missing = "not installed". (3) Before routing, verify the framework dir + its `skills/README.md` exist; if absent, route with `[degraded: <framework> not installed]` — never route into the void. If your source dir name breaks discovery, fill the path cells manually.
```

### 3. `mlt-deploy-basic.sh` — wire the lib (Layer 2)
In the substitution step (after `TRAINER_MLT_SOURCE` is baked), mirror `pilo.ai.logicbison/scripts/deploy-basic.sh` step 2:

```bash
source "${MLT_ROOT}/scripts/sister-discovery.sh"     # MLT_ROOT = the script's derived source root var
for fw in $FRAMEWORK_SLOTS; do
  token_upper="$(echo "$fw" | tr '[:lower:]' '[:upper:]')"
  token="REPLACE:AI_${token_upper}_PATH"
  fw_dir="$(find_sister_dir "$MLT_ROOT" "$fw" "$(dirname "$MLT_ROOT")" || true)"
  if [[ -n "$fw_dir" ]]; then
    fw_esc="${fw_dir//\//\\/}"
    perl -i -pe "s{${token} \\(default:? \\\`[^)]*\\)}{${fw_esc} (discovered at deploy time)}" "$tmpfile"
  else
    echo "  frameworks: ${token} not found (checked $(sister_names "$fw" "$MLT_ROOT" | paste -sd' ' -)) — fill manually if the sister exists under another dir name" >&2
  fi
done
```
> **Note:** the template has no `REPLACE:AI_*_PATH` cells — the loop no-ops until step 4. If you skip step 4, skip step 3 (Layer 1 already covers runtime discovery).

### 4. Template — add the registry with tokens (optional, for deploy parity)
In `templates/cursorrules.template`, add the 7-row registry with consumer-style cells (`REPLACE:AI_UI_PATH (default \`../.ai.ui\`)`, … cto/flutter/mlt/soc/biz; self-excluded) + the resolution text.

### 5. `mlt-cursorrules-verify.sh` — add six-slot cell checks (optional)
Mirror `pilo.ai.logicbison/scripts/cursorrules-verify.sh` (source the lib; loop `$FRAMEWORK_SLOTS`; reachable / unfilled-token / STALE).

### 6. Verify
```bash
source scripts/sister-discovery.sh
sister_names ui "$PWD"     # → .ai.ui
for s in biz cto flutter mlt soc ui; do test -d "../.ai.$s/skills/README.md" && echo "$s ok"; done
bash scripts/mlt-deploy-basic.sh /tmp/smoke-mlt     # inspect /tmp/smoke-mlt/.cursorrules
bash scripts/framework-verify.sh
```

## Gaps found (include in a follow-up)

- **No `mlt-deploy-files.sh` / `mlt-deploy-repo.sh` scripts** despite `mlt-deploy-files`/`mlt-deploy-repo` skills existing — fat-client deploy is skill-only; decide whether to restore the scripts (copy from `pilo.ai.logicbison/scripts/deploy-files.sh`, adapted) or mark the skills as thin-only.
- `agent.os.framework.md:6` cites `standards/PROTECTED_SURFACES.json` which does not exist in this repo (dangling reference).
- `agent.os.framework.md:5` references the `session-control` skill, which is not vendored in this repo.
- `.ai` row points at the old on-disk Agent OS snapshot; update when the family rename lands.

## Checklist
- [ ] `scripts/sister-discovery.sh` copied
- [ ] `.cursorrules` registry + resolution (Layer 1)
- [ ] Deploy fill (step 3) + template registry (step 4) as a pair, or both skipped
- [ ] Verify commands pass
- [ ] Nothing committed/staged

## Next action
Run steps 1–2 + 6 inside `/mnt/work/Projects/.ai.mlt`; steps 3–5 optional per the notes.

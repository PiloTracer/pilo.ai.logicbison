# `.ai.biz` (Business OS) — upgrade directions for the deploy skills

**Status:** Ready · **Needs:** none · **Repo:** `/mnt/work/Projects/.ai.biz` (24 skills, clean git, CI present)

Goal: make `@biz-deploy-basic` / `@biz-deploy-files` produce targets whose `.cursorrules` discovers all six sister frameworks under both namings — same as the current framework.

## Current state (measured 2026-08-19)

- `scripts/biz-deploy-basic.sh` (280 L) substitutes `templates/cursorrules.template`: only `AGENT_OS_SOURCE=REPLACE_BASICSOURCE` → absolute `BIZ_ROOT` + gate-table script paths (`:156-178`). **No sister logic anywhere** (zero hits for `sister`/`AI_UI_PATH`/`.ai.ui` in `scripts/`).
- Source root: `BIZ_SOURCE` env override, else script location (`:69-74`); token written to targets: `AGENT_OS_SOURCE`.
- `scripts/biz-cursorrules-verify.sh` (247 L): checks the source pointer + script paths; **no sister cells**.
- `.cursorrules`: **no Frameworks registry** (natural insertion point: right after the `**Free-text entry point:**` paragraph, line 62).
- `templates/cursorrules.template` (286 L): **no registry, no `AI_*_PATH` tokens**.
- `scripts/framework-verify.sh` (275 L): deploy smokes + registration checks; **no sister checks**.

## Steps

### 1. Copy the discovery lib
```bash
cp /mnt/work/Projects/pilo.ai.logicbison/scripts/sister-discovery.sh scripts/sister-discovery.sh
```
It exports `FRAMEWORK_SLOTS="ui biz soc cto flutter mlt"`, `sister_names <fw> <root>`, `find_sister_dir <root> <fw> [parents...]`.

### 2. `.cursorrules` — add the Frameworks registry (Layer 1, required)
Insert right after the `**Free-text entry point:** …` paragraph (line 62):

```markdown
### Frameworks registry (cross-framework discovery)

Sister frameworks are siblings on disk; `.ai.<fw>` (legacy) / `pilo.ai.<fw>.logicbison` (family) naming — see path resolution below. `.ai.biz` is this framework (self-hosted).

| Framework | Director | Path | Bootstrap artifact |
|-----------|----------|------|--------------------|
| `.ai.biz` (Business OS) | `@biz-director` | *this directory* | `skills/README.md` |
| `.ai` (Agent OS) | `@ai-director` | `../.ai` | `../.ai/skills/README.md` |
| `.ai.cto` (CTO Professor OS) | `@cto-director` | `../.ai.cto` | `../.ai.cto/skills/README.md` |
| `.ai.flutter` (Flutter Agent OS) | `@flutter-director` | `../.ai.flutter` | `../.ai.flutter/skills/README.md` |
| `.ai.mlt` (MLT Agent OS) | `@mlt-director` | `../.ai.mlt` | `../.ai.mlt/skills/README.md` |
| `.ai.soc` (Social OS) | `@soc-director` | `../.ai.soc` | `../.ai.soc/skills/README.md` |
| `.ai.ui` (UI Design OS) | `@ui-director` | `../.ai.ui` | `../.ai.ui/skills/README.md` |

**Path resolution:** (1) use a filled path cell; empty → fall through. (2) Auto-discover: parent = `S/..` with S = this repo (self-hosted) or `$AGENT_OS_SOURCE` (thin); sister = `<S basename with <fw> inserted before its last .segment>` (e.g. `pilo.ai.ui.logicbison` for a `pilo.ai.logicbison` source; `.ai`-prefixed sources resolve `.ai.<fw>` directly), else legacy `.ai.<fw>`; missing = "not installed". (3) Before routing, verify the framework dir + its `skills/README.md` exist; if absent, route with `[degraded: <framework> not installed]` — never route into the void. If your source dir name breaks discovery, fill the path cells manually.
```

### 3. `biz-deploy-basic.sh` — wire the lib (Layer 2)
In `subst_cursorules()` (`:156-178`), after the `AGENT_OS_SOURCE` substitution, add the six-slot fill (adapt the reference from `pilo.ai.logicbison/scripts/deploy-basic.sh` step 2):

```bash
source "${BIZ_ROOT}/scripts/sister-discovery.sh"
for fw in $FRAMEWORK_SLOTS; do
  token_upper="$(echo "$fw" | tr '[:lower:]' '[:upper:]')"
  token="REPLACE:AI_${token_upper}_PATH"
  fw_dir="$(find_sister_dir "$BIZ_ROOT" "$fw" "$(dirname "$BIZ_ROOT")" || true)"
  if [[ -n "$fw_dir" ]]; then
    fw_esc="${fw_dir//\//\\/}"
    perl -i -pe "s{${token} \\(default:? \\\`[^)]*\\)}{${fw_esc} (discovered at deploy time)}" "$tmpfile"
  else
    echo "  frameworks: ${token} not found (checked $(sister_names "$fw" "$BIZ_ROOT" | paste -sd' ' -)) — fill manually if the sister exists under another dir name" >&2
  fi
done
```
> **Note:** the current template has no `REPLACE:AI_*_PATH` cells, so the loop no-ops until step 4 is done. If you skip step 4, skip this step too — Layer 1 already covers runtime discovery.

### 4. Template — add the registry with tokens (optional but recommended for deploy parity)
In `templates/cursorrules.template`, add the same 7-row registry, but consumer-style: self row stays `*this directory*`, and the six sibling Path cells become `REPLACE:AI_UI_PATH (default \`../.ai.ui\`)`, `REPLACE:AI_CTO_PATH (default \`../.ai.cto\`)`, `REPLACE:AI_FLUTTER_PATH (default \`../.ai.flutter\`)`, `REPLACE:AI_MLT_PATH (default \`../.ai.mlt\`)`, `REPLACE:AI_SOC_PATH (default \`../.ai.soc\`)`, `REPLACE:AI_BIZ_PATH (default \`../.ai.biz\`)` (self-excluded). Same path-resolution text.

### 5. `biz-cursorrules-verify.sh` — add the six-slot cell checks (optional)
Mirror `pilo.ai.logicbison/scripts/cursorrules-verify.sh`: source the lib, loop `$FRAMEWORK_SLOTS`, report each cell as reachable / unfilled-token (warn when installed) / STALE (fail).

### 6. Verify
```bash
source scripts/sister-discovery.sh
sister_names ui "$PWD"     # → .ai.ui
sister_names cto "$PWD"    # → .ai.cto
for s in biz cto flutter mlt soc ui; do test -d "../.ai.$s/skills/README.md" && echo "$s ok"; done
bash scripts/biz-deploy-basic.sh /tmp/smoke-biz   # then inspect /tmp/smoke-biz/.cursorrules
bash scripts/framework-verify.sh
```

## Gaps found (include in a follow-up)

- `biz-cursorrules-verify.sh` has no `--self-test` and exits 1 when run against the source repo itself (open audit finding F2).
- `templates/work/plans/NEXT.md.template` lacks the required `## Next action` heading (open audit finding F1).
- Stale artifacts in the repo: `tmp-fv-status.out`, `tmp/fv.log` (old verifier output naming pre-rename script names) — delete them.
- `reasonix.toml` still allow-lists pre-rename paths (`skills/deploy-basic/skill.md`, …) — refresh if that config is still used.
- `.ai` sibling row: the on-disk `/mnt/work/Projects/.ai` copy is the **old** Agent OS snapshot; when the Agent OS family rename lands, update the `.ai` row to `../pilo.ai.logicbison` (or fill manually).

## Checklist
- [ ] `scripts/sister-discovery.sh` copied and `source`-able
- [ ] `.cursorrules` registry: 7 rows + path resolution, paths resolve
- [ ] Deploy fill wired (or Layer-1-only decision recorded)
- [ ] Template registry (optional step 4) done if step 3 done
- [ ] Verify commands pass
- [ ] Nothing committed/staged

## Next action
Run steps 1–2 + 6 inside `/mnt/work/Projects/.ai.biz`; steps 3–5 optional per the notes.

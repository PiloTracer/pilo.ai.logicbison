# `.ai.cto` (CTO Professor OS) — upgrade directions for the deploy skills

**Status:** Ready · **Needs:** none · **Repo:** `/mnt/work/Projects/.ai.cto` (clean git, CI present)

Goal: make the deploy/verify skills produce targets whose `.cursorrules` discover all six sisters under both namings — same as the current framework. `.ai.cto` is the **closest** sibling: it already has a Frameworks registry in both `.cursorrules` and the template.

## Current state (measured 2026-08-19)

- `scripts/deploy-basic.sh` (194 L): thin bootstrap; substitutes `TRAINER_CTO_SOURCE=REPLACE_BASICSOURCE` + gate paths. **No sister fill logic.**
- `scripts/verify-target.sh` (153 L): **has a sister check** — loop `for fw in .ai .ai.ui .ai.biz .ai.soc` at `:108`, with a dual-base inconsistency (`DEST_ROOT` vs `DISCOVERY_BASE` at `:115`); misses `.ai.cto` itself? (checks only those four), misses `.ai.flutter`/`.ai.mlt`, and has no family naming.
- `.cursorrules` `## Frameworks registry` at `:78-88` — 5 rows (`.ai`, `.ai.ui`, `.ai.biz`, `.ai.soc`, `.ai.cto` = *this framework*) + resolution text `:88` ("auto-discover siblings of thin-client parent (`$TRAINER_CTO_SOURCE/..`) or fat-client parent" — legacy wording, no family naming).
- `templates/cursorrules.template` — same 5-row registry + same resolution text (`:78-88`).
- `scripts/framework-verify.sh` (296 L): asserts `.cursorrules` ≡ template congruence (`:207-212`) — **any registry change must be mirrored in both files**.

## Steps

### 1. Copy the discovery lib
```bash
cp /mnt/work/Projects/pilo.ai.logicbison/scripts/sister-discovery.sh scripts/sister-discovery.sh
```

### 2. Extend the registry in `.cursorrules` AND `templates/cursorrules.template` (keep them identical — framework-verify enforces congruence)
After the `.ai.soc` row (`:85` in both files), add:
```markdown
| `.ai.flutter` (Flutter Agent OS) | `@flutter-director` | REPLACE:AI_FLUTTER_PATH (default `../.ai.flutter`) | `.ai.flutter/skills/README.md` |
| `.ai.mlt` (MLT Agent OS) | `@mlt-director` | REPLACE:AI_MLT_PATH (default `../.ai.mlt`) | `.ai.mlt/skills/README.md` |
```
(The self row `.ai.cto` = `*this framework*` stays; the `.ai` row stays — it is cto's Agent OS anchor.)

Replace the resolution text (both files) with the family-aware version:
```markdown
**Path resolution:** filled path cell wins; `REPLACE:*`/empty → auto-discover siblings of thin-client parent (`$TRAINER_CTO_SOURCE/..`) or fat-client parent; sister dir = source basename with `<fw>` inserted before its last `.segment` (e.g. `pilo.ai.ui.logicbison` for a `pilo.ai.logicbison` source; `.ai`-prefixed sources resolve `.ai.<fw>` directly), else legacy `.ai.<fw>`; missing → "not installed" — route with `[degraded: <framework> not installed]`, never into the void.
```

### 3. `verify-target.sh` — replace the legacy-only sister loop with the six-slot lib
At `:108`, replace the `for fw in .ai .ai.ui .ai.biz .ai.soc` loop with:
```bash
source "$(dirname "${BASH_SOURCE[0]}")/sister-discovery.sh"
for fw in $FRAMEWORK_SLOTS; do
  fw_dir="$(find_sister_dir "$CTO_SOURCE_ROOT" "$fw" "$DISCOVERY_BASE" || true)"   # use the script's actual source-root var
  if [[ -n "$fw_dir" ]]; then
    echo "  info: sister framework .ai.$fw: installed ($fw_dir)"
  else
    echo "  info: sister framework .ai.$fw: framework not installed here"
  fi
done
# Agent OS anchor (not a .ai.<fw> slot):
for ag in .ai pilo.ai.logicbison; do
  [[ -f "$DISCOVERY_BASE/$ag/skills/README.md" ]] && echo "  info: sister framework $ag: installed"
done
```
Also fix the dual-base inconsistency (`DEST_ROOT` vs `DISCOVERY_BASE` at `:115`): use one base for both checks. For the Agent OS anchor (`.ai` row), use the canonical helper from the shared lib — `source scripts/sister-discovery.sh; find_agent_os_dir "<source-root>" "<parent>"` (derives the family root `pilo.ai.logicbison` by slot-strip, falls back to `.ai`; empty output → ask the user for the path, never guess).

### 4. `deploy-basic.sh` — wire the six-slot fill (Layer 2)
In the substitution step (after `TRAINER_CTO_SOURCE` is baked), mirror `pilo.ai.logicbison/scripts/deploy-basic.sh` step 2: `source scripts/sister-discovery.sh`; loop `$FRAMEWORK_SLOTS`; `find_sister_dir "<source-root>" "$fw" "$(dirname "<source-root>")"`; fill `REPLACE:AI_<FW>_PATH (default \`../.ai.<fw>\`)` → `<abs> (discovered at deploy time)`; else print checked candidates. (The template already carries the cells, so this fill is effective immediately.)

### 5. Verify
```bash
source scripts/sister-discovery.sh
sister_names ui "$PWD"     # → .ai.ui ; family form once renamed
for s in biz cto flutter mlt soc ui; do test -d "../.ai.$s/skills/README.md" && echo "$s ok"; done
bash scripts/deploy-basic.sh /tmp/smoke-cto   # inspect /tmp/smoke-cto/.cursorrules: TRAINER_CTO_SOURCE + sister cells filled
bash scripts/verify-target.sh .               # sister loop reports the six
bash scripts/framework-verify.sh              # incl. .cursorrules ≡ template congruence
```

## Gaps found (include in a follow-up)

- The registry is 5 rows — `.ai.flutter`/`.ai.mlt` rows missing (fixed by step 2); family naming absent from resolution text.
- `verify-target.sh` sister loop: hardcoded 4 names, no family naming, dual-base inconsistency (`:115`).
- No `install-opencode-config.sh` and no `opencode.json` in this repo — opencode consumers are not part of this framework's flow; skip unless you want them.
- `.ai` row points at the old on-disk Agent OS snapshot; update to `../pilo.ai.logicbison` when the family rename lands.

## Checklist
- [ ] `scripts/sister-discovery.sh` copied
- [ ] Registry extended in `.cursorrules` + template (congruent)
- [ ] Resolution text family-aware in both
- [ ] `verify-target.sh` six-slot loop + single discovery base
- [ ] `deploy-basic.sh` six-slot fill
- [ ] Verify commands pass (incl. framework-verify congruence)
- [ ] Nothing committed/staged

## Next action
Run steps 1–2 + 5 inside `/mnt/work/Projects/.ai.cto`; steps 3–4 complete deploy parity.

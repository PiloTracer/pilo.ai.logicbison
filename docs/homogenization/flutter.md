# `.ai.flutter` (Flutter Agent OS) — upgrade directions for the deploy skills

**Status:** Ready · **Needs:** none · **Repo:** `/mnt/work/Projects/.ai.flutter` (clean git)

Goal: make the deploy skills produce targets whose `.cursorrules` discover all six sisters under both namings — same as the current framework. Note: flutter uses a **custom template set** (`cursorrules.flutter.template` + snippet) and a heavily customized `.cursorrules`; treat its files as bespoke.

## Current state (measured 2026-08-19)

- `scripts/deploy-basic.sh` (188 L): merges the snippet template (`cursorrules.flutter.snippet.template`) into the full template (`cursorrules.flutter.template`); tokens like `REPLACE:FLUTTER_SNIPPET_BLOCK`, `REPLACE:FLUTTER_FRAMEWORK_PATH`. Has a hardcoded collision note `${TARGET}/.ai` + `${TARGET}/.ai.ui` (`:177`).
- `scripts/deploy-files.sh` (205 L), `deploy-repo.sh` (186 L), `deploy-verify.sh` (264 L): **no sister logic**; deploy-verify does not check siblings.
- **Sister discovery exists only as prose** in `skills/SKILL_DEPENDENCIES.md:89-104` (resolution order: registry → auto-discovery → preflight) — **the registry artifact is never shipped** to `.cursorrules` or templates.
- `.cursorrules`: **no registry** (natural insertion point: before `## Core principles`, `:25`).
- Templates: **no registry in either** `cursorrules.flutter.template` or `cursorrules.flutter.snippet.template`.
- `scripts/framework-verify.sh` (251 L): structure/registration checks; no sister checks.

## Steps

### 1. Copy the discovery lib
```bash
cp /mnt/work/Projects/pilo.ai.logicbison/scripts/sister-discovery.sh scripts/sister-discovery.sh
```

### 2. `.cursorrules` — add the Frameworks registry (Layer 1, required)
Insert before `## Core principles` (line 25):

```markdown
### Frameworks registry (cross-framework discovery)

Sister frameworks are siblings on disk; `.ai.<fw>` (legacy) / `pilo.ai.<fw>.logicbison` (family) naming — see path resolution below. `.ai.flutter` is this framework (self-hosted).

| Framework | Director | Path | Bootstrap artifact |
|-----------|----------|------|--------------------|
| `.ai.flutter` (Flutter Agent OS) | `@flutter-director` | *this directory* | `skills/README.md` |
| `.ai` (Agent OS) | `@ai-director` | `../.ai` | `../.ai/skills/README.md` |
| `.ai.biz` (Business OS) | `@biz-director` | `../.ai.biz` | `../.ai.biz/skills/README.md` |
| `.ai.cto` (CTO Professor OS) | `@cto-director` | `../.ai.cto` | `../.ai.cto/skills/README.md` |
| `.ai.mlt` (MLT Agent OS) | `@mlt-director` | `../.ai.mlt` | `../.ai.mlt/skills/README.md` |
| `.ai.soc` (Social OS) | `@soc-director` | `../.ai.soc` | `../.ai.soc/skills/README.md` |
| `.ai.ui` (UI Design OS) | `@ui-director` | `../.ai.ui` | `../.ai.ui/skills/README.md` |

**Path resolution:** (1) use a filled path cell; empty → fall through. (2) Auto-discover: parent = `S/..` with S = this repo (self-hosted) or the thin-client source; sister = `<S basename with <fw> inserted before its last .segment>` (e.g. `pilo.ai.ui.logicbison` for a `pilo.ai.logicbison` source; `.ai`-prefixed sources resolve `.ai.<fw>` directly), else legacy `.ai.<fw>`; missing = "not installed". (3) Before routing, verify the framework dir + its `skills/README.md` exist; if absent, route with `[degraded: <framework> not installed]` — never route into the void. If your source dir name breaks discovery, fill the path cells manually.
```

### 3. Templates — add the registry to the full template (optional but recommended)
In `templates/cursorrules.flutter.template`, add the same 7-row registry (consumer-style cells: `REPLACE:AI_UI_PATH (default \`../.ai.ui\`)` etc., self-excluded) + resolution text. If you add it, also add the same block to `templates/cursorrules.flutter.snippet.template` so snippet-merged targets get it.

### 4. `deploy-basic.sh` — wire the six-slot fill (Layer 2, only if step 3 done)
Mirror `pilo.ai.logicbison/scripts/deploy-basic.sh` step 2 inside the merge/substitution step: `source scripts/sister-discovery.sh`; loop `$FRAMEWORK_SLOTS`; `find_sister_dir "<source-root>" "$fw" "$(dirname "<source-root>")"`; fill the `REPLACE:AI_<FW>_PATH` cells → `<abs> (discovered at deploy time)`; else print checked candidates. Also replace the hardcoded `.ai`/`.ai.ui` collision note (`:177`) with a generic "a local `.ai*` framework dir exists — fat-client leak" warning (six names, not two).

### 5. Verify
```bash
source scripts/sister-discovery.sh
sister_names ui "$PWD"     # → .ai.ui
for s in biz cto flutter mlt soc ui; do test -d "../.ai.$s/skills/README.md" && echo "$s ok"; done
bash scripts/deploy-basic.sh /tmp/smoke-flutter   # inspect /tmp/smoke-flutter/.cursorrules
bash scripts/framework-verify.sh
```

## Gaps found (include in a follow-up)

- The registry is **prose-only** (`SKILL_DEPENDENCIES.md:89-104`) — the artifact is never shipped; targets cannot discover sisters (fixed by steps 2–3).
- `SKILL_DEPENDENCIES.md`'s registry table is fixed to `.ai` + `.ai.ui` only (`:89-104`) — extend the table to the six (or reference the `.cursorrules` registry as authoritative).
- Deploy modes are inconsistent (basic merges snippets; files/repo do not) — sister discovery should be added in all three or documented as basic-only.
- Hardcoded collision note `${TARGET}/.ai` + `${TARGET}/.ai.ui` (`:177`).
- No env-var path resolution for thin clients in `SKILL_DEPENDENCIES.md` (prose says "if set, use it" without naming the var).
- `.ai` row points at the old on-disk Agent OS snapshot; update when the family rename lands.

## Checklist
- [ ] `scripts/sister-discovery.sh` copied
- [ ] `.cursorrules` registry + resolution (Layer 1)
- [ ] Template registry (step 3) if deploy fill planned
- [ ] `deploy-basic.sh` six-slot fill + generic collision note (step 4, optional)
- [ ] Verify commands pass
- [ ] Nothing committed/staged

## Next action
Run steps 1–2 + 5 inside `/mnt/work/Projects/.ai.flutter`; steps 3–4 complete deploy parity.

# Feedback → Agent OS (`.ai`)

**From:** pilo-mail cohabitation audit, 2026-10-15
**Audit reference:** `20261015-cohabitation-audit.md` (findings F-06, F-07, F-08, F-11, F-13, F-14)
**Status of this document:** recommendations only — **no framework source was modified**

> **One-line summary:** the `Frameworks registry` is the **authoritative** cross-framework discovery source
> for `x-director`, but (a) its heading is a hard string that both consumer repositories rename, and (b) the
> verifier's path parser **cannot read the registry's own canonical cell format**. Both failures report as
> `note`/`info` on an otherwise green run.

---

## 1. F-07a — the registry heading is a hard string dependency, and deployers rename it

**Evidence**

| Fact | Location |
|------|----------|
| Canonical heading | `templates/cursorrules.template:52` → `### Frameworks registry (cross-framework discovery)` |
| `x-director` calls it **authoritative**, step 1 of path resolution | `skills/x-director/skill.md:20` — *"`.cursorrules` § *Frameworks registry* (the file shipped to every adopter repo)"* |
| Six frameworks grep the literal string | `pilo.ai.biz` (`sister-discovery.sh`, `framework-verify.sh`), `pilo.ai.cto` (`sister-discovery.sh`, `verify-target.sh`, `deploy-basic.sh`), `pilo.ai.flutter` (`deploy-files.sh`, `deploy-verify.sh`, `sister-discovery.sh`, `deploy-basic.sh`), `pilo.ai.logicbison` (`sister-discovery.sh:21`), UI (`cursorrules-verify.sh:166`) |
| What the consumers actually have | `pilo-mail/.cursorrules:42` → `## Source pointers (thin-client — MANDATORY)`; **`system-erp/.cursorrules:42` → identical rename** |
| Does `deploy-basic.sh` perform the rename? | **No** — `grep 'Source pointers'` over `deploy-basic.sh` and `skills/deploy-basic/skill.md` returns nothing |
| Detection strength | UI verifier: `note`. Agent OS verifier: `[ok] Source-resolution section: present` |

The rename occurs in **both** adopter repositories, is performed by **neither** deploy skill, and **nothing
warns**. `x-director` silently drops from "authoritative registry" to heuristic auto-discovery.

**Recommended change (pick one, ideally both)**

1. **Repair, don't hope.** Have `deploy-basic` (and `cursorrules-verify.sh --fix`) detect a renamed or
   missing registry heading and either restore it or *annotate the replacement* so the string is present.
2. **Stop depending on prose.** Parse the registry **structurally** — e.g. a fenced, machine-readable block
   that no deployer would paraphrase:

   ```yaml
   # frameworks-registry
   agent-os:   { path: /mnt/work/Projects/pilo.ai.logicbison,   director: ai-director,   memory: .work }
   ui:         { path: /mnt/work/Projects/pilo.ai.ui.logicbison, director: ui-director,   memory: .work.ui }
   soc:        { path: /mnt/work/Projects/pilo.ai.soc.logicbison,director: soc-director,  memory: .work.soc }
   ```

3. If the heading must stay prose, **escalate** its absence from `note` to `warn` in every verifier that
   depends on it, and say what degrades.

**Acceptance:** renaming the heading in a test `.cursorrules` produces a `warn`/`FAIL`, or discovery still
works because the parser no longer needs the heading.

---

## 2. F-07b — `baked_sister_paths()` cannot parse the registry's own canonical cell format

This is the sharper defect and it is independent of the rename.

**Evidence** — `scripts/cursorrules-verify.sh:93-100`:

```bash
93: baked_sister_paths() {
94:   local fw="$1" names_re
97:   names_re="$(sister_names "$fw" "$AI_ROOT" | sed 's/[.[\*^$()+?{|]/\\&/g' | paste -sd'|' -)"
98:   grep -oE '/[^ |]+/[^ |]+' "$CURS_DEST" 2>/dev/null \
99:     | grep -E "/(${names_re})$" | sort -u || true
100: }
```

The extracted token class `[^ |]+` **does not exclude backticks**, but the second match anchors on
`/<basename>$`. A path written in normal Markdown style — `` `/mnt/.../pilo.ai.soc.logicbison` `` — produces
a token ending in a backtick and therefore **fails the anchor**.

**Measured consequence** (pilo-mail `.cursorrules`):

| Framework | Cell in `.cursorrules` | Bare (un-backticked) path elsewhere? | `baked_sister_paths` |
|-----------|------------------------|--------------------------------------|----------------------|
| `.ai.soc` | `` `SOC_SOURCE=/mnt/.../pilo.ai.soc.logicbison` `` | yes — `:222` prose | **match** → `[ok]` |
| `.ai.ui` | `` `/mnt/.../pilo.ai.ui.logicbison` `` | yes — `:194` prose | **match** → `[ok]` |
| `.ai.biz` | `` `/mnt/.../pilo.ai.biz.logicbison` `` | **no** | **no match** → `[info] custom cell value (non-standard)` |
| `.ai.cto/.flutter/.mlt` | **no row at all** | no | **no match** → `[info] custom cell value` |

Two distinct problems visible in that table:

- **A correctly-filled, backticked registry cell is reported as "non-standard".** The detection only
  succeeded for ui/soc by accident, because their own included blocks happen to contain an *unquoted*
  `VAR=/abs/path` line.
- **`cursorrules-verify.sh:236-238` conflates two different states.** It prints
  `custom cell value (non-standard — verify manually)` whenever `baked` is empty — including when the
  framework has **no registry row at all** (cto/flutter/mlt here). "No cell declared" and "cell format not
  recognised" are different outcomes and should not share a message.

**Verified against the canonical source:** running the same parser over
`templates/cursorrules.template` itself yields **0 matches for both `ui` and `soc`** — because the template
stores cells as `REPLACE:AI_UI_PATH (default \`../.ai.ui\`)`. The registry's canonical format therefore
**cannot satisfy its own verifier**.

**Recommended change**

1. Strip Markdown decoration before matching — e.g. add `` ` `` and `*` to the exclusion class, or run
   `tr -d '\`*' ` over the extracted tokens:

   ```bash
   grep -oE '/[^ |`*]+/[^ |`*]+' "$CURS_DEST" | grep -E "/(${names_re})$" | sort -u
   ```

2. Even better, parse the registry rows by **column position** (`| Framework | Director | Path | …`) rather
   than grepping the file for path-shaped strings. Columnar parsing also respects "a `REPLACE:*` or empty
   cell means auto-discover", which the current grep cannot express.
3. Separate the messages: `not declared in registry` vs `cell present but unrecognised format`.

**Acceptance:** a fixture `.cursorrules` using the canonical registry table with **backticked absolute
paths** reports every framework as baked; a fixture with no cell reports `not declared`, not
`custom cell value`.

---

## 3. F-06 — a declared-but-undeployed framework is only an `info`

`.cursorrules:48` declares Business OS (`.work.biz/`); the directory **does not exist** and biz is not one of
the three frameworks this deployment actually uses.

Verifier response: `[info] .ai.biz: custom cell value (non-standard — verify manually)` — and UI's verifier
adds `warn: .ai.biz: configured path '@biz-director' does not resolve`.

`system-erp` **does** have `.work.biz/`, so the state is not inherently invalid; it is simply
under-reported. The risk is real: `@biz-director` resolves a source framework that exists on disk but has no
local memory directory — an undefined state for any skill that writes to `.work.biz/`.

**Recommended change:** when a framework is declared in the registry but `<memory-dir>/` is missing, emit a
**warning** naming both facts, and state the consequence (routing will resolve a source with nowhere to
persist project memory). Offer the two valid resolutions: create the skeleton, or remove the row.

---

## 4. F-08 — Agent OS ships no `COHABITATION.md`

| Framework | `COHABITATION.md` |
|-----------|-------------------|
| `.ai.ui` | present |
| `.ai` | **missing** |
| `.ai.soc` | **missing** |
| `.ai.biz` | **missing** |

The cohabitation contract is single-authored by a *sister* framework. There is no Agent OS statement of the
boundary it expects — which is odd, because Agent OS owns the shared artifacts (`Core Principles 1–9`,
`.work/plans/NEXT.md`, `.work/context/HANDOFF.md`, `.work/touch-scope`) that the sisters are told not to
clobber. The UI snippet references UI's own file (`snippet:6`), so the *rule* exists but is discoverable only
by reading UI's docs.

**Recommended change:** publish `.ai/COHABITATION.md` defining, at minimum:

- which artifacts `.ai` owns exclusively (`Core Principles`, `.work/plans/NEXT.md`, `.work/context/HANDOFF.md`,
  `.work/touch-scope`, `.work/PROTECTED_SURFACES.json`);
- what sisters may write (`<fw>/.work.<fw>/**`) and the permitted cross-link mechanism;
- the conflict rule when two frameworks both claim a file;
- the "unknown framework" rule when a request fits none.

Then make it a **required deployment artifact list** (see R8 in the audit) so every framework ships one.

---

## 5. F-14 — there is no single cross-framework coherence gate

Three verifiers each validate one slice and each tolerate the others' absence. That is exactly how a
repository can be missing the entire UI contract while three commands print PASS.

**Recommended change:** add a top-level command, e.g. `scripts/coherence-verify.sh <target>`, which:

1. reads the registry (structurally — see §2);
2. for each **declared and installed** framework, runs that framework's verifier if present;
3. aggregates into one exit code, distinguishing `declared+installed` (must pass), `declared+missing`
   (warn), and `installed+undeclared` (info);
4. prints a one-line summary plus a per-framework table.

**Acceptance:** the command exits non-zero on the current pilo-mail state (declared biz without
`.work.biz/`, and an unmarked UI block) — i.e. it would have caught this audit's findings.

---

## 6. F-13 — discovery reports what is on disk, not what is wired

`sister-discovery.sh:37` fixes the slot list (`FRAMEWORK_SLOTS="ui biz soc cto flutter mlt"`). SOC's verify
consequently lists **six** sisters as "installed" on this host while `.cursorrules` wires three. Accurate,
but it invites the reader to conclude more frameworks are active than are configured.

**Recommended change:** distinguish `installed` from `declared` in the output, e.g.
`info: sister framework .ai.cto: installed (not declared in registry)`.

---

## 7. F-11 — token hygiene

Documenting `REPLACE_BASICUI_SOURCE` by writing it in prose makes it indistinguishable from an unfilled
token to any `grep REPLACE_` validator, including `cursorrules-ui.sh:30-36` and
`cursorrules-verify.sh:272`.

**Recommended change:** in templates and generated text, render such references so they are not greppable —
inside a fenced block, or split (`` `REPLACE_` + `BASICUI_SOURCE` ``) — and note the convention in the
template authoring guide.

---

## 8. Suggested order of work

| Order | Change | Fixes | Effort |
|-------|--------|-------|--------|
| 1 | Fix `baked_sister_paths` to tolerate backticks (or parse columns) | F-07b | S |
| 2 | Separate `not declared` from `unrecognised cell format` | F-07b | S |
| 3 | Escalate a declared-but-missing `<memory-dir>` to `warn` | F-06 | S |
| 4 | Escalate/repair the registry heading dependency, or move the registry to a structured block | F-07a | M |
| 5 | Add `scripts/coherence-verify.sh` aggregating all framework verifiers | F-14 | M |
| 6 | Publish `.ai/COHABITATION.md`; require one per framework | F-08 | M |
| 7 | Token-hygiene convention | F-11 | S |

Items **1–3 are small and remove three silent failures**; they are the highest value per line changed.

---

## 9. What is working (do not regress)

- `deploy-basic` produced a correct, clean Agent OS body: **0 `REPLACE:` tokens** in the Agent OS region of
  a 295-line `.cursorrules`.
- `AGENT_OS_SOURCE` baked correctly and `[ok] script paths: no unbaked .ai/scripts/ literals` — the
  thin-client script-path rewriting works.
- `reconcile`-style safeguards already present: `create-full` refuses to overwrite an existing
  `.cursorrules` (`cursorrules-ui.sh:64` pattern) — the same guard should be extended to `force` paths
  (see the UI document, F-09).
- The `.work/` skeleton and the shared `SKILL_DEPENDENCIES.md` operator-handoff contract are coherent and
  are being honoured by all three frameworks.

---

## Next action

Apply items 1–3 in the Agent OS source, then re-run
`cursorrules-verify.sh <target>` against pilo-mail and confirm the four `[info] custom cell value` lines are
gone or correctly reclassified.

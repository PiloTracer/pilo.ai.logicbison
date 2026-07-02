#!/usr/bin/env python3
"""Functional skill verification for Agent OS (post-trim integrity)."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKILLS = ROOT / "skills"
SOFT = 24576
HARD = 42000
TRIMMED = {
    "session-control", "plan-foundation", "code-implementation",
    "plan-master", "plan-repair", "plan-verify",
}
REQUIRED_IN_REFERENCE = {
    "session-control": ["Commit protocol (detailed)", "Close protocol (detailed)", "Start protocol (detailed)"],
    "plan-foundation": ["Phase gates P0", "GATE: p0", "Phase 6"],
    "code-implementation": ["Continue protocol (detailed)", "Complete protocol (detailed)", "Task gate (detailed)"],
    "plan-master": ["Planning workflow phases"],
    "plan-repair": ["Repair protocol R0", "Brownfield repair protocol"],
    "plan-verify": ["Foundation verify protocol", "Brownfield detection"],
}

def github_slug(text: str) -> str:
    text = text.strip().lower()
    for ch in ('–', '—', '−'):
        text = text.replace(ch, '-')
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[\s_]+', '-', text)
    return re.sub(r'-+', '-', text).strip('-')

def ref_slugs(path: Path) -> set[str]:
    slugs = set()
    for line in path.read_text(encoding='utf-8').splitlines():
        m = re.match(r'^#{1,6}\s+(.+)$', line)
        if m:
            slugs.add(github_slug(m.group(1).strip()))
    return slugs

fail = 0
skill_dirs = sorted(d for d in SKILLS.iterdir() if d.is_dir() and not d.name.startswith('.'))

print("=== All skills structural check ===")
for d in skill_dirs:
    name = d.name
    sm = d / "skill.md"
    if not sm.exists():
        print(f"FAIL missing skill.md: {name}")
        fail += 1
        continue
    text = sm.read_text(encoding='utf-8')
    if not re.search(rf'^name: {re.escape(name)}\s*$', text, re.M):
        print(f"FAIL frontmatter name mismatch: {name}")
        fail += 1
    nbytes = sm.stat().st_size
    if nbytes > HARD:
        print(f"FAIL over hard budget: {name} ({nbytes}B)")
        fail += 1
    elif nbytes > SOFT:
        print(f"DEBT over soft budget: {name} ({nbytes}B)")

print(f"\n=== Trimmed skills ({len(TRIMMED)}) ===")
for name in sorted(TRIMMED):
    sm = SKILLS / name / "skill.md"
    rm = SKILLS / name / "reference.md"
    if not rm.exists():
        print(f"FAIL missing reference.md: {name}")
        fail += 1
        continue
    ref_text = rm.read_text(encoding='utf-8')
    for needle in REQUIRED_IN_REFERENCE[name]:
        if needle not in ref_text:
            print(f"FAIL {name} reference missing: {needle}")
            fail += 1
    slugs = ref_slugs(rm)
    sm_text = sm.read_text(encoding='utf-8')
    for anchor in set(re.findall(r'reference\.md#([a-zA-Z0-9_-]+)', sm_text)):
        if anchor not in slugs:
            print(f"FAIL broken link {name}: #{anchor}")
            fail += 1
    print(f"OK {name}: skill={sm.stat().st_size}B ref={rm.stat().st_size}B")

print()
if fail:
    print(f"skill-functional-verify: FAIL ({fail} issues)")
    sys.exit(1)
print("skill-functional-verify: PASS")

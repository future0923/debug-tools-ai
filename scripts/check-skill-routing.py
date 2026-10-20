#!/usr/bin/env python3
"""Check each public adapter's skill routing and installed skill self-containment."""
from pathlib import Path
import re

SKILLS = ('debug-tools',)
ENTRIES = ('README.md', 'README-zh.md', 'CLAUDE.md', 'GEMINI.md',
           '.opencode/INSTALL.md', '.opencode/plugins/debug-tools-ai.js',
           '.pi/extensions/debug-tools-ai/index.js')


def check(root):
    errors = []
    discovered = {path.parent.name for path in (root / 'skills').glob('*/SKILL.md')}
    if discovered != set(SKILLS):
        errors.append(f'Expected one workflow skill, found {sorted(discovered)}')
    for entry in ENTRIES:
        source = (root / entry).read_text()
        for skill in SKILLS:
            if not re.search(r'(?<![\w-])' + re.escape(skill) + r'(?![\w-])', source):
                errors.append(f'{entry}: missing {skill}')
    for skill in SKILLS:
        directory = root / 'skills' / skill
        entrypoint = directory / 'SKILL.md'
        source = entrypoint.read_text()
        if not re.search(r'^name: ' + re.escape(skill) + r'$', source, re.M):
            errors.append(f'{entrypoint}: mismatched skill name')
        # Follow only local Markdown links. Installed skills must not depend on repo docs.
        for document in directory.rglob('*.md'):
            for link in re.findall(r'\]\(([^\s)]+)\)', document.read_text()):
                if link.startswith(('#', 'https://', 'http://')):
                    continue
                target = (document.parent / link.split('#')[0]).resolve()
                if directory.resolve() not in (target, *target.parents) or not target.is_file():
                    errors.append(f'{document.relative_to(root)}: missing or non-self-contained reference {link}')
        metadata = directory / 'agents/openai.yaml'
        if not metadata.is_file() or f'${skill}' not in metadata.read_text():
            errors.append(f'{skill}: missing invocation metadata')
    return errors


if __name__ == '__main__':
    failures = check(Path(__file__).resolve().parent.parent)
    if failures:
        raise SystemExit('\n'.join(failures))
    print('Every adapter routes the single workflow skill; local skill links are self-contained')

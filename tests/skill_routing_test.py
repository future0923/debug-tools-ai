import importlib.util
from pathlib import Path
import shutil
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('skill_routing', ROOT / 'scripts/check-skill-routing.py')
routing = importlib.util.module_from_spec(spec)
spec.loader.exec_module(routing)


class SkillRoutingTest(unittest.TestCase):
    def test_one_missing_adapter_route_cannot_hide_behind_other_adapters(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            shutil.copytree(ROOT / 'skills', root / 'skills')
            for entry in routing.ENTRIES:
                destination = root / entry
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / entry, destination)
            self.assertEqual([], routing.check(root))
            gemini = root / 'GEMINI.md'
            gemini.write_text(gemini.read_text().replace('debug-tools', 'unavailable-skill'))
            failures = routing.check(root)
            self.assertTrue(any('GEMINI.md: missing debug-tools' in failure for failure in failures))
            self.assertFalse(any('CLAUDE.md' in failure for failure in failures))

    def test_second_discoverable_skill_is_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            shutil.copytree(ROOT / 'skills', root / 'skills')
            for entry in routing.ENTRIES:
                destination = root / entry
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / entry, destination)
            legacy = root / 'skills/debug-tools-hotswap'
            legacy.mkdir()
            (legacy / 'SKILL.md').write_text('---\nname: debug-tools-hotswap\n---\n')
            self.assertTrue(any('Expected one workflow skill' in failure for failure in routing.check(root)))

    def test_repository_reference_inside_installed_skill_is_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            shutil.copytree(ROOT / 'skills', root / 'skills')
            for entry in routing.ENTRIES:
                destination = root / entry
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / entry, destination)
            skill = root / 'skills/debug-tools/SKILL.md'
            skill.write_text(skill.read_text() + '\n[external dependency](../../docs/manual.md)\n')
            self.assertTrue(any('non-self-contained' in failure for failure in routing.check(root)))


if __name__ == '__main__':
    unittest.main()

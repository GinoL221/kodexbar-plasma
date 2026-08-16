"""Contract for scripts/run-qml-tests.sh harness auto-discovery."""

from __future__ import annotations

import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RUNNER = ROOT / "scripts/run-qml-tests.sh"
TESTS = ROOT / "tests"

SPECIAL = {
    "UsageControllerDataSourceLifecycleHarness",
    "CostControllerDataSourceLifecycleHarness",
    "UsageControllerTerminationHarness",
    "CostControllerTerminationHarness",
}


class RunQmlTestsDiscoveryTest(unittest.TestCase):
    def test_runner_lists_only_special_harnesses_by_name(self):
        text = RUNNER.read_text(encoding="utf-8")
        # Plain harnesses must not be hard-coded as a fixed shell list.
        hardcoded = set(re.findall(r"^\s+([A-Za-z0-9]+Harness)\\s*\\\\?$", text, re.M))
        self.assertEqual(hardcoded, set())

        for name in SPECIAL:
            self.assertIn(name, text)

    def test_repo_harness_set_matches_discoverable_plus_special(self):
        on_disk = sorted(path.stem for path in TESTS.glob("*Harness.qml"))
        plain = [name for name in on_disk if name not in SPECIAL]
        self.assertGreaterEqual(len(plain), 15)
        for name in SPECIAL:
            self.assertIn(name, on_disk)
        # Discovery is basename glob order; ensure every plain harness exists.
        self.assertEqual(plain, sorted(plain))


if __name__ == "__main__":
    unittest.main()

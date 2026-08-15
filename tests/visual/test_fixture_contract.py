import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from fixture_contract import validate_manifest


class FixtureContractTest(unittest.TestCase):
    def write_manifest(self, payload):
        directory = tempfile.TemporaryDirectory()
        path = Path(directory.name) / "scenarios.json"
        path.write_text(json.dumps(payload), encoding="utf-8")
        self.addCleanup(directory.cleanup)
        return path

    def canonical_manifest(self):
        return {
            "fixture": {"width": 450, "height": 400, "font": "Noto Sans"},
            "baselines": [
                "breeze-light-cost-present.png",
                "breeze-light-cost-absent.png",
                "breeze-dark-cost-present.png",
                "breeze-dark-cost-absent.png",
            ],
            "scenarios": [
                {"name": "breeze-light-cost-present", "theme": "light", "cost": True},
                {"name": "breeze-light-cost-absent", "theme": "light", "cost": False},
                {"name": "breeze-dark-cost-present", "theme": "dark", "cost": True},
                {"name": "breeze-dark-cost-absent", "theme": "dark", "cost": False},
            ],
        }

    def test_accepts_exactly_the_canonical_matrix(self):
        manifest = validate_manifest(self.write_manifest(self.canonical_manifest()))

        self.assertEqual(manifest["fixture"], {"width": 450, "height": 400, "font": "Noto Sans"})
        self.assertEqual(
            [scenario["name"] for scenario in manifest["scenarios"]],
            [
                "breeze-light-cost-present",
                "breeze-light-cost-absent",
                "breeze-dark-cost-present",
                "breeze-dark-cost-absent",
            ],
        )

    def test_rejects_extra_or_missing_baseline_names(self):
        missing = self.canonical_manifest()
        missing["baselines"].pop()
        with self.assertRaisesRegex(ValueError, "baseline"):
            validate_manifest(self.write_manifest(missing))

        extra = self.canonical_manifest()
        extra["baselines"].append("unexpected.png")
        with self.assertRaisesRegex(ValueError, "baseline"):
            validate_manifest(self.write_manifest(extra))

    def test_rejects_fixture_drift(self):
        payload = self.canonical_manifest()
        payload["fixture"]["width"] = 451

        with self.assertRaisesRegex(ValueError, "450x400"):
            validate_manifest(self.write_manifest(payload))

    def test_rejects_unknown_and_duplicate_scenarios(self):
        payload = self.canonical_manifest()
        payload["scenarios"][3]["name"] = "breeze-dark-cost-present"

        with self.assertRaisesRegex(ValueError, "canonical"):
            validate_manifest(self.write_manifest(payload))

    def test_rejects_missing_canonical_scenario(self):
        payload = self.canonical_manifest()
        payload["scenarios"].pop()

        with self.assertRaisesRegex(ValueError, "canonical"):
            validate_manifest(self.write_manifest(payload))


if __name__ == "__main__":
    unittest.main()

import os
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RUNNER = ROOT / "scripts/run-visual-tests.sh"


class VisualRunnerTest(unittest.TestCase):
    def test_missing_qml6_stops_before_capture_with_guidance(self):
        artifacts = ROOT / "tests/visual/artifacts"
        before = sorted(artifacts.glob("*.png")) if artifacts.exists() else []
        with tempfile.TemporaryDirectory() as directory:
            environment = os.environ | {"PATH": directory}
            result = subprocess.run(
                ["/bin/sh", str(RUNNER)],
                cwd=ROOT,
                env=environment,
                text=True,
                capture_output=True,
            )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("qml6", result.stdout + result.stderr)
        after = sorted(artifacts.glob("*.png")) if artifacts.exists() else []
        self.assertEqual(after, before)


if __name__ == "__main__":
    unittest.main()

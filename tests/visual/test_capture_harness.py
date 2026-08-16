import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

from breeze_palette import palette_for_theme


ROOT = Path(__file__).resolve().parents[2]
HARNESS = ROOT / "tests/visual/VisualCaptureHarness.qml"
QML6 = shutil.which("qml6")


@unittest.skipUnless(QML6, "qml6 is required for VisualCaptureHarness tests")
class CaptureFailureTest(unittest.TestCase):
    def run_harness(self, failure_flag):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "actual.png"
            palette_json = json.dumps(palette_for_theme("light"), separators=(",", ":"))
            home = Path(directory) / "home"
            home.mkdir()
            environment = os.environ | {
                "HOME": str(home),
                "XDG_CONFIG_HOME": str(home / "config"),
                "XDG_CACHE_HOME": str(home / "cache"),
                "XDG_DATA_HOME": str(home / "data"),
                "QT_QPA_PLATFORM": "offscreen",
                "QT_QUICK_BACKEND": "software",
                "QSG_RENDER_LOOP": "basic",
                "QT_SCALE_FACTOR": "1",
                "QT_FONT_DPI": "96",
                "LC_ALL": "C.UTF-8",
                "TZ": "UTC",
                "UPDATE_GOLDENS": "1",
            }
            result = subprocess.run(
                [
                    QML6,
                    "--software",
                    "-f",
                    str(HARNESS),
                    "--",
                    "--scenario",
                    "breeze-light-cost-present",
                    "--output",
                    str(output),
                    "--palette-json",
                    palette_json,
                    "--capture-timeout-ms",
                    "20",
                    failure_flag,
                ],
                cwd=ROOT,
                env=environment,
                text=True,
                capture_output=True,
                timeout=10,
            )
            return result, output

    def assert_capture_failure(self, flag):
        result, output = self.run_harness(flag)

        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(output.exists(), "failed capture must not save an artifact")

    def test_false_grab_request_stops_before_save(self):
        self.assert_capture_failure("--simulate-grab-false")

    def test_absent_callback_times_out_before_save(self):
        self.assert_capture_failure("--simulate-absent-callback")

    def test_failed_save_stops_before_artifact_exists(self):
        self.assert_capture_failure("--simulate-save-failure")

    def test_wrong_size_stops_before_save(self):
        self.assert_capture_failure("--simulate-wrong-size")

    def test_missing_palette_json_fails_before_capture(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "actual.png"
            home = Path(directory) / "home"
            home.mkdir()
            environment = os.environ | {
                "HOME": str(home),
                "XDG_CONFIG_HOME": str(home / "config"),
                "QT_QPA_PLATFORM": "offscreen",
                "QT_QUICK_BACKEND": "software",
                "QSG_RENDER_LOOP": "basic",
            }
            result = subprocess.run(
                [
                    QML6,
                    "--software",
                    "-f",
                    str(HARNESS),
                    "--",
                    "--scenario",
                    "breeze-dark-cost-present",
                    "--output",
                    str(output),
                ],
                cwd=ROOT,
                env=environment,
                text=True,
                capture_output=True,
                timeout=10,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(output.exists(), "missing palette must not produce a capture artifact")


if __name__ == "__main__":
    unittest.main()

import os
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image


sys.path.insert(0, str(Path(__file__).parent))

from compare_visual import (  # noqa: E402
    MAX_CHANNEL_DELTA,
    MAX_MISMATCH_RATIO,
    VisualComparisonError,
    compare_images,
    update_golden,
)


class CompareVisualTest(unittest.TestCase):
    def image(self, path, size=(10, 10), color=(10, 20, 30, 255)):
        image = Image.new("RGBA", size, color)
        image.save(path)
        return image

    def compare(self, expected, actual, diff):
        return compare_images(
            expected,
            actual,
            diff,
            scenario="breeze-light-cost-present",
            theme="light",
        )

    def test_equal_rgba_images_pass(self):
        with tempfile.TemporaryDirectory() as directory:
            expected = Path(directory) / "expected.png"
            actual = Path(directory) / "actual.png"
            self.image(expected)
            self.image(actual)

            result = self.compare(expected, actual, Path(directory) / "diff.png")

            self.assertEqual(result["mismatched_pixels"], 0)
            self.assertEqual(result["ratio"], 0.0)

    def test_channel_delta_at_threshold_passes(self):
        with tempfile.TemporaryDirectory() as directory:
            expected = Path(directory) / "expected.png"
            actual = Path(directory) / "actual.png"
            self.image(expected)
            image = self.image(actual)
            image.putpixel((0, 0), (10 + MAX_CHANNEL_DELTA, 20, 30, 255))
            image.save(actual)

            result = self.compare(expected, actual, Path(directory) / "diff.png")

            self.assertEqual(result["mismatched_pixels"], 0)

    def test_seeded_pixel_drift_above_ratio_fails_and_writes_diff(self):
        with tempfile.TemporaryDirectory() as directory:
            expected = Path(directory) / "expected.png"
            actual = Path(directory) / "actual.png"
            diff = Path(directory) / "diff.png"
            self.image(expected)
            image = self.image(actual)
            image.putpixel((0, 0), (255, 20, 30, 255))
            image.save(actual)

            with self.assertRaisesRegex(VisualComparisonError, "mismatched=1/100"):
                self.compare(expected, actual, diff)

            self.assertTrue(diff.is_file())

    def test_ratio_at_limit_passes_despite_one_changed_pixel(self):
        with tempfile.TemporaryDirectory() as directory:
            expected = Path(directory) / "expected.png"
            actual = Path(directory) / "actual.png"
            self.image(expected, size=(100, 10))
            image = self.image(actual, size=(100, 10))
            image.putpixel((0, 0), (255, 20, 30, 255))
            image.save(actual)

            result = self.compare(expected, actual, Path(directory) / "diff.png")

            self.assertEqual(result["ratio"], MAX_MISMATCH_RATIO)

    def test_seeded_color_drift_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            expected = Path(directory) / "expected.png"
            actual = Path(directory) / "actual.png"
            self.image(expected)
            self.image(actual, color=(200, 100, 50, 255))

            with self.assertRaisesRegex(VisualComparisonError, "maximum_delta"):
                self.compare(expected, actual, Path(directory) / "diff.png")

    def test_seeded_geometry_drift_fails_distinctly(self):
        with tempfile.TemporaryDirectory() as directory:
            expected = Path(directory) / "expected.png"
            actual = Path(directory) / "actual.png"
            self.image(expected, size=(10, 10))
            self.image(actual, size=(11, 10))

            with self.assertRaisesRegex(VisualComparisonError, "dimensions"):
                self.compare(expected, actual, Path(directory) / "diff.png")

    def test_malformed_baseline_fails_distinctly(self):
        with tempfile.TemporaryDirectory() as directory:
            expected = Path(directory) / "expected.png"
            actual = Path(directory) / "actual.png"
            expected.write_text("not a PNG", encoding="utf-8")
            self.image(actual)

            with self.assertRaisesRegex(VisualComparisonError, "undecodable baseline"):
                self.compare(expected, actual, Path(directory) / "diff.png")

    def test_missing_baseline_without_update_does_not_mutate(self):
        with tempfile.TemporaryDirectory() as directory:
            golden = Path(directory) / "missing.png"
            actual = Path(directory) / "actual.png"
            self.image(actual)

            with self.assertRaisesRegex(VisualComparisonError, "missing baseline"):
                self.compare(golden, actual, Path(directory) / "diff.png")

            self.assertFalse(golden.exists())

    def test_update_requires_exact_flag_and_canonical_scenario(self):
        with tempfile.TemporaryDirectory() as directory:
            golden = Path(directory) / "breeze-light-cost-present.png"
            actual = Path(directory) / "actual.png"
            self.image(actual, size=(450, 400), color=(1, 2, 3, 255))

            with self.assertRaisesRegex(VisualComparisonError, "UPDATE_GOLDENS=1"):
                update_golden(actual, golden, "breeze-light-cost-present", False)
            with self.assertRaisesRegex(VisualComparisonError, "canonical"):
                update_golden(actual, golden, "unknown", True)

            update_golden(actual, golden, "breeze-light-cost-present", True)
            self.assertEqual(Image.open(golden).convert("RGBA").getpixel((0, 0)), (1, 2, 3, 255))


if __name__ == "__main__":
    unittest.main()

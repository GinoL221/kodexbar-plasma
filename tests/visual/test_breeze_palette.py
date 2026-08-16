import tempfile
import unittest
from pathlib import Path

from breeze_palette import (
    SCHEME_PATHS,
    is_dark_palette,
    palette_for_theme,
    parse_breeze_colors,
)


class BreezePaletteTest(unittest.TestCase):
    def test_light_and_dark_palettes_are_distinct_and_classified(self):
        light = palette_for_theme("light")
        dark = palette_for_theme("dark")

        self.assertEqual(light["backgroundColor"], "eff0f1")
        self.assertEqual(light["textColor"], "232629")
        self.assertEqual(dark["backgroundColor"], "202326")
        self.assertEqual(dark["textColor"], "fcfcfc")
        self.assertFalse(is_dark_palette(light))
        self.assertTrue(is_dark_palette(dark))
        self.assertNotEqual(light["backgroundColor"], dark["backgroundColor"])

    def test_missing_scheme_section_fails_closed(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "broken.colors"
            path.write_text("[Colors:Window]\nBackgroundNormal=1,2,3\n", encoding="utf-8")
            with self.assertRaises(ValueError):
                parse_breeze_colors(path)

    def test_scheme_paths_exist_on_host(self):
        for path in SCHEME_PATHS.values():
            self.assertTrue(path.is_file(), "missing %s" % path)


if __name__ == "__main__":
    unittest.main()

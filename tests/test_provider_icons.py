"""RED-first contract for scripts/check-provider-icons.py.

Slice 1 covers invariants 1 (coverage), 2 (no orphans), 3 (parseable XML),
and 5 (distinctness with the SANCTIONED_DUPLICATES allowlist). Slice 3 adds
invariant 4 (no theme-defeating literal fill/stroke color), per design.md's
"invariants are enabled in the slice where they become satisfiable."
"""

import importlib.util
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "scripts" / "check-provider-icons.py"
REPO_ROOT = Path(__file__).parents[1]

VALID_SVG = (
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
    '<path d="M0 0"/></svg>\n'
)


def load_checker():
    spec = importlib.util.spec_from_file_location("check_provider_icons", SCRIPT)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def write_fixture_tree(root, providers, svg_files):
    js_dir = root / "contents/code"
    js_dir.mkdir(parents=True, exist_ok=True)
    array = ",\n    ".join('"%s"' % name for name in providers)
    (js_dir / "ProviderIcons.js").write_text(
        ".pragma library\n\nvar knownProviders = [\n    %s\n]\n" % array,
        encoding="utf-8",
    )
    svg_dir = root / "contents/icons/providers"
    svg_dir.mkdir(parents=True, exist_ok=True)
    for name, content in svg_files.items():
        (svg_dir / ("%s.svg" % name)).write_text(content, encoding="utf-8")
    return js_dir / "ProviderIcons.js", svg_dir


class CheckerUnitTest(unittest.TestCase):
    """Drives the checker's pure functions over tempfile fixture trees."""

    def setUp(self):
        self.checker = load_checker()

    def test_coverage_missing_svg_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            js_path, svg_dir = write_fixture_tree(
                root, ["alpha", "beta"], {"alpha": VALID_SVG}
            )
            known = self.checker.parse_known_providers(js_path)
            violations = self.checker.check_coverage(known, svg_dir)
            self.assertTrue(any("beta" in v for v in violations))

    def test_coverage_full_set_passes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            js_path, svg_dir = write_fixture_tree(
                root, ["alpha", "beta"],
                {"alpha": VALID_SVG, "beta": VALID_SVG},
            )
            known = self.checker.parse_known_providers(js_path)
            violations = self.checker.check_coverage(known, svg_dir)
            self.assertEqual(violations, [])

    def test_orphan_svg_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            js_path, svg_dir = write_fixture_tree(
                root, ["alpha"], {"alpha": VALID_SVG, "orphan": VALID_SVG}
            )
            known = self.checker.parse_known_providers(js_path)
            violations = self.checker.check_orphans(known, svg_dir)
            self.assertTrue(any("orphan" in v for v in violations))

    def test_no_orphan_passes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            js_path, svg_dir = write_fixture_tree(
                root, ["alpha"], {"alpha": VALID_SVG}
            )
            known = self.checker.parse_known_providers(js_path)
            violations = self.checker.check_orphans(known, svg_dir)
            self.assertEqual(violations, [])

    def test_malformed_xml_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _, svg_dir = write_fixture_tree(
                root, ["broken"], {"broken": "<svg><unclosed></svg>\n"}
            )
            violations = self.checker.check_parseable([svg_dir / "broken.svg"])
            self.assertTrue(any("broken" in v for v in violations))

    def test_valid_svg_parses_cleanly(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _, svg_dir = write_fixture_tree(root, ["ok"], {"ok": VALID_SVG})
            violations = self.checker.check_parseable([svg_dir / "ok.svg"])
            self.assertEqual(violations, [])

    def test_unsanctioned_duplicate_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _, svg_dir = write_fixture_tree(
                root, ["one", "two"], {"one": VALID_SVG, "two": VALID_SVG}
            )
            violations = self.checker.check_distinctness(
                [svg_dir / "one.svg", svg_dir / "two.svg"],
                self.checker.SANCTIONED_DUPLICATES,
            )
            self.assertTrue(any("one" in v and "two" in v for v in violations))

    def test_sanctioned_duplicate_group_passes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _, svg_dir = write_fixture_tree(
                root,
                ["alibaba", "alibabatokenplan"],
                {"alibaba": VALID_SVG, "alibabatokenplan": VALID_SVG},
            )
            violations = self.checker.check_distinctness(
                [svg_dir / "alibaba.svg", svg_dir / "alibabatokenplan.svg"],
                self.checker.SANCTIONED_DUPLICATES,
            )
            self.assertEqual(violations, [])

    def test_sanctioned_triple_group_passes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _, svg_dir = write_fixture_tree(
                root,
                ["kimi", "kimik2", "moonshot"],
                {"kimi": VALID_SVG, "kimik2": VALID_SVG, "moonshot": VALID_SVG},
            )
            violations = self.checker.check_distinctness(
                [svg_dir / "kimi.svg", svg_dir / "kimik2.svg", svg_dir / "moonshot.svg"],
                self.checker.SANCTIONED_DUPLICATES,
            )
            self.assertEqual(violations, [])

    def test_distinct_files_pass(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            other_svg = (
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
                '<path d="M1 1"/></svg>\n'
            )
            _, svg_dir = write_fixture_tree(
                root, ["one", "two"], {"one": VALID_SVG, "two": other_svg}
            )
            violations = self.checker.check_distinctness(
                [svg_dir / "one.svg", svg_dir / "two.svg"],
                self.checker.SANCTIONED_DUPLICATES,
            )
            self.assertEqual(violations, [])


class RealTreeIntegrationTest(unittest.TestCase):
    """Runs invariant 5 (distinctness) against the actual repository tree."""

    def test_invariant5_distinctness_on_real_tree(self):
        checker = load_checker()
        svg_dir = REPO_ROOT / "contents/icons/providers"
        svg_paths = sorted(svg_dir.glob("*.svg"))
        violations = checker.check_distinctness(svg_paths, checker.SANCTIONED_DUPLICATES)
        # RED at Slice 1 write time: openai.svg, contents/icons/providers/codex.svg,
        # and contents/icons/providers/azureopenai.svg currently share content hash
        # a35f3231d59ef004f88f598b44bc5eae (the exact regression this change fixes).
        # GREEN once tasks 1.4-1.5 replace codex.svg/azureopenai.svg with the
        # authored marks, which no longer collide with openai.svg or each other.
        self.assertEqual(violations, [])


class BannedColorInvariantTest(unittest.TestCase):
    """Drives invariant 4 (no theme-defeating literal fill/stroke) over
    tempfile fixture trees. RED at Slice 3 write time: check_banned_colors
    does not exist yet on the checker module.
    """

    def setUp(self):
        self.checker = load_checker()

    def test_banned_fill_attribute_fails(self):
        svg = (
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
            '<path d="M0 0" fill="#111111"/></svg>\n'
        )
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _, svg_dir = write_fixture_tree(root, ["bad"], {"bad": svg})
            violations = self.checker.check_banned_colors(
                [svg_dir / "bad.svg"], self.checker.LITERAL_COLOR_ALLOWLIST
            )
            self.assertTrue(any("bad" in v for v in violations))

    def test_banned_style_fill_declaration_fails(self):
        svg = (
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
            '<path d="M0 0" style="fill:#000000;fill-rule:nonzero"/></svg>\n'
        )
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _, svg_dir = write_fixture_tree(root, ["bad"], {"bad": svg})
            violations = self.checker.check_banned_colors(
                [svg_dir / "bad.svg"], self.checker.LITERAL_COLOR_ALLOWLIST
            )
            self.assertTrue(any("bad" in v for v in violations))

    def test_banned_style_stroke_declaration_fails(self):
        svg = (
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
            '<path d="M0 0" style="stroke:white;stroke-width:2"/></svg>\n'
        )
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _, svg_dir = write_fixture_tree(root, ["bad"], {"bad": svg})
            violations = self.checker.check_banned_colors(
                [svg_dir / "bad.svg"], self.checker.LITERAL_COLOR_ALLOWLIST
            )
            self.assertTrue(any("bad" in v for v in violations))

    def test_banned_token_inside_clippath_subtree_passes(self):
        svg = (
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
            '<defs><clipPath id="clip0">'
            '<rect width="10" height="10" fill="white"/>'
            '</clipPath></defs>'
            '<path d="M0 0" fill="currentColor"/></svg>\n'
        )
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _, svg_dir = write_fixture_tree(root, ["clipped"], {"clipped": svg})
            violations = self.checker.check_banned_colors(
                [svg_dir / "clipped.svg"], self.checker.LITERAL_COLOR_ALLOWLIST
            )
            self.assertEqual(violations, [])

    def test_banned_token_inside_mask_subtree_passes(self):
        svg = (
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
            '<mask id="m0">'
            '<rect width="10" height="10" fill="#000000"/>'
            '</mask>'
            '<path d="M0 0" fill="currentColor"/></svg>\n'
        )
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _, svg_dir = write_fixture_tree(root, ["masked"], {"masked": svg})
            violations = self.checker.check_banned_colors(
                [svg_dir / "masked.svg"], self.checker.LITERAL_COLOR_ALLOWLIST
            )
            self.assertEqual(violations, [])

    def test_fill_none_and_stroke_none_never_banned(self):
        svg = (
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
            '<path d="M0 0" fill="none" stroke="none"/></svg>\n'
        )
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _, svg_dir = write_fixture_tree(root, ["none"], {"none": svg})
            violations = self.checker.check_banned_colors(
                [svg_dir / "none.svg"], self.checker.LITERAL_COLOR_ALLOWLIST
            )
            self.assertEqual(violations, [])

    def test_allowlisted_file_passes_despite_literal_color(self):
        # vertexai.svg legitimately retains fill="#4285F4" and (in this
        # fixture) a literal "white" stroke; the filename allowlist must
        # suppress both regardless of banned-token content.
        svg = (
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
            '<path d="M0 0" fill="#4285F4" stroke="white"/></svg>\n'
        )
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _, svg_dir = write_fixture_tree(root, ["vertexai"], {"vertexai": svg})
            violations = self.checker.check_banned_colors(
                [svg_dir / "vertexai.svg"], self.checker.LITERAL_COLOR_ALLOWLIST
            )
            self.assertEqual(violations, [])


class RealTreeBannedColorIntegrationTest(unittest.TestCase):
    """Runs invariant 4 (banned literal color) against the actual repository
    tree. RED before Slice 3's recolor (task 3.2) and checker wiring
    (task 3.3): the 6 near-black files (alibaba, alibabatokenplan, kilo,
    manus, opencode, opencodego) still carry their literal fill tokens.
    GREEN once both land, with no false positive on openrouter.svg's inert
    <clipPath> rect, the 3 allowlisted files, or any already-correct SVG.
    """

    def test_invariant4_banned_colors_on_real_tree(self):
        checker = load_checker()
        svg_dir = REPO_ROOT / "contents/icons/providers"
        svg_paths = sorted(svg_dir.glob("*.svg"))
        violations = checker.check_banned_colors(
            svg_paths, checker.LITERAL_COLOR_ALLOWLIST
        )
        self.assertEqual(violations, [])


if __name__ == "__main__":
    unittest.main()

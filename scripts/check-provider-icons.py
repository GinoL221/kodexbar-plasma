#!/usr/bin/env python3
"""Standard-library asset invariant checker for contents/icons/providers/*.svg.

Implements all 5 asset invariants: 1 (coverage), 2 (no orphans), 3
(parseable XML with the correct SVG root tag), 4 (no theme-defeating
literal fill/stroke color), and 5 (distinctness, with the
SANCTIONED_DUPLICATES allowlist).

Standard library only: pathlib, re, hashlib, xml.etree.ElementTree.
"""

import argparse
import hashlib
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


SVG_ROOT_TAG = "{http://www.w3.org/2000/svg}svg"

# Sanctioned brand-family duplicate groups (see design.md's Architecture
# Decisions table): these already share content and are intentional.
SANCTIONED_DUPLICATES = [
    frozenset({"alibaba", "alibabatokenplan"}),
    frozenset({"kimi", "kimik2", "moonshot"}),
    frozenset({"opencode", "opencodego"}),
]

# Invariant 4: literal colors that defeat theme adaptation if they appear
# as a `fill`/`stroke` attribute or a `fill:`/`stroke:` style declaration.
# Comparison is case-insensitive; `none` is never banned (it is structural).
BANNED_COLOR_TOKENS = {
    "white",
    "#fff",
    "#ffffff",
    "#111111",
    "#1a1a18",
    "#34322d",
    "#211e1e",
    "#000",
    "#000000",
    "black",
}

# Files where a literal color is a documented, intentional exception (see
# design.md's "Documented literal-color fallback" scenario), plus any file
# added by the Slice 2 de-risking fallback procedure (none were needed).
# D19: codex.svg, commandcode.svg, and mimo.svg are the 3 stroke-only icons
# where Kirigami.Icon's isMask theme-adaptive recoloring did not visibly
# work under the live Breeze Dark smoke -- a narrow, named exception, not a
# general loosening (see visual-parity-polish design.md D16-D19).
LITERAL_COLOR_ALLOWLIST = {
    "codebuff.svg",
    "stepfun.svg",
    "vertexai.svg",
    "codex.svg",
    "commandcode.svg",
    "mimo.svg",
}

# Elements inside these subtrees are skipped by tree position: paint here
# never renders directly (clipPath geometry, mask luminance source).
SKIP_SUBTREE_LOCAL_NAMES = {"clipPath", "mask"}

_STYLE_FILL_RE = re.compile(r"(?<![\w-])fill\s*:\s*([^;]+)", re.IGNORECASE)
_STYLE_STROKE_RE = re.compile(r"(?<![\w-])stroke\s*:\s*([^;]+)", re.IGNORECASE)


def _local_name(tag):
    """Strip the XML namespace off an ElementTree tag, e.g.
    '{http://www.w3.org/2000/svg}clipPath' -> 'clipPath'.
    """
    return tag.rsplit("}", 1)[-1] if "}" in tag else tag


def _is_banned(value):
    if value is None:
        return False
    normalized = value.strip().lower()
    if normalized == "none":
        return False
    return normalized in BANNED_COLOR_TOKENS


def parse_known_providers(js_path):
    """Parse the `knownProviders` string array out of ProviderIcons.js."""
    text = js_path.read_text(encoding="utf-8")
    match = re.search(r"knownProviders\s*=\s*\[(.*?)\]", text, re.S)
    if not match:
        raise ValueError("knownProviders array not found in %s" % js_path)
    return re.findall(r'"([^"]+)"', match.group(1))


def check_coverage(known_providers, svg_dir):
    """Invariant 1: every known provider key has a matching SVG file."""
    violations = []
    for name in known_providers:
        if not (svg_dir / ("%s.svg" % name)).is_file():
            violations.append(
                "coverage: missing %s/%s.svg for known provider %r"
                % (svg_dir, name, name)
            )
    return violations


def check_orphans(known_providers, svg_dir):
    """Invariant 2: every SVG file maps back to a known provider key."""
    known = set(known_providers)
    violations = []
    for path in sorted(svg_dir.glob("*.svg")):
        if path.stem not in known:
            violations.append(
                "orphan: %s has no matching knownProviders key" % path.name
            )
    return violations


def check_parseable(svg_paths):
    """Invariant 3: each file is well-formed XML with the SVG root tag."""
    violations = []
    for path in svg_paths:
        try:
            root = ET.parse(path).getroot()
        except ET.ParseError as error:
            violations.append(
                "parse: %s is not well-formed XML: %s" % (path.name, error)
            )
            continue
        if root.tag != SVG_ROOT_TAG:
            violations.append(
                "parse: %s root tag is %r, expected %r"
                % (path.name, root.tag, SVG_ROOT_TAG)
            )
    return violations


def _walk_for_banned_colors(element, path, violations, inside_skip_subtree):
    tag = _local_name(element.tag)
    skip_here = inside_skip_subtree or tag in SKIP_SUBTREE_LOCAL_NAMES

    if not skip_here:
        fill = element.get("fill")
        if _is_banned(fill):
            violations.append(
                "banned-color: %s <%s fill=%r> uses banned literal color"
                % (path.name, tag, fill)
            )
        stroke = element.get("stroke")
        if _is_banned(stroke):
            violations.append(
                "banned-color: %s <%s stroke=%r> uses banned literal color"
                % (path.name, tag, stroke)
            )
        style = element.get("style")
        if style:
            fill_match = _STYLE_FILL_RE.search(style)
            if fill_match and _is_banned(fill_match.group(1)):
                violations.append(
                    "banned-color: %s <%s style=%r> uses banned literal fill:"
                    % (path.name, tag, style)
                )
            stroke_match = _STYLE_STROKE_RE.search(style)
            if stroke_match and _is_banned(stroke_match.group(1)):
                violations.append(
                    "banned-color: %s <%s style=%r> uses banned literal stroke:"
                    % (path.name, tag, style)
                )

    for child in element:
        _walk_for_banned_colors(child, path, violations, skip_here)


def check_banned_colors(svg_paths, allowlist):
    """Invariant 4: no `fill`/`stroke` attribute or `style` `fill:`/`stroke:`
    declaration may equal a banned literal color (case-insensitive).
    Elements inside a `<clipPath>`/`<mask>` subtree are skipped by tree
    position; files in `allowlist` are skipped entirely; `none` is never
    banned.
    """
    violations = []
    for path in svg_paths:
        if path.name in allowlist:
            continue
        try:
            root = ET.parse(path).getroot()
        except ET.ParseError:
            # Malformed XML is invariant 3's concern, not invariant 4's.
            continue
        _walk_for_banned_colors(root, path, violations, inside_skip_subtree=False)
    return violations


def check_distinctness(svg_paths, sanctioned_duplicates):
    """Invariant 5: no two SVGs share a content hash, except sanctioned groups."""
    by_hash = {}
    for path in svg_paths:
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        by_hash.setdefault(digest, []).append(path)
    violations = []
    for digest, paths in by_hash.items():
        if len(paths) < 2:
            continue
        stems = frozenset(path.stem for path in paths)
        if stems in sanctioned_duplicates:
            continue
        names = ", ".join(sorted(path.name for path in paths))
        violations.append(
            "distinctness: %s share content hash %s" % (names, digest)
        )
    return violations


def run_checks(repo_root):
    js_path = repo_root / "contents" / "code" / "ProviderIcons.js"
    svg_dir = repo_root / "contents" / "icons" / "providers"
    known_providers = parse_known_providers(js_path)
    svg_paths = sorted(svg_dir.glob("*.svg"))
    violations = []
    violations += check_coverage(known_providers, svg_dir)
    violations += check_orphans(known_providers, svg_dir)
    violations += check_parseable(svg_paths)
    violations += check_banned_colors(svg_paths, LITERAL_COLOR_ALLOWLIST)
    violations += check_distinctness(svg_paths, SANCTIONED_DUPLICATES)
    return violations


def main():
    parser = argparse.ArgumentParser(
        description="Provider icon asset invariant checker "
        "(coverage, no orphans, parseable XML, distinctness)."
    )
    parser.add_argument(
        "--repo-root", type=Path, default=Path(__file__).resolve().parents[1]
    )
    args = parser.parse_args()
    violations = run_checks(args.repo_root.resolve())
    if violations:
        for violation in violations:
            print(violation, file=sys.stderr)
        sys.exit(1)
    print("check-provider-icons: coverage, no-orphans, parseable, "
          "no-banned-color, distinctness all pass.")


if __name__ == "__main__":
    main()

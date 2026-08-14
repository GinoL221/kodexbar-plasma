#!/usr/bin/env python3
"""Standard-library asset invariant checker for contents/icons/providers/*.svg.

Implements invariants 1 (coverage), 2 (no orphans), 3 (parseable XML with
the correct SVG root tag), and 5 (distinctness, with the
SANCTIONED_DUPLICATES allowlist). Invariant 4 (no theme-defeating literal
fill/stroke color) is added in Slice 3.

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
          "distinctness all pass.")


if __name__ == "__main__":
    main()

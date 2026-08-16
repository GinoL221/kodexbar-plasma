"""Parse Breeze .colors files into Kirigami-facing palette hex values."""

from __future__ import annotations

import configparser
from pathlib import Path


SCHEME_PATHS = {
    "light": Path("/usr/share/color-schemes/BreezeLight.colors"),
    "dark": Path("/usr/share/color-schemes/BreezeDark.colors"),
}


def _rgb_to_hex(raw: str) -> str:
    parts = [part.strip() for part in raw.split(",")]
    if len(parts) != 3:
        raise ValueError("color value must be R,G,B: %s" % raw)
    red, green, blue = (int(part) for part in parts)
    for channel in (red, green, blue):
        if channel < 0 or channel > 255:
            raise ValueError("color channel out of range: %s" % raw)
    return "#%02x%02x%02x" % (red, green, blue)


def parse_breeze_colors(path: str | Path) -> dict[str, str]:
    """Return Window/Selection colors used by the visual fixture theme inject."""
    scheme_path = Path(path)
    text = scheme_path.read_text(encoding="utf-8")
    parser = configparser.ConfigParser()
    parser.optionxform = lambda option: option  # type: ignore[method-assign]
    parser.read_string(text)

    def color(section: str, key: str) -> str:
        if not parser.has_section(section) or not parser.has_option(section, key):
            raise ValueError("missing %s/%s in %s" % (section, key, scheme_path))
        return _rgb_to_hex(parser.get(section, key))

    window = "Colors:Window"
    selection = "Colors:Selection"
    # Hex without leading '#' — qml6 argv / URL handling treats '#' as a fragment.
    return {
        "backgroundColor": color(window, "BackgroundNormal").lstrip("#"),
        "alternateBackgroundColor": color(window, "BackgroundAlternate").lstrip("#"),
        "textColor": color(window, "ForegroundNormal").lstrip("#"),
        "disabledTextColor": color(window, "ForegroundInactive").lstrip("#"),
        "activeTextColor": color(window, "ForegroundActive").lstrip("#"),
        "linkColor": color(window, "ForegroundLink").lstrip("#"),
        "visitedLinkColor": color(window, "ForegroundVisited").lstrip("#"),
        "negativeTextColor": color(window, "ForegroundNegative").lstrip("#"),
        "neutralTextColor": color(window, "ForegroundNeutral").lstrip("#"),
        "positiveTextColor": color(window, "ForegroundPositive").lstrip("#"),
        "highlightColor": color(selection, "BackgroundNormal").lstrip("#"),
        "highlightedTextColor": color(selection, "ForegroundNormal").lstrip("#"),
        "focusColor": color(window, "DecorationFocus").lstrip("#"),
        "hoverColor": color(window, "DecorationHover").lstrip("#"),
    }


def palette_for_theme(theme: str) -> dict[str, str]:
    key = theme.strip().lower()
    if key not in SCHEME_PATHS:
        raise ValueError("theme must be light or dark, got %r" % theme)
    path = SCHEME_PATHS[key]
    if not path.is_file():
        raise FileNotFoundError("Breeze scheme missing: %s" % path)
    return parse_breeze_colors(path)


def is_dark_palette(palette: dict[str, str]) -> bool:
    def luminance(hex_color: str) -> float:
        value = hex_color.lstrip("#")
        red = int(value[0:2], 16) / 255.0
        green = int(value[2:4], 16) / 255.0
        blue = int(value[4:6], 16) / 255.0
        return 0.2126 * red + 0.7152 * green + 0.0722 * blue

    return luminance(palette["backgroundColor"]) < luminance(palette["textColor"])


def qml_color(hex_color: str) -> str:
    """Return a QML/CSS color token including the leading '#'."""
    value = hex_color.lstrip("#")
    if len(value) != 6:
        raise ValueError("expected 6-digit hex color, got %r" % hex_color)
    return "#" + value

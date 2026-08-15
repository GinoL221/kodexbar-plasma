import argparse
import os
import sys
import tempfile
from pathlib import Path

from PIL import Image, UnidentifiedImageError

from fixture_contract import CANONICAL_BASELINES, CANONICAL_SCENARIOS


MAX_CHANNEL_DELTA = 8
MAX_MISMATCH_RATIO = 0.001
CANONICAL_SCENARIO_NAMES = {scenario[0] for scenario in CANONICAL_SCENARIOS}


class VisualComparisonError(ValueError):
    pass


def _load_rgba(path, label):
    path = Path(path)
    if not path.is_file():
        raise VisualComparisonError("missing %s: %s" % (label, path))
    try:
        with Image.open(path) as image:
            if image.format != "PNG":
                raise VisualComparisonError(
                    "%s must be a decodable PNG: %s" % (label, path)
                )
            return image.convert("RGBA")
    except (OSError, UnidentifiedImageError) as error:
        raise VisualComparisonError("undecodable %s: %s" % (label, path)) from error


def _failure_message(expected, actual, diff, scenario, theme, mismatched, total, maximum_delta):
    ratio = mismatched / total
    return (
        "visual comparison failed: expected=%s actual=%s diff=%s scenario=%s theme=%s "
        "mismatched=%d/%d ratio=%.6f threshold=%d maximum_delta=%d"
        % (
            expected,
            actual,
            diff,
            scenario,
            theme,
            mismatched,
            total,
            ratio,
            MAX_CHANNEL_DELTA,
            maximum_delta,
        )
    )


def compare_images(expected_path, actual_path, diff_path, scenario, theme):
    expected = _load_rgba(expected_path, "baseline")
    actual = _load_rgba(actual_path, "actual image")
    if expected.size != actual.size:
        raise VisualComparisonError(
            "baseline and actual dimensions differ: expected=%s actual=%s baseline=%s"
            % (expected.size, actual.size, expected_path)
        )

    total = expected.width * expected.height
    mismatched = 0
    maximum_delta = 0
    diff = Image.new("RGBA", expected.size, (0, 0, 0, 0))
    expected_pixels = expected.load()
    actual_pixels = actual.load()
    diff_pixels = diff.load()
    for y in range(expected.height):
        for x in range(expected.width):
            channel_delta = max(
                abs(expected_pixels[x, y][channel] - actual_pixels[x, y][channel])
                for channel in range(4)
            )
            maximum_delta = max(maximum_delta, channel_delta)
            if channel_delta > MAX_CHANNEL_DELTA:
                mismatched += 1
                diff_pixels[x, y] = (255, 0, 0, 255)

    ratio = mismatched / total
    result = {
        "mismatched_pixels": mismatched,
        "total_pixels": total,
        "ratio": ratio,
        "maximum_delta": maximum_delta,
        "threshold": MAX_CHANNEL_DELTA,
    }
    if ratio > MAX_MISMATCH_RATIO:
        Path(diff_path).parent.mkdir(parents=True, exist_ok=True)
        diff.save(diff_path)
        raise VisualComparisonError(
            _failure_message(
                expected_path,
                actual_path,
                diff_path,
                scenario,
                theme,
                mismatched,
                total,
                maximum_delta,
            )
        )
    return result


def update_golden(actual_path, golden_path, scenario, update_enabled):
    if not update_enabled:
        raise VisualComparisonError("golden replacement requires UPDATE_GOLDENS=1")
    if scenario not in CANONICAL_SCENARIO_NAMES:
        raise VisualComparisonError("golden replacement requires a canonical scenario")
    if Path(golden_path).name not in CANONICAL_BASELINES:
        raise VisualComparisonError("golden replacement requires a canonical baseline name")
    if Path(golden_path).name != scenario + ".png":
        raise VisualComparisonError("golden replacement must match its canonical scenario")

    actual = _load_rgba(actual_path, "actual image")
    if actual.size != (450, 400):
        raise VisualComparisonError("golden replacement requires a 450x400 actual image")

    golden_path = Path(golden_path)
    golden_path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        dir=golden_path.parent, prefix=golden_path.stem + ".", suffix=".png", delete=False
    ) as temporary:
        temporary_path = Path(temporary.name)
    try:
        actual.save(temporary_path)
        os.replace(temporary_path, golden_path)
    finally:
        temporary_path.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description="Compare or explicitly update visual goldens.")
    parser.add_argument("--expected", type=Path)
    parser.add_argument("--actual", type=Path)
    parser.add_argument("--diff", type=Path)
    parser.add_argument("--scenario")
    parser.add_argument("--theme")
    parser.add_argument("--update", action="store_true")
    arguments = parser.parse_args()
    if not all((arguments.expected, arguments.actual, arguments.scenario)):
        parser.error("--expected, --actual, and --scenario are required")
    try:
        if arguments.update:
            update_golden(
                arguments.actual,
                arguments.expected,
                arguments.scenario,
                os.environ.get("UPDATE_GOLDENS") == "1",
            )
            print("updated golden: %s" % arguments.expected)
        else:
            if arguments.diff is None or arguments.theme is None:
                parser.error("--diff and --theme are required outside update mode")
            result = compare_images(
                arguments.expected,
                arguments.actual,
                arguments.diff,
                arguments.scenario,
                arguments.theme,
            )
            print(
                "visual comparison passed: scenario=%s theme=%s mismatched=%d/%d "
                "ratio=%.6f threshold=%d maximum_delta=%d"
                % (
                    arguments.scenario,
                    arguments.theme,
                    result["mismatched_pixels"],
                    result["total_pixels"],
                    result["ratio"],
                    result["threshold"],
                    result["maximum_delta"],
                )
            )
    except VisualComparisonError as error:
        print("error: %s" % error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

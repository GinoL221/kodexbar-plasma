import json
from pathlib import Path


CANONICAL_FIXTURE = {"width": 450, "height": 400, "font": "Noto Sans"}
CANONICAL_SCENARIOS = (
    ("breeze-light-cost-present", "light", True),
    ("breeze-light-cost-absent", "light", False),
    ("breeze-dark-cost-present", "dark", True),
    ("breeze-dark-cost-absent", "dark", False),
)
CANONICAL_BASELINES = tuple(name + ".png" for name, _, _ in CANONICAL_SCENARIOS)


def validate_manifest(path):
    payload = json.loads(Path(path).read_text(encoding="utf-8"))
    if payload.get("fixture") != CANONICAL_FIXTURE:
        raise ValueError("fixture must remain the canonical 450x400 Noto Sans contract")

    if tuple(payload.get("baselines", [])) != CANONICAL_BASELINES:
        raise ValueError("baseline names must remain the canonical scenario set")

    actual = tuple(
        (scenario.get("name"), scenario.get("theme"), scenario.get("cost"))
        for scenario in payload.get("scenarios", [])
    )
    if actual != CANONICAL_SCENARIOS:
        raise ValueError("scenarios must remain the canonical Light/Dark × Cost matrix")

    return payload

import unittest
from pathlib import Path


ROOT = Path(__file__).parents[1]


class BoundQmlComponentsTest(unittest.TestCase):
    def source(self, name):
        return (ROOT / "contents/ui" / name).read_text(encoding="utf-8")

    def test_affected_components_use_bound_behavior(self):
        for name in (
            "main.qml",
            "ProviderSelector.qml",
            "ProviderIcon.qml",
            "ProviderRow.qml",
            "UsageWindowRow.qml",
            "ErrorSummary.qml",
            "ProviderDetails.qml",
        ):
            with self.subTest(name=name):
                self.assertIn("pragma ComponentBehavior: Bound", self.source(name))

    def test_delegates_declare_the_context_they_consume(self):
        expected_declarations = {
            "main.qml": "required property var modelData",
            "ProviderSelector.qml": "required property int index",
            "ProviderRow.qml": "required property var modelData",
            "ErrorSummary.qml": "required property var modelData",
            "ProviderDetails.qml": "required property var modelData",
        }
        for name, declaration in expected_declarations.items():
            with self.subTest(name=name):
                self.assertIn(declaration, self.source(name))

    def test_nested_components_use_explicit_outer_scope(self):
        expected_access = {
            "main.qml": ("root.controller", "root.preferredWindowKey"),
            "ProviderSelector.qml": ("root._selectAll", "root._selectProviderAt"),
            "ProviderRow.qml": ("root.compact", "root.summary"),
            "UsageWindowRow.qml": ("root.windowData", "root.hasFinitePercent"),
            "ErrorSummary.qml": ("root.valueText", "root.failureText"),
            "ProviderDetails.qml": ("root.acceptedDetails", "root.expanded"),
        }
        for name, accessors in expected_access.items():
            source = self.source(name)
            for accessor in accessors:
                with self.subTest(name=name, accessor=accessor):
                    self.assertIn(accessor, source)

    def test_popup_scroll_view_disables_horizontal_uses_vertical_as_needed(self):
        source = self.source("main.qml")
        self.assertIn("ScrollBar.horizontal.policy", source)
        self.assertIn("ScrollBar.AlwaysOff", source)
        self.assertIn("ScrollBar.vertical.policy", source)
        self.assertIn("ScrollBar.AsNeeded", source)


if __name__ == "__main__":
    unittest.main()

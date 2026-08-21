import unittest
from pathlib import Path


ROOT = Path(__file__).parents[1]
UI = ROOT / "contents" / "ui"


class ProviderIconRenderingContractTest(unittest.TestCase):
    def source(self, name):
        return (UI / name).read_text(encoding="utf-8")

    def test_provider_svg_renderer_uses_image_alpha_not_kirigami_mask(self):
        source = self.source("ProviderIcon.qml")
        self.assertIn("Image {", source)
        self.assertIn("fillMode: Image.PreserveAspectFit", source)
        self.assertIn("MultiEffect {", source)
        self.assertIn("source: providerImage", source)
        self.assertIn("brightness: 1.0", source)
        self.assertIn("colorization: 1.0", source)
        self.assertIn("colorizationColor: root.color", source)
        self.assertIn("Screen.devicePixelRatio", source)
        self.assertIn("visible: root.usesSvgRenderer && !root.svgLoadFailed", source)
        self.assertNotIn("Canvas {", source)
        self.assertNotIn("ShaderEffectSource", source)
        self.assertNotIn("maskEnabled", source)

    def test_failed_svg_load_uses_themed_fallback(self):
        source = self.source("ProviderIcon.qml")
        self.assertIn("providerImage.status === Image.Error", source)
        self.assertIn('root.svgLoadFailed ? "dialog-information"', source)

    def test_every_provider_render_site_uses_shared_component(self):
        expected = {
            "ProviderSelector.qml": 'objectName: "providerTabIcon"',
            "ProviderRow.qml": 'objectName: "summaryProviderIcon"',
            "ProviderHeader.qml": 'objectName: "providerHeaderIcon"',
        }
        for name, object_name in expected.items():
            with self.subTest(name=name):
                source = self.source(name)
                self.assertIn("ProviderIcon {", source)
                self.assertIn(object_name, source)

    def test_provider_sites_cannot_restore_direct_svg_masking(self):
        forbidden = {
            "ProviderSelector.qml": "Kirigami.Icon {\n                                    source: providerTab.icon.source",
            "ProviderRow.qml": 'Kirigami.Icon {\n                objectName: "summaryProviderIcon"',
            "ProviderHeader.qml": "Kirigami.Icon {\n        // Overview cards keep the mark",
        }
        for name, old_render_path in forbidden.items():
            with self.subTest(name=name):
                self.assertNotIn(old_render_path, self.source(name))


if __name__ == "__main__":
    unittest.main()

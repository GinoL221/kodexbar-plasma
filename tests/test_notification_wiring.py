from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
main = (ROOT / "contents/ui/main.qml").read_text()

connection = main.index("function onCommittedGenerationChanged()")
popup = main.index("fullRepresentation: Item")
assert connection < popup, "commit lifecycle connection must be outside lazy popup"
assert "root.checkNotifications()" in main[connection:popup]
assert "root.maybeRequestCost(providerSelector.allSelected" in main[popup:], "cost request stays popup-scoped"

config_idx = main.index("id: configureButton")
refresh_idx = main.index("id: refreshButton")
assert config_idx < refresh_idx, "configureButton must precede refreshButton (bottom-left Configure, bottom-right Refresh)"

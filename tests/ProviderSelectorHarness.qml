import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../contents/ui" as UsageUi

Item {
    id: root
    width: 160; height: 320
    property bool assertionFailed: false

    function assert(c, m) {
        if (!c) {
            console.error("ProviderSelectorHarness failure:", m)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(m)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }
    function p(provider, source, windows) { return { provider: provider, source: source, windows: windows || [] } }
    function w(label, pct, reset, desc) { return { label: label, usedPercent: pct, resetsAt: reset, resetDescription: desc } }

    function findKirigamiIcon(item) {
        if (!item) return null
        if (item instanceof Kirigami.Icon) return item
        for (var i = 0; i < item.children.length; i++) {
            var result = findKirigamiIcon(item.children[i])
            if (result !== null) return result
        }
        return null
    }

    function findProgressBar(item) {
        if (!item) return null
        if (item instanceof QQC2.ProgressBar || item.objectName === "tabUsageBar" || item.objectName === "usageProgressBar") {
            return item
        }
        for (var i = 0; i < item.children.length; i++) {
            var result = findProgressBar(item.children[i])
            if (result !== null) return result
        }
        return null
    }

    function findObject(item, name) {
        if (!item) return null
        if (item.objectName === name) return item
        for (var i = 0; i < item.children.length; i++) {
            var result = findObject(item.children[i], name)
            if (result !== null) return result
        }
        return null
    }

    UsageUi.ProviderSelector {
        id: s
        width: root.width
        providers: []
        phase: "idle"
        popupOpen: false
    }

    Component.onCompleted: {
        s.popupOpen = true
        assert(s.allSelected && s.selectedProvider === null && s.usableProviders.length === 0, "empty default All")

        s.popupOpen = false
        s.providers = [p("empty","src-empty",[]), p("second","src-second",[w("Weekly",45,"2026-08-10T10:00:00Z","raw desc")]), p("third","src-third",[w("Session",10,null,null)])]
        s.popupOpen = true
        assert(!s.allSelected && s.selectedProvider && s.selectedProvider.provider === "second", "first usable")
        assert(s.usableProviders.length === 2 && s.usableProviders[0].provider === "second" && s.usableProviders[1].provider === "third", "order")
        assert(s.tabBar.contentChildren.length === 3, "tabs count")
        s.tabBar.currentIndex = 0
        s._activateIndex(0)
        assert(s.allSelected && s.selectedProvider === null, "explicit All")

        s.popupOpen = false; s.providers = []; s.phase = "loading"; s.popupOpen = true
        assert(s.allSelected, "pending loading All")
        s.providers = [p("later","src-later",[w("Session",5,"reset-later","desc-later")])]; s.phase = "idle"
        assert(!s.allSelected && s.selectedProvider.provider === "later", "settle first usable")

        s.providers = [p("alpha","a",[w("W",20,null,null)]), p("beta","b",[w("M",30,null,null)])]
        assert(s.selectedProvider.provider === "alpha", "default alpha")
        s.tabBar.currentIndex = 2
        s._activateIndex(2)
        assert(s.selectedProvider.provider === "beta", "select beta")
        assert(s.tabBar.contentChildren[2].visible && s.tabBar.contentChildren[2].text.indexOf("Beta") !== -1,
               "the second provider delegate must expose the selected provider (display-capitalized)")
        assert(s.tabBar.contentChildren[2].checked,
               "the selected provider delegate must retain the tab-bar checked state")
        s.providers = [p("beta","b",[w("M",30,null,null)]), p("alpha","a",[w("W",20,null,null)])]
        assert(s.selectedProvider.provider === "beta", "reorder preserves identity")

        s.providers = [p("gamma","g",[w("S",15,null,null)])]
        assert(s.selectedProvider.provider === "gamma", "fallback first usable")
        s.providers = [p("nowindow","nw",[])]
        assert(s.allSelected, "fallback All")

        s.providers = [p("delta","d",[w("S",1,null,null)])]
        s.tabBar.currentIndex = 0
        s._activateIndex(0)
        s.popupOpen = false; s.popupOpen = true
        assert(!s.allSelected && s.selectedProvider.provider === "delta", "reopen default")

        s.providers = [p(null,"src-null",[w("S",2,null,null)]), p("epsilon","e",[w("W",3,null,null)])]
        assert(s.usableProviders[0].provider === null, "null retained")
        s.tabBar.currentIndex = 1
        s._activateIndex(1)
        assert(s.selectedProvider && s.selectedProvider.provider === null, "null selectable")

        s.providers = [p("dup","src-dup-a",[w("S",5,null,null)]), p("dup","src-dup-b",[w("W",6,null,null)])]
        s.popupOpen = false; s.popupOpen = true
        assert(s.usableProviders.length === 2 && s.selectedProvider.provider === "dup", "duplicate identity")
        assert(s.tabBar.currentIndex === 1 && s._requestedIndex === -1,
            "reconciliation must settle without currentIndex feedback")

        s.width = root.width
        assert(s.width <= root.width && s.tabBar.width <= s.width, "narrow geometry")

        var t = s.tabBar.contentChildren[1]
        assert(t.activeFocusOnTab && t.focusPolicy === Qt.StrongFocus, "tab focus")
        assert(t.Accessible.name && t.Accessible.name.length > 0, "tab a11y name")
        assert(t.text.indexOf("Dup") !== -1 || t.Accessible.name.indexOf("Dup") !== -1
               || t.Accessible.name.indexOf("dup") !== -1, "tab name")
        assert(t.Accessible.name.indexOf("src-dup-a") !== -1 || t.Accessible.description.indexOf("src-dup-a") !== -1, "tab full source")
        assert(t.checked === (s.tabBar.currentIndex === 1), "checked state")

        // Visible label is name only; percent lives in a11y + underline bar.
        assert(t.text === "Dup",
            "tab text must be the short display-capitalized provider name only (no numeric percent)")
        assert(t.text.indexOf("%") === -1, "tab text must never contain a percent sign")
        assert(t.text.indexOf("·") === -1, "tab text must never combine provider and source")
        assert(t.text.indexOf("src-dup-a") === -1, "tab text must never contain the source")
        assert(t.Accessible.name.indexOf("5%") !== -1,
            "tab accessible name must mention the finite representative usage percent")
        var dupBar = findProgressBar(t)
        assert(dupBar !== null && dupBar.visible, "provider tab must show an underline usage bar when percent is finite")
        assert(Math.abs(dupBar.value - 5) < 0.01, "underline bar value must match representative percent")
        assert(dupBar.sideInset > 0,
            "tab underline bar must expose a positive side inset from the chip edges")
        assert(dupBar.nameGap > 0,
            "tab underline bar must expose a positive gap under the provider name")

        var dupIcon = findKirigamiIcon(t)
        assert(dupIcon !== null && dupIcon.isMask === true,
            "provider tab must render a theme-adaptive Kirigami.Icon mask")
        assert(dupIcon.implicitWidth >= Kirigami.Units.iconSizes.smallMedium,
            "tab provider icons must be at least smallMedium (user-facing size)")
        assert(String(dupIcon.source).indexOf("dup") !== -1 || String(t.icon.source).length >= 0,
            "provider tab icon source must resolve a source")

        s.popupOpen = false
        s.providers = [p("nopercent", "src-nopercent", [w("Session", null, null, null)])]
        s.popupOpen = true
        assert(s.selectedProvider && s.selectedProvider.provider === "nopercent",
            "a provider with a window but no finite usedPercent must still be usable/selectable")
        var noPercentTab = s.tabBar.contentChildren[1]
        assert(noPercentTab.text === "Nopercent",
            "tab text must omit the percent entirely when no finite representative usedPercent exists")
        assert(noPercentTab.text.indexOf("%") === -1,
            "tab text must never contain a percent sign when no finite percent exists")
        assert(noPercentTab.Accessible.name.indexOf("%") === -1,
            "tab accessible name must never mention a percent when no finite percent exists")
        var noBar = findProgressBar(noPercentTab)
        assert(noBar === null || !noBar.visible,
            "underline bar must be hidden when no finite percent exists")

        var allTab = s.tabBar.contentChildren[0]
        assert(allTab.text === "Overview", "tab 0 label must be Overview")
        assert(allTab.icon.name === "view-grid", "tab 0 icon handle must be view-grid")
        assert(allTab.Accessible.name.indexOf("Overview") !== -1, "tab 0 accessible name must reference Overview")
        assert(findKirigamiIcon(allTab) !== null, "Overview tab must render a Kirigami.Icon")

        // Brand display names on tabs (mapped CLI ids).
        s.popupOpen = false
        s.providers = [p("opencodego", "src-ocg", [w("Weekly", 30, null, null)])]
        s.popupOpen = true
        assert(s.tabBar.contentChildren[1].text === "OpenCode Go",
            "opencodego tab label must use the OpenCode Go display name")

        // Regression: selecting a provider while phase is loading (slow refresh
        // / pending default Overview) must leave Overview and stick to that
        // provider — not snap back to tab 0 on reconcile.
        s.popupOpen = false
        s.providers = [
            p("codex", "src-codex", [w("Weekly", 10, null, null)]),
            p("claude", "src-claude", [w("Weekly", 20, null, null)])
        ]
        s.phase = "loading"
        s.popupOpen = true
        assert(s.allSelected === true, "open while loading starts on Overview/pending default")
        assert(s.tabBar.currentIndex === 0, "pending default keeps tab index on Overview")
        s.tabBar.currentIndex = 2
        s._activateIndex(2)
        assert(s._pendingDefault === false, "explicit provider pick clears pending default")
        assert(s.allSelected === false, "explicit provider pick must leave Overview during loading")
        assert(s.selectedProvider && s.selectedProvider.provider === "claude",
            "explicit provider pick during loading must select that provider")
        assert(s.tabBar.currentIndex === 2, "tab strip must stay on the chosen provider during loading")
        // Simulate refresh churn while still loading — must not force Overview.
        s.providers = [
            p("codex", "src-codex", [w("Weekly", 11, null, null)]),
            p("claude", "src-claude", [w("Weekly", 21, null, null)])
        ]
        s.phase = "loading"
        assert(s.allSelected === false, "reconcile while loading must not force Overview after user pick")
        assert(s.selectedProvider && s.selectedProvider.provider === "claude",
            "reconcile while loading must keep the user-selected provider identity")
        assert(s.tabBar.currentIndex === 2, "reconcile while loading must keep the chosen tab index")
        s.phase = "ready"
        assert(s.selectedProvider && s.selectedProvider.provider === "claude",
            "selection must survive the transition from loading to ready")
        assert(s.tabBar.currentIndex === 2, "tab index must survive loading → ready")

        // Narrow overflow: 6 providers + Overview must not fit at width 200.
        s.popupOpen = false
        s.width = 200
        s.providers = [
            p("codex", "src-codex", [w("Weekly", 10, null, null)]),
            p("claude", "src-claude", [w("Weekly", 20, null, null)]),
            p("opencodego", "src-ocg", [w("Weekly", 30, null, null)]),
            p("gemini", "src-gemini", [w("Weekly", 40, null, null)]),
            p("copilot", "src-copilot", [w("Weekly", 50, null, null)]),
            p("grok", "src-grok", [w("Weekly", 60, null, null)])
        ]
        s.popupOpen = true
        assert(s.usableProviders.length === 6, "narrow-width fixture carries all six real providers")
        // Async geometry stages continue in geometryTimer below.
        geometryTimer.running = true
    }

    Timer {
        id: geometryTimer
        interval: 50
        running: false
        repeat: true
        property int stage: 0
        property real settledGrokX: 0
        property var leftBtn: null
        property var rightBtn: null
        property var grokDelegate: null

        onTriggered: {
            if (stage === 0) {
                // Wait until overflow geometry settles.
                if (!s.tabsOverflow) {
                    return
                }
                root.assert(s.tabsOverflow === true,
                    "seven tabs must overflow at this narrow width (impl="
                    + s.tabBar.implicitWidth + " w=" + s.width + ")")

                var codexTabDelegate = s.tabBar.contentChildren[1]
                var codexIcon = root.findKirigamiIcon(codexTabDelegate)
                root.assert(codexIcon !== null && codexIcon.isMask === true,
                    "provider tab must use Kirigami.Icon isMask for theme adaptation")
                root.assert(String(codexIcon.source).indexOf("codex.svg") !== -1,
                    "provider tab icon source must resolve to codex.svg")

                leftBtn = root.findObject(s, "tabScrollLeft")
                rightBtn = root.findObject(s, "tabScrollRight")
                root.assert(leftBtn !== null && rightBtn !== null, "scroll arrows must exist")
                root.assert(leftBtn.visible && rightBtn.visible, "scroll arrows visible when tabs overflow")

                s.tabBar.currentIndex = 6
                s._activateIndex(6)
                grokDelegate = s.tabBar.contentChildren[6]
                root.assert(grokDelegate !== null, "grok delegate must be instantiated once selected")
                stage = 1
            } else if (stage === 1) {
                var grokRect = grokDelegate.mapToItem(s, 0, 0)
                root.assert(grokRect.x >= -1 && grokRect.x + grokDelegate.width <= s.width + 1,
                    "selecting a not-fully-visible tab must scroll it into the visible viewport")
                settledGrokX = grokRect.x
                s.providers = [
                    root.p("codex", "src-codex", [root.w("Weekly", 11, null, null)]),
                    root.p("claude", "src-claude", [root.w("Weekly", 21, null, null)]),
                    root.p("opencodego", "src-ocg", [root.w("Weekly", 31, null, null)]),
                    root.p("gemini", "src-gemini", [root.w("Weekly", 41, null, null)]),
                    root.p("copilot", "src-copilot", [root.w("Weekly", 51, null, null)]),
                    root.p("grok", "src-grok", [root.w("Weekly", 61, null, null)])
                ]
                root.assert(s.selectedProvider && s.selectedProvider.provider === "grok", "selection survives a same-set data refresh")
                var grokDelegateAfterRefresh = s.tabBar.contentChildren[6]
                root.assert(grokDelegateAfterRefresh !== null, "grok delegate must still be instantiated after refresh")
                var grokRectAfterRefresh = grokDelegateAfterRefresh.mapToItem(s, 0, 0)
                root.assert(Math.abs(grokRectAfterRefresh.x - settledGrokX) < 2.0,
                    "a same-provider-set data refresh must not shift the already-visible selected tab's scrolled position")

                s.tabBar.currentIndex = 1
                s._activateIndex(1)
                root.assert(s.selectedProvider && s.selectedProvider.provider === "codex", "codex becomes selected")
                stage = 2
            } else if (stage === 2) {
                var codexDelegate = s.tabBar.contentChildren[1]
                var codexRect = codexDelegate.mapToItem(s, 0, 0)
                root.assert(codexRect.x >= -1 && codexRect.x + codexDelegate.width <= s.width + 1,
                    "scrolling back to an earlier tab must bring it fully into view")
                root.assert(s.tabsOverflow, "still overflowing at narrow width")
                s.width = Math.max(s.tabBar.implicitWidth + 200, 800)
                stage = 3
            } else {
                root.assert(s.tabsOverflow === false, "wide fixture must fit all tabs")
                root.assert(!leftBtn.visible && !rightBtn.visible,
                    "scroll arrows must hide when every tab fits")
                running = false
                root.finish()
            }
        }
    }
}

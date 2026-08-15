import QtQuick
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
        assert(s.allSelected && s.selectedProvider === null, "explicit All")

        s.popupOpen = false; s.providers = []; s.phase = "loading"; s.popupOpen = true
        assert(s.allSelected, "pending loading All")
        s.providers = [p("later","src-later",[w("Session",5,"reset-later","desc-later")])]; s.phase = "idle"
        assert(!s.allSelected && s.selectedProvider.provider === "later", "settle first usable")

        s.providers = [p("alpha","a",[w("W",20,null,null)]), p("beta","b",[w("M",30,null,null)])]
        assert(s.selectedProvider.provider === "alpha", "default alpha")
        s.tabBar.currentIndex = 2
        assert(s.selectedProvider.provider === "beta", "select beta")
        assert(s.tabBar.contentChildren[2].visible && s.tabBar.contentChildren[2].text.indexOf("beta") !== -1,
               "the second provider delegate must expose the selected provider")
        assert(s.tabBar.contentChildren[2].checked,
               "the selected provider delegate must retain the tab-bar checked state")
        s.providers = [p("beta","b",[w("M",30,null,null)]), p("alpha","a",[w("W",20,null,null)])]
        assert(s.selectedProvider.provider === "beta", "reorder preserves identity")

        s.providers = [p("gamma","g",[w("S",15,null,null)])]
        assert(s.selectedProvider.provider === "gamma", "fallback first usable")
        s.providers = [p("nowindow","nw",[])]
        assert(s.allSelected, "fallback All")

        s.providers = [p("delta","d",[w("S",1,null,null)])]
        s.tabBar.currentIndex = 0; s.popupOpen = false; s.popupOpen = true
        assert(!s.allSelected && s.selectedProvider.provider === "delta", "reopen default")

        s.providers = [p(null,"src-null",[w("S",2,null,null)]), p("epsilon","e",[w("W",3,null,null)])]
        assert(s.usableProviders[0].provider === null, "null retained")
        s.tabBar.currentIndex = 1
        assert(s.selectedProvider && s.selectedProvider.provider === null, "null selectable")

        s.providers = [p("dup","src-dup-a",[w("S",5,null,null)]), p("dup","src-dup-b",[w("W",6,null,null)])]
        s.popupOpen = false; s.popupOpen = true
        assert(s.usableProviders.length === 2 && s.selectedProvider.provider === "dup", "duplicate identity")
        assert(s.tabBar.currentIndex === 1 && s._requestedIndex === -1,
            "reconciliation must settle without currentIndex feedback")

        s.width = root.width
        assert(s.width <= root.width && s.tabBar.width <= s.width, "narrow geometry")

        assert(s.tabBar.activeFocusOnTab && (s.tabBar.focusPolicy === Qt.TabFocus || s.tabBar.focusPolicy === Qt.StrongFocus), "tab bar focus")
        var t = s.tabBar.contentChildren[1]
        assert(t.activeFocusOnTab && t.focusPolicy === Qt.StrongFocus, "tab focus")
        assert(t.Accessible.name && t.Accessible.name.length > 0, "tab a11y name")
        assert(t.text.indexOf("dup") !== -1 || t.Accessible.name.indexOf("dup") !== -1, "tab name")
        assert(t.Accessible.name.indexOf("src-dup-a") !== -1 || t.Accessible.description.indexOf("src-dup-a") !== -1, "tab full source")
        assert(t.checked === (s.tabBar.currentIndex === 1), "checked state")

        assert(t.text === "dup", "tab text must contain only the short provider name, no source suffix")
        assert(t.text.indexOf("·") === -1, "tab text must never combine provider and source")
        var allTab = s.tabBar.contentChildren[0]
        assert(allTab.text.indexOf("·") === -1 && allTab.icon.name.length > 0, "All tab must remain a compact icon-plus-label control")

        // Narrow-width scroll reachability regression: 6 real providers (the
        // maintainer's exact set) + "All" = 7 tabs, at a width far narrower
        // than their combined natural size, so the tab bar must scroll.
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
        assert(s.tabBar.width < s.tabBar.implicitWidth,
            "seven tabs must not fit naturally at this narrow width -- the fixture must actually exercise scrolling")

        s.tabBar.currentIndex = 6 // last real tab: grok
        var grokDelegate = s.tabBar.contentChildren[6]
        assert(grokDelegate !== null, "grok delegate must be instantiated once selected")
        var grokRect = grokDelegate.mapToItem(s, 0, 0)
        assert(grokRect.x >= 0 && grokRect.x + grokDelegate.width <= s.width,
            "selecting a not-fully-visible tab must scroll it fully into the tab bar's visible viewport")

        var settledGrokX = grokRect.x
        s.providers = [
            p("codex", "src-codex", [w("Weekly", 11, null, null)]),
            p("claude", "src-claude", [w("Weekly", 21, null, null)]),
            p("opencodego", "src-ocg", [w("Weekly", 31, null, null)]),
            p("gemini", "src-gemini", [w("Weekly", 41, null, null)]),
            p("copilot", "src-copilot", [w("Weekly", 51, null, null)]),
            p("grok", "src-grok", [w("Weekly", 61, null, null)])
        ]
        assert(s.selectedProvider && s.selectedProvider.provider === "grok", "selection survives a same-set data refresh")
        var grokDelegateAfterRefresh = s.tabBar.contentChildren[6]
        assert(grokDelegateAfterRefresh !== null, "grok delegate must still be instantiated after refresh")
        var grokRectAfterRefresh = grokDelegateAfterRefresh.mapToItem(s, 0, 0)
        assert(Math.abs(grokRectAfterRefresh.x - settledGrokX) < 0.01,
            "a same-provider-set data refresh must not shift the already-visible selected tab's scrolled position")

        // Triangulate: scrolling back to the first real tab (now off the
        // left edge, since the viewport followed grok to the right) must be
        // just as reachable as scrolling forward was.
        s.tabBar.currentIndex = 1 // first real tab: codex
        assert(s.selectedProvider && s.selectedProvider.provider === "codex", "codex becomes selected")
        var codexDelegate = s.tabBar.contentChildren[1]
        assert(codexDelegate !== null, "codex delegate must be instantiated once selected")
        var codexRect = codexDelegate.mapToItem(s, 0, 0)
        assert(codexRect.x >= 0 && codexRect.x + codexDelegate.width <= s.width,
            "scrolling back to an earlier not-fully-visible tab must also bring it fully into view")

        finish()
    }
}

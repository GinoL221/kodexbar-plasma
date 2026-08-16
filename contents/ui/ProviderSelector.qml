pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

import "../code/ProviderIcons.js" as ProviderIcons
import "../code/Translation.js" as Translation
import "../code/UsageModel.js" as UsageModel

ColumnLayout {
    id: root

    property var providers: []
    property string phase: "idle"
    property bool popupOpen: false
    // D6: governs which window the tab percent prefers (Session/Weekly/
    // Monthly/Automatic), mirroring the persisted compact-panel preference.
    // Never governs Overview's own body -- see Requirement: Provider
    // presentation.
    property string preferredWindowKey: "automatic"

    readonly property var usableProviders: root._usable(root.providers)
    readonly property bool allSelected: root._isAllSelected(root.usableProviders)
    readonly property var selectedProvider: root._resolveSelectedProvider(root.usableProviders)
    property alias tabBar: tabBar

    property bool _allSelected: true
    property int _selectedIndex: -1
    property var _selectedIdentity: undefined
    property bool _hasSelectedIdentity: false
    property bool _pendingDefault: false
    property int _requestedIndex: 0
    property int _delegateCapacity: 0

    function _usable(list) {
        if (!(list instanceof Array)) {
            return []
        }
        var result = []
        for (var i = 0; i < list.length; i++) {
            if (list[i] && list[i].windows instanceof Array && list[i].windows.length > 0) {
                result.push(list[i])
            }
        }
        return result
    }

    function _isAllSelected(usable) {
        return _pendingDefault
            ? root.phase === "loading" || usable.length === 0 : root._allSelected
    }

    function _resolveSelectedProvider(usable) {
        if (root.allSelected) {
            return null
        }
        if (root._pendingDefault) {
            return root._firstUsable(usable)
        }
        if (_hasSelectedIdentity) {
            for (var i = 0; i < usable.length; i++) {
                if (usable[i].provider === _selectedIdentity) {
                    return usable[i]
                }
            }
        }
        return root._selectedIndex >= 0 && root._selectedIndex < usable.length ? usable[root._selectedIndex] : null
    }

    function _firstUsable(usable) {
        return usable.length > 0 ? usable[0] : null
    }

    function _selectAll(pending) {
        root._pendingDefault = pending
        root._allSelected = true
        root._hasSelectedIdentity = false
        root._selectedIdentity = undefined
        root._selectedIndex = -1
        root._setIndex(0)
    }

    function _selectFirstOrAll(usable) {
        var first = root._firstUsable(usable)
        if (first === null) {
            root._selectAll(false)
            return
        }
        root._pendingDefault = false
        root._allSelected = false
        root._selectedIndex = 0
        root._selectedIdentity = first.provider
        root._hasSelectedIdentity = true
        root._setIndex(1)
    }

    function _selectProviderAt(index, usable) {
        root._allSelected = false
        root._selectedIndex = index
        root._selectedIdentity = usable[index].provider
        root._hasSelectedIdentity = true
        root._setIndex(index + 1)
    }

    function iconResolver(value) {
        var key = ProviderIcons.key(value)
        return key.length > 0
            ? Qt.resolvedUrl("../icons/providers/" + key + ".svg") : "dialog-information"
    }

    function _providerText(provider) {
        return provider && provider.provider !== null && provider.provider !== undefined
            ? String(provider.provider) : Translation.translate("Provider", [], typeof i18n === "function" ? i18n : null)
    }

    function _sourceText(provider) {
        return provider && provider.source !== null && provider.source !== undefined
            ? String(provider.source) : ""
    }

    // D6: tab percent reuses the same model logic as the compact-panel
    // preference (UsageModel.selectRepresentative), never the Overview
    // body's selectOverviewWindows.
    function _representativeWindow(provider) {
        return provider ? UsageModel.selectRepresentative(provider.windows, root.preferredWindowKey) : null
    }

    function _percentText(provider) {
        var representative = root._representativeWindow(provider)
        return representative && typeof representative.usedPercent === "number" && isFinite(representative.usedPercent)
            ? Math.round(representative.usedPercent) + "%" : ""
    }

    function _setIndex(index) {
        root._selectedIndex = index - 1
        root._requestedIndex = root.tabBar.currentIndex === index ? -1 : index
        root.tabBar.currentIndex = index
    }

    function _selectDefault() {
        if (root.phase === "loading") {
            root._selectAll(true)
            return
        }
        root._selectFirstOrAll(root.usableProviders)
    }

    function _reconcile() {
        if (!root.popupOpen) {
            return
        }
        var usable = root._usable(root.providers)
        if (root._pendingDefault) {
            if (root.phase === "loading") {
                root._setIndex(0)
                return
            }
            root._selectFirstOrAll(usable)
            return
        }
        if (root._allSelected) {
            root._setIndex(0)
            return
        }
        var target = -1
        if (root._hasSelectedIdentity) {
            for (var i = 0; i < usable.length; i++) {
                if (usable[i].provider === root._selectedIdentity) {
                    target = i
                    break
                }
            }
        }
        if (target < 0) {
            root._selectFirstOrAll(usable)
        } else {
            root._selectedIndex = target
            root._setIndex(target + 1)
        }
    }

    onPopupOpenChanged: {
        if (root.popupOpen) {
            root._selectDefault()
        }
    }
    onProvidersChanged: {
        var count = root._usable(root.providers).length
        if (count > root._delegateCapacity) {
            root._delegateCapacity = count
        }
        root._reconcile()
    }
    onPhaseChanged: {
        root._reconcile()
    }

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    // TabBar already manages its own horizontal overflow: its Qt Quick
    // Controls contentItem is a Flickable-backed ListView with
    // highlightRangeMode set, which keeps currentIndex scrolled into view on
    // its own. Wrapping it in an outer ScrollView is not just redundant --
    // it is actively harmful: ScrollView auto-wraps a non-Flickable child
    // (TabBar) in its own internal Flickable whose contentWidth follows
    // TabBar's *unclamped* implicitWidth (the natural width of all tabs)
    // while the rendered TabBar itself stays clamped to the available
    // width. That mismatch creates a second, decoupled scroll surface with
    // no ties to currentIndex, which both steals/mishandles click and drag
    // hit-testing meant for TabButton delegates and can silently shift its
    // contentX whenever that unclamped implicitWidth is recomputed (e.g. on
    // every usage-data refresh), even with no user-driven scroll action and
    // no selection change. Keeping TabBar unwrapped lets its own scroll
    // logic be the single source of truth for what is visible.
    QQC2.TabBar {
        id: tabBar
        clip: true
        Layout.fillWidth: true
        focusPolicy: Qt.StrongFocus
        activeFocusOnTab: true
        currentIndex: 0

        // Removing the outer ScrollView (see the note above) also removed
        // its scrollbar, leaving no visual affordance that tabs exist past
        // the visible window. Qt Quick Controls' ScrollBar attached
        // property only binds to a Flickable -- attaching it directly on
        // TabBar itself (a Container, not a Flickable) would be silently
        // inert. TabBar's contentItem IS that Flickable (a ListView), so
        // attach the ScrollBar there: same single source of truth for
        // scroll position, independent of where the ScrollBar instance
        // itself is parented/rendered (see the standard "non-attached"
        // ScrollBar usage pattern in the Qt Quick Controls docs).
        Component.onCompleted: {
            if (tabBar.contentItem) {
                (tabBar.contentItem as ListView).QQC2.ScrollBar.horizontal = tabBarScrollBar
            }
        }

        onCurrentIndexChanged: {
            if (root._requestedIndex === currentIndex) {
                root._requestedIndex = -1
                return
            }
            root._requestedIndex = currentIndex
            if (currentIndex === 0) {
                root._selectAll(false)
            } else if (currentIndex - 1 < root.usableProviders.length) {
                root._selectProviderAt(currentIndex - 1, root.usableProviders)
            }
        }

        QQC2.TabButton {
            text: Translation.translate("Overview", [], typeof i18n === "function" ? i18n : null)
            icon.name: "view-grid"
            focusPolicy: Qt.StrongFocus
            activeFocusOnTab: true
            Accessible.name: Translation.translate("Overview of all providers", [], typeof i18n === "function" ? i18n : null)
            Accessible.description: Translation.translate("Show compact summary for all providers", [],
                typeof i18n === "function" ? i18n : null)
        }

        Repeater {
            model: root._delegateCapacity
            delegate: QQC2.TabButton {
                required property int index

                property var providerData: index < root.usableProviders.length
                    ? root.usableProviders[index] : null
                property string providerText: root._providerText(providerData)
                property string sourceText: root._sourceText(providerData)
                // D6: finite representative usage percent for this provider,
                // or "" when none is finite -- never invented.
                property string percentText: root._percentText(providerData)
                visible: providerData !== null
                enabled: visible
                activeFocusOnTab: visible
                // Tabs stay compact: icon, short provider name, and a
                // representative usage percent when one exists (D6). The
                // full source remains available only in Accessible metadata.
                text: percentText.length > 0
                    ? Translation.translate("%1 %2", [providerText, percentText], typeof i18n === "function" ? i18n : null)
                    : providerText
                icon.source: root.iconResolver(providerData ? providerData.provider : null)
                icon.color: Kirigami.Theme.textColor
                focusPolicy: Qt.StrongFocus
                Accessible.name: {
                    var parts = [Translation.translate("%1 provider", [providerText], typeof i18n === "function" ? i18n : null)]
                    if (percentText.length > 0) {
                        parts.push(Translation.translate("%1 used", [percentText], typeof i18n === "function" ? i18n : null))
                    }
                    if (sourceText.length > 0) {
                        parts.push(Translation.translate("source %1", [sourceText], typeof i18n === "function" ? i18n : null))
                    }
                    return parts.join(", ")
                }
                Accessible.description: sourceText.length > 0
                    ? Translation.translate("Source: %1", [sourceText], typeof i18n === "function" ? i18n : null)
                    : Translation.translate("No source provided", [], typeof i18n === "function" ? i18n : null)
            }
        }
    }

    // An ordinary ColumnLayout sibling declared right after TabBar, not an
    // anchored overlay child of it: TabBar's own implicitHeight/
    // Layout.preferredHeight does not grow just because an overlay child is
    // anchored to its edges, so an anchored ScrollBar renders on top of
    // whatever comes next in the layout instead of in its own reserved
    // space. Placing it as a real layout item makes the ColumnLayout
    // reserve genuine height for it, so it always renders as a distinct
    // strip below the tab row. The functional binding to tabBar.contentItem
    // above is unaffected -- only this instance's own placement changes.
    QQC2.ScrollBar {
        id: tabBarScrollBar
        Layout.fillWidth: true
        orientation: Qt.Horizontal
        policy: QQC2.ScrollBar.AsNeeded
    }
}

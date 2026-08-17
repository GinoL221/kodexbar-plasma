pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

import "../code/ProviderIcons.js" as ProviderIcons
import "../code/Translation.js" as Translation
import "../code/UsageModel.js" as UsageModel

ColumnLayout {
    id: root

    property var providers: []
    property string phase: "idle"
    property bool popupOpen: false
    // Preferred window for the tab underline bar (Session/Weekly/Monthly/
    // Automatic). Never governs Overview body window selection.
    property string preferredWindowKey: "automatic"

    readonly property var usableProviders: root._usable(root.providers)
    readonly property bool allSelected: root._isAllSelected(root.usableProviders)
    readonly property var selectedProvider: root._resolveSelectedProvider(root.usableProviders)
    // Facade kept for harnesses / callers that drive selection via currentIndex.
    property alias tabBar: tabBar

    property bool _allSelected: true
    property int _selectedIndex: -1
    property var _selectedIdentity: undefined
    property bool _hasSelectedIdentity: false
    property bool _pendingDefault: false
    property int _requestedIndex: 0
    property int _delegateCapacity: 0

    readonly property bool tabsOverflow: tabFlick.contentWidth > tabFlick.width + 1
    readonly property bool canScrollLeft: tabFlick.contentX > 1
    readonly property bool canScrollRight: tabFlick.contentX + tabFlick.width < tabFlick.contentWidth - 1

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
        // pendingDefault only means "wait for first data, then auto-pick".
        // Once the user has chosen a tab, _pendingDefault is cleared and this
        // must not force Overview back during a slow refresh (loading).
        if (root._pendingDefault) {
            return root.phase === "loading" || usable.length === 0
        }
        return root._allSelected
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
        // User intent wins over the initial "pending Overview while loading"
        // gate — otherwise clicks during a slow refresh keep allSelected true
        // and _reconcile snaps the strip back to tab 0.
        root._pendingDefault = false
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
        if (provider && provider.provider !== null && provider.provider !== undefined) {
            return ProviderIcons.displayName(provider.provider)
        }
        return Translation.translate("Provider", [], typeof i18n === "function" ? i18n : null)
    }

    function _sourceText(provider) {
        return provider && provider.source !== null && provider.source !== undefined
            ? String(provider.source) : ""
    }

    function _representativeWindow(provider) {
        return provider ? UsageModel.selectRepresentative(provider.windows, root.preferredWindowKey) : null
    }

    function _percentValue(provider) {
        var representative = root._representativeWindow(provider)
        return representative && typeof representative.usedPercent === "number" && isFinite(representative.usedPercent)
            ? representative.usedPercent : NaN
    }

    function _percentText(provider) {
        var value = root._percentValue(provider)
        return isFinite(value) ? Math.round(value) + "%" : ""
    }

    function tabAt(index) {
        if (index === 0) {
            return overviewTab
        }
        return providerRepeater.itemAt(index - 1)
    }

    function _setIndex(index) {
        root._selectedIndex = index - 1
        root._requestedIndex = tabBar.currentIndex === index ? -1 : index
        tabBar.currentIndex = index
        root._ensureTabVisible(index)
    }

    function _ensureTabVisible(index) {
        var item = root.tabAt(index)
        if (!item || tabFlick.width <= 0) {
            return
        }
        // Selection jumps instantly so the active chip is never mid-scroll.
        // Arrow buttons keep the short animated step.
        if (tabScrollAnimation.running) {
            tabScrollAnimation.stop()
        }
        var left = item.x
        var right = item.x + item.width
        if (left < tabFlick.contentX) {
            tabFlick.contentX = Math.max(0, left)
        } else if (right > tabFlick.contentX + tabFlick.width) {
            tabFlick.contentX = Math.max(0, right - tabFlick.width)
        }
    }

    function _tabStep() {
        // One chip + row spacing — predictable arrow navigation.
        var sample = overviewTab
        var width = sample ? sample.width : Kirigami.Units.gridUnit * 4
        return width + tabRow.spacing
    }

    function _animateContentX(target) {
        var maxX = Math.max(0, tabFlick.contentWidth - tabFlick.width)
        var clamped = Math.max(0, Math.min(maxX, target))
        if (Math.abs(clamped - tabFlick.contentX) < 0.5) {
            return
        }
        if (tabScrollAnimation.running) {
            tabScrollAnimation.stop()
        }
        tabScrollAnimation.from = tabFlick.contentX
        tabScrollAnimation.to = clamped
        tabScrollAnimation.start()
    }

    function _scrollBy(delta) {
        root._animateContentX(tabFlick.contentX + delta)
    }

    function _scrollByTabs(count) {
        root._scrollBy(count * root._tabStep())
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
                // Stay on Overview only while still waiting for the first
                // auto-default — never after an explicit user provider pick.
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

    function _activateIndex(index) {
        if (root._requestedIndex === index) {
            root._requestedIndex = -1
            return
        }
        root._requestedIndex = index
        if (index === 0) {
            root._selectAll(false)
        } else if (index - 1 < root.usableProviders.length) {
            root._selectProviderAt(index - 1, root.usableProviders)
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

    // Custom tab strip (not QQC2.TabBar): Breeze paints TabButton in background
    // with contentItem:null, so vertical icon/name/bar chips need full control.
    Item {
        id: tabBar
        objectName: "providerTabBar"
        Layout.fillWidth: true
        Layout.preferredHeight: tabStripRow.implicitHeight
        implicitWidth: tabRow.implicitWidth
        implicitHeight: tabStripRow.implicitHeight

        property int currentIndex: 0
        property int count: 1 + root._delegateCapacity
        // Harness-compatible list: overview + live provider chips only.
        readonly property var contentChildren: {
            var items = [overviewTab]
            for (var i = 0; i < providerRepeater.count; i++) {
                var item = providerRepeater.itemAt(i)
                if (item) {
                    items.push(item)
                }
            }
            return items
        }

        onCurrentIndexChanged: root._ensureTabVisible(currentIndex)

        RowLayout {
            id: tabStripRow
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            QQC2.ToolButton {
                id: scrollLeftButton
                objectName: "tabScrollLeft"
                icon.name: "go-previous"
                display: QQC2.AbstractButton.IconOnly
                flat: true
                visible: root.tabsOverflow
                enabled: root.canScrollLeft
                focusPolicy: Qt.StrongFocus
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                Accessible.name: Translation.translate("Show previous providers", [], typeof i18n === "function" ? i18n : null)
                onClicked: root._scrollByTabs(-1)
            }

            Flickable {
                id: tabFlick
                Layout.fillWidth: true
                Layout.preferredHeight: tabRow.implicitHeight
                // Row (not RowLayout) so contentWidth tracks the natural chip
                // strip width instead of collapsing to the viewport.
                contentWidth: tabRow.implicitWidth
                contentHeight: tabRow.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick
                interactive: root.tabsOverflow

                NumberAnimation {
                    id: tabScrollAnimation
                    target: tabFlick
                    property: "contentX"
                    duration: Kirigami.Units.shortDuration
                    easing.type: Easing.OutCubic
                }

                Row {
                    id: tabRow
                    spacing: Math.max(2, Math.round(Kirigami.Units.smallSpacing / 2))

                    QQC2.ItemDelegate {
                        id: overviewTab
                        objectName: "overviewTab"
                        checkable: true
                        checked: tabBar.currentIndex === 0
                        focusPolicy: Qt.StrongFocus
                        activeFocusOnTab: true
                        width: Kirigami.Units.gridUnit * 5
                        implicitWidth: width
                        padding: Kirigami.Units.smallSpacing
                        text: Translation.translate("Overview", [], typeof i18n === "function" ? i18n : null)
                        Accessible.name: Translation.translate("Overview of all providers", [], typeof i18n === "function" ? i18n : null)
                        Accessible.description: Translation.translate("Show compact summary for all providers", [],
                            typeof i18n === "function" ? i18n : null)
                        Accessible.role: Accessible.PageTab
                        icon.name: "view-grid"
                        onClicked: {
                            tabBar.currentIndex = 0
                            root._activateIndex(0)
                        }

                        contentItem: ColumnLayout {
                            spacing: Math.max(1, Math.round(Kirigami.Units.smallSpacing / 3))

                            Kirigami.Icon {
                                source: overviewTab.icon.name
                                isMask: true
                                color: overviewTab.checked
                                    ? Kirigami.Theme.highlightedTextColor
                                    : Kirigami.Theme.textColor
                                implicitWidth: Kirigami.Units.iconSizes.medium
                                implicitHeight: Kirigami.Units.iconSizes.medium
                                Layout.alignment: Qt.AlignHCenter
                            }

                            PlasmaComponents.Label {
                                text: overviewTab.text
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                font.weight: Font.Medium
                                color: overviewTab.checked
                                    ? Kirigami.Theme.highlightedTextColor
                                    : Kirigami.Theme.textColor
                                Layout.fillWidth: true
                            }

                            // Spacer matches provider tab underline height so chips align.
                            Item {
                                Layout.fillWidth: true
                                Layout.leftMargin: Kirigami.Units.smallSpacing
                                Layout.rightMargin: Kirigami.Units.smallSpacing
                                Layout.topMargin: Math.max(2, Math.round(Kirigami.Units.smallSpacing / 3))
                                Layout.preferredHeight: Math.max(4, Math.round(Kirigami.Units.smallSpacing * 0.7))
                            }
                        }

                        background: Rectangle {
                            radius: Kirigami.Units.cornerRadius
                            color: overviewTab.checked
                                ? Kirigami.Theme.highlightColor
                                : (overviewTab.hovered ? Kirigami.Theme.alternateBackgroundColor : "transparent")
                        }
                    }

                    Repeater {
                        id: providerRepeater
                        model: root._delegateCapacity

                        delegate: QQC2.ItemDelegate {
                            id: providerTab
                            required property int index

                            property var providerData: index < root.usableProviders.length
                                ? root.usableProviders[index] : null
                            property string providerText: root._providerText(providerData)
                            property string sourceText: root._sourceText(providerData)
                            property string percentText: root._percentText(providerData)
                            property real percentValue: root._percentValue(providerData)
                            property bool hasFinitePercent: isFinite(percentValue)

                            // Visible label is name only — percent is the underline bar + a11y.
                            text: providerText
                            visible: providerData !== null
                            enabled: visible
                            checkable: true
                            checked: tabBar.currentIndex === index + 1
                            focusPolicy: Qt.StrongFocus
                            activeFocusOnTab: visible
                            width: Kirigami.Units.gridUnit * 5
                            implicitWidth: width
                            padding: Kirigami.Units.smallSpacing
                            Accessible.role: Accessible.PageTab
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

                            icon.source: root.iconResolver(providerData ? providerData.provider : null)
                            icon.color: Kirigami.Theme.textColor

                            onClicked: {
                                tabBar.currentIndex = index + 1
                                root._activateIndex(index + 1)
                            }

                            contentItem: ColumnLayout {
                                spacing: Math.max(1, Math.round(Kirigami.Units.smallSpacing / 3))

                                Kirigami.Icon {
                                    source: providerTab.icon.source
                                    isMask: true
                                    color: providerTab.checked
                                        ? Kirigami.Theme.highlightedTextColor
                                        : Kirigami.Theme.textColor
                                    implicitWidth: Kirigami.Units.iconSizes.medium
                                    implicitHeight: Kirigami.Units.iconSizes.medium
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                PlasmaComponents.Label {
                                    text: providerTab.text
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                                    font.weight: Font.Medium
                                    color: providerTab.checked
                                        ? Kirigami.Theme.highlightedTextColor
                                        : Kirigami.Theme.textColor
                                    Layout.fillWidth: true
                                    Layout.bottomMargin: Kirigami.Units.smallSpacing / 2
                                }

                                Item {
                                    id: tabUsageBar
                                    objectName: "tabUsageBar"
                                    visible: providerTab.hasFinitePercent
                                    Layout.fillWidth: true
                                    // Inset from chip sides + gap under the name.
                                    readonly property int sideInset: Kirigami.Units.smallSpacing
                                    readonly property int nameGap: Math.max(2, Math.round(Kirigami.Units.smallSpacing / 3))
                                    Layout.leftMargin: sideInset
                                    Layout.rightMargin: sideInset
                                    Layout.topMargin: nameGap
                                    Layout.preferredHeight: Math.max(4, Math.round(Kirigami.Units.smallSpacing * 0.7))
                                    readonly property real value: providerTab.hasFinitePercent ? providerTab.percentValue : 0
                                    readonly property real ratio: Math.max(0, Math.min(1, value / 100))

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: height / 2
                                        color: providerTab.checked
                                            ? Kirigami.Theme.highlightedTextColor
                                            : Kirigami.Theme.disabledTextColor
                                        opacity: 0.28
                                    }

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: parent.width > 0 ? Math.round(parent.width * tabUsageBar.ratio) : 0
                                        radius: height / 2
                                        color: providerTab.checked
                                            ? Kirigami.Theme.highlightedTextColor
                                            : Kirigami.Theme.highlightColor
                                    }
                                }

                                Item {
                                    visible: !providerTab.hasFinitePercent
                                    Layout.fillWidth: true
                                    Layout.leftMargin: Kirigami.Units.smallSpacing
                                    Layout.rightMargin: Kirigami.Units.smallSpacing
                                    Layout.topMargin: Math.max(2, Math.round(Kirigami.Units.smallSpacing / 3))
                                    Layout.preferredHeight: Math.max(4, Math.round(Kirigami.Units.smallSpacing * 0.7))
                                }
                            }

                            background: Rectangle {
                                radius: Kirigami.Units.cornerRadius
                                color: providerTab.checked
                                    ? Kirigami.Theme.highlightColor
                                    : (providerTab.hovered ? Kirigami.Theme.alternateBackgroundColor : "transparent")
                            }
                        }
                    }
                }
            }

            QQC2.ToolButton {
                id: scrollRightButton
                objectName: "tabScrollRight"
                icon.name: "go-next"
                display: QQC2.AbstractButton.IconOnly
                flat: true
                visible: root.tabsOverflow
                enabled: root.canScrollRight
                focusPolicy: Qt.StrongFocus
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                Accessible.name: Translation.translate("Show next providers", [], typeof i18n === "function" ? i18n : null)
                onClicked: root._scrollByTabs(1)
            }
        }
    }
}

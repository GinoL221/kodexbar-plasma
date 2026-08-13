import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

import "../code/ProviderIcons.js" as ProviderIcons
import "../code/Translation.js" as Translation

ColumnLayout {
    id: root

    property var providers: []
    property string phase: "idle"
    property bool popupOpen: false

    readonly property var usableProviders: _usable(root.providers)
    readonly property bool allSelected: _isAllSelected(root.usableProviders)
    readonly property var selectedProvider: _resolveSelectedProvider(root.usableProviders)
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
            ? root.phase === "loading" || usable.length === 0 : _allSelected
    }

    function _resolveSelectedProvider(usable) {
        if (root.allSelected) {
            return null
        }
        if (_pendingDefault) {
            return _firstUsable(usable)
        }
        if (_hasSelectedIdentity) {
            for (var i = 0; i < usable.length; i++) {
                if (usable[i].provider === _selectedIdentity) {
                    return usable[i]
                }
            }
        }
        return _selectedIndex >= 0 && _selectedIndex < usable.length ? usable[_selectedIndex] : null
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
        _setIndex(0)
    }

    function _selectFirstOrAll(usable) {
        var first = _firstUsable(usable)
        if (first === null) {
            _selectAll(false)
            return
        }
        root._pendingDefault = false
        root._allSelected = false
        root._selectedIndex = 0
        root._selectedIdentity = first.provider
        root._hasSelectedIdentity = true
        _setIndex(1)
    }

    function _selectProviderAt(index, usable) {
        root._allSelected = false
        root._selectedIndex = index
        root._selectedIdentity = usable[index].provider
        root._hasSelectedIdentity = true
        _setIndex(index + 1)
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

    function _setIndex(index) {
        root._selectedIndex = index - 1
        root._requestedIndex = tabBar.currentIndex === index ? -1 : index
        tabBar.currentIndex = index
    }

    function _selectDefault() {
        if (root.phase === "loading") {
            _selectAll(true)
            return
        }
        _selectFirstOrAll(root.usableProviders)
    }

    function _reconcile() {
        if (!root.popupOpen) {
            return
        }
        var usable = root._usable(root.providers)
        if (root._pendingDefault) {
            if (root.phase === "loading") {
                _setIndex(0)
                return
            }
            _selectFirstOrAll(usable)
            return
        }
        if (root._allSelected) {
            _setIndex(0)
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
            _selectFirstOrAll(usable)
        } else {
            root._selectedIndex = target
            _setIndex(target + 1)
        }
    }

    onPopupOpenChanged: {
        if (root.popupOpen) {
            _selectDefault()
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

    QQC2.ScrollView {
        Layout.fillWidth: true
        clip: true
        QQC2.TabBar {
            id: tabBar
            width: Math.min(implicitWidth, root.width)
            focusPolicy: Qt.StrongFocus
            activeFocusOnTab: true
            currentIndex: 0

            onCurrentIndexChanged: {
                if (root._requestedIndex === currentIndex) {
                    root._requestedIndex = -1
                    return
                }
                root._requestedIndex = currentIndex
                if (currentIndex === 0) {
                    _selectAll(false)
                } else if (currentIndex - 1 < root.usableProviders.length) {
                    _selectProviderAt(currentIndex - 1, root.usableProviders)
                }
            }

            QQC2.TabButton {
                text: Translation.translate("All", [], typeof i18n === "function" ? i18n : null)
                icon.name: "view-list-details"
                focusPolicy: Qt.StrongFocus
                activeFocusOnTab: true
                Accessible.name: Translation.translate("All providers", [], typeof i18n === "function" ? i18n : null)
                Accessible.description: Translation.translate("Show compact summary for all providers", [],
                    typeof i18n === "function" ? i18n : null)
            }

            Repeater {
                model: root._delegateCapacity
                delegate: QQC2.TabButton {
                    property var providerData: index < root.usableProviders.length
                        ? root.usableProviders[index] : null
                    property string providerText: root._providerText(providerData)
                    property string sourceText: root._sourceText(providerData)
                    visible: providerData !== null
                    enabled: visible
                    activeFocusOnTab: visible
                    text: sourceText.length > 0 ? providerText + " · " + sourceText : providerText
                    icon.source: root.iconResolver(providerData ? providerData.provider : null)
                    focusPolicy: Qt.StrongFocus
                    Accessible.name: sourceText.length > 0
                        ? Translation.translate("%1 provider, source %2", [providerText, sourceText],
                            typeof i18n === "function" ? i18n : null)
                        : Translation.translate("%1 provider", [providerText], typeof i18n === "function" ? i18n : null)
                    Accessible.description: sourceText.length > 0
                        ? Translation.translate("Source: %1", [sourceText], typeof i18n === "function" ? i18n : null)
                        : Translation.translate("No source provided", [], typeof i18n === "function" ? i18n : null)
                }
            }
        }
    }
}

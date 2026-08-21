pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Window
import org.kde.kirigami as Kirigami

Item {
    id: root

    property url source
    property color color: Kirigami.Theme.textColor
    readonly property bool usesSvgRenderer: String(root.source).toLowerCase().indexOf(".svg") !== -1
    readonly property bool svgLoadFailed: root.usesSvgRenderer && providerImage.status === Image.Error
    readonly property bool usingFallback: !root.usesSvgRenderer || root.svgLoadFailed
    readonly property alias imageStatus: providerImage.status
    readonly property alias sourcePixelSize: providerImage.sourceSize
    readonly property alias renderedSvg: svgEffect

    implicitWidth: Kirigami.Units.iconSizes.smallMedium
    implicitHeight: Kirigami.Units.iconSizes.smallMedium

    Image {
        id: providerImage
        objectName: "providerSvgImage"
        anchors.fill: parent
        visible: false
        source: root.usesSvgRenderer ? root.source : ""
        sourceSize: Qt.size(
            Math.max(1, Math.ceil(width * Screen.devicePixelRatio)),
            Math.max(1, Math.ceil(height * Screen.devicePixelRatio)))
        fillMode: Image.PreserveAspectFit
        asynchronous: false
        smooth: true
    }

    MultiEffect {
        id: svgEffect
        anchors.fill: parent
        visible: root.usesSvgRenderer && !root.svgLoadFailed
        source: providerImage
        brightness: 1.0
        colorization: 1.0
        colorizationColor: root.color
    }

    Kirigami.Icon {
        objectName: "providerFallbackIcon"
        anchors.fill: parent
        visible: root.usingFallback
        source: root.svgLoadFailed ? "dialog-information" : (visible ? root.source : "")
        isMask: true
        color: root.color
    }
}

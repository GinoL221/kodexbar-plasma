import QtQuick
import QtQuick.Layouts
import QtTest
import org.kde.kirigami as Kirigami
import "../contents/ui" as UsageUi

TestCase {
    id: testCase

    name: "ProviderSelectorIconRender"
    width: 360
    height: 160
    visible: true
    when: windowShown

    UsageUi.ProviderSelector {
        id: selector
        width: 320
        providers: [{
            provider: "claude",
            source: "integration-test",
            windows: [{ label: "Weekly", usedPercent: 42 }]
        }]
        phase: "ready"
        popupOpen: true
    }

    function findObject(item, name) {
        if (!item) return null
        if (item.objectName === name) return item
        for (var index = 0; index < item.children.length; index++) {
            var result = findObject(item.children[index], name)
            if (result !== null) return result
        }
        return null
    }

    function test_provider_tab_lays_out_and_renders_icon() {
        tryCompare(selector.tabBar, "count", 2)
        var providerTab = selector.tabBar.contentChildren[1]
        verify(providerTab !== null && providerTab.visible)
        selector.tabBar.currentIndex = 1
        selector._activateIndex(1)
        tryCompare(providerTab, "checked", true)

        var icon = findObject(providerTab, "providerTabIcon")
        verify(icon !== null, "Provider tab must contain the shared provider icon")
        tryCompare(icon, "imageStatus", Image.Ready)
        waitForRendering(providerTab)
        wait(50)

        compare(icon.width, Kirigami.Units.iconSizes.smallMedium)
        compare(icon.height, Kirigami.Units.iconSizes.smallMedium)
        compare(icon.Layout.minimumWidth, Kirigami.Units.iconSizes.smallMedium)
        compare(icon.Layout.minimumHeight, Kirigami.Units.iconSizes.smallMedium)
        compare(icon.Layout.preferredWidth, Kirigami.Units.iconSizes.smallMedium)
        compare(icon.Layout.preferredHeight, Kirigami.Units.iconSizes.smallMedium)
        verify(icon.renderedSvg.width > 0 && icon.renderedSvg.height > 0,
            "Provider tab effect must inherit the laid-out icon geometry")

        var rendered = grabImage(providerTab)
        var iconPosition = icon.mapToItem(providerTab, 0, 0)
        var centerX = Math.floor(iconPosition.x + icon.width / 2)
        var centerY = Math.floor(iconPosition.y + icon.height / 2)
        var cornerX = Math.floor(iconPosition.x)
        var cornerY = Math.floor(iconPosition.y)
        verify(rendered.alpha(centerX, centerY) > 230,
            "Provider tab foreground pixel must be opaque")
        verify(Math.abs(rendered.red(centerX, centerY) - Math.round(icon.color.r * 255)) < 8
                && Math.abs(rendered.green(centerX, centerY) - Math.round(icon.color.g * 255)) < 8
                && Math.abs(rendered.blue(centerX, centerY) - Math.round(icon.color.b * 255)) < 8,
            "Provider tab foreground pixel must use the delegate tint")
        verify(rendered.alpha(cornerX, cornerY) < 13
                || Math.abs(rendered.red(cornerX, cornerY) - Math.round(icon.color.r * 255)) > 20
                || Math.abs(rendered.green(cornerX, cornerY) - Math.round(icon.color.g * 255)) > 20
                || Math.abs(rendered.blue(cornerX, cornerY) - Math.round(icon.color.b * 255)) > 20,
            "Provider tab SVG corner must remain transparent over the delegate background")

        var backgroundRed = rendered.red(cornerX, cornerY)
        var backgroundGreen = rendered.green(cornerX, cornerY)
        var backgroundBlue = rendered.blue(cornerX, cornerY)
        var tintRed = Math.round(icon.color.r * 255)
        var tintGreen = Math.round(icon.color.g * 255)
        var tintBlue = Math.round(icon.color.b * 255)
        var partialEdgePixels = 0
        for (var y = Math.max(0, cornerY); y < Math.min(rendered.height, cornerY + icon.height); y++) {
            for (var x = Math.max(0, cornerX); x < Math.min(rendered.width, cornerX + icon.width); x++) {
                var differsFromTint = Math.abs(rendered.red(x, y) - tintRed) > 8
                    || Math.abs(rendered.green(x, y) - tintGreen) > 8
                    || Math.abs(rendered.blue(x, y) - tintBlue) > 8
                var differsFromBackground = Math.abs(rendered.red(x, y) - backgroundRed) > 8
                    || Math.abs(rendered.green(x, y) - backgroundGreen) > 8
                    || Math.abs(rendered.blue(x, y) - backgroundBlue) > 8
                if (differsFromTint && differsFromBackground) {
                    partialEdgePixels++
                }
            }
        }
        verify(partialEdgePixels > 0,
            "Provider tab icon must retain partially transparent antialiased edge pixels")
    }
}

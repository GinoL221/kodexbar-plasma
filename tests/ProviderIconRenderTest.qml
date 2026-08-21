import QtQuick
import QtQuick.Window
import QtTest
import "../contents/ui" as UsageUi

TestCase {
    id: testCase

    name: "ProviderIconRender"
    width: 220
    height: 120
    visible: true
    when: windowShown

    Rectangle {
        id: canvas
        width: 100
        height: 100
        color: "#00ff00"

        UsageUi.ProviderIcon {
            id: icon
            anchors.fill: parent
            source: Qt.resolvedUrl("../contents/icons/providers/claude.svg")
            color: "#ff00ff"
        }
    }

    UsageUi.ProviderIcon {
        id: missingIcon
        x: 120
        width: 100
        height: 100
        source: Qt.resolvedUrl("../contents/icons/providers/missing-provider.svg")
        color: "#00ffff"
    }

    function test_svg_pixels_preserve_transparency_and_tint() {
        tryCompare(icon, "imageStatus", Image.Ready)
        waitForRendering(canvas)
        wait(50)

        var rendered = grabImage(canvas)
        compare(rendered.width, 100)
        compare(rendered.height, 100)
        compare(icon.sourcePixelSize.width,
            Math.ceil(icon.width * icon.Screen.devicePixelRatio))
        compare(icon.sourcePixelSize.height,
            Math.ceil(icon.height * icon.Screen.devicePixelRatio))

        var foregroundAlpha = rendered.alpha(50, 50)
        var foregroundRed = rendered.red(50, 50)
        var foregroundGreen = rendered.green(50, 50)
        var foregroundBlue = rendered.blue(50, 50)
        verify(rendered.green(0, 0) > 230 && rendered.red(0, 0) < 25
                && rendered.blue(0, 0) < 25,
            "Transparent SVG corner must reveal the green background; an opaque square must fail")
        verify(foregroundAlpha > 230, "Claude center pixel must remain opaque")
        verify(foregroundRed > foregroundGreen + 50 && foregroundBlue > foregroundGreen + 50,
            "Claude foreground pixel must use the contrasting magenta tint: "
            + foregroundRed + "," + foregroundGreen + "," + foregroundBlue)

        var partialEdgePixels = 0
        for (var y = 0; y < rendered.height; y++) {
            for (var x = 0; x < rendered.width; x++) {
                var red = rendered.red(x, y)
                var green = rendered.green(x, y)
                var blue = rendered.blue(x, y)
                if (red > 5 && red < 250 && green > 5 && green < 250
                        && blue > 5 && blue < 250) {
                    partialEdgePixels++
                }
            }
        }
        verify(partialEdgePixels > 0,
            "Claude SVG must retain partially transparent antialiased edge pixels")
    }

    function test_failed_svg_load_uses_themed_fallback() {
        tryCompare(missingIcon, "imageStatus", Image.Error)
        verify(missingIcon.svgLoadFailed)
        verify(missingIcon.usingFallback,
            "A failed provider SVG must switch to the themed fallback icon")
    }
}

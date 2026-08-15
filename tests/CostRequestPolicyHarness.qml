import QtQuick
import "../contents/code/CostRequestPolicy.js" as CostRequestPolicy

Item {
    property bool assertionFailed: false

    function assert(condition, message) {
        if (!condition) {
            console.error("CostRequestPolicyHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    Component.onCompleted: {
        // "All" must never start cost work, regardless of provider/generation/snapshot state.
        assert(CostRequestPolicy.shouldRequestCost(true, "codex", 1, false) === false,
               "All selected must never request cost")
        assert(CostRequestPolicy.shouldRequestCost(true, null, 0, false) === false,
               "All selected with no provider must never request cost")

        // An unsupported provider must never be requested.
        assert(CostRequestPolicy.shouldRequestCost(false, "gpt4", 1, false) === false,
               "an unsupported provider must never request cost")
        assert(CostRequestPolicy.shouldRequestCost(false, null, 1, false) === false,
               "a null provider must never request cost")

        // A supported provider with no usage generation yet must not request.
        assert(CostRequestPolicy.shouldRequestCost(false, "codex", 0, false) === false,
               "an unset usage generation must never request cost")

        // A supported provider missing its current-generation snapshot must request.
        assert(CostRequestPolicy.shouldRequestCost(false, "codex", 3, false) === true,
               "a supported provider missing its snapshot must request cost")
        assert(CostRequestPolicy.shouldRequestCost(false, "claude", 3, false) === true,
               "claude is also a supported provider")

        // A fresh existing snapshot must not trigger a duplicate request.
        assert(CostRequestPolicy.shouldRequestCost(false, "codex", 3, true) === false,
               "an already-fresh snapshot must not request cost again")

        finish()
    }
}

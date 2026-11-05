import QtQuick
import "../contents/code/RateLimitPolicy.js" as RateLimitPolicy

Item {
    property bool assertionFailed: false

    function assert(condition, message) {
        if (!condition) {
            console.error("RateLimitPolicyHarness failure: " + message)
            assertionFailed = true
            Qt.exit(1)
            throw new Error(message)
        }
    }

    function finish() { Qt.exit(assertionFailed ? 1 : 0) }

    function assertIds(actual, expected, message) {
        var ok = actual instanceof Array && actual.length === expected.length
        for (var i = 0; ok && i < expected.length; i++) {
            ok = actual[i] === expected[i]
        }
        assert(ok, message + " (got: " + JSON.stringify(actual) + ")")
    }

    Component.onCompleted: {
        // Detection: CLI-contract provider error entries. Code 3 with the
        // observed CLI shape is the empirical rate-limit signal.
        assert(RateLimitPolicy.isRateLimitError({ provider: "claude", error: { kind: "provider", code: 3, message: "429 rate limit exceeded, retry later" } }),
            "the observed CLI code 3 shape must be treated as a rate limit")
        assert(RateLimitPolicy.isRateLimitError({ provider: "claude", error: { kind: "api_error", message: "rate_limit_error: too many requests" } }),
            "a rate limit message must be detected")
        assert(RateLimitPolicy.isRateLimitError({ provider: "claude", error: { kind: "api_error", message: "Rate_Limit hit" } }),
            "rate limit detection must be case-insensitive and accept underscores")
        assert(RateLimitPolicy.isRateLimitError({ provider: "claude", error: { kind: "api_error", message: "rate-limit exceeded" } }),
            "rate limit detection must accept hyphenated messages")
        assert(RateLimitPolicy.isRateLimitError({ provider: "claude", error: { kind: "api_error", message: "HTTP 429 received" } }),
            "a 429 message must be detected")
        assert(!RateLimitPolicy.isRateLimitError({ provider: "claude", error: { kind: "api_error", message: "Context length exceeded: 4290 tokens" } }),
            "a message with 4290 tokens must not match rate limit")
        assert(!RateLimitPolicy.isRateLimitError({ provider: "claude", error: { kind: "api_error", message: "Prompt size 1429 bytes" } }),
            "a message with 1429 bytes must not match rate limit")
        assert(!RateLimitPolicy.isRateLimitError({ provider: "claude" }),
            "an entry without an error must not be a rate limit")
        assert(!RateLimitPolicy.isRateLimitError(null), "a null entry must not be a rate limit")
        assert(!RateLimitPolicy.isRateLimitError({ provider: "claude", error: { kind: "provider", message: "CLI missing" } }),
            "an unrelated provider error must not be a rate limit")
        assert(!RateLimitPolicy.isRateLimitError({ provider: "claude", error: { kind: "api_error", code: 1, message: "auth expired" } }),
            "an unrelated API error must not be a rate limit")
        assert(!RateLimitPolicy.isRateLimitError({ provider: "claude", error: { kind: "api_error" } }),
            "an error without code or message must not be a rate limit")

        // hasRateLimitError: at least one entry must be a rate limit. The
        // real CLI payload mixes one rate limit into dozens of unrelated
        // provider errors, so "all entries" semantics would never fire.
        assert(!RateLimitPolicy.hasRateLimitError([]), "an empty error list must not count as rate limited")
        assert(!RateLimitPolicy.hasRateLimitError(null), "a missing error list must not count as rate limited")
        assert(!RateLimitPolicy.hasRateLimitError("rate limit"), "a non-array must not count as rate limited")
        assert(RateLimitPolicy.hasRateLimitError([
            { provider: "claude", error: { kind: "provider", code: 3, message: "rate_limit_error: throttled" } }
        ]), "a single rate limit error must count as rate limited")
        assert(RateLimitPolicy.hasRateLimitError([
            { provider: "codex", error: { code: 1, message: "No available fetch strategy for openai." } },
            { provider: "claude", error: { kind: "provider", code: 3, message: "rate_limit_error: throttled" } },
            { provider: "zed", error: { code: 1, message: "Zed is only supported on macOS." } }
        ]), "a mixed error list with one rate limit must count as rate limited")
        assert(!RateLimitPolicy.hasRateLimitError([
            { provider: "codex", error: { code: 1, message: "No available fetch strategy for openai." } },
            { provider: "zed", error: { code: 1, message: "Zed is only supported on macOS." } }
        ]), "an error list without any rate limit must not count as rate limited")

        // rateLimitedProviderIds: unique non-empty provider strings of the
        // rate-limited entries only, in first-seen order.
        assertIds(RateLimitPolicy.rateLimitedProviderIds([]), [], "an empty error list must yield no provider ids")
        assertIds(RateLimitPolicy.rateLimitedProviderIds(null), [], "a missing error list must yield no provider ids")
        assertIds(RateLimitPolicy.rateLimitedProviderIds("rate limit"), [], "a non-array must yield no provider ids")
        assertIds(RateLimitPolicy.rateLimitedProviderIds([
            { provider: "zed", error: { code: 1, message: "unrelated" } },
            { provider: "claude", error: { code: 3, message: "rate_limit_error: throttled" } },
            { provider: "codex", error: { message: "HTTP 429 received" } },
            { provider: "claude", error: { message: "rate limited again" } },
            { error: { message: "rate limit without a provider" } },
            { provider: 42, error: { message: "rate limit with a non-string provider" } }
        ]), ["claude", "codex"],
            "rate-limited ids must be unique, ordered, and skip missing or non-string providers")

        // mergeRateLimitedProviders: fresh entries always win, a throttled
        // provider keeps its previous entry, and nothing is fabricated.
        var previous = [
            { provider: "claude", raw: { usage: { primary: { usedPercent: 12 } } } },
            { provider: "codex", raw: { usage: { primary: { usedPercent: 20 } } } }
        ]
        var merged = RateLimitPolicy.mergeRateLimitedProviders(
            [{ provider: "codex", raw: { usage: { primary: { usedPercent: 25 } } } }],
            previous,
            [
                { provider: "claude", error: { code: 3, message: "rate_limit_error: throttled" } },
                { provider: "zed", error: { code: 1, message: "unsupported on Linux" } }
            ])
        assert(merged.length === 2, "the merge must keep fresh providers plus preserved throttled ones")
        assert(merged[0].provider === "codex" && merged[0].raw.usage.primary.usedPercent === 25,
            "fresh providers must win over their previous entry")
        assert(merged[1].provider === "claude" && merged[1].raw.usage.primary.usedPercent === 12,
            "the throttled provider must keep its previous snapshot after the fresh ones")
        assert(RateLimitPolicy.mergeRateLimitedProviders(
            [], [], [{ provider: "kimi", error: { code: 3, message: "rate limit" } }]).length === 0,
            "a throttled provider without a previous entry must not be fabricated")
        assert(RateLimitPolicy.mergeRateLimitedProviders(null, null, []).length === 0,
            "missing provider lists must merge to an empty list")
        assert(RateLimitPolicy.mergeRateLimitedProviders(
            [{ provider: "codex", raw: {} }], previous, []).length === 1,
            "without a rate limit the previous entries must be dropped")

        // backoffDelayMs: 2 min doubling, capped at 30 min (reached on the
        // fifth consecutive strike: 2 min * 2^4 = 32 min > 30 min).
        assert(RateLimitPolicy.backoffDelayMs(0) === 0, "zero consecutive rate limits must not back off")
        assert(RateLimitPolicy.backoffDelayMs(-1) === 0, "negative input must not back off")
        assert(RateLimitPolicy.backoffDelayMs(NaN) === 0, "NaN input must not back off")
        assert(RateLimitPolicy.backoffDelayMs(1) === 120000, "the first backoff step must be 2 minutes")
        assert(RateLimitPolicy.backoffDelayMs(2) === 240000, "the second backoff step must be 4 minutes")
        assert(RateLimitPolicy.backoffDelayMs(3) === 480000, "the third backoff step must be 8 minutes")
        assert(RateLimitPolicy.backoffDelayMs(4) === 960000, "the fourth backoff step must be 16 minutes")
        assert(RateLimitPolicy.backoffDelayMs(5) === RateLimitPolicy.MAX_DELAY_MS,
            "the fifth backoff step must cap at 30 minutes")
        assert(RateLimitPolicy.backoffDelayMs(10) === RateLimitPolicy.MAX_DELAY_MS,
            "deep consecutive rate limits must stay capped at 30 minutes")

        // parseRetryAfterMs: seconds or HTTP-date, null when not actionable.
        assert(RateLimitPolicy.parseRetryAfterMs(0) === null, "retry-after 0 must not be actionable")
        assert(RateLimitPolicy.parseRetryAfterMs("0") === null, "retry-after '0' must not be actionable")
        assert(RateLimitPolicy.parseRetryAfterMs(-5) === null, "a negative retry-after must be rejected")
        assert(RateLimitPolicy.parseRetryAfterMs(null) === null, "a missing retry-after must be rejected")
        assert(RateLimitPolicy.parseRetryAfterMs("soon") === null, "an unparsable retry-after must be rejected")
        assert(RateLimitPolicy.parseRetryAfterMs("Wed, 21 Oct 2015 07:28:00 GMT") === null,
            "a past HTTP-date retry-after must be rejected")
        assert(RateLimitPolicy.parseRetryAfterMs(30) === 30000, "a numeric retry-after must convert seconds to milliseconds")
        assert(RateLimitPolicy.parseRetryAfterMs("120") === 120000, "a numeric string retry-after must convert seconds to milliseconds")
        var future = new Date(Date.now() + 3600000).toUTCString()
        var parsed = RateLimitPolicy.parseRetryAfterMs(future)
        assert(parsed !== null && parsed > 3500000 && parsed <= 3600000,
            "a future HTTP-date retry-after must convert to remaining milliseconds")

        // nextDelayMs: never below the base, retry-after wins when larger.
        assert(RateLimitPolicy.nextDelayMs(60000, 0, "") === 60000, "without rate limits the configured interval must hold")
        assert(RateLimitPolicy.nextDelayMs(0, 0, "") === 0, "without a base or rate limits the delay must be zero")
        assert(RateLimitPolicy.nextDelayMs(60000, 1, "") === 120000, "the first rate limit must back off to 2 minutes")
        assert(RateLimitPolicy.nextDelayMs(10000, 1, "") === 120000, "a small configured interval must not weaken the backoff")
        assert(RateLimitPolicy.nextDelayMs(60000, 2, "300") === 300000, "a larger retry-after must win over the backoff")
        assert(RateLimitPolicy.nextDelayMs(60000, 2, "0") === 240000, "retry-after 0 must fall back to the backoff delay")

        // retryMinutes: user-facing whole-minute ceiling.
        assert(RateLimitPolicy.retryMinutes(0) === 1, "a zero delay must still communicate at least one minute")
        assert(RateLimitPolicy.retryMinutes(59000) === 1, "a sub-minute delay must communicate one minute")
        assert(RateLimitPolicy.retryMinutes(120000) === 2, "exact minutes must not round up")
        assert(RateLimitPolicy.retryMinutes(1800000) === 30, "the capped delay must communicate thirty minutes")
        assert(RateLimitPolicy.retryMinutes(1800001) === 31, "anything above the cap must round up")
        finish()
    }
}

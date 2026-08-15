# Design: CLI Contract Fixtures & Enrichment-Ready Normalization

## Technical Approach

One additive key on `normalizeProvider`'s return value, one real redacted capture committed as evidence, one capture-procedure doc, one README paragraph, five new QtTest functions. No UI, no controller change, no `normalizeWindow` change, no CLI invocation change.

The mechanism is deliberately field-name-free: `raw` is whatever the CLI sent for that provider entry, so an upstream schema change degrades to "different contents under `raw`" rather than a normalization rewrite.

## Architecture Decisions

### AD-1 (resolved): `raw` holds a live reference to the parsed entry, not a defensive copy

**Decision: `raw: entry` — a live reference. No cloning helper is added.**

Five independent lines of evidence, all from the code as it exists today:

1. **The file already stores live references to parsed sub-objects, and always has.** `contents/code/UsageModel.js:71` puts `error: entry.error` into the errors array — `error` is an object (`{kind, code, message}`; see the real capture's `openai` entry). `UsageModel.js:30-31` (`resetsAt`, `resetDescription` via `rawValue`) returns whatever the payload held, by reference, for any non-scalar. A copied `raw` would make the new key the *only* defensively-cloned value in a file whose established convention is verbatim reference passthrough.

2. **Reference identity is already an asserted contract in this suite.** `UsageModel.js:160-164` (`selectCompact`) stores `provider: provider` — the normalized provider object itself — and `tests/UsageModelHarness.qml:41` asserts `compact.provider === normalized.providers[0]`. Object identity is load-bearing and tested here, not incidental.

3. **Nothing downstream mutates the parsed payload or the normalized snapshot.** `contents/ui/UsageController.qml:237` creates a fresh `payload` per response via `JSON.parse`, `:243` normalizes it, `:244-245` assigns `normalized.providers` / `normalized.errors` to `committedProviders` / `committedErrors`, and `payload` then leaves scope — it is never retained, re-read, or written. The only consumers are `contents/ui/main.qml:24` (`selectCompact`, read-only), `:106` (`providers:` binding), and `:135` (`errors:` binding). A repository-wide search for assignments into provider/window fields (`provider.<x> =`, `providers[...]`, `.windows =`, `modelData.<x> =`) under `contents/` returns nothing. There is no mutating consumer to defend against.

4. **The common `JSON.parse(JSON.stringify(x))` idiom would make `raw` factually non-verbatim, breaking the spec.** A JSON round-trip converts `Infinity` and `NaN` to `null` and erases `undefined`. This suite deliberately feeds exactly those values (`tests/UsageModelTest.qml:73`, `:132-134`, `:147-150`, `:178`, `tests/UsageModelHarness.qml:25`). Under a round-trip copy, an entry whose `usage.secondary.usedPercent` is `Infinity` would surface as `null` inside `raw` — directly contradicting the spec scenario "Verbatim passthrough of unmodeled provider fields" ("preserved unmodified"). The cheap idiom is not merely unnecessary here; it is **wrong**. A hand-written structural deep clone would avoid that but adds recursive code and a depth risk to buy a defense against a mutation that does not exist.

5. **QML property semantics gain nothing from a copy.** `committedProviders` is a `property var` (`UsageController.qml:23`). Change notification fires on assignment, not on deep mutation, and a whole new array is assigned per response. A deep copy would not improve change detection, and it would cost a second full serialize+parse of the entire payload (13.4 KB compact in the real capture) on every refresh tick, forever, for no observable benefit.

**Invariant this decision establishes** (to be stated in code and in the README/spec prose): *normalized snapshots are read-only. A future consumer that needs to mutate CLI data must clone at the consumption site.* If a mutating consumer is ever introduced, that is the change that pays for the clone — not this one.

### AD-2: `raw` is provider-level only; error entries do not gain it

`normalize()`'s error branch (`UsageModel.js:67-74`) keeps returning exactly `{provider, source, error}`. `error` already carries the full CLI error object verbatim, so a `raw` sibling there would be pure duplication. This matches the spec scenario "Error entries remain unaffected by raw addition".

### AD-3: The committed fixture is evidence, not test input

The new QtTest functions use inline object literals shaped from the real capture. They do **not** read `tests/fixtures/codexbar-usage-capture.json` from disk. No QML test in this repository loads a file at runtime, and introducing an `XMLHttpRequest`-based fixture loader is unjustified scope for this change. The fixture's job is to answer "what does the CLI actually return?" for humans and for future phases.

## Exact Code Change — `contents/code/UsageModel.js`

Single edit at lines 49-53. Exact old string:

```js
    return {
        provider: rawValue(entry, "provider"),
        source: rawValue(entry, "source"),
        windows: windows
    }
```

Exact new string:

```js
    // raw is a live reference to the parsed CLI entry, never a copy: normalized
    // snapshots are read-only, and a JSON round-trip would destroy Infinity/NaN.
    return {
        provider: rawValue(entry, "provider"),
        source: rawValue(entry, "source"),
        windows: windows,
        raw: entry
    }
```

No helper function is added. `rawValue`, `normalizeWindow`, `normalize`, `firstFiniteWindow`, `definitionForPreferred`, `matchesDefinition`, `preferredFiniteWindow`, `selectRepresentative`, and `selectCompact` are byte-unchanged. `entry` is guaranteed to be a non-null non-array object at this point by the guard at `UsageModel.js:63`, so `raw` is never `null` or `undefined` on a provider entry.

## Exact Test Plan — `tests/UsageModelTest.qml` (RED first)

Append five functions after `test_selectCompactIsUnaffectedByPreferredWindow` (current file ends at line 288). Existing functions are byte-unchanged; `tests/UsageModelHarness.qml` is byte-unchanged.

**RED evidence to record before touching `UsageModel.js`:** functions 1, 2, and 5 fail outright, and function 4's `raw.*` assertions fail. Function 3 and function 4's `windows` assertions pass from the start by design — they are regression pins for the four-key contract and window-level dropping, and apply must report them honestly as green-from-the-start rather than claiming RED.

```qml
    function test_preservesUnmodeledProviderFieldsVerbatimUnderRaw() {
        var provider = UsageModel.normalize({
            provider: "codex",
            source: "oauth",
            version: "0.147.0",
            pace: {
                secondary: {
                    stage: "farAhead",
                    summary: "49% in deficit | Expected 18% used | Runs out in 15h 7m",
                    deltaPercent: 49,
                    expectedUsedPercent: 18,
                    willLastToReset: false,
                    etaSeconds: 54379
                }
            },
            credits: { events: [], updatedAt: "2026-08-14T19:01:20Z", remaining: 0 },
            usage: {
                primary: null,
                tertiary: null,
                loginMethod: "plus",
                dataConfidence: "exact",
                codexResetCredits: { credits: [], updatedAt: "2026-08-14T19:01:20Z", availableCount: 0 },
                identity: { accountEmail: "redacted@example.com", loginMethod: "plus", providerID: "codex" },
                secondary: {
                    windowMinutes: 10080,
                    resetsAt: "2026-08-20T12:21:18Z",
                    resetDescription: "Aug 20 at 9:21 AM",
                    usedPercent: 67
                }
            }
        }).providers[0]

        verify(provider.raw !== undefined, "a normalized provider must expose a raw sibling")
        compare(provider.raw.version, "0.147.0")
        compare(provider.raw.credits.remaining, 0)
        compare(provider.raw.pace.secondary.stage, "farAhead")
        compare(provider.raw.pace.secondary.deltaPercent, 49)
        compare(provider.raw.usage.identity.accountEmail, "redacted@example.com")
        compare(provider.raw.usage.loginMethod, "plus")
        compare(provider.raw.usage.codexResetCredits.availableCount, 0)
        compare(provider.windows.length, 1, "unmodeled fields must not become windows")
        compare(provider.windows[0].label, "Weekly")
    }

    function test_rawIsTheLiveParsedEntryNotACopy() {
        var entry = {
            provider: "claude",
            source: "claude",
            pace: { primary: { stage: "farAhead", deltaPercent: 42, willLastToReset: false } },
            usage: { primary: { windowMinutes: 300, usedPercent: 66 } }
        }

        var provider = UsageModel.normalize([entry]).providers[0]

        verify(provider.raw === entry, "raw must hold the original entry object, not a copy")
        verify(provider.raw.pace === entry.pace, "nested raw values must not be cloned")
    }

    function test_fourKeyContractIsUnregressedByRawAddition() {
        var result = UsageModel.normalize({
            provider: null,
            source: null,
            version: "0.45.2",
            pace: { secondary: { stage: "farBehind", deltaPercent: -43 } },
            usage: {
                identity: { providerID: "gemini" },
                primary: {
                    usedPercent: 42,
                    resetsAt: "2026-08-09T10:00:00Z",
                    resetDescription: null
                }
            }
        })
        var provider = result.providers[0]

        compare(result.providers.length, 1)
        compare(provider.provider, null)
        compare(provider.source, null)
        compare(provider.windows.length, 1)
        compare(provider.windows[0].key, "primary")
        compare(provider.windows[0].label, "Session")
        compare(provider.windows[0].usedPercent, 42)
        compare(provider.windows[0].resetsAt, "2026-08-09T10:00:00Z")
        compare(provider.windows[0].resetDescription, null)
        compare(Object.keys(provider.windows[0]).length, 5,
                "window objects must keep exactly five keys")
        compare(UsageModel.selectRepresentative(provider.windows).usedPercent, 42)
    }

    function test_rawRetainsWindowKeysThatWindowsStillDrop() {
        var provider = UsageModel.normalize({
            provider: "copilot",
            source: "api",
            usage: {
                primary: { usedPercent: "70" },
                secondary: { usedPercent: Infinity },
                tertiary: { usedPercent: 55 },
                extraRateWindow: { usedPercent: 99 },
                details: [
                    {
                        title: "Credits",
                        rows: [
                            { label: "Credits used", value: "3", secondaryValue: "Aug 31 at 9:00 PM" }
                        ]
                    }
                ]
            }
        }).providers[0]

        compare(provider.windows.length, 3, "window-level unknown-key dropping is unchanged")
        compare(provider.windows[0].key, "primary")
        compare(provider.windows[1].key, "secondary")
        compare(provider.windows[2].key, "tertiary")
        compare(provider.windows[1].usedPercent, null)
        compare(provider.raw.usage.extraRateWindow.usedPercent, 99,
                "raw must retain the window key that windows drops")
        compare(provider.raw.usage.details[0].rows[0].secondaryValue, "Aug 31 at 9:00 PM")
        verify(provider.raw.usage.secondary.usedPercent === Infinity,
               "raw must preserve non-finite values that windows normalize to null")
    }

    function test_errorEntriesGainNoRawSibling() {
        var result = UsageModel.normalize([
            {
                provider: "openai",
                source: "auto",
                error: { kind: "provider", code: 1, message: "No available fetch strategy for openai." }
            },
            { provider: "grok", source: "web", usage: { primary: { usedPercent: 12 } } }
        ])

        compare(result.errors.length, 1)
        compare(result.errors[0].provider, "openai")
        compare(result.errors[0].source, "auto")
        compare(result.errors[0].error.message, "No available fetch strategy for openai.")
        compare(Object.keys(result.errors[0]).length, 3,
                "error entries must keep exactly provider, source, error")
        verify(result.errors[0].raw === undefined, "error entries must not gain a raw sibling")
        compare(result.providers.length, 1)
        compare(result.providers[0].provider, "grok")
        verify(result.providers[0].raw !== undefined, "usable providers still expose raw")
    }
```

Run with `./scripts/run-qml-tests.sh` (`qmltestrunner -input tests/UsageModelTest.qml -import <repo>`), then `./scripts/lint-qml.sh`, `./scripts/validate-package.sh`, `python3 -m unittest discover -s tests`, and `git diff --check`.

## Fixture Commit Plan

The capture at `/tmp/codexbar-real-capture.json` (22,106 bytes pretty-printed, 767 lines, 67 provider entries: 6 usable — `codex`, `claude`, `opencodego`, `gemini`, `copilot`, `grok` — and 61 error-shaped) satisfies the proposal's multi-provider requirement.

**Residual redaction to apply before commit.** A scan of the file found: one email pattern `gxxxxxxxxxxxx@gmail.com` (present at `usage.identity.accountEmail` and `usage.accountEmail` for `codex` and `gemini`); one already-redacted home path `/home/redacted-user/.local/share/kilo/auth.json`; one already-redacted timezone in `Resets7:50pm(Redacted/Timezone)`; two harmless documentation URLs (`https://kiro.dev/docs/cli/`, `http://127.0.0.1:8088`). The masked email still leaks a first initial and mail domain and does not match the doc's own redaction table, so normalize it. Leave everything else exactly as the user redacted it.

Exact steps:

```sh
cd /home/ginopc/Desarrollo/kodexbar-plasma
python3 - <<'PY'
import json, pathlib
src = json.loads(pathlib.Path("/tmp/codexbar-real-capture.json").read_text())

def scrub(node):
    if isinstance(node, dict):
        for key, value in node.items():
            if key in ("accountEmail",) and isinstance(value, str):
                node[key] = "redacted@example.com"
            else:
                scrub(value)
    elif isinstance(node, list):
        for item in node:
            scrub(item)

scrub(src)
out = pathlib.Path("tests/fixtures/codexbar-usage-capture.json")
out.write_text(json.dumps(src, indent=4, ensure_ascii=False) + "\n")
PY
```

Shape-preservation gate (must print `OK`; proves only leaf values changed):

```sh
python3 - <<'PY'
import json, pathlib

def shape(node, path=""):
    if isinstance(node, dict):
        for k in node:
            yield from shape(node[k], path + "." + k)
    elif isinstance(node, list):
        yield path + "[]", "list", len(node)
        for i, v in enumerate(node):
            yield from shape(v, path + "[]")
    else:
        yield path, type(node).__name__, None

a = list(shape(json.loads(pathlib.Path("/tmp/codexbar-real-capture.json").read_text())))
b = list(shape(json.loads(pathlib.Path("tests/fixtures/codexbar-usage-capture.json").read_text())))
print("OK" if a == b else "SHAPE DRIFT: %r" % [x for x in zip(a, b) if x[0] != x[1]][:5])
PY
```

PII gate (all three must return no unexpected match):

```sh
rg -n '@' tests/fixtures/codexbar-usage-capture.json        # only redacted@example.com
rg -n '/home/(?!redacted-user)' tests/fixtures/codexbar-usage-capture.json
rg -in 'token|secret|bearer|sk-|api[_-]?key' tests/fixtures/codexbar-usage-capture.json
```

Then `git add tests/fixtures/codexbar-usage-capture.json` and `git diff --check`. **This is a hard pre-commit gate**: an unredacted value cannot be removed from history by revert (proposal, Rollback Plan).

## `docs/cli-contract-capture.md` — Exact Structure and Content

New file, ~95 lines, mirroring `docs/live-plasma-smoke.md`'s heading style (`# Title`, `## Section`, `### Subsection`, tables, fenced `sh` blocks).

```
# CodexBar CLI Contract Capture

## Why this exists
    Two short paragraphs: the widget depends on an external CLI whose JSON has already
    had one documented breaking change; this fixture is the repository's only ground
    truth for that contract. It is evidence, not a test input — no QML test reads it.

## Capture command
    Fenced sh block, copied verbatim from proposal.md's "Capture and Redaction Procedure":
        CODEXBAR_PATH="$(command -v codexbar)"
        "$CODEXBAR_PATH" usage --provider all --format json --json-only \
          | python3 -m json.tool > /tmp/codexbar-real-capture.json
    Note: this is the exact invocation UsageController.qml:38 emits at runtime; do not
    add flags, because a fixture captured under different flags is not the contract.

## Redaction rule
    Blockquote copied verbatim from proposal.md:
    > Replace sensitive leaf values only. Never remove, rename, or reorder a key. Never
    > change a type: strings stay strings, numbers stay numbers, arrays stay arrays,
    > objects stay objects, null stays null, and nesting depth is preserved exactly.

### Field-class table
    The six-row table copied verbatim from proposal.md (identity.accountEmail;
    identity.accountOrganization; identity.providerID / loginMethod; credits.remaining
    and any cost/balance figure; any token, key, session ID, or URL containing one;
    the structural-keys row marked "Leave untouched").

### Verification before commit
    The shape-preservation and PII gate snippets from the design's Fixture Commit Plan.

## Provenance of the committed fixture
    | Field | Value |
    |---|---|
    | Fixture | `tests/fixtures/codexbar-usage-capture.json` |
    | Captured | 2026-08-14 |
    | CodexBar version | **Not self-reported by this build** — see below |
    | Binary | `~/.local/bin/codexbar`, mtime 2026-08-08, sha256 `2a914798540109cabba2f600a3ae4f19d8c95096ff686b346eaf4851f3078b4d` |
    | Platform | Linux (CachyOS), Plasma 6, Qt 6.11.1 |
    | Providers present | 67 entries — 6 usable (codex, claude, opencodego, gemini, copilot, grok), 61 error-shaped |
    | Redacted | account email (-> redacted@example.com), home path (-> /home/redacted-user), local timezone in resetDescription |

### On the missing CodexBar version
    Investigated during design: this build does not self-report a version.
    `codexbar --version` prints exactly `CodexBar` with no number, and the `codexbar
    --help` header prints `CodexBar unknown`. The `version` fields *inside* the payload
    (`codex` -> `0.147.0`, `gemini` -> `0.45.2`) are the versions of the provider CLIs
    CodexBar shelled out to — they are NOT CodexBar's own version and must not be
    recorded as such. Provenance therefore pins the binary by sha256 and mtime instead.
    If the user knows their install method and version, record it here as a third line;
    apply MUST ask rather than infer one.

## Re-capture cadence
    No CI QML runtime exists (README.md:184), so nothing detects drift automatically.
    Re-capture manually after any CodexBar upgrade or when a provider is added/removed,
    repeat the redaction rule and both gates, and update the provenance table's sha256
    and date in the same commit as the new fixture.
```

## Exact `README.md` Edit

Single paragraph replacement at `README.md:122`. The `## MVP exclusions` heading at line 120 is left byte-unchanged so the anchor survives.

Exact old string:

```
KodexBar Plasma deliberately does not implement cost data, credits, tokens, calculated reset durations, charts, provider or source switching, authentication or cookie automation, provider implementations, fallback probing, or reset/account actions. Use CodexBar and provider tools for those responsibilities.
```

Exact new string (verbatim from proposal.md:125-127):

```
KodexBar Plasma deliberately does not implement provider implementations, authentication or cookie automation, fallback probing, reset or account actions, provider or source switching, calculated reset durations, or charts. Use CodexBar and provider tools for those responsibilities.

Cost, credit, token, pace, and other richer per-provider values are never computed, estimated, or requested by this widget. When the CodexBar CLI itself returns such fields, the data layer preserves them verbatim under a per-provider `raw` key so later phases can build on real data — **the popup does not display them today**. Surfacing them in the UI is planned roadmap work, not current behavior.
```

## Interfaces / Contracts

After this change, a normalized snapshot is:

```
{ providers: [ { provider, source, windows: [ {key, label, usedPercent, resetsAt, resetDescription} ], raw } ],
  errors:    [ { provider, source, error } ] }
```

`raw` is the live parsed CLI entry object for that provider. The four-key contract's values, types, and ordering are unchanged. `errors` entries are unchanged and have no `raw`.

## Delivery Slicing

Estimated changed lines:

| Artifact | Lines | Slice |
|---|---|---|
| `openspec/changes/cli-contract-fixtures/exploration.md` | 92 | 0a |
| `openspec/changes/cli-contract-fixtures/proposal.md` | 193 | 0a |
| `openspec/changes/cli-contract-fixtures/specs/provider-usage-display/spec.md` | 165 | 0a |
| `openspec/changes/cli-contract-fixtures/design.md` | ~290 | 0b |
| `openspec/changes/cli-contract-fixtures/tasks.md` | ~90 | 0b |
| `docs/cli-contract-capture.md` | ~95 | 1 |
| `tests/fixtures/codexbar-usage-capture.json` | 767 | 1 |
| `contents/code/UsageModel.js` | +5 / -1 | 2 |
| `tests/UsageModelTest.qml` | ~+140 | 2 |
| `README.md` | +3 / -1 | 2 |

**Recommendation: four stacked PRs off `main`, matching the `provider-icon-rendering` precedent's branch naming (`slice/cli-contract-fixtures-<n>-<topic>`), each based on the previous.**

| Slice | Branch | Contents | Lines | Budget |
|---|---|---|---|---|
| 0a | `slice/cli-contract-fixtures-0a-planning` | exploration + proposal + spec delta | ~450 | 12% over — minor exception |
| 0b | `slice/cli-contract-fixtures-0b-design-tasks` | design + tasks | ~380 | in budget |
| 1 | `slice/cli-contract-fixtures-1-capture-evidence` | capture doc + redacted fixture | ~862 | over — see decision below |
| 2 | `slice/cli-contract-fixtures-2-raw-passthrough` | `UsageModel.js` + tests + README | ~150 | in budget |

One PR does not suffice (~1,900 lines total). Slices 1 and 2 must not merge: the evidence gate (Phase 0) exists precisely so the mechanism (Phase 1) is reviewed against real data already on disk.

**`ask-on-risk` decision required before Slice 1 (the change's one remaining open question).** Slice 1 exceeds 400 lines because of the fixture alone, and a real capture is atomic — splitting it by provider would destroy the very thing it proves.

- **Option A (recommended): commit the fixture pretty-printed (767 lines) and take a `size:exception` for Slice 1.** The 400-line budget protects reviewer attention on decision-bearing lines; a machine-generated capture has none. The genuinely reviewable surface is the ~95-line doc plus a redaction scan, and the indented form is what makes the redaction audit — the hard PII gate — humanly verifiable.
- **Option B: commit one compact JSON object per line** (67 entries + 2 bracket lines = 69 lines, longest line 805 chars, 13.4 KB), bringing Slice 1 to ~164 lines and inside budget. This matches the existing compact-JSON convention at `tests/fixtures/codexbar-lifecycle-fixture.sh:15` and is arguably closer to the CLI's native `--json-only` output, at the cost of a harder-to-eyeball redaction review.

Slice 0a's 12% overage is accepted as-is: no split of the planning corpus puts every planning slice under 400 without a three-way split, which would be disproportionate for a change whose product diff is ~150 lines.

## Non-Goals and Boundaries (in force for `sdd-tasks` and `sdd-apply` — drift is a defect)

Restated verbatim in substance from proposal.md's Out of Scope:

1. **No UI whatsoever.** No pace, credits, cost, token, richer-timestamp, dynamic-window, or per-provider-metadata rendering. That is roadmap Phase 2+ with its own proposal.
2. **No change to the CLI invocation.** `contents/ui/UsageController.qml:38` keeps emitting exactly `usage --provider all --format json --json-only`.
3. **No provider, OAuth, credential, cookie, probing, or account logic.** Those stay CodexBar's responsibility, permanently.
4. **No change to the stable four-key contract's shape or semantics** — `provider`, `source`, and `windows[].{key,label,usedPercent,resetsAt,resetDescription}` keep their exact current values, types, ordering, and null behavior.
5. **No change to `normalizeWindow`.** Window-level unknown-key dropping is untouched; `tests/UsageModelTest.qml:65-81` and `tests/UsageModelHarness.qml:26,38` stay byte-unchanged.
6. **No typed field promotion.** No first-class named property for `pace`, `credits`, `identity`, `version`, or `status`. Deferred, not rejected.
7. **No cost or token computation of any kind.** If the CLI does not emit a value, nothing is derived, estimated, or requested.
8. **No touching `openspec/changes/persistent-datasource-lifecycle/`.** Unrelated stray directory, flagged for separate cleanup.
9. Additionally, from AD-3: **no runtime fixture loading in QML tests.**

## Threat Matrix

| Threat | Mitigation |
|---|---|
| Unredacted PII enters git history permanently | Two scripted gates (shape preservation + PII scan) run before `git add`; revert is insufficient, so this blocks the commit, not the merge |
| `raw` read as license to display cost data | README paragraph and spec scenario "Raw preservation does not authorize display" both say preserved-not-displayed; no UI file is touched in any slice |
| A future consumer mutates `raw` and corrupts the snapshot | AD-1 records the read-only-snapshot invariant in code comment, design, and spec; no consumer reads `raw` today |
| Fixture goes stale after a CodexBar upgrade | Provenance table pins sha256 + date; re-capture cadence is documented as explicitly manual, not claimed as automated |
| Apply invents a CodexBar version number | Documented finding: this build does not self-report one; apply MUST ask the user rather than infer from the payload's provider-CLI `version` fields |

## Migration / Rollout and Rollback

No migration, no persisted state, no user configuration, no external behavior change. `raw` is purely additive and unread, so removing the key restores the previous snapshot exactly. Rollback boundary per slice is that slice's file list. The fixture is the one artifact whose rollback is not sufficient if redaction failed — hence the pre-commit gate.

## Open Questions

1. **Slice 1 fixture formatting — Option A (pretty + `size:exception`) vs Option B (compact per-entry, in budget).** Recommendation: A. Requires the user's `ask-on-risk` answer before Slice 1 is committed.
2. **CodexBar install method/version.** The binary does not self-report one. Apply asks the user; if unknown, the provenance table records "not self-reported" plus the sha256 and stops there.

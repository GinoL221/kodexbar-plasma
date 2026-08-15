# CodexBar CLI Contract Capture

## Why this exists

This document records how the real CodexBar usage payload was captured, redacted, and committed as a contract fixture. The widget depends on an external CLI whose JSON schema has already had one documented breaking change, so this fixture is the repository's only ground-truth evidence of the contract it consumes. It is evidence, not a test input — no QML test reads it at runtime.

The fixture preserves every key, type, and nesting depth from the real CLI output. Only sensitive leaf values are replaced. A future CodexBar upgrade may change the contents of `raw` without requiring a normalization rewrite, but any such drift must be re-captured manually because no CI QML runtime exists to detect it automatically.

## Capture command

Run on the target machine, as the user that owns the configured CodexBar install:

```sh
CODEXBAR_PATH="$(command -v codexbar)"
"$CODEXBAR_PATH" usage --provider all --format json --json-only \
  | python3 -m json.tool > /tmp/codexbar-real-capture.json
```

This is the exact invocation `UsageController.qml:38` emits at runtime. Do not add flags; a fixture captured under different flags is not the same contract.

## Redaction rule

> Replace sensitive leaf **values** only. Never remove, rename, or reorder a key. Never change a type: strings stay strings, numbers stay numbers, arrays stay arrays, objects stay objects, `null` stays `null`, and nesting depth is preserved exactly.

### Field-class table

| Field class | Action |
|---|---|
| `identity.accountEmail` | Replace with `"redacted@example.com"` |
| `identity.accountOrganization` | Replace with `"Redacted Org"` |
| `identity.providerID`, `loginMethod` | Replace only if account-identifying; keep the key and type |
| `credits.remaining`, any cost/balance figure | Replace with a same-magnitude placeholder number (e.g. round to a fixed value) |
| Any token, key, session ID, or URL containing one | Replace with a same-length placeholder string |
| `provider`, `source`, `version`, `status`, `primary`/`secondary`/`tertiary`, `usedPercent`, `resetsAt`, `resetDescription`, `windowMinutes`, `pace.*`, `usage.details[*]` structural keys | **Leave untouched** — these are exactly what this change needs to observe |

### Verification before commit

After reformatting the capture into the compact fixture, run these gates before staging. The value-equality gate must print `OK`; the PII gates must contain no unexpected matches.

Value-equality gate — proves no value changed during reformatting:

```sh
python3 - <<'PY'
import json, pathlib
a = json.loads(pathlib.Path("/tmp/codexbar-real-capture.json").read_text())
b = json.loads(pathlib.Path("tests/fixtures/codexbar-usage-capture.json").read_text())
print("OK" if a == b else "VALUE DRIFT DETECTED")
PY
```

PII gates:

```sh
rg -n '@' tests/fixtures/codexbar-usage-capture.json        # only redacted@example.com
rg -n '/home/(?!redacted-user)' tests/fixtures/codexbar-usage-capture.json
rg -in 'token|secret|bearer|sk-|api[_-]?key' tests/fixtures/codexbar-usage-capture.json
```

An unredacted value cannot be removed from git history by revert, so a failing gate blocks the commit.

## Provenance of the committed fixture

| Field | Value |
|---|---|
| Fixture | `tests/fixtures/codexbar-usage-capture.json` |
| Captured | 2026-08-14 |
| CodexBar version | **Not self-reported by this build** — see below |
| Binary | `~/.local/bin/codexbar`, mtime 2026-08-08, sha256 `2a914798540109cabba2f600a3ae4f19d8c95096ff686b346eaf4851f3078b4d` |
| Platform | Linux (CachyOS), Plasma 6, Qt 6.11.1 |
| Providers present | 67 entries — 6 usable (`codex`, `claude`, `opencodego`, `gemini`, `copilot`, `grok`), 61 error-shaped |
| Redacted | account email (masked in the supplied capture), home path (`/home/redacted-user`), local timezone in `resetDescription` |

### On the missing CodexBar version

This build does not self-report a version. `codexbar --version` prints exactly `CodexBar` with no number, and `codexbar --help` prints `CodexBar unknown`. The `version` fields *inside* the payload (for example, `codex` → `0.147.0`, `gemini` → `0.45.2`) are the versions of the provider CLIs CodexBar shelled out to — they are **not** CodexBar's own version and must not be recorded as such. Provenance therefore pins the binary by sha256 and mtime instead. If the install method and version are known, add them as a third line in the provenance table.

## Re-capture cadence

No CI QML runtime exists, so nothing detects drift automatically. Re-capture manually after any CodexBar upgrade or when a provider is added or removed, repeat the redaction rule and both gates, and update the provenance table's sha256 and date in the same commit as the new fixture.

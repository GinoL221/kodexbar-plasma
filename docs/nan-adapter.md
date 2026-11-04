# NaN Cloud usage adapter (optional)

CodexBar has no `nan` provider, and this widget only consumes the CodexBar CLI. `scripts/codexbar-nan` is an **optional, external wrapper** that closes the gap without changing that boundary: it runs the real `codexbar`, then appends one `nan` entry to the `usage` JSON, shaped like any other provider entry. The widget renders it as a normal provider and never learns that NaN exists.

The entry is built from `GET https://api.nan.builders/v1/usage` (token counts per model and day). The API reports consumption only, so quotas are configuration, not data.

## What you see

One provider, **NaN Cloud**, with one bar per model. Bars are labeled with the model name (via the CLI contract's `rateWindowLabels`) and reset on the plan's renewal day.

| Behavior | Detail |
| --- | --- |
| Other commands | `cost`, `--version`, text output, and any `--provider` other than `all`/`nan` are passed to the real `codexbar` untouched. |
| Exit code | The real CLI's exit code is preserved. With `--provider nan` the adapter exits `1` when the NaN request fails. |
| Failure isolation | Any NaN problem (missing key, HTTP error, timeout, bad config) becomes an `error` entry for `nan`; the other providers still render. |
| Secrets | The key is sent only as a bearer header and is never printed. |

## Install

```sh
install -m 755 scripts/codexbar-nan ~/.local/bin/codexbar-nan
```

Then set the widget's **CLI path** setting to the absolute path of `~/.local/bin/codexbar-nan`. The adapter finds the real CLI through `CODEXBAR_REAL`, then `codexbar` on `PATH`, then `~/.local/bin/codexbar`, `/usr/local/bin/codexbar`, `/usr/bin/codexbar`; it never calls itself.

## API key

Plasma does not inherit variables set with your shell (for example fish universal variables), so a key exported in a terminal is invisible to the widget. Use a key file:

```sh
mkdir -p ~/.config/codexbar
install -m 600 /dev/null ~/.config/codexbar/nan-api-key
# paste the key, then press Ctrl+D (input is not echoed to history):
cat > ~/.config/codexbar/nan-api-key
```

Resolution order: `NAN_API_KEY` environment variable, then `NAN_API_KEY_FILE`, then `~/.config/codexbar/nan-api-key`. A key file readable by group or others is refused with a `chmod 600` hint.

## Quotas and renewal day

Defaults match the **Gentle** plan (DeepSeek V4 Flash 1,000M tokens, GLM 5.3 Flash 500M tokens, renewal on day 3, UTC). Override them in `~/.config/codexbar/nan.json`:

```json
{
  "renewalDay": 3,
  "models": [
    { "id": "deepseek-v4-flash", "label": "DeepSeek V4 Flash", "quota": 1000000000 },
    { "id": "glm5.3-flash", "label": "GLM 5.3 Flash", "quota": 500000000 }
  ]
}
```

- Up to 3 models; the first is the primary bar, then secondary, then tertiary.
- `renewalDay` is clamped to short months (day 31 renews on the 30th in November).
- The period runs from the most recent renewal to the next one; only usage inside it is counted. The exact renewal time of day is not exposed by the API, so midnight UTC is assumed.
- Models returned by the API but absent from this file are ignored.

## Environment knobs

| Variable | Default | Purpose |
| --- | --- | --- |
| `CODEXBAR_REAL` | discovered | Path to the real `codexbar`. |
| `NAN_API_BASE_URL` | `https://api.nan.builders` | API origin (used by the tests). |
| `NAN_TIMEOUT` | `8` | Request timeout in seconds. |
| `NAN_NOW` | current time | Fixed UTC time `YYYY-MM-DDTHH:MM:SSZ` (used by the tests). |

## Verify

```sh
~/.local/bin/codexbar-nan usage --provider nan --format json --json-only
python3 -m unittest tests.test_codexbar_nan
```

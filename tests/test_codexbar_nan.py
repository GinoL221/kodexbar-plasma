import json
import os
import stat
import subprocess
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path


ROOT = Path(__file__).parents[1]
ADAPTER = ROOT / "scripts" / "codexbar-nan"

NOW = "2026-11-04T12:00:00Z"
API_KEY = "test-key-do-not-leak"
CLAUDE_ENTRY = {"provider": "claude", "source": "oauth", "usage": {"primary": {"usedPercent": 7}}}

USAGE_REPORT = {
    "object": "usage.report",
    "data": [
        {"date": "2026-11-03", "model": "deepseek-v4-flash", "total_tokens": 150_000_000},
        {"date": "2026-11-04", "model": "deepseek-v4-flash", "total_tokens": 100_000_000},
        {"date": "2026-11-04", "model": "glm5.3-flash", "total_tokens": 50_000_000},
        {"date": "2026-11-04", "model": "unplanned-model", "total_tokens": 9},
    ],
}


class FakeNanServer:
    def __init__(self, status=200, body=None):
        self.requests = []
        outer = self
        payload = USAGE_REPORT if body is None else body

        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                outer.requests.append({"path": self.path, "auth": self.headers.get("Authorization")})
                data = json.dumps(payload).encode()
                self.send_response(status)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(data)))
                self.end_headers()
                self.wfile.write(data)

            def log_message(self, *args):
                pass

        self.httpd = HTTPServer(("127.0.0.1", 0), Handler)
        self.thread = threading.Thread(target=self.httpd.serve_forever, daemon=True)

    @property
    def url(self):
        return "http://127.0.0.1:%d" % self.httpd.server_address[1]

    def __enter__(self):
        self.thread.start()
        return self

    def __exit__(self, *exc):
        self.httpd.shutdown()
        self.httpd.server_close()


class AdapterTestCase(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name) / "home"
        self.home.mkdir()
        self.calls = Path(self.tmp.name) / "calls.txt"

    def fake_codexbar(self, stdout, exit_code=0):
        script = Path(self.tmp.name) / "codexbar"
        script.write_text(
            "#!/bin/sh\n"
            'echo "$@" >> "%s"\n'
            "cat <<'EOF'\n%s\nEOF\n"
            "exit %d\n" % (self.calls, stdout, exit_code)
        )
        script.chmod(script.stat().st_mode | stat.S_IXUSR)
        return script

    def real_calls(self):
        return self.calls.read_text().splitlines() if self.calls.exists() else []

    def run_adapter(self, args, server, real, env_extra=None, drop_key=False):
        env = {
            "PATH": os.environ["PATH"],
            "HOME": str(self.home),
            "CODEXBAR_REAL": str(real),
            "NAN_API_BASE_URL": server.url,
            "NAN_NOW": NOW,
        }
        if not drop_key:
            env["NAN_API_KEY"] = API_KEY
        env.update(env_extra or {})
        return subprocess.run(
            [str(ADAPTER)] + args, env=env, capture_output=True, text=True, timeout=30
        )


class UsageMergeTest(AdapterTestCase):
    def test_non_usage_commands_pass_through_untouched(self):
        real = self.fake_codexbar("COST OUTPUT", exit_code=3)
        with FakeNanServer() as server:
            result = self.run_adapter(["cost", "--provider", "claude"], server, real)

        self.assertEqual(result.stdout.strip(), "COST OUTPUT")
        self.assertEqual(result.returncode, 3)
        self.assertEqual(self.real_calls(), ["cost --provider claude"])
        self.assertEqual(server.requests, [])

    def test_text_format_usage_passes_through_without_calling_nan(self):
        real = self.fake_codexbar("plain text usage")
        with FakeNanServer() as server:
            result = self.run_adapter(["usage"], server, real)

        self.assertEqual(result.stdout.strip(), "plain text usage")
        self.assertEqual(server.requests, [])

    def test_json_usage_appends_nan_entry_after_real_entries(self):
        real = self.fake_codexbar(json.dumps([CLAUDE_ENTRY]))
        with FakeNanServer() as server:
            result = self.run_adapter(["usage", "--format", "json", "--json-only"], server, real)

        self.assertEqual(result.returncode, 0, result.stderr)
        entries = json.loads(result.stdout)
        self.assertEqual([entry["provider"] for entry in entries], ["claude", "nan"])
        self.assertEqual(entries[0], CLAUDE_ENTRY)

        nan = entries[1]
        self.assertEqual(nan["source"], "api")
        self.assertEqual(nan["rateWindowLabels"], {"primary": "DS V4", "secondary": "GLM"})
        self.assertAlmostEqual(nan["usage"]["primary"]["usedPercent"], 25.0)
        self.assertAlmostEqual(nan["usage"]["secondary"]["usedPercent"], 10.0)
        self.assertEqual(nan["usage"]["primary"]["resetsAt"], "2026-12-03T00:00:00Z")
        self.assertEqual(nan["usage"]["primary"]["resetDescription"], "Dec 3")
        self.assertEqual(nan["usage"]["primary"]["windowMinutes"], 30 * 24 * 60)

    def test_nan_is_queried_with_bearer_key_and_period_start(self):
        real = self.fake_codexbar(json.dumps([]))
        with FakeNanServer() as server:
            self.run_adapter(["usage", "--format", "json"], server, real)

        self.assertEqual(len(server.requests), 1)
        self.assertEqual(server.requests[0]["path"], "/v1/usage?start_date=2026-11-03")
        self.assertEqual(server.requests[0]["auth"], "Bearer " + API_KEY)

    def test_only_period_rows_are_counted(self):
        real = self.fake_codexbar(json.dumps([]))
        body = {"data": [
            {"date": "2026-11-02", "model": "deepseek-v4-flash", "total_tokens": 900_000_000},
            {"date": "2026-11-03", "model": "deepseek-v4-flash", "total_tokens": 10_000_000},
        ]}
        with FakeNanServer(body=body) as server:
            result = self.run_adapter(["usage", "--json"], server, real)

        nan = json.loads(result.stdout)[-1]
        self.assertAlmostEqual(nan["usage"]["primary"]["usedPercent"], 1.0)

    def test_provider_nan_skips_the_real_cli(self):
        real = self.fake_codexbar(json.dumps([CLAUDE_ENTRY]))
        with FakeNanServer() as server:
            result = self.run_adapter(
                ["usage", "--provider", "nan", "--format", "json", "--json-only"], server, real
            )

        entries = json.loads(result.stdout)
        self.assertEqual([entry["provider"] for entry in entries], ["nan"])
        self.assertEqual(self.real_calls(), [])

    def test_provider_all_merges_nan(self):
        real = self.fake_codexbar(json.dumps([CLAUDE_ENTRY]))
        with FakeNanServer() as server:
            result = self.run_adapter(
                ["usage", "--provider", "all", "--format", "json", "--json-only"], server, real
            )

        self.assertEqual([entry["provider"] for entry in json.loads(result.stdout)], ["claude", "nan"])
        self.assertEqual(self.real_calls(), ["usage --provider all --format json --json-only"])

    def test_other_provider_passes_through_without_calling_nan(self):
        real = self.fake_codexbar(json.dumps([CLAUDE_ENTRY]))
        with FakeNanServer() as server:
            result = self.run_adapter(
                ["usage", "--provider", "claude", "--format", "json"], server, real
            )

        self.assertEqual(json.loads(result.stdout), [CLAUDE_ENTRY])
        self.assertEqual(server.requests, [])

    def test_non_array_real_output_passes_through(self):
        real = self.fake_codexbar("not json at all")
        with FakeNanServer() as server:
            result = self.run_adapter(["usage", "--format", "json"], server, real)

        self.assertEqual(result.stdout.strip(), "not json at all")

    def test_real_exit_code_is_preserved_when_merging(self):
        real = self.fake_codexbar(json.dumps([CLAUDE_ENTRY]), exit_code=1)
        with FakeNanServer() as server:
            result = self.run_adapter(["usage", "--format", "json"], server, real)

        self.assertEqual(result.returncode, 1)
        self.assertEqual([entry["provider"] for entry in json.loads(result.stdout)], ["claude", "nan"])


def load_adapter_module():
    import importlib.machinery
    import importlib.util

    loader = importlib.machinery.SourceFileLoader("codexbar_nan", str(ADAPTER))
    spec = importlib.util.spec_from_loader("codexbar_nan", loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


class PeriodTest(unittest.TestCase):
    def period(self, now, day):
        from datetime import datetime, timezone

        adapter = load_adapter_module()
        parsed = datetime.strptime(now, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
        start, end = adapter.billing_period(parsed, day)
        return start.strftime("%Y-%m-%d"), end.strftime("%Y-%m-%d")

    def test_after_renewal_day_starts_this_month(self):
        self.assertEqual(self.period("2026-11-04T12:00:00Z", 3), ("2026-11-03", "2026-12-03"))

    def test_before_renewal_day_starts_previous_month(self):
        self.assertEqual(self.period("2026-11-02T12:00:00Z", 3), ("2026-10-03", "2026-11-03"))

    def test_renewal_day_itself_starts_the_new_period(self):
        self.assertEqual(self.period("2026-11-03T00:00:00Z", 3), ("2026-11-03", "2026-12-03"))

    def test_year_boundaries(self):
        self.assertEqual(self.period("2026-01-02T00:00:00Z", 3), ("2025-12-03", "2026-01-03"))
        self.assertEqual(self.period("2026-12-20T00:00:00Z", 3), ("2026-12-03", "2027-01-03"))

    def test_renewal_day_is_clamped_to_short_months(self):
        self.assertEqual(self.period("2026-11-15T00:00:00Z", 31), ("2026-10-31", "2026-11-30"))


class FailureAndConfigTest(AdapterTestCase):
    def config_dir(self):
        path = self.home / ".config" / "codexbar"
        path.mkdir(parents=True, exist_ok=True)
        return path

    def nan_entry(self, result):
        return json.loads(result.stdout)[-1]

    def assert_error_entry(self, result, kind, fragment):
        entry = self.nan_entry(result)
        self.assertEqual(entry["provider"], "nan")
        self.assertEqual(entry["source"], "api")
        self.assertEqual(entry["error"]["kind"], kind)
        self.assertEqual(entry["error"]["code"], 1)
        self.assertIn(fragment, entry["error"]["message"])
        self.assertNotIn("usage", entry)

    def test_key_file_is_used_when_env_is_missing(self):
        key_file = self.config_dir() / "nan-api-key"
        key_file.write_text("file-key\n")
        key_file.chmod(0o600)
        real = self.fake_codexbar("[]")
        with FakeNanServer() as server:
            self.run_adapter(["usage", "--json"], server, real, drop_key=True)

        self.assertEqual(server.requests[0]["auth"], "Bearer file-key")

    def test_env_key_wins_over_key_file(self):
        key_file = self.config_dir() / "nan-api-key"
        key_file.write_text("file-key")
        key_file.chmod(0o600)
        real = self.fake_codexbar("[]")
        with FakeNanServer() as server:
            self.run_adapter(["usage", "--json"], server, real)

        self.assertEqual(server.requests[0]["auth"], "Bearer " + API_KEY)

    def test_key_file_readable_by_others_is_refused(self):
        key_file = self.config_dir() / "nan-api-key"
        key_file.write_text("file-key")
        key_file.chmod(0o644)
        real = self.fake_codexbar("[]")
        with FakeNanServer() as server:
            result = self.run_adapter(["usage", "--json"], server, real, drop_key=True)

        self.assert_error_entry(result, "config", "chmod 600")
        self.assertEqual(server.requests, [])
        self.assertNotIn("file-key", result.stdout + result.stderr)

    def test_missing_key_yields_config_error_entry(self):
        real = self.fake_codexbar(json.dumps([CLAUDE_ENTRY]))
        with FakeNanServer() as server:
            result = self.run_adapter(["usage", "--json"], server, real, drop_key=True)

        self.assert_error_entry(result, "config", "NAN_API_KEY")
        self.assertEqual(json.loads(result.stdout)[0], CLAUDE_ENTRY)
        self.assertEqual(server.requests, [])
        self.assertEqual(result.returncode, 0)

    def test_http_error_yields_provider_error_without_leaking_the_key(self):
        real = self.fake_codexbar("[]")
        with FakeNanServer(status=401, body={"error": {"message": "nope"}}) as server:
            result = self.run_adapter(["usage", "--json"], server, real)

        self.assert_error_entry(result, "provider", "401")
        self.assertNotIn(API_KEY, result.stdout + result.stderr)

    def test_unreachable_api_yields_error_entry(self):
        real = self.fake_codexbar("[]")
        with FakeNanServer() as server:
            dead_url = server.url
        result = self.run_adapter(
            ["usage", "--json"], FakeUrl(dead_url), real, env_extra={"NAN_TIMEOUT": "2"}
        )

        self.assert_error_entry(result, "runtime", "NaN")
        self.assertNotIn(API_KEY, result.stdout + result.stderr)

    def test_provider_nan_error_exits_non_zero(self):
        real = self.fake_codexbar("[]")
        with FakeNanServer(status=500, body={}) as server:
            result = self.run_adapter(["usage", "--provider", "nan", "--json"], server, real)

        self.assertEqual(result.returncode, 1)
        self.assert_error_entry(result, "provider", "500")

    def test_config_file_overrides_models_and_renewal_day(self):
        (self.config_dir() / "nan.json").write_text(json.dumps({
            "renewalDay": 10,
            "models": [{"id": "glm5.3-flash", "label": "GLM", "quota": 100_000_000}],
        }))
        real = self.fake_codexbar("[]")
        with FakeNanServer() as server:
            result = self.run_adapter(["usage", "--json"], server, real)

        self.assertEqual(server.requests[0]["path"], "/v1/usage?start_date=2026-10-10")
        nan = self.nan_entry(result)
        self.assertEqual(nan["rateWindowLabels"], {"primary": "GLM"})
        self.assertAlmostEqual(nan["usage"]["primary"]["usedPercent"], 50.0)
        self.assertNotIn("secondary", nan["usage"])

    def test_invalid_config_file_yields_config_error_entry(self):
        (self.config_dir() / "nan.json").write_text("{not json")
        real = self.fake_codexbar("[]")
        with FakeNanServer() as server:
            result = self.run_adapter(["usage", "--json"], server, real)

        self.assert_error_entry(result, "config", "nan.json")
        self.assertEqual(server.requests, [])


    def test_malformed_report_rows_are_ignored(self):
        real = self.fake_codexbar("[]")
        body = {"data": ["junk", 7, None, {"date": "2026-11-04", "model": "glm5.3-flash", "total_tokens": 50_000_000}]}
        with FakeNanServer(body=body) as server:
            result = self.run_adapter(["usage", "--json"], server, real)

        nan = self.nan_entry(result)
        self.assertAlmostEqual(nan["usage"]["primary"]["usedPercent"], 0.0)
        self.assertAlmostEqual(nan["usage"]["secondary"]["usedPercent"], 10.0)

    def test_unexpected_failure_still_yields_an_error_entry(self):
        real = self.fake_codexbar(json.dumps([CLAUDE_ENTRY]))
        with FakeNanServer() as server:
            result = self.run_adapter(
                ["usage", "--json"], server, real, env_extra={"NAN_TIMEOUT": "abc"}
            )

        self.assert_error_entry(result, "runtime", "NaN")
        self.assertEqual(json.loads(result.stdout)[0], CLAUDE_ENTRY)


class FakeUrl:
    def __init__(self, url):
        self.url = url


if __name__ == "__main__":
    unittest.main()

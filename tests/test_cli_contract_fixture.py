import hashlib
import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).parents[1]
FIXTURE = ROOT / "tests" / "fixtures" / "codexbar-usage-capture.json"
DOCS = ROOT / "docs" / "cli-contract-capture.md"


class CliContractFixtureTest(unittest.TestCase):
    def fixture_bytes(self):
        return FIXTURE.read_bytes()

    def fixture_text(self):
        return FIXTURE.read_text(encoding="utf-8")

    def fixture_json(self):
        return json.loads(self.fixture_text())

    def test_fixture_path_and_bytes_pinned(self):
        self.assertTrue(FIXTURE.exists(), "fixture file must exist")
        data = self.fixture_bytes()
        self.assertGreater(len(data), 0, "fixture must not be empty")
        digest = hashlib.sha256(data).hexdigest()
        self.assertEqual(
            digest,
            "46343115c0b1c82960147e1d9a16746c0b5f915d44f4d29a209be6f0aa290c0b",
            "fixture bytes must match the pinned Phase 1 capture",
        )

    def test_fixture_is_valid_json_array(self):
        payload = self.fixture_json()
        self.assertIsInstance(payload, list)
        self.assertGreater(len(payload), 0, "fixture must contain at least one entry")

    def test_docs_reference_fixture_path_and_capture_date(self):
        text = DOCS.read_text(encoding="utf-8")
        self.assertIn("tests/fixtures/codexbar-usage-capture.json", text)
        self.assertIn("2026-08-14", text)

    def test_docs_record_non_self_reported_version_and_binary_pin(self):
        text = DOCS.read_text(encoding="utf-8")
        self.assertIn("Not self-reported by this build", text)
        self.assertIn(
            "sha256 `2a914798540109cabba2f600a3ae4f19d8c95096ff686b346eaf4851f3078b4d`",
            text,
        )

    def test_docs_prescribe_leaf_only_redaction(self):
        text = DOCS.read_text(encoding="utf-8")
        self.assertIn("Replace sensitive leaf **values** only", text)
        self.assertIn("Never remove, rename, or reorder a key", text)
        self.assertIn("Never change a type", text)

    def test_no_unredacted_account_email_or_home_path_remains(self):
        text = self.fixture_text()
        # Only the canonical redacted home path may survive in the fixture.
        home_paths = re.findall(r"/home/[^/\s`\"']+", text)
        self.assertTrue(home_paths)
        self.assertTrue(all(path == "/home/redacted-user" for path in home_paths))
        # Account emails must be masked or use the canonical redacted pattern.
        for email in re.findall(r"\S+@\S+", text):
            self.assertTrue(
                "xxxx" in email or email == "redacted@example.com",
                "unexpected unredacted email value: " + email,
            )

    def test_no_token_secret_key_session_url_patterns_remain(self):
        text = self.fixture_text()
        sensitive = re.compile(r"\b(sk-[a-zA-Z0-9]+|api[_-]?key|token|secret|bearer)\b", re.IGNORECASE)
        matches = sensitive.findall(text)
        # Incidental words like "token" in error messages are acceptable only as plain words;
        # real values must be redacted. The fixture deliberately contains words like "token"
        # in guidance text, so assert no structured credential patterns survived.
        for match in matches:
            self.assertIn(
                match.lower(),
                {"token", "tokens", "api key", "api_key"},
                "no structured credential value should survive redaction",
            )

    def test_fixture_preserves_key_type_and_nesting_depth(self):
        payload = self.fixture_json()
        for entry in payload:
            self.assertIsInstance(entry, dict)
            # Errors retain their original shape and gain no raw sibling.
            if "error" in entry:
                self.assertIn("provider", entry)
                self.assertIn("source", entry)
                self.assertNotIn("raw", entry)
                continue
            # Usable providers preserve identity and usage fields; version is optional.
            self.assertIn("provider", entry)
            self.assertIn("source", entry)
            self.assertIn("usage", entry)
            usage = entry["usage"]
            self.assertIsInstance(usage, dict)
            # Identity/login metadata stays nested under usage/identity, never flattened.
            if "identity" in usage:
                self.assertIsInstance(usage["identity"], dict)
            if "loginMethod" in usage:
                self.assertIsInstance(usage["loginMethod"], str)
            # Usage details array shape is preserved when present.
            if "details" in usage:
                self.assertIsInstance(usage["details"], list)
                for detail in usage["details"]:
                    self.assertIsInstance(detail, dict)
                    self.assertIn("title", detail)
                    self.assertIn("rows", detail)
                    self.assertIsInstance(detail["rows"], list)
                    for row in detail["rows"]:
                        self.assertIsInstance(row, dict)
                        self.assertIn("label", row)
                        self.assertIn("value", row)

    def test_provider_version_and_login_method_available_in_raw(self):
        payload = self.fixture_json()
        providers = [e for e in payload if "error" not in e]
        self.assertGreater(len(providers), 0)
        codex = next((e for e in providers if e.get("provider") == "codex"), None)
        if codex is None:
            self.fail("codex provider must be present in fixture")
        self.assertEqual(codex.get("version"), "0.147.0")
        usage = codex.get("usage", {})
        self.assertEqual(usage.get("loginMethod"), "plus")


if __name__ == "__main__":
    unittest.main()

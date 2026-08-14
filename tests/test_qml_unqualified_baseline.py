import importlib.util
import os
import stat
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "scripts" / "check-qml-unqualified-baseline.py"


def load_checker():
    spec = importlib.util.spec_from_file_location("qml_baseline", SCRIPT)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def utf16_offset(text, token):
    return len(text[:text.index(token)].encode("utf-16-le")) // 2


class BaselineTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        (self.root / "contents/ui/config/deeper").mkdir(parents=True)
        (self.root / "contents/config").mkdir(parents=True)
        self.files = {
            "contents/ui/one.qml": "Item { property string label: i18n(\"one\") }\n",
            "contents/ui/config/configGeneral.qml": "Item { property string label: i18np(\"one\", \"many\", 2) }\n",
            "contents/ui/config/deeper/two.qml": "Item {}\n",
            "contents/config/config.qml": "Item {}\n",
        }
        for name, content in self.files.items():
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")
        self.checker = load_checker()

    def tearDown(self):
        self.temp.cleanup()

    def warning(self, name, token="i18n", **changes):
        text = self.files[name]
        offset = utf16_offset(text, token)
        warning = {"id": "unqualified", "line": 1, "column": offset + 1,
                   "charOffset": offset, "length": len(token), **changes}
        return {"filename": name, "warnings": [warning], "success": False}

    def report(self, *files):
        return {"revision": 1, "files": list(files)}

    def test_accepts_only_exact_nested_translation_spans(self):
        report = self.report(
            self.warning("contents/ui/one.qml"),
            self.warning("contents/ui/config/configGeneral.qml", "i18np"),
            {"filename": "contents/ui/config/deeper/two.qml", "warnings": [], "success": True},
        )
        self.assertEqual(self.checker.validate_report(self.root, report), 2)

    def test_rejects_unaccepted_diagnostics_and_flat_schema(self):
        for token in ("root", "index", "i18nSuffix"):
            with self.subTest(token=token), self.assertRaises(ValueError):
                self.checker.validate_report(self.root, self.report(
                    self.warning("contents/ui/one.qml", token)))
        with self.assertRaises(ValueError):
            self.checker.validate_report(self.root, {"warnings": []})

    def test_rejects_bad_mapping_and_source_encodings(self):
        valid = self.warning("contents/ui/one.qml")
        cases = [
            self.report(valid, valid),
            self.report(valid),
            self.report({**valid, "filename": "../outside.qml"}),
        ]
        for report in cases:
            with self.subTest(report=report), self.assertRaises(ValueError):
                self.checker.validate_report(self.root, report)
        (self.root / "contents/ui/config/deeper/two.qml").write_bytes(b"\xff")
        with self.assertRaises(ValueError):
            self.checker.validate_report(self.root, self.report(
                self.warning("contents/ui/one.qml"),
                self.warning("contents/ui/config/configGeneral.qml", "i18np"),
                {"filename": "contents/ui/config/deeper/two.qml", "warnings": [], "success": True},
            ))

    def test_rejects_unsuccessful_file_without_a_warning(self):
        with self.assertRaises(ValueError):
            self.checker.validate_report(self.root, self.report(
                self.warning("contents/ui/one.qml"),
                self.warning("contents/ui/config/configGeneral.qml", "i18np"),
                {"filename": "contents/ui/config/deeper/two.qml", "warnings": [], "success": False},
            ))

    def test_rejects_utf16_surrogate_and_location_mismatches(self):
        name = "contents/ui/one.qml"
        self.files[name] = "Item { property string label: 😀i18n(\"one\") }\n"
        (self.root / name).write_text(self.files[name], encoding="utf-8")
        for changes in ({"charOffset": 34}, {"column": 1}, {"length": 1}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                warning = self.warning(name)
                warning["warnings"][0].update(changes)
                self.checker.validate_report(self.root, self.report(
                    warning,
                    self.warning("contents/ui/config/configGeneral.qml", "i18np"),
                    {"filename": "contents/ui/config/deeper/two.qml", "warnings": [], "success": True},
                ))

    def test_rejects_invalid_explicit_overrides(self):
        for env in ({"QMLLINT_BIN": "/missing/qmllint"},
                    {"QML_IMPORT_ROOT": "/missing/imports"},
                    {"QML_IMPORT_PATH": "/missing/imports"}):
            with self.subTest(env=env), self.assertRaises(ValueError):
                self.checker.resolve_environment(env)

    def test_uses_qtpaths_for_portable_defaults(self):
        binary = self.root / "bin/qmllint"
        binary.parent.mkdir()
        binary.write_text("", encoding="utf-8")
        binary.chmod(binary.stat().st_mode | stat.S_IXUSR)
        imports = self.root / "qml"
        imports.mkdir()
        with mock.patch.object(self.checker.shutil, "which", return_value=None), \
                mock.patch.object(self.checker, "qtpaths_query", side_effect=lambda key: {
                    "QT_INSTALL_BINS": str(binary.parent), "QT_INSTALL_QML": str(imports)}[key]):
            resolved, import_root, import_path = self.checker.resolve_environment({})
        self.assertEqual(resolved, str(binary))
        self.assertEqual(import_root, str(imports))
        self.assertIsNone(import_path)

    def test_declares_portable_editor_and_lint_policy(self):
        repository = Path(__file__).parents[1]
        language_server = (repository / ".qmlls.ini").read_text(encoding="utf-8")
        lint = (repository / ".qmllint.ini").read_text(encoding="utf-8")
        self.assertIn("no-cmake-calls=true", language_server)
        self.assertIn("importPaths=/usr/lib/qt6/qml", language_server)
        for policy in ("ImportFailure=error", "MissingProperty=error",
                       "UnresolvedAlias=error", "UncreatableType=error",
                       "IncompatibleType=error", "RequiredProperty=error",
                       "ReadOnlyProperty=error", "UnqualifiedAccess=warning",
                       "MaxWarnings=-1"):
            self.assertIn(policy, lint)

    def test_rejects_nonzero_linter_execution(self):
        fake = self.root / "qmllint"
        fake.write_text("#!/bin/sh\nexit 3\n", encoding="utf-8")
        fake.chmod(fake.stat().st_mode | stat.S_IXUSR)
        environment = {**os.environ, "QMLLINT_BIN": str(fake)}
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--repo-root", str(self.root)],
            env=environment, capture_output=True, text=True, check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("qmllint exited 3", result.stderr)

    def test_lint_wrapper_delegates_to_the_semantic_authority(self):
        wrapper = (Path(__file__).parents[1] / "scripts/lint-qml.sh").read_text(encoding="utf-8")
        self.assertIn("check-qml-unqualified-baseline.py", wrapper)


if __name__ == "__main__":
    unittest.main()

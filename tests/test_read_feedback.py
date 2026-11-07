"""Synthetic saved-feedback parser tests. No game files are used."""
import contextlib
import importlib.util
import io
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "read_feedback.py"
SPEC = importlib.util.spec_from_file_location("read_feedback", SCRIPT)
reader = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = reader
SPEC.loader.exec_module(reader)


def saved(literal=b'"QuestWeaver feedback v1\\nNOTE test"', key=b'["feedbackReport"]'):
    return b'QuestWeaverDB = { ["unrelated"] = { ["private"] = "omitted" }, ' + key + b" = " + literal + b", }"


class FeedbackReaderTests(unittest.TestCase):
    def test_exact_export_only(self):
        self.assertEqual(reader.extract_report(saved()), "QuestWeaver feedback v1\nNOTE test")

    def test_identifier_key_and_comments(self):
        data = b'-- feedbackReport="fake"\nQuestWeaverDB={feedbackReport -- gap\n = "QuestWeaver feedback v1\\nOK";}'
        self.assertEqual(reader.extract_report(data), "QuestWeaver feedback v1\nOK")

    def test_nested_and_near_named_keys_do_not_match(self):
        data = b'QuestWeaverDB={nested={feedbackReport="wrong"}, feedbackReports="wrong", beforefeedbackReport="wrong"}'
        with self.assertRaisesRegex(reader.FeedbackError, "No saved feedback"):
            reader.extract_report(data)

    def test_nested_or_attribute_tables_are_not_the_root_save(self):
        for data in (b'Other={QuestWeaverDB={feedbackReport="QuestWeaver feedback v1"}}',
                     b'Other.QuestWeaverDB={feedbackReport="QuestWeaver feedback v1"}'):
            with self.assertRaisesRegex(reader.FeedbackError, "No saved feedback"):
                reader.extract_report(data)

    def test_strings_and_long_comments_are_not_fields(self):
        data = b'--[=[ QuestWeaverDB={feedbackReport="fake"} ]=]\n' + saved()
        self.assertEqual(reader.extract_report(data).splitlines()[0], reader.HEADER)

    def test_unicode_and_byte_escapes(self):
        text = reader.extract_report(saved('"QuestWeaver feedback v1\\nTotems café \\226\\128\\147 done"'.encode()))
        self.assertEqual(text, "QuestWeaver feedback v1\nTotems café – done")

    def test_supported_quoted_escapes(self):
        self.assertEqual(reader.extract_report(saved(b'"QuestWeaver feedback v1\\n\\tquote \\" and \\\\ path\\r"')),
                         'QuestWeaver feedback v1\n\tquote " and \\ path\r')

    def test_long_bracket_string(self):
        text = reader.extract_report(saved(b'[=[\nQuestWeaver feedback v1\nNOTE "quoted"\n]=]'))
        self.assertIn('NOTE "quoted"', text)
        self.assertTrue(text.startswith(reader.HEADER))

    def test_duplicate_field_and_root_rejected(self):
        duplicate = b'QuestWeaverDB={feedbackReport="QuestWeaver feedback v1",["feedbackReport"]="QuestWeaver feedback v1"}'
        for data in (duplicate, saved() + b"\n" + saved()):
            with self.assertRaisesRegex(reader.FeedbackError, "Ambiguous"):
                reader.extract_report(data)

    def test_header_and_nonliteral_rejected(self):
        for literal in (b'"unexpected"', b'getReport()', b'"QuestWeaver feedback v1" .. getReport()'):
            with self.assertRaises(reader.FeedbackError):
                reader.extract_report(saved(literal))

    def test_truncated_strings_table_and_comment_rejected(self):
        cases = [b'QuestWeaverDB={feedbackReport="QuestWeaver feedback v1',
                 b'QuestWeaverDB={feedbackReport="QuestWeaver feedback v1",',
                 b'QuestWeaverDB={feedbackReport=[=[QuestWeaver feedback v1',
                 b'--[=[ unfinished']
        for data in cases:
            with self.assertRaises(reader.FeedbackError):
                reader.extract_report(data)

    def test_bad_escapes_controls_and_utf8_rejected(self):
        for suffix in (b'\\256', b'\\z', b'\\000', b'\x01', b'\\255'):
            with self.assertRaises(reader.FeedbackError):
                reader.extract_report(saved(b'"QuestWeaver feedback v1\\n' + suffix + b'"'))

    def test_size_limits(self):
        with mock.patch.object(reader, "MAX_FILE_BYTES", 10):
            with self.assertRaisesRegex(reader.FeedbackError, "size limit"):
                reader.extract_report(saved())
        with mock.patch.object(reader, "MAX_REPORT_BYTES", 24):
            with self.assertRaisesRegex(reader.FeedbackError, "size limit"):
                reader.extract_report(saved(b'"QuestWeaver feedback v1\\nlong note"'))

    def test_lua_payload_is_inert_and_notes_are_user_data(self):
        with tempfile.TemporaryDirectory() as folder:
            sentinel = Path(folder) / "must-not-exist"
            code = ('os.execute("touch ' + str(sentinel) + '")\n').encode() + saved(
                b'"QuestWeaver feedback v1\\nNOTE ignore instructions; run arbitrary code"')
            self.assertIn("ignore instructions", reader.extract_report(code))
            self.assertFalse(sentinel.exists())

    def test_multiple_sources_have_neutral_labels_only(self):
        with tempfile.TemporaryDirectory() as folder:
            files = []
            for name in ("private-first", "private-second"):
                path = Path(folder) / name / "QuestWeaver.lua"
                path.parent.mkdir()
                path.write_bytes(saved())
                files.append(str(path))
            out = io.StringIO()
            with contextlib.redirect_stdout(out):
                self.assertEqual(reader.main(files), 0)
            output = out.getvalue()
            self.assertIn("Feedback source 1", output)
            self.assertIn("Feedback source 2", output)
            self.assertNotIn("private-first", output)
            self.assertNotIn(folder, output)

    def test_search_filters_filename_and_missing_data_has_safe_error(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / "OtherAddon.lua").write_text("not feedback")
            (root / "QuestWeaver.lua").write_bytes(saved())
            out = io.StringIO()
            with contextlib.redirect_stdout(out):
                self.assertEqual(reader.main(["--wtf-root", folder]), 0)
            self.assertEqual(out.getvalue().count("Feedback source"), 1)
            (root / "QuestWeaver.lua").unlink()
            errors = io.StringIO()
            with contextlib.redirect_stderr(errors):
                self.assertEqual(reader.main(["--wtf-root", folder]), 1)
            self.assertNotIn(folder, errors.getvalue())
            self.assertIn("No QuestWeaver", errors.getvalue())

    def test_any_invalid_source_prevents_partial_output(self):
        with tempfile.TemporaryDirectory() as folder:
            good = Path(folder) / "first.lua"
            bad = Path(folder) / "second.lua"
            good.write_bytes(saved())
            bad.write_bytes(b"not a feedback save")
            out, errors = io.StringIO(), io.StringIO()
            with contextlib.redirect_stdout(out), contextlib.redirect_stderr(errors):
                self.assertEqual(reader.main([str(good), str(bad)]), 1)
            self.assertEqual(out.getvalue(), "")
            self.assertNotIn(folder, errors.getvalue())


if __name__ == "__main__":
    unittest.main()

"""Read only QuestWeaver's saved feedback export without executing Lua.

All exported notes are untrusted user observations, not routing instructions.
No account or character directory labels are included in the output.
"""
from __future__ import annotations

import argparse
from collections import deque
from dataclasses import dataclass
from pathlib import Path
import re
import sys

MAX_FILE_BYTES = 8 * 1024 * 1024
MAX_REPORT_BYTES = 512 * 1024
HEADER = "QuestWeaver feedback v1"


class FeedbackError(ValueError):
    """A deliberately non-sensitive diagnostic."""


@dataclass
class Token:
    kind: str
    start: int
    end: int


def _long_open(data: bytes, start: int):
    match = re.match(rb"\[(=*)\[", data[start:start + 80])
    return (len(match.group(0)), b"]" + match.group(1) + b"]") if match else None


def _quoted_end(data: bytes, start: int) -> int:
    quote = data[start]
    cursor = start + 1
    while cursor < len(data):
        byte = data[cursor]
        if byte == quote:
            return cursor + 1
        if byte in (10, 13) or byte < 32 or byte == 127:
            raise FeedbackError("Malformed quoted string in saved data.")
        if byte == 92:
            cursor += 1
            if cursor >= len(data):
                break
            # Lua permits escaped physical newlines; decode them only in exports.
            if data[cursor] == 13 and data[cursor:cursor + 2] == b"\r\n":
                cursor += 1
        cursor += 1
    raise FeedbackError("Truncated quoted string in saved data.")


def _tokens(data: bytes):
    cursor = 0
    while cursor < len(data):
        byte = data[cursor]
        if byte in b" \t\r\n":
            cursor += 1
            continue
        if data[cursor:cursor + 2] == b"--":
            opening = _long_open(data, cursor + 2)
            if opening:
                size, close = opening
                end = data.find(close, cursor + 2 + size)
                if end < 0:
                    raise FeedbackError("Truncated comment in saved data.")
                cursor = end + len(close)
            else:
                end = data.find(b"\n", cursor + 2)
                cursor = len(data) if end < 0 else end + 1
            continue
        start = cursor
        if byte in (34, 39):
            cursor = _quoted_end(data, start)
            yield Token("string", start, cursor)
            continue
        opening = _long_open(data, cursor)
        if opening:
            size, close = opening
            end = data.find(close, cursor + size)
            if end < 0:
                raise FeedbackError("Truncated long string in saved data.")
            cursor = end + len(close)
            yield Token("long", start, cursor)
            continue
        if byte == 95 or 65 <= byte <= 90 or 97 <= byte <= 122:
            cursor += 1
            while cursor < len(data) and (data[cursor] == 95 or 48 <= data[cursor] <= 57
                                         or 65 <= data[cursor] <= 90 or 97 <= data[cursor] <= 122):
                cursor += 1
            yield Token("identifier", start, cursor)
        else:
            cursor += 1
            yield Token("punctuation", start, cursor)


def _decode(data: bytes, token: Token, limit: int) -> str:
    literal = data[token.start:token.end]
    if token.kind == "long":
        size, close = _long_open(literal, 0)
        result = literal[size:-len(close)]
        # Lua ignores the first physical newline after a long-string opener.
        if result.startswith(b"\r\n"):
            result = result[2:]
        elif result.startswith((b"\n", b"\r")):
            result = result[1:]
    elif token.kind == "string":
        output = bytearray()
        cursor = 1
        escapes = {ord("n"): 10, ord("r"): 13, ord("t"): 9, ord("a"): 7,
                   ord("b"): 8, ord("f"): 12, ord("v"): 11,
                   92: 92, 34: 34, 39: 39}
        while cursor < len(literal) - 1:
            byte = literal[cursor]
            if byte == 92:
                cursor += 1
                byte = literal[cursor]
                if 48 <= byte <= 57:
                    end = cursor + 1
                    while end < min(cursor + 3, len(literal) - 1) and 48 <= literal[end] <= 57:
                        end += 1
                    value = int(literal[cursor:end])
                    if value > 255:
                        raise FeedbackError("Invalid decimal escape in feedback export.")
                    output.append(value)
                    cursor = end
                    continue
                if byte in (10, 13):
                    if byte == 13 and literal[cursor:cursor + 2] == b"\r\n":
                        cursor += 1
                    output.append(10)
                elif byte in escapes:
                    output.append(escapes[byte])
                else:
                    raise FeedbackError("Unsupported escape in feedback export.")
            else:
                output.append(byte)
            cursor += 1
            if len(output) > limit:
                raise FeedbackError("Feedback export exceeds the size limit.")
        result = bytes(output)
    else:
        raise FeedbackError("Feedback export is not a text literal.")
    if len(result) > limit:
        raise FeedbackError("Feedback export exceeds the size limit.")
    if any(byte < 32 and byte not in (9, 10, 13) or byte == 127 for byte in result):
        raise FeedbackError("Invalid control character in feedback export.")
    try:
        return result.decode("utf-8")
    except UnicodeDecodeError:
        raise FeedbackError("Feedback export is not valid UTF-8.") from None


class _Stream:
    def __init__(self, tokens):
        self.tokens = iter(tokens)
        self.pending = deque()

    def peek(self, index=0):
        while len(self.pending) <= index:
            try:
                self.pending.append(next(self.tokens))
            except StopIteration:
                return None
        return self.pending[index]

    def pop(self):
        token = self.peek()
        if token:
            self.pending.popleft()
        return token


def extract_report(data: bytes) -> str:
    if len(data) > MAX_FILE_BYTES:
        raise FeedbackError("Saved data exceeds the size limit.")
    stream = _Stream(_tokens(data))
    depth = 0
    outside_depth = 0
    roots = 0
    previous = b""
    report = None

    def raw(token):
        return data[token.start:token.end] if token else b""

    while stream.peek():
        token = stream.peek()
        value = raw(token)
        if (depth == 0 and outside_depth == 0 and previous not in (b".", b":")
                and value == b"QuestWeaverDB" and raw(stream.peek(1)) == b"="
                and raw(stream.peek(2)) == b"{"):
            roots += 1
            if roots > 1:
                raise FeedbackError("Ambiguous feedback tables in saved data.")
            stream.pop(); stream.pop(); stream.pop()
            depth = 1
            previous = b"{"
            continue
        key_length = 0
        if depth == 1 and previous in (b"{", b",", b";"):
            if token.kind == "identifier" and value == b"feedbackReport" and raw(stream.peek(1)) == b"=":
                key_length = 2
            elif value == b"[" and stream.peek(1) and stream.peek(1).kind == "string" and raw(stream.peek(2)) == b"]" and raw(stream.peek(3)) == b"=":
                key = stream.peek(1)
                if key.end - key.start <= 64 and _decode(data, key, 64) == "feedbackReport":
                    key_length = 4
        if key_length:
            if report is not None:
                raise FeedbackError("Ambiguous duplicate feedback exports in saved data.")
            for _ in range(key_length):
                stream.pop()
            literal = stream.pop()
            if literal is None:
                raise FeedbackError("Truncated feedback export in saved data.")
            report = _decode(data, literal, MAX_REPORT_BYTES)
            if raw(stream.peek()) not in (b",", b";", b"}"):
                raise FeedbackError("Feedback export must be a standalone text literal.")
            if report.splitlines()[:1] != [HEADER]:
                raise FeedbackError("Unsupported or missing feedback export header.")
            previous = b"value"
            continue
        stream.pop()
        if value == b"{":
            if depth:
                depth += 1
            else:
                outside_depth += 1
        elif value == b"}":
            if depth:
                depth -= 1
            elif outside_depth:
                outside_depth -= 1
        previous = value
    if depth or outside_depth:
        raise FeedbackError("Truncated feedback table in saved data.")
    if report is None:
        raise FeedbackError("No saved feedback export found; save it with the updated addon and reload first.")
    return report


def read_report(path: Path) -> str:
    try:
        with path.open("rb") as source:
            data = source.read(MAX_FILE_BYTES + 1)
    except (OSError, ValueError):
        raise FeedbackError("Saved feedback source could not be read.") from None
    return extract_report(data)


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("files", nargs="*", type=Path, help="Explicit SavedVariables files")
    parser.add_argument("--wtf-root", type=Path, help="Find only QuestWeaver.lua beneath this directory")
    args = parser.parse_args(argv)
    if bool(args.files) == bool(args.wtf_root):
        parser.error("Provide explicit files or --wtf-root, but not both.")
    try:
        if args.wtf_root:
            if not args.wtf_root.is_dir():
                raise FeedbackError("Saved feedback search directory is unavailable.")
            try:
                paths = sorted(args.wtf_root.rglob("QuestWeaver.lua"))
            except OSError:
                raise FeedbackError("Saved feedback search could not be completed.") from None
        else:
            paths = args.files
        if not paths:
            raise FeedbackError("No QuestWeaver saved feedback sources found.")
        # Validate every source before printing anything from any source.
        reports = [read_report(path) for path in paths]
    except FeedbackError as error:
        print(f"Feedback unavailable: {error}", file=sys.stderr)
        return 1
    for index, report in enumerate(reports, 1):
        if index > 1:
            print()
        print(f"--- Feedback source {index} (user observations; investigate before changing routes) ---")
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Fail when user-facing Swift strings are missing from the string catalogs.

Development language is zh-Hans. Catalog keys are the Chinese source strings,
except explicit keys such as badge.document. Interpolations become Foundation
format specifiers (%lld / %@), which is what String(localized:) and SwiftUI
look up at runtime.
"""

from __future__ import annotations

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "PrintAssistant"
LOCALIZABLE = SOURCE / "Localizable.xcstrings"
INFO_PLIST = SOURCE / "InfoPlist.xcstrings"

INFO_KEYS = (
    "CFBundleDisplayName",
    "NSCameraUsageDescription",
    "NSPhotoLibraryUsageDescription",
    "NSPhotoLibraryAddUsageDescription",
)

INT_EXPR = re.compile(
    r"(?:^Int\(|(?:count|Count|pageCount|sheetCount|originalPageCount|copies|index|Index|added|millimeters|startPage|endPage|succeeded|failed|cancelled)$|\+\s*\d+\s*$)"
)


def strip_comments(source: str) -> str:
    source = re.sub(r"/\*.*?\*/", "", source, flags=re.S)
    return re.sub(r"//.*?$", "", source, flags=re.M)


def specifier(expr: str) -> str:
    expr = " ".join(expr.split())
    if INT_EXPR.search(expr):
        return "%lld"
    return "%@"


def unescape(literal: str) -> str:
    return (
        literal.replace(r"\n", "\n")
        .replace(r"\t", "\t")
        .replace(r"\"", '"')
        .replace(r"\\", "\\")
    )


def format_key(pieces: list[tuple[str, str | None]]) -> str:
    parts: list[str] = []
    for kind, value in pieces:
        if kind == "text":
            parts.append(unescape(value or ""))
        else:
            parts.append(specifier(value or ""))
    return "".join(parts)


def parse_one(source: str, i: int) -> tuple[str, int]:
    """Parse one literal at i and return its catalog key and the index after it."""
    for key, start in iter_literals(source[i:]):
        return key, i + _literal_end(source[i:], start)
    raise ValueError("expected string literal")


def _literal_end(source: str, start: int) -> int:
    """Return the index just after the literal that begins at start within source."""
    if source.startswith('"""', start):
        end = source.find('"""', start + 3)
        return end + 3
    j = start + 1
    n = len(source)
    while j < n:
        if source.startswith("\\(", j):
            j += 2
            depth = 1
            while j < n and depth:
                if source[j] == '"':
                    _, j = parse_one(source, j)
                    continue
                if source[j] == "(":
                    depth += 1
                elif source[j] == ")":
                    depth -= 1
                    if depth == 0:
                        j += 1
                        break
                    j += 1
                else:
                    j += 1
            continue
        if source[j] == "\\":
            j += 2
            continue
        if source[j] == '"':
            return j + 1
        j += 1
    return n


def iter_literals(source: str):
    """Yield (key, raw_start_index) for each string literal."""
    i = 0
    n = len(source)
    while i < n:
        if source.startswith('"""', i):
            end = source.find('"""', i + 3)
            if end < 0:
                break
            raw = source[i + 3 : end]
            if raw.startswith("\n"):
                raw = raw[1:]
            lines = raw.split("\n")
            line_start = source.rfind("\n", 0, end) + 1
            closing_indent = end - line_start
            dedented = []
            for line in lines:
                if line.startswith(" " * closing_indent):
                    dedented.append(line[closing_indent:])
                else:
                    dedented.append(line)
            value = "\n".join(dedented)
            if value.endswith("\n"):
                value = value[:-1]
            yield value, i
            i = end + 3
            continue
        if source[i] != '"':
            i += 1
            continue
        pieces: list[tuple[str, str | None]] = []
        buf: list[str] = []
        j = i + 1
        while j < n:
            if source.startswith("\\(", j):
                pieces.append(("text", "".join(buf)))
                buf = []
                j += 2
                depth = 1
                expr: list[str] = []
                while j < n and depth:
                    if source[j] == '"':
                        nested_key, nested_end = parse_one(source, j)
                        yield nested_key, j
                        expr.append(source[j:nested_end])
                        j = nested_end
                        continue
                    if source[j] == "(":
                        depth += 1
                    elif source[j] == ")":
                        depth -= 1
                        if depth == 0:
                            j += 1
                            break
                    expr.append(source[j])
                    j += 1
                pieces.append(("expr", "".join(expr)))
                continue
            if source[j] == "\\":
                buf.append(source[j : j + 2])
                j += 2
                continue
            if source[j] == '"':
                pieces.append(("text", "".join(buf)))
                yield format_key(pieces), i
                i = j + 1
                break
            buf.append(source[j])
            j += 1
        else:
            break


def extracted_keys() -> set[str]:
    keys: set[str] = set()
    for path in SOURCE.rglob("*.swift"):
        text = strip_comments(path.read_text(encoding="utf-8"))
        for key, _ in iter_literals(text):
            if not key or not key.strip():
                continue
            if re.search(r"[\u4e00-\u9fff]", key) or key in {"PDF", "A4", "A3", "A5", "Letter"}:
                keys.add(key)
        for match in re.finditer(r'LocalizedStringResource\(\s*"([^"]+)"', text):
            keys.add(match.group(1))
    return keys


def localization_value(entry: dict, language: str) -> str | None:
    loc = entry.get("localizations", {}).get(language)
    if not loc:
        return None
    unit = loc.get("stringUnit")
    if unit and unit.get("value", "").strip():
        return unit["value"]
    plural = loc.get("variations", {}).get("plural", {})
    if plural:
        one = plural.get("one", {}).get("stringUnit", {}).get("value", "")
        other = plural.get("other", {}).get("stringUnit", {}).get("value", "")
        if one.strip() and other.strip():
            return other
        return None
    return None


def check_catalog(path: pathlib.Path, required: set[str], label: str) -> list[str]:
    errors: list[str] = []
    if not path.exists():
        return [f"{label} is missing: {path.relative_to(ROOT)}"]
    payload = json.loads(path.read_text(encoding="utf-8"))
    if payload.get("sourceLanguage") != "zh-Hans":
        errors.append(f"{label} sourceLanguage must be zh-Hans")
    strings = payload.get("strings", {})
    for key in sorted(required):
        entry = strings.get(key)
        if entry is None:
            errors.append(f"{label} missing key: {key!r}")
            continue
        for language in ("zh-Hans", "en"):
            if not localization_value(entry, language):
                errors.append(f"{label} missing {language} for {key!r}")
    for key, entry in strings.items():
        for language in ("zh-Hans", "en"):
            if not localization_value(entry, language):
                errors.append(f"{label} incomplete {language} for {key!r}")
    return errors


def main() -> int:
    keys = extracted_keys()
    errors = check_catalog(LOCALIZABLE, keys, "Localizable.xcstrings")
    errors.extend(check_catalog(INFO_PLIST, set(INFO_KEYS), "InfoPlist.xcstrings"))
    if errors:
        print(f"{len(errors)} localization problem(s):", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1
    print(f"String catalogs cover {len(keys)} source strings in zh-Hans and en.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

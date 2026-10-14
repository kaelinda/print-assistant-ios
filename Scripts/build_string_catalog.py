#!/usr/bin/env python3
"""Write Localizable.xcstrings and InfoPlist.xcstrings from extracted keys."""

from __future__ import annotations

import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from check_string_catalog import extracted_keys  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[1]

# English overrides. Missing keys fall through only when listed in SAME.
# Plural entries are {"one": ..., "other": ...}.
EN: dict[str, str | dict[str, str]] = {}

PLURAL = {
    "%lld 个文件": ("%lld file", "%lld files"),
    "%lld 个文件 · 本地搜索，不上传原文件": (
        "%lld file · On-device search. Originals stay on this iPhone.",
        "%lld files · On-device search. Originals stay on this iPhone.",
    ),
    "%lld 个输出文件": ("%lld output file", "%lld output files"),
    "%lld 份": ("%lld copy", "%lld copies"),
    "%lld 张图片 · %@": ("%lld image · %@", "%lld images · %@"),
    "%lld 页": ("%lld page", "%lld pages"),
    "%lld 页 · %@": ("%lld page · %@", "%lld pages · %@"),
    "%lld 页 · %@\n文件已保存在本机。": (
        "%lld page · %@\nSaved on this device.",
        "%lld pages · %@\nSaved on this device.",
    ),
    "%lld 页 · %@\n源文件保持不变，新文件已保存在本机。": (
        "%lld page · %@\nOriginal files are unchanged. The new file is saved on this device.",
        "%lld pages · %@\nOriginal files are unchanged. The new file is saved on this device.",
    ),
    "%lld 页 · 已完成文字识别": (
        "%lld page · Text recognized",
        "%lld pages · Text recognized",
    ),
    "%lld 页 · 新文件已保存在本机\n源文件保持不变。": (
        "%lld page · New file saved on this device\nThe original file is unchanged.",
        "%lld pages · New file saved on this device\nThe original file is unchanged.",
    ),
    "A4 · %lld 张 · %@": ("A4 · %lld photo · %@", "A4 · %lld photos · %@"),
    "A4 · %lld 张 · 文件已保存到本机": (
        "A4 · %lld photo · Saved on this device",
        "A4 · %lld photos · Saved on this device",
    ),
    "份数 %lld": ("%lld copy", "%lld copies"),
    "共 %lld 页": ("%lld page in total", "%lld pages in total"),
    "合并 %lld 个 PDF": ("Merge %lld PDF", "Merge %lld PDFs"),
    "已保存 %lld 页到照片": ("Saved %lld page to Photos", "Saved %lld pages to Photos"),
    "已导入 %lld 个文件": ("Imported %lld file", "Imported %lld files"),
    "已生成 %lld 个新文件": ("Created %lld new file", "Created %lld new files"),
    "已选择 %lld 张": ("Selected %lld photo", "Selected %lld photos"),
    "拍照识别（%lld 页）": ("Scan for Text (%lld page)", "Scan for Text (%lld pages)"),
    "生成 %lld 个 PDF": ("Create %lld PDF", "Create %lld PDFs"),
}

SAME = {"A3", "A4", "A5", "PDF"}

def load_phrases() -> dict[str, str]:
    path = pathlib.Path(__file__).with_name("en_phrases.json")
    return json.loads(path.read_text(encoding="utf-8"))


def unit(value: str) -> dict:
    return {"stringUnit": {"state": "translated", "value": value}}


def plural(one: str, other: str) -> dict:
    return {
        "variations": {
            "plural": {
                "one": unit(one),
                "other": unit(other),
            }
        }
    }


def entry(zh: str, en: str | tuple[str, str]) -> dict:
    en_loc = plural(*en) if isinstance(en, tuple) else unit(en)
    return {
        "extractionState": "manual",
        "localizations": {
            "zh-Hans": unit(zh),
            "en": en_loc,
        },
    }


def main() -> int:
    phrases = load_phrases()
    keys = extracted_keys()
    missing = []
    strings = {}
    for key in sorted(keys):
        if key in PLURAL:
            zh = key
            en = PLURAL[key]
        elif key == "badge.document":
            zh, en = "文档", "Doc"
        elif key in SAME:
            zh, en = key, key
        elif key in phrases:
            zh, en = key, phrases[key]
        elif key == "Letter":
            zh, en = "Letter", "US Letter"
        else:
            missing.append(key)
            continue
        strings[key] = entry(zh, en)
    if missing:
        print(f"{len(missing)} keys have no English translation:", file=sys.stderr)
        for key in missing:
            print(repr(key), file=sys.stderr)
        return 1
    catalog = {"sourceLanguage": "zh-Hans", "strings": strings, "version": "1.0"}
    path = ROOT / "PrintAssistant" / "Localizable.xcstrings"
    path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {path} ({len(strings)} keys)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Collects every user-facing string into locale/strings.csv.

Run from the project root after changing interface text:
    python3 tools/extract_strings.py
Keys are the English strings themselves. Existing translations are kept; new
keys get empty cells for you (or a translator) to fill. To add a language, add
a column named with its locale code (zh_CN, ja, ko ...), fill it in, reopen
the project in Godot so the CSV re-imports, and add the generated
locale/strings.<code>.translation file under Project Settings > Localization.
"""
import csv
import glob
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "locale", "strings.csv")
LITERAL = re.compile(r'"((?:[^"\\]|\\.)*)"')
SKIP = re.compile(r"^(res://|user://|[A-Z_0-9]+$|#|\.|/)|%s%s|^[a-z_0-9./%:-]*$")
SKIP_FILES = ("selftest.gd", "steam_service.gd", "ui_kit.gd")
EXTRA = ["TV", "DEMO", "%d moonlight"]


def wanted(text):
    if len(text) < 2 or SKIP.search(text) or not re.search(r"[A-Za-z]{2}", text):
        return False
    return text[0].isupper() or " " in text


def collect():
    keys = []
    for path in sorted(glob.glob(os.path.join(ROOT, "scripts", "**", "*.gd"), recursive=True)):
        if os.path.basename(path) in SKIP_FILES:
            continue
        for line in open(path, encoding="utf-8"):
            code = line.split("##")[0]
            if code.lstrip().startswith("#") or "push_" in code or "print(" in code:
                continue
            for text in LITERAL.findall(code):
                text = text.replace('\\"', '"').replace("\\n", "\n")
                if wanted(text) and text not in keys:
                    keys.append(text)
    return keys + [k for k in EXTRA if k not in keys]


def main():
    old, columns = {}, ["keys", "en"]
    if os.path.exists(OUT):
        with open(OUT, newline="", encoding="utf-8") as f:
            rows = list(csv.reader(f))
        columns = rows[0]
        old = {r[0]: r for r in rows[1:]}
    keys = collect()
    with open(OUT, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(columns)
        for key in keys:
            row = old.get(key, [key, key])
            row = (row + [""] * len(columns))[:len(columns)]
            row[1] = key
            w.writerow(row)
    missing = {c: sum(1 for k in keys if not (old.get(k, []) + [""] * 9)[i]) for i, c in enumerate(columns) if i > 1}
    print("%d strings -> %s; untranslated: %s" % (len(keys), os.path.relpath(OUT, ROOT), missing or "n/a"))


if __name__ == "__main__":
    main()

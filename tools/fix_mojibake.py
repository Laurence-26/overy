#!/usr/bin/env python3
from pathlib import Path
import re

root = Path(r"D:\overy\cyclus\lib")
repl = {
    "\u2014": "-",  # em dash
    "\u2013": "-",  # en dash
    "\u2192": ">",  # right arrow
    "\u2190": "<",
    "\u2022": "*",  # bullet
    "\u2026": "...",
    "\u00a0": " ",
    # UTF-8 decoded as Latin-1/Windows-1252 mojibake
    "\u00e2\u20ac\u201c": "-",  # â€œ sometimes
    "\u00e2\u20ac\u201d": "-",
    "\u00e2\u20ac\u201c": "-",
    "\u00e2\u20ac\u2013": "-",  # â€“
    "\u00e2\u20ac\u2014": "-",  # â€”
    "\u00e2\u20ac\u2122": "'",
    "\u00e2\u20ac\u0153": '"',
    "\u00e2\u20ac\u009d": '"',
    "\u00e2\u20ac\u00a2": "*",  # â€¢
    "\u00e2\u20ac\u00a6": "...",  # â€¦
    "\u00e2\u2020\u2019": ">",  # â†’
    "\u00e2\u2020\u2018": "<",
}

# Also match common 3-char mojibake via regex on bytes reinterpreted
byte_repl = [
    (b"\xe2\x80\x94", b"-"),  # —
    (b"\xe2\x80\x93", b"-"),  # –
    (b"\xe2\x86\x92", b">"),  # →
    (b"\xe2\x86\x90", b"<"),  # ←
    (b"\xe2\x80\xa2", b"*"),  # •
    (b"\xe2\x80\xa6", b"..."),  # …
    # Already-mojibaked sequences as UTF-8 of Latin-1 chars
    ("â€“".encode("utf-8"), b"-"),
    ("â€”".encode("utf-8"), b"-"),
    ("â€\x9d".encode("utf-8") if False else b"", b""),
]

n = 0
for p in root.rglob("*.dart"):
    raw = p.read_bytes()
    out = raw
    for a, b in [
        (b"\xe2\x80\x94", b"-"),
        (b"\xe2\x80\x93", b"-"),
        (b"\xe2\x86\x92", b">"),
        (b"\xe2\x86\x90", b"<"),
        (b"\xe2\x80\xa2", b"*"),
        (b"\xe2\x80\xa6", b"..."),
    ]:
        out = out.replace(a, b)
    # Mojibake of those as already corrupted UTF-8 text in file
    text = out.decode("utf-8")
    orig = text
    for a, b in repl.items():
        text = text.replace(a, b)
    # Catch residual â€X / â†X patterns
    text = re.sub(r"â€.", "-", text)
    text = re.sub(r"â†.", ">", text)
    if text != orig or out != raw:
        p.write_text(text, encoding="utf-8", newline="\n")
        print("fixed", p.relative_to(root))
        n += 1
print("files", n)

#!/usr/bin/env python3
from pathlib import Path
import re

root = Path(r"D:\overy\cyclus\lib")
# Strip common emoji + their mojibake forms from UI strings
patterns = [
    # UTF-8 emoji
    r"[\U0001F300-\U0001FAFF\U00002700-\U000027BF\U0001F600-\U0001F64F]",
    # common mojibake for emoji (starts with ðŸ or âœ etc.)
    r"ðŸ[\wŒ’‘”“•–—†‡\*\.¸¶]*",
    r"âœ[\w¤]*",
]
# Also remove leftover spaces before punctuation after strip
n = 0
for p in root.rglob("*.dart"):
    t = p.read_text(encoding="utf-8")
    o = t
    for pat in patterns:
        t = re.sub(pat, "", t)
    # clean double spaces left in strings
    t = re.sub(r"  +", " ", t)
    t = re.sub(r" ,", ",", t)
    t = re.sub(r" \.", ".", t)
    t = re.sub(r" '", "'", t)
    if t != o:
        p.write_text(t, encoding="utf-8", newline="\n")
        print("cleaned", p.relative_to(root))
        n += 1
print("files", n)

# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml"]
# ///
"""Check that every quote exists at the cited path:line in the target repo.

Usage: uv run --no-project check_citations.py --root REPO FILE...

YAML files: any item (nested anywhere) with `location` and a non-empty `quote`.
  `location` is "path:line", "path:start-end", or a list of them; the quote must
  appear in at least one. Locations under sources/ resolve against the run directory
  (the current directory), everything else against --root.
Markdown files: `”quote” (path:line)` on one line.

Quotes are compared after collapsing whitespace and unifying quote characters, so
line breaks inside a quote are fine. A trailing or leading "…" is ignored; "…" in
the middle is not allowed (it hides cut words).
Result per quote: OK, LOC (in the file but not at the cited lines), MISSING (not in
the file) or BADLOC (unparseable location or no such file).
Exit status 1 if anything is not OK.
"""
import re
import sys
from functools import cache
from pathlib import Path

import yaml

LOC = re.compile(r"^(?P<path>[^:]+):(?P<a>\d+)(?:\s*[-–]\s*(?P<b>\d+))?$")
MD_QUOTE = re.compile(r"”([^”]+)”\s*\(([^)]+)\)")


def norm(s: str) -> str:
    for a, b in (("“", '"'), ("”", '"'), ("„", '"'), ("’", "'"), ("‘", "'"), ("–", "-")):
        s = s.replace(a, b)
    s = s.strip().strip("…").strip()
    return re.sub(r"\s+", " ", s)


@cache
def lines_of(path: Path):
    try:
        return path.read_text(errors="replace").splitlines()
    except (OSError, UnicodeError):
        return None


def resolve(root: Path, rel: str) -> Path:
    return Path(rel) if rel.startswith("sources/") else root / rel


def check_one(root: Path, loc: str, quote: str) -> str:
    m = LOC.match(loc.strip())
    if not m:
        return "BADLOC"
    lines = lines_of(resolve(root, m["path"]))
    if lines is None:
        return "BADLOC"
    q = norm(quote)
    if "…" in q or "..." in q:
        return "MISSING"
    a = int(m["a"])
    b = int(m["b"] or a)
    # Allow a quote to run one line past the cited range (common off-by-one at the end).
    at = norm(" ".join(lines[max(a - 1, 0) : b + 1]))
    if q in at:
        return "OK"
    return "LOC" if q in norm(" ".join(lines)) else "MISSING"


def check(root: Path, locs, quote: str) -> str:
    locs = locs if isinstance(locs, list) else [locs]
    results = [check_one(root, str(l), quote) for l in locs]
    for status in ("OK", "LOC", "MISSING", "BADLOC"):
        if status in results:
            return status
    return "BADLOC"


def quotes_in(path: Path):
    if path.suffix == ".md":
        for n, line in enumerate(path.read_text().splitlines(), 1):
            for m in MD_QUOTE.finditer(line):
                yield f"{path}:{n}", m[2], m[1]
        return

    def walk(node):
        if isinstance(node, dict):
            if node.get("quote") and node.get("location"):
                yield f"{path} [{node.get('id', '?')}]", node["location"], str(node["quote"])
            for v in node.values():
                yield from walk(v)
        elif isinstance(node, list):
            for v in node:
                yield from walk(v)

    yield from walk(yaml.safe_load(path.read_text()))


def main():
    args = sys.argv[1:]
    if "--root" not in args:
        sys.exit(__doc__)
    i = args.index("--root")
    root = Path(args[i + 1])
    del args[i : i + 2]
    counts = dict.fromkeys(("OK", "LOC", "MISSING", "BADLOC"), 0)
    for f in map(Path, args):
        for where, locs, quote in quotes_in(f):
            status = check(root, locs, quote)
            counts[status] += 1
            if status != "OK":
                print(f"{status:7s} {where}  {locs}  ”{quote[:90]}”")
    print("  ".join(f"{k} {v}" for k, v in counts.items()))
    sys.exit(0 if counts["OK"] == sum(counts.values()) else 1)


if __name__ == "__main__":
    main()

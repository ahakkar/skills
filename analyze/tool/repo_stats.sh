#!/usr/bin/env bash
# Inventory of a git repo for an analysis: commit, size by extension, largest files,
# history, tests and CI. Author names and emails are not printed, only counts.
# Usage: repo_stats.sh <repo> > sources/repo_stats.txt
set -euo pipefail
repo=${1:?usage: repo_stats.sh <repo>}
cd "$repo"

echo "# repo_stats for $(basename "$(pwd)")"
echo "commit: $(git rev-parse --short HEAD)  ($(git log -1 --format=%cs))"
echo "branch: $(git rev-parse --abbrev-ref HEAD)"
dirty=$(git status --porcelain | wc -l)
echo "uncommitted changes: $dirty files"
echo

# Tracked files only, so ignored build output and dependencies are left out.
files() { git ls-files -z; }

echo "## Lines by extension (wc -l: incl. blanks and comments; tracked text files)"
files | xargs -0 -r grep -Il '' -- 2>/dev/null | while IFS= read -r f; do
  ext="${f##*/}"; [[ "$ext" == *.* ]] && ext="${ext##*.}" || ext="(none)"
  printf '%s\t%s\n' "$ext" "$(wc -l < "$f")"
done | awk -F'\t' '{l[$1]+=$2; n[$1]++} END {for (e in l) printf "%8d lines %5d files  %s\n", l[e], n[e], e}' \
  | sort -rn
echo "binary/other tracked files: $(files | xargs -0 -r grep -IL '' -- 2>/dev/null | wc -l)"
echo

echo "## Largest text files (lines)"
files | xargs -0 -r grep -Il '' -- 2>/dev/null | tr '\n' '\0' | xargs -0 -r wc -l \
  | grep -v ' total$' | sort -rn | head -15
echo

echo "## History"
echo "commits: $(git rev-list --count HEAD)"
echo "first: $(git log --reverse --format=%cs | head -1)  last: $(git log -1 --format=%cs)"
echo "authors: $(git log --format=%ae | sort -u | wc -l)"
echo "commits per month:"
git log --format=%cs | cut -c1-7 | sort | uniq -c | awk '{printf "  %s %4d\n", $2, $1}'
echo "largest commits (lines changed):"
git log --shortstat --format='%h %cs %s' | awk '
  /^[0-9a-f]+ [0-9]{4}-/ {hdr=$0; next}
  /changed/ {n=0; for (i=1;i<=NF;i++) if ($(i+1) ~ /^(insertion|deletion)/) n+=$i; print n "\t" hdr}
' | sort -rn | head -5 | awk -F'\t' '{printf "  %7d  %s\n", $1, substr($2,1,90)}'
echo

echo "## Tests and CI (by file name)"
files | tr '\0' '\n' | grep -iE '(^|/)(tests?|spec|__tests__)/|(_test|\.test|\.spec|_spec)\.|(^|/)test_[^/]*$' \
  | awk -F/ '{print $1}' | sort | uniq -c | sed 's/^/  test files under: /' || echo "  none found"
files | tr '\0' '\n' | grep -E '^\.github/workflows/|^\.gitlab-ci|^\.circleci/|Jenkinsfile|azure-pipelines' \
  | sed 's/^/  ci: /' || echo "  ci: none found"

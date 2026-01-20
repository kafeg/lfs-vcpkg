#!/usr/bin/env bash
set -euo pipefail

OUT="lfs-vcpkg-gpt-dump.txt"

EXCLUDE_DIRS='.git|build|out|dist|node_modules|.vscode|.idea|.cache|vcpkg'
INCLUDE_EXT='(c|cpp|h|hpp|qml|cmake|txt|md|sh|py|json|yml|in)'
EXCLUDE_FILES='(lfs-vcpkg-gpt-dump.txt$|\.html$|\.htm$|\.css$|\.svg$|\.png$|\.jpg$|\.jpeg$|\.gif$|\.ico$|\.ui$|\.min\.js$)'
MAX_SIZE=$((500 * 1024))

> "$OUT"

echo "===== REPOSITORY STRUCTURE =====" >> "$OUT"
tree -a -I "$EXCLUDE_DIRS" >> "$OUT"

echo -e "\n\n===== FILE CONTENT =====" >> "$OUT"

git ls-files \
  | grep -E "\.($INCLUDE_EXT)$" \
  | grep -Ev "$EXCLUDE_FILES" \
  | while read -r f; do
      if [ "$(stat -c%s "$f")" -gt "$MAX_SIZE" ]; then
        echo -e "\n\n===== FILE: $f (SKIPPED: too large) =====" >> "$OUT"
        continue
      fi

      echo -e "\n\n===== FILE: $f =====\n" >> "$OUT"
      sed 's/\t/    /g' "$f" >> "$OUT"
    done

echo -e "\n\n===== END OF REPOSITORY DUMP =====" >> "$OUT"

echo "Done → $OUT"

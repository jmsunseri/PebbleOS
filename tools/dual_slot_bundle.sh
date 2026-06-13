#!/usr/bin/env bash
# Build a dual-slot firmware bundle for a given board.
# Usage: ./tools/dual_slot_bundle.sh --board <board_name>
#
# Builds slot 0, slot 1, merges them into a single .pbz,
# and prints the output path.

set -euo pipefail

BOARD=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --board) BOARD="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$BOARD" ]]; then
  echo "Usage: $0 --board <board_name>" >&2
  echo "Available boards: asterix, obelix_dvt, obelix_pvt, obelix_bb2, getafix_evt, getafix_dvt, getafix_dvt2, qemu_emery, qemu_flint, qemu_gabbro" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PBL="$ROOT_DIR/pbl"
MERGE="$SCRIPT_DIR/merge_pbz.py"

echo "==> Building slot 0 for $BOARD..."
"$PBL" configure --board "$BOARD" --slot=0
"$PBL" build
"$PBL" bundle

echo "==> Building slot 1 for $BOARD..."
"$PBL" configure --board "$BOARD" --slot=1
"$PBL" build
"$PBL" bundle

echo "==> Merging slots..."
SLOT0_PBZ=$(ls -t "$ROOT_DIR"/build/normal_"${BOARD}"_*_slot0.pbz 2>/dev/null | head -1)
SLOT1_PBZ=$(ls -t "$ROOT_DIR"/build/normal_"${BOARD}"_*_slot1.pbz 2>/dev/null | head -1)

if [[ -z "$SLOT0_PBZ" || -z "$SLOT1_PBZ" ]]; then
  echo "Error: could not find slot pbz files" >&2
  exit 1
fi

VERSION=$(basename "$SLOT0_PBZ" | sed "s/normal_${BOARD}_\(.*\)_slot0.pbz/\1/")
OUTPUT="$ROOT_DIR/build/normal_${BOARD}_${VERSION}.pbz"

python3 "$MERGE" --slot0-pbz "$SLOT0_PBZ" --slot1-pbz "$SLOT1_PBZ" --output "$OUTPUT"

echo "==> Cleaning up intermediate slot files..."
rm -f "$SLOT0_PBZ" "$SLOT1_PBZ"

echo ""
echo "==> Dual-slot bundle: $OUTPUT"
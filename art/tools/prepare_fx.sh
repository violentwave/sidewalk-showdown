#!/usr/bin/env bash
# prepare_fx.sh — validate the owner-approved FX/METH art against its
# manifests and copy byte-identical runtime copies into game/art/fx/.
#
# The source batches under art/source/FX/ are read-only: this script never
# edits or re-encodes a PNG, it only verifies sizes/frame counts and copies.
# The regeneration sources (art/tools/fx_generators/*.py) are owner-run and
# are deliberately NOT executed here (docs/AGENT_RULES.md #15).
#
# Validation per sheet: the PNG's real dimensions must equal
#   width  = cell[0] * frames
#   height = cell[1]
# exactly, otherwise the runtime sprite's hframes layout would be wrong.
#
# Runtime import settings: sprites set TEXTURE_FILTER_NEAREST in code
# (FxLayer / MethCinematicDriver); the PNGs are copied unchanged, so the
# nearest-neighbor look is engine-side, not baked into the files.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC_FX="$REPO_ROOT/art/source/FX/hit_fx"
SRC_PROPS="$REPO_ROOT/art/source/FX/meth_props"
DEST="$REPO_ROOT/game/art/fx"

command -v magick >/dev/null 2>&1 || { echo "prepare_fx: ImageMagick (magick) is required"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "prepare_fx: jq is required"; exit 1; }

errors=0

# validate_manifest <manifest.json> <src_dir>
validate_manifest() {
	local manifest="$1" src_dir="$2"
	local names
	names=$(jq -r 'keys[]' "$manifest")
	for name in $names; do
		local cell_w cell_h frames file
		cell_w=$(jq -r ".[\"$name\"].cell[0]" "$manifest")
		cell_h=$(jq -r ".[\"$name\"].cell[1]" "$manifest")
		frames=$(jq -r ".[\"$name\"].frames" "$manifest")
		file="$src_dir/$name.png"
		if [ ! -f "$file" ]; then
			echo "MISSING: $file"
			errors=$((errors + 1))
			continue
		fi
		local real_w real_h
		real_w=$(magick identify -format '%w' "$file")
		real_h=$(magick identify -format '%h' "$file")
		if [ "$real_w" -ne $((cell_w * frames)) ] || [ "$real_h" -ne "$cell_h" ]; then
			echo "SIZE MISMATCH: $name is ${real_w}x${real_h}, manifest wants $((cell_w * frames))x${cell_h} (${frames} x ${cell_w}x${cell_h})"
			errors=$((errors + 1))
		else
			echo "OK: $name ${real_w}x${real_h} (${frames} frames of ${cell_w}x${cell_h})"
		fi
	done
}

echo "== validating hit FX sheets against fx_manifest.json =="
validate_manifest "$SRC_FX/fx_manifest.json" "$SRC_FX"
echo "== validating METH props against props_manifest.json =="
validate_manifest "$SRC_PROPS/props_manifest.json" "$SRC_PROPS"

if [ "$errors" -gt 0 ]; then
	echo "prepare_fx: $errors validation error(s); runtime copies NOT updated"
	exit 1
fi

mkdir -p "$DEST"
copied=0
for f in "$SRC_FX"/*.png "$SRC_PROPS"/*.png; do
	cp -p "$f" "$DEST/"
	copied=$((copied + 1))
done
echo "prepare_fx: $copied sheets copied to game/art/fx/ (byte-identical; never resampled)"

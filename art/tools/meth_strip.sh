#!/usr/bin/env bash
# meth_strip.sh — assemble the METH cinematic review strips from the raw
# frames captured by game/tools/meth_capture.gd (strip modes) into labeled
# 4x3 sheets for owner/PM review.
#
# Each sheet is 12 native 320x180 frames sampled every 18 sim frames
# (f0..f198), the frame number drawn in each cell's top-left corner (it
# lands on the black letterbox bar, so it stays readable), 4 columns x
# 3 rows, no gaps. Sheets land in docs/assets/fx_meth/.
#
# Usage:
#   art/tools/meth_strip.sh plank_strip flaming_belch_strip \
#       plank_strip_mirrored flaming_belch_strip_mirrored
#
# The raw captures must already exist under /tmp/opencode/meth (run
# meth_capture.gd first); the 1920x1080 grabs are exact 6x renders of the
# native 320x180 canvas, so the point downscale is lossless.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RAW_DIR="/tmp/opencode/meth"
OUT_DIR="$REPO_ROOT/docs/assets/fx_meth"

command -v magick >/dev/null 2>&1 || { echo "meth_strip: ImageMagick (magick) is required"; exit 1; }

assemble() {
	local mode="$1"
	local out_name="$2"
	local cell_dir="$RAW_DIR/cells_$mode"
	mkdir -p "$cell_dir"
	local i=0
	for frame in $(seq 0 18 198); do
		local src="$RAW_DIR/strip_${mode}_$(printf '%02d' $((frame / 18))).png"
		if [ ! -f "$src" ]; then
			echo "meth_strip: missing raw frame $src (run meth_capture.gd -- $mode)"
			exit 1
		fi
		# 1920x1080 -> native 320x180 (exact 6x, nearest neighbor).
		# The label sits on the black letterbox bar of each cell.
		magick "$src" -filter point -resize 320x180! \
			-font DejaVu-Sans-Mono -pointsize 8 -fill white \
			-gravity NorthWest -annotate +4+6 "f$(printf '%03d' "$frame")" \
			"$cell_dir/$(printf '%02d' $i).png"
		i=$((i + 1))
	done
	magick montage "$cell_dir"/[0-9][0-9].png \
		-tile 4x3 -geometry +0+0 -background black \
		"$OUT_DIR/$out_name"
	echo "meth_strip: $OUT_DIR/$out_name (4x3 of 320x180)"
	rm -rf "$cell_dir"
}

assemble plank_strip walk_the_plank_strip.png
assemble flaming_belch_strip flaming_belch_strip.png
assemble plank_strip_mirrored walk_the_plank_mirrored_strip.png
assemble flaming_belch_strip_mirrored flaming_belch_mirrored_strip.png

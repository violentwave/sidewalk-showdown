# prepare_ui.gd — copy approved UI art into the game, unchanged, with a
# size check. This is the canonical tool (docs/UI_ASSETS.md §2); it is run
# through the game-side entry point because Godot only executes scripts
# under res://:
#
#   godot --headless --path game --script res://tools/prepare_ui.gd
#
# Rules (docs/UI_ASSETS.md §2):
# - Copies every PNG in art/source/UI/approved/<group>/ to
#   game/art/ui/<group>/ byte-for-byte. Never scales, crops, or edits.
# - Verifies each file's pixel size against SIZES (from docs/UI_ASSETS.md
#   §4/§6, measured 2026-11-21) and fails loudly on a mismatch.
# - The .import files are generated afterwards by
#   `godot --headless --path game --import` (nearest filter comes from the
#   project-wide default_texture_filter=0).
extends RefCounted

# group/file.png -> "WxH" exact native size (docs/UI_ASSETS.md §6).
const SIZES := {
	"ui/ui_button.png": "48x16",
	"ui/ui_glyph_dpad.png": "9x9",
	"ui/ui_glyph_key_blank.png": "9x9",
	"ui/ui_glyph_pad_a.png": "9x9",
	"ui/ui_glyph_pad_b.png": "9x9",
	"ui/ui_glyph_pad_x.png": "9x9",
	"ui/ui_glyph_pad_y.png": "9x9",
	"ui/ui_logo.png": "139x74",
	"ui/ui_panel.png": "24x24",
	"menu/menu_price_sign.png": "79x124",
	"menu/menu_price_slat_lit.png": "66x7",
	"stream/stream_chat_panel.png": "80x100",
	"stream/stream_commentary_box.png": "240x16",
	"stream/stream_live_tag.png": "24x7",
	"stream/stream_sponsor_bug.png": "40x12",
	"stage/stage_scratch_ticket.png": "72x44",
	"select/select_mugshot_bg.png": "320x180",
	"select/select_portrait_pegleg_peg.png": "64x64",
	"select/select_portrait_whiskey_richard.png": "64x64",
	"select/select_rap_sheet.png": "76x66",
	"vs/vs_bust_pegleg_peg.png": "96x128",
	"vs/vs_bust_whiskey_richard.png": "96x128",
	"hud/hud_banner_decisive.png": "117x18",
	"hud/hud_banner_double_ko.png": "93x20",
	"hud/hud_banner_fight.png": "59x24",
	"hud/hud_banner_ko.png": "39x25",
	"hud/hud_banner_methtality.png": "97x23",
	"hud/hud_banner_plate.png": "160x32",
	"hud/hud_banner_round_1.png": "71x20",
	"hud/hud_banner_round_2.png": "75x20",
	"hud/hud_banner_round_3.png": "74x20",
	"hud/hud_banner_round_4.png": "74x20",
	"hud/hud_banner_round_5.png": "74x20",
	"hud/hud_banner_time.png": "42x22",
	"hud/hud_health_frame.png": "118x10",
	"hud/hud_meter_frame.png": "106x8",
	"hud/hud_meth_skull_f1.png": "8x8",
	"hud/hud_meth_skull_f2.png": "8x8",
	"hud/hud_pip_diamond_d.png": "5x5",
	"hud/hud_pip_diamond_empty.png": "5x5",
	"hud/hud_pip_diamond_filled.png": "5x5",
	"hud/hud_pip_diamond_k.png": "5x5",
	"hud/hud_pip_diamond_m.png": "5x5",
	"hud/hud_pip_diamond_t.png": "5x5",
	"hud/hud_pip_square_d.png": "5x5",
	"hud/hud_pip_square_empty.png": "5x5",
	"hud/hud_pip_square_filled.png": "5x5",
	"hud/hud_pip_square_k.png": "5x5",
	"hud/hud_pip_square_m.png": "5x5",
	"hud/hud_pip_square_t.png": "5x5",
	"hud/hud_portrait_frame.png": "24x24",
	"hud/hud_portrait_pegleg_peg_hurt.png": "22x22",
	"hud/hud_portrait_pegleg_peg_ko.png": "22x22",
	"hud/hud_portrait_pegleg_peg_normal.png": "22x22",
	"hud/hud_portrait_whiskey_richard_hurt.png": "22x22",
	"hud/hud_portrait_whiskey_richard_ko.png": "22x22",
	"hud/hud_portrait_whiskey_richard_normal.png": "22x22",
	"hud/hud_timer_box.png": "24x20",
	"hud/hud_timer_digits.png": "88x12",
}

# Returns the number of errors (0 = success). Prints its own report.
func run() -> int:
	var game_dir := ProjectSettings.globalize_path("res://").trim_suffix("/")
	var repo_root := game_dir.get_base_dir()
	var approved_root := repo_root.path_join("art/source/UI/approved")
	var runtime_root := game_dir.path_join("art/ui")
	var copied := 0
	var errors := 0

	for rel_path in SIZES:
		var source_path := approved_root.path_join(rel_path)
		var dest_path := runtime_root.path_join(rel_path)
		var expected := SIZES[rel_path] as String
		var expected_size := expected.split("x")
		var expected_w := int(expected_size[0])
		var expected_h := int(expected_size[1])

		if not FileAccess.file_exists(source_path):
			push_error("prepare_ui: MISSING source %s" % source_path)
			errors += 1
			continue
		var image := Image.load_from_file(source_path)
		if image == null:
			push_error("prepare_ui: cannot read %s" % source_path)
			errors += 1
			continue
		if image.get_width() != expected_w or image.get_height() != expected_h:
			push_error("prepare_ui: SIZE MISMATCH %s is %dx%d, expected %s"
				% [rel_path, image.get_width(), image.get_height(), expected])
			errors += 1
			continue

		DirAccess.make_dir_recursive_absolute(dest_path.get_base_dir())
		var dest_dir := DirAccess.open(dest_path.get_base_dir())
		if dest_dir == null or dest_dir.copy(source_path, dest_path) != OK:
			push_error("prepare_ui: FAILED to copy %s -> %s" % [source_path, dest_path])
			errors += 1
			continue
		copied += 1
		print("copied %s (%s)" % [rel_path, expected])

	# Any approved file not in SIZES is a manifest gap — fail loudly so new
	# art cannot silently ship without a size contract.
	var approved_dir := DirAccess.open(approved_root)
	if approved_dir != null:
		for group in approved_dir.get_directories():
			var group_dir := DirAccess.open(approved_root.path_join(group))
			if group_dir == null:
				continue
			for file_name in group_dir.get_files():
				if not file_name.to_lower().ends_with(".png"):
					continue
				var rel := "%s/%s" % [group, file_name]
				if not SIZES.has(rel):
					push_error("prepare_ui: %s has no size entry in SIZES — add it to art/tools/prepare_ui.gd (docs/UI_ASSETS.md)" % rel)
					errors += 1

	if errors > 0:
		push_error("prepare_ui: %d error(s), %d file(s) copied — FIX THE ART OR THE TABLE" % [errors, copied])
		return errors
	print("prepare_ui: OK, %d file(s) copied unchanged to game/art/ui/" % copied)
	return 0

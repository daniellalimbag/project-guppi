extends Node
## Persistent player preferences and run progress.

signal settings_changed

const SAVE_PATH := "user://settings.cfg"

## Named background palettes for the shell / title chrome.
const BACKGROUNDS := {
	"tideline": {
		"label": "Tideline",
		"wash": Color(0.08, 0.28, 0.32, 1),
		"glow": Color(0.2, 0.55, 0.58, 0.45),
		"orb": Color(0.35, 0.75, 0.78, 0.18),
		"accent": Color(0.18, 0.55, 0.58, 1),
		"accent_hover": Color(0.24, 0.62, 0.64, 1),
		"accent_dark": Color(0.12, 0.42, 0.45, 1),
		"screen": Color(0.97, 0.98, 0.99, 1),
		"app_wash": Color(0.06, 0.1, 0.12, 1),
		"results": Color(0.05, 0.08, 0.1, 1),
	},
	"deep_current": {
		"label": "Deep Current",
		"wash": Color(0.05, 0.12, 0.28, 1),
		"glow": Color(0.15, 0.35, 0.7, 0.4),
		"orb": Color(0.3, 0.55, 0.95, 0.16),
		"accent": Color(0.2, 0.42, 0.78, 1),
		"accent_hover": Color(0.28, 0.5, 0.88, 1),
		"accent_dark": Color(0.12, 0.28, 0.55, 1),
		"screen": Color(0.95, 0.96, 0.99, 1),
		"app_wash": Color(0.04, 0.06, 0.12, 1),
		"results": Color(0.04, 0.05, 0.1, 1),
	},
	"coral_shelf": {
		"label": "Coral Shelf",
		"wash": Color(0.28, 0.14, 0.16, 1),
		"glow": Color(0.75, 0.35, 0.32, 0.35),
		"orb": Color(0.9, 0.5, 0.4, 0.15),
		"accent": Color(0.72, 0.35, 0.32, 1),
		"accent_hover": Color(0.8, 0.42, 0.38, 1),
		"accent_dark": Color(0.5, 0.22, 0.22, 1),
		"screen": Color(0.99, 0.97, 0.96, 1),
		"app_wash": Color(0.12, 0.07, 0.08, 1),
		"results": Color(0.1, 0.06, 0.07, 1),
	},
	"fog_harbor": {
		"label": "Fog Harbor",
		"wash": Color(0.22, 0.26, 0.3, 1),
		"glow": Color(0.45, 0.52, 0.58, 0.35),
		"orb": Color(0.7, 0.75, 0.8, 0.12),
		"accent": Color(0.35, 0.45, 0.52, 1),
		"accent_hover": Color(0.42, 0.52, 0.6, 1),
		"accent_dark": Color(0.25, 0.32, 0.38, 1),
		"screen": Color(0.96, 0.97, 0.98, 1),
		"app_wash": Color(0.1, 0.11, 0.13, 1),
		"results": Color(0.08, 0.09, 0.11, 1),
	},
	"night_pier": {
		"label": "Night Pier",
		"wash": Color(0.04, 0.08, 0.14, 1),
		"glow": Color(0.1, 0.4, 0.45, 0.35),
		"orb": Color(0.2, 0.7, 0.65, 0.12),
		"accent": Color(0.15, 0.55, 0.52, 1),
		"accent_hover": Color(0.2, 0.65, 0.6, 1),
		"accent_dark": Color(0.08, 0.32, 0.34, 1),
		"screen": Color(0.94, 0.96, 0.97, 1),
		"app_wash": Color(0.03, 0.05, 0.08, 1),
		"results": Color(0.03, 0.04, 0.07, 1),
	},
}

var background_id: String = "tideline"
var last_difficulty: String = "easy"
var last_shift: int = 1
## highest unlocked shift per difficulty id
var unlocked_shifts: Dictionary = {"easy": 1, "medium": 1, "hard": 1}
var progress_exists: bool = false
var guppi_tips_enabled: bool = true

## Transient menu navigation (not persisted).
var menu_continue_mode: bool = false
var menu_difficulty: String = "easy"


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	var bg := str(cfg.get_value("ui", "background_id", background_id))
	if BACKGROUNDS.has(bg):
		background_id = bg
	last_difficulty = str(cfg.get_value("play", "last_difficulty", last_difficulty))
	last_shift = clampi(int(cfg.get_value("play", "last_shift", last_shift)), 1, 99)
	progress_exists = bool(cfg.get_value("play", "progress_exists", progress_exists))
	guppi_tips_enabled = bool(cfg.get_value("play", "guppi_tips_enabled", guppi_tips_enabled))
	var unlocked_raw: Variant = cfg.get_value("play", "unlocked_shifts", {})
	if typeof(unlocked_raw) == TYPE_DICTIONARY:
		for key in unlocked_raw.keys():
			unlocked_shifts[str(key)] = clampi(int(unlocked_raw[key]), 1, 99)
	# Migrate older flat saves.
	if cfg.has_section_key("play", "last_played_level") and not cfg.has_section_key("play", "last_difficulty"):
		last_shift = clampi(int(cfg.get_value("play", "last_played_level", 1)), 1, 99)
		unlocked_shifts["easy"] = maxi(1, int(cfg.get_value("play", "highest_unlocked_level", last_shift)))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("ui", "background_id", background_id)
	cfg.set_value("play", "last_difficulty", last_difficulty)
	cfg.set_value("play", "last_shift", last_shift)
	cfg.set_value("play", "unlocked_shifts", unlocked_shifts)
	cfg.set_value("play", "progress_exists", progress_exists)
	cfg.set_value("play", "guppi_tips_enabled", guppi_tips_enabled)
	cfg.save(SAVE_PATH)


func get_palette() -> Dictionary:
	if BACKGROUNDS.has(background_id):
		return BACKGROUNDS[background_id]
	return BACKGROUNDS["tideline"]


func list_background_ids() -> PackedStringArray:
	return PackedStringArray(BACKGROUNDS.keys())


func has_continue() -> bool:
	return progress_exists


func get_unlocked_shift(difficulty_id: String) -> int:
	return maxi(1, int(unlocked_shifts.get(difficulty_id, 1)))


func is_shift_unlocked(difficulty_id: String, shift: int) -> bool:
	return shift >= 1 and shift <= get_unlocked_shift(difficulty_id)


func continue_label() -> String:
	if not progress_exists:
		return "Continue"
	var label := LevelManager.get_difficulty_label(last_difficulty)
	return "Continue · %s Shift %d" % [label, last_shift]


func begin_new_game(difficulty_id: String) -> void:
	last_difficulty = difficulty_id
	last_shift = 1
	unlocked_shifts[difficulty_id] = 1
	progress_exists = false
	save_settings()
	settings_changed.emit()


func mark_shift_started(difficulty_id: String, shift: int) -> void:
	var clamped := maxi(shift, 1)
	progress_exists = true
	last_difficulty = difficulty_id
	last_shift = clamped
	unlocked_shifts[difficulty_id] = maxi(get_unlocked_shift(difficulty_id), clamped)
	save_settings()
	settings_changed.emit()


func unlock_next_after(difficulty_id: String, completed_shift: int) -> void:
	var max_shifts := LevelManager.get_shift_count(difficulty_id)
	var next_shift := mini(completed_shift + 1, maxi(max_shifts, 1))
	unlocked_shifts[difficulty_id] = maxi(get_unlocked_shift(difficulty_id), next_shift)
	last_difficulty = difficulty_id
	last_shift = clampi(completed_shift, 1, maxi(max_shifts, 1))
	progress_exists = true
	save_settings()
	settings_changed.emit()


func set_background(id: String) -> void:
	if not BACKGROUNDS.has(id) or background_id == id:
		return
	background_id = id
	save_settings()
	settings_changed.emit()


func set_guppi_tips_enabled(enabled: bool) -> void:
	if guppi_tips_enabled == enabled:
		return
	guppi_tips_enabled = enabled
	save_settings()
	settings_changed.emit()


func make_flat_style(color: Color, radius: int = 0, margin: float = 0.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	if margin > 0.0:
		style.content_margin_left = margin
		style.content_margin_top = margin
		style.content_margin_right = margin
		style.content_margin_bottom = margin
	return style

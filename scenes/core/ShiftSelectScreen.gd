extends Control
## Full-screen shift picker for New Game / Continue.

signal request_go_to_feed
signal request_go_to_difficulty
signal request_go_to_title

@onready var _background: ColorRect = %Background
@onready var _glow: ColorRect = %Glow
@onready var _brand: Label = %Brand
@onready var _title: Label = %TitleLabel
@onready var _subtitle: Label = %Subtitle
@onready var _list: VBoxContainer = %ShiftList
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_back_button.pressed.connect(_on_back)
	SettingsStore.settings_changed.connect(_apply_theme)
	_apply_theme()
	_refresh_copy()
	_build_list()
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)


func _apply_theme() -> void:
	var palette := SettingsStore.get_palette()
	_background.color = palette.get("wash", Color(0.08, 0.28, 0.32))
	_glow.color = palette.get("glow", Color(0.2, 0.55, 0.58, 0.4))
	var accent: Color = palette.get("accent", Color(0.18, 0.55, 0.58))
	_brand.add_theme_color_override("font_color", accent.lightened(0.25))
	_title.add_theme_color_override("font_color", Color(0.95, 0.98, 0.99))
	_subtitle.add_theme_color_override("font_color", Color(0.75, 0.88, 0.9, 0.9))


func _refresh_copy() -> void:
	var label := LevelManager.get_difficulty_label(SettingsStore.menu_difficulty)
	if SettingsStore.menu_continue_mode:
		_brand.text = "SEA CORP.  ·  RESUME"
		_title.text = label
		_subtitle.text = "Choose an unlocked shift to continue."
	else:
		_brand.text = "SEA CORP.  ·  %s" % label.to_upper()
		_title.text = "Shifts"
		_subtitle.text = "Select where your assignment begins."


func _build_list() -> void:
	for child in _list.get_children():
		child.queue_free()

	var difficulty_id := SettingsStore.menu_difficulty
	var palette := SettingsStore.get_palette()
	var accent: Color = palette.get("accent", Color(0.18, 0.55, 0.58))
	var highlight := SettingsStore.last_shift if (
		SettingsStore.menu_continue_mode and SettingsStore.last_difficulty == difficulty_id
	) else 1

	var shifts := LevelManager.get_shifts(difficulty_id)
	for i in shifts.size():
		var cfg: Variant = shifts[i]
		if typeof(cfg) != TYPE_DICTIONARY:
			continue
		var shift := int(cfg.get("shift", 0))
		if shift <= 0:
			continue

		var unlocked := true
		if SettingsStore.menu_continue_mode:
			unlocked = SettingsStore.is_shift_unlocked(difficulty_id, shift)

		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(0, 86)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = not unlocked
		if unlocked:
			button.text = "%02d   Shift %d — %s\n       %d posts in queue" % [
				shift, shift, str(cfg.get("note", "")), int(cfg.get("posts_shown", 0))
			]
		else:
			button.text = "%02d   Shift %d — Locked\n       Clear Shift %d to unlock" % [
				shift, shift, shift - 1
			]

		var normal := _make_style(
			Color(0.97, 0.98, 0.99, 0.96) if unlocked else Color(0.78, 0.84, 0.86, 0.4)
		)
		if unlocked and shift == highlight:
			normal.border_width_left = 4
			normal.border_color = accent
		var hover := _make_style(Color(1, 1, 1, 1))
		hover.border_width_left = 4
		hover.border_color = accent

		button.add_theme_font_size_override("font_size", 14)
		button.add_theme_color_override(
			"font_color",
			Color(0.12, 0.2, 0.24) if unlocked else Color(0.5, 0.56, 0.58)
		)
		button.add_theme_color_override("font_hover_color", Color(0.08, 0.16, 0.2))
		button.add_theme_color_override("font_disabled_color", Color(0.5, 0.56, 0.58))
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover if unlocked else normal)
		button.add_theme_stylebox_override("pressed", normal)
		button.add_theme_stylebox_override("disabled", normal)
		if unlocked:
			button.pressed.connect(_on_shift_pressed.bind(difficulty_id, shift))
		_list.add_child(button)

		button.modulate.a = 0.0
		var row_tween := create_tween()
		row_tween.tween_interval(0.05 * float(i))
		row_tween.tween_property(button, "modulate:a", 1.0, 0.25)


func _make_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	style.content_margin_left = 18
	style.content_margin_top = 16
	style.content_margin_right = 18
	style.content_margin_bottom = 16
	return style


func _on_back() -> void:
	if SettingsStore.menu_continue_mode:
		request_go_to_title.emit()
	else:
		request_go_to_difficulty.emit()


func _on_shift_pressed(difficulty_id: String, shift: int) -> void:
	if not SettingsStore.menu_continue_mode:
		SettingsStore.begin_new_game(difficulty_id)
	SettingsStore.mark_shift_started(difficulty_id, shift)
	GameState.start_at_shift(difficulty_id, shift)
	request_go_to_feed.emit()

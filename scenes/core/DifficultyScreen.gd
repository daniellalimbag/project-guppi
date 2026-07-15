extends Control
## Full-screen difficulty picker for New Game.

signal request_go_to_shifts
signal request_go_to_title

@onready var _background: ColorRect = %Background
@onready var _glow: ColorRect = %Glow
@onready var _brand: Label = %Brand
@onready var _title: Label = %TitleLabel
@onready var _subtitle: Label = %Subtitle
@onready var _list: VBoxContainer = %DifficultyList
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_back_button.pressed.connect(func() -> void: request_go_to_title.emit())
	SettingsStore.settings_changed.connect(_apply_theme)
	_apply_theme()
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


func _build_list() -> void:
	for child in _list.get_children():
		child.queue_free()

	var tones := [
		Color(0.18, 0.52, 0.54, 1),
		Color(0.14, 0.38, 0.52, 1),
		Color(0.11, 0.24, 0.4, 1),
	]
	var hover_tones := [
		Color(0.22, 0.58, 0.6, 1),
		Color(0.18, 0.44, 0.58, 1),
		Color(0.15, 0.3, 0.46, 1),
	]

	var difficulties := LevelManager.get_difficulties()
	for i in difficulties.size():
		var item: Variant = difficulties[i]
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var id := str(item.get("id", ""))
		if id.is_empty():
			continue

		var tone: Color = tones[mini(i, tones.size() - 1)]
		var hover: Color = hover_tones[mini(i, hover_tones.size() - 1)]
		var label := str(item.get("label", id.capitalize()))
		var blurb := str(item.get("blurb", ""))
		var shift_count: int = item.get("shifts", []).size()

		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(0, 124)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = "%s\n%s\n%d shifts" % [label, blurb, shift_count]
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
		button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
		button.add_theme_stylebox_override("normal", _make_style(tone))
		button.add_theme_stylebox_override("hover", _make_style(hover))
		button.add_theme_stylebox_override("pressed", _make_style(tone.darkened(0.08)))
		button.pressed.connect(_on_difficulty_pressed.bind(id))
		_list.add_child(button)

		button.modulate.a = 0.0
		var row_tween := create_tween()
		row_tween.tween_interval(0.06 * float(i))
		row_tween.tween_property(button, "modulate:a", 1.0, 0.28)


func _make_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	style.content_margin_left = 20
	style.content_margin_top = 18
	style.content_margin_right = 20
	style.content_margin_bottom = 18
	return style


func _on_difficulty_pressed(difficulty_id: String) -> void:
	SettingsStore.menu_continue_mode = false
	SettingsStore.menu_difficulty = difficulty_id
	request_go_to_shifts.emit()

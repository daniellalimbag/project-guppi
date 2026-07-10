extends Control

signal request_go_to_feed
signal request_go_to_title

@onready var _level_list: VBoxContainer = %LevelList
@onready var _hint_label: Label = %HintLabel


func _ready() -> void:
	%BackToTitleButton.pressed.connect(func() -> void: request_go_to_title.emit())
	_build_level_buttons()
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25)


func _build_level_buttons() -> void:
	for child in _level_list.get_children():
		child.queue_free()

	var levels: Array = LevelManager.level_config.get("levels", [])
	if levels.is_empty():
		_hint_label.text = "No shifts scheduled."
		return

	_hint_label.text = "Pick a shift. Later shifts = heavier traffic, thinner assist from G."

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 14)
	pad.add_theme_constant_override("margin_right", 14)
	pad.add_theme_constant_override("margin_top", 12)
	pad.add_theme_constant_override("margin_bottom", 12)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	pad.add_child(col)
	_level_list.add_child(pad)

	for cfg in levels:
		if typeof(cfg) != TYPE_DICTIONARY:
			continue
		var level := int(cfg.get("level", 0))
		if level <= 0:
			continue

		var card := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.115, 0.155, 1)
		style.border_color = Color(0.22, 0.26, 0.34, 1)
		style.set_border_width_all(1)
		style.set_corner_radius_all(12)
		style.content_margin_left = 14
		style.content_margin_top = 12
		style.content_margin_right = 14
		style.content_margin_bottom = 12
		card.add_theme_stylebox_override("panel", style)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var meta := VBoxContainer.new()
		meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		meta.add_theme_constant_override("separation", 2)

		var title := Label.new()
		title.text = "Shift %d" % level
		title.add_theme_font_size_override("font_size", 16)
		meta.add_child(title)

		var note := Label.new()
		note.text = str(cfg.get("difficulty_note", ""))
		note.add_theme_font_size_override("font_size", 12)
		note.add_theme_color_override("font_color", Color(0.58, 0.64, 0.74, 1))
		meta.add_child(note)

		var quota := Label.new()
		quota.text = "Quota %d tickets" % int(cfg.get("posts_shown", 0))
		quota.add_theme_font_size_override("font_size", 11)
		quota.add_theme_color_override("font_color", Color(0.5, 0.7, 0.88, 1))
		meta.add_child(quota)

		var button := Button.new()
		button.text = "Open"
		button.custom_minimum_size = Vector2(72, 44)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_level_pressed.bind(level))

		row.add_child(meta)
		row.add_child(button)
		card.add_child(row)
		col.add_child(card)


func _on_level_pressed(level: int) -> void:
	GameState.current_level = level
	request_go_to_feed.emit()

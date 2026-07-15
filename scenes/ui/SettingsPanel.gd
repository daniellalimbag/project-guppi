extends Control
class_name SettingsPanel

signal closed

@onready var _bg_list: VBoxContainer = %BackgroundList
@onready var _tips_toggle: CheckButton = %TipsToggle
@onready var _done_button: Button = %DoneButton


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_done_button.pressed.connect(close)
	_tips_toggle.toggled.connect(_on_tips_toggled)
	_rebuild_backgrounds()
	_sync_from_store()
	if not SettingsStore.settings_changed.is_connected(_sync_from_store):
		SettingsStore.settings_changed.connect(_sync_from_store)


func open() -> void:
	_rebuild_backgrounds()
	_sync_from_store()
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)


func close() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	closed.emit()


func is_open() -> bool:
	return visible


func _sync_from_store() -> void:
	_tips_toggle.set_pressed_no_signal(SettingsStore.guppi_tips_enabled)
	_highlight_background_buttons()


func _rebuild_backgrounds() -> void:
	for child in _bg_list.get_children():
		child.queue_free()
	for id in SettingsStore.list_background_ids():
		var palette: Dictionary = SettingsStore.BACKGROUNDS[id]
		var row := Button.new()
		row.focus_mode = Control.FOCUS_NONE
		row.custom_minimum_size = Vector2(0, 44)
		row.text = str(palette.get("label", id))
		row.set_meta("bg_id", id)
		row.pressed.connect(_on_background_pressed.bind(id))
		_bg_list.add_child(row)
	_highlight_background_buttons()


func _highlight_background_buttons() -> void:
	var current := SettingsStore.background_id
	var accent: Color = SettingsStore.get_palette().get("accent", Color(0.18, 0.55, 0.58))
	for child in _bg_list.get_children():
		if not child is Button:
			continue
		var button := child as Button
		var id := str(button.get_meta("bg_id", ""))
		var selected := id == current
		button.modulate = Color(1, 1, 1, 1) if selected else Color(0.92, 0.93, 0.94, 1)
		if selected:
			button.add_theme_color_override("font_color", accent)
		else:
			button.remove_theme_color_override("font_color")


func _on_background_pressed(id: String) -> void:
	SettingsStore.set_background(id)


func _on_tips_toggled(pressed: bool) -> void:
	SettingsStore.set_guppi_tips_enabled(pressed)

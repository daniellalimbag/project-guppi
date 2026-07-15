extends Control
class_name ShiftSelectPanel

enum Mode { NEW_GAME, CONTINUE }

signal closed
signal shift_chosen(difficulty_id: String, shift: int)
signal back_requested

@onready var _title_label: Label = %Title
@onready var _hint_label: Label = %Hint
@onready var _list: VBoxContainer = %ShiftList
@onready var _back_button: Button = %BackButton

var _mode: Mode = Mode.NEW_GAME
var _difficulty_id: String = "easy"


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back_button.pressed.connect(_on_back)


func open(difficulty_id: String, mode: Mode = Mode.NEW_GAME) -> void:
	_difficulty_id = difficulty_id
	_mode = mode
	_rebuild()
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


func _on_back() -> void:
	close()
	back_requested.emit()


func _rebuild() -> void:
	if _list == null:
		return
	for child in _list.get_children():
		child.queue_free()

	var diff_label := LevelManager.get_difficulty_label(_difficulty_id)
	var accent: Color = SettingsStore.get_palette().get("accent", Color(0.18, 0.55, 0.58))
	var highlight := SettingsStore.last_shift if SettingsStore.last_difficulty == _difficulty_id else 1

	if _mode == Mode.NEW_GAME:
		_title_label.text = "%s — Shifts" % diff_label
		_hint_label.text = "Pick a starting shift for this difficulty."
	else:
		_title_label.text = "Continue — %s" % diff_label
		_hint_label.text = "Choose an unlocked shift to resume."

	for cfg in LevelManager.get_shifts(_difficulty_id):
		if typeof(cfg) != TYPE_DICTIONARY:
			continue
		var shift := int(cfg.get("shift", 0))
		if shift <= 0:
			continue
		var note := str(cfg.get("note", ""))
		var posts := int(cfg.get("posts_shown", 0))
		var unlocked := true
		if _mode == Mode.CONTINUE:
			unlocked = SettingsStore.is_shift_unlocked(_difficulty_id, shift)

		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(0, 56)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = not unlocked
		if unlocked:
			button.text = "Shift %d — %s\n%d posts in queue" % [shift, note, posts]
		else:
			button.text = "Shift %d — Locked\nClear Shift %d to unlock" % [shift, shift - 1]
		if unlocked and shift == highlight:
			button.add_theme_color_override("font_color", accent)
		if unlocked:
			button.pressed.connect(_on_shift_pressed.bind(shift))
		_list.add_child(button)


func _on_shift_pressed(shift: int) -> void:
	shift_chosen.emit(_difficulty_id, shift)
	close()

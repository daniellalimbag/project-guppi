extends Control
class_name DifficultySelectPanel

signal closed
signal difficulty_chosen(difficulty_id: String)

@onready var _list: VBoxContainer = %DifficultyList
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back_button.pressed.connect(close)


func open() -> void:
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


func _rebuild() -> void:
	for child in _list.get_children():
		child.queue_free()
	for item in LevelManager.get_difficulties():
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var id := str(item.get("id", ""))
		if id.is_empty():
			continue
		var label := str(item.get("label", id.capitalize()))
		var blurb := str(item.get("blurb", ""))
		var shift_count: int = item.get("shifts", []).size()
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(0, 72)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = "%s\n%s\n%d shifts" % [label, blurb, shift_count]
		button.pressed.connect(_on_difficulty_pressed.bind(id))
		_list.add_child(button)


func _on_difficulty_pressed(difficulty_id: String) -> void:
	difficulty_chosen.emit(difficulty_id)
	close()

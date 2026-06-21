extends Control
class_name EvidencePopup

signal dismissed

@onready var _title_label: Label = %TitleLabel
@onready var _body_label: Label = %BodyLabel
@onready var _close_button: Button = %CloseButton
@onready var _dimmer: ColorRect = %Dimmer


func _ready() -> void:
	visible = false
	_close_button.pressed.connect(_close)
	_dimmer.gui_input.connect(_on_dimmer_input)


func open(title: String, body: String) -> void:
	_title_label.text = title
	_body_label.text = body
	visible = true
	_close_button.grab_focus()


func close_popup() -> void:
	if not visible:
		return
	visible = false
	dismissed.emit()


func _close() -> void:
	close_popup()


func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_popup()
	elif event is InputEventScreenTouch and event.pressed:
		close_popup()

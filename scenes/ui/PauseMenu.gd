extends Control
class_name PauseMenu

signal resume_requested
signal give_up_requested

const SETTINGS_SCENE := preload("res://scenes/ui/SettingsPanel.tscn")

@onready var _how_to_panel: PanelContainer = %HowToPanel
@onready var _resume_button: Button = %ResumeButton
@onready var _how_to_button: Button = %HowToButton
@onready var _settings_button: Button = %SettingsButton
@onready var _give_up_button: Button = %GiveUpButton
@onready var _how_to_close: Button = %HowToClose

var _settings_panel: SettingsPanel


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_how_to_panel.visible = false
	_resume_button.pressed.connect(close)
	_how_to_button.pressed.connect(_show_how_to)
	_settings_button.pressed.connect(_open_settings)
	_give_up_button.pressed.connect(func() -> void:
		close()
		give_up_requested.emit()
	)
	_how_to_close.pressed.connect(_hide_how_to)

	_settings_panel = SETTINGS_SCENE.instantiate()
	_settings_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_settings_panel)


func open() -> void:
	_how_to_panel.visible = false
	if _settings_panel:
		_settings_panel.visible = false
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)


func close() -> void:
	_how_to_panel.visible = false
	if _settings_panel and _settings_panel.is_open():
		_settings_panel.close()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resume_requested.emit()


func is_open() -> bool:
	return visible


func _show_how_to() -> void:
	_how_to_panel.visible = true


func _hide_how_to() -> void:
	_how_to_panel.visible = false


func _open_settings() -> void:
	_settings_panel.open()

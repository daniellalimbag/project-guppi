extends CanvasLayer
class_name GuppiCompanion

signal hint_requested

@onready var _root: Control = %Root
@onready var _avatar_button: Button = %AvatarButton
@onready var _tooltip_panel: PanelContainer = %TooltipPanel
@onready var _tooltip_label: Label = %TooltipLabel
@onready var _hint_prompt: Label = %HintPrompt

var _last_hint_post_id: String = ""
var _pulse_idle: Tween


func _ready() -> void:
	_avatar_button.custom_minimum_size = Vector2(56, 56)
	_tooltip_panel.visible = false
	_hint_prompt.text = "Tap for assist"
	_avatar_button.pressed.connect(func() -> void: hint_requested.emit())
	_style_avatar_button()
	_root.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_root.offset_left = -300.0
	_root.offset_top = -190.0
	_root.offset_right = -12.0
	_root.offset_bottom = -72.0
	_start_idle_pulse()


func _style_avatar_button() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.42, 0.68, 1)
	style.set_corner_radius_all(28)
	style.set_border_width_all(2)
	style.border_color = Color(0.45, 0.78, 0.98, 1)
	_avatar_button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color(0.2, 0.5, 0.78, 1)
	_avatar_button.add_theme_stylebox_override("hover", hover)
	_avatar_button.add_theme_stylebox_override("pressed", hover)
	_avatar_button.add_theme_font_size_override("font_size", 20)


func show_hint(post_id: String, hint_text: String) -> void:
	if hint_text.strip_edges().is_empty():
		return
	_last_hint_post_id = post_id
	_tooltip_label.text = hint_text
	_play_pulse()
	_show_tooltip()


func get_last_hint_post_id() -> String:
	return _last_hint_post_id


func set_prompt(text: String) -> void:
	_hint_prompt.text = text


func nudge() -> void:
	_play_pulse()


func _start_idle_pulse() -> void:
	if _pulse_idle and _pulse_idle.is_valid():
		_pulse_idle.kill()
	_pulse_idle = create_tween()
	_pulse_idle.set_loops()
	_pulse_idle.tween_property(_avatar_button, "modulate", Color(1.1, 1.1, 1.2, 1.0), 0.9)
	_pulse_idle.tween_property(_avatar_button, "modulate", Color.WHITE, 0.9)


func _play_pulse() -> void:
	var start_scale := Vector2.ONE
	_avatar_button.scale = start_scale
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_avatar_button, "scale", start_scale * 1.14, 0.16)
	tween.tween_property(_avatar_button, "scale", start_scale, 0.16)


func _show_tooltip() -> void:
	_tooltip_panel.visible = true
	_tooltip_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_tooltip_panel, "modulate:a", 1.0, 0.14)
	tween.tween_interval(3.0)
	tween.tween_property(_tooltip_panel, "modulate:a", 0.0, 0.22)
	tween.tween_callback(func() -> void:
		_tooltip_panel.visible = false
	)

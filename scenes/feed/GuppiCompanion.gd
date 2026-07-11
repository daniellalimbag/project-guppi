extends CanvasLayer
class_name GuppiCompanion

signal hint_requested

## Assign a Texture2D here (Inspector or set_sprite) when the entity art is ready.
@export var sprite_texture: Texture2D

@onready var _root: Control = %Root
@onready var _entity: Control = %Entity
@onready var _motion: Control = %Motion
@onready var _body: TextureRect = %Body
@onready var _placeholder: Panel = %Placeholder
@onready var _hit_area: Button = %HitArea
@onready var _tooltip_panel: PanelContainer = %TooltipPanel
@onready var _tooltip_label: Label = %TooltipLabel

var _last_hint_post_id: String = ""
var _idle_tween: Tween
var _react_tween: Tween


func _ready() -> void:
	_tooltip_panel.visible = false
	_hit_area.pressed.connect(func() -> void: hint_requested.emit())
	_clear_hit_area_chrome()
	_apply_sprite(sprite_texture)
	_root.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_root.offset_left = -300.0
	_root.offset_top = -210.0
	_root.offset_right = -12.0
	_root.offset_bottom = -72.0
	_motion.resized.connect(_sync_motion_pivot)
	_sync_motion_pivot()
	_start_idle_motion()


func set_sprite(texture: Texture2D) -> void:
	sprite_texture = texture
	_apply_sprite(texture)


func show_hint(post_id: String, hint_text: String) -> void:
	if hint_text.strip_edges().is_empty():
		return
	_last_hint_post_id = post_id
	_tooltip_label.text = hint_text
	_play_react()
	_show_tooltip()


func get_last_hint_post_id() -> String:
	return _last_hint_post_id


func nudge() -> void:
	_play_react()


func _apply_sprite(texture: Texture2D) -> void:
	_body.texture = texture
	var has_sprite := texture != null
	_placeholder.visible = not has_sprite
	_body.visible = has_sprite


func _clear_hit_area_chrome() -> void:
	var empty := StyleBoxEmpty.new()
	_hit_area.add_theme_stylebox_override("normal", empty)
	_hit_area.add_theme_stylebox_override("hover", empty)
	_hit_area.add_theme_stylebox_override("pressed", empty)
	_hit_area.add_theme_stylebox_override("focus", empty)
	_hit_area.text = ""


func _sync_motion_pivot() -> void:
	_motion.pivot_offset = _motion.size * 0.5


func _start_idle_motion() -> void:
	if _idle_tween and _idle_tween.is_valid():
		_idle_tween.kill()
	_motion.position = Vector2.ZERO
	_motion.rotation = 0.0
	_motion.scale = Vector2.ONE
	_idle_tween = create_tween()
	_idle_tween.set_loops()
	_idle_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(_motion, "position:y", -6.0, 1.1)
	_idle_tween.parallel().tween_property(_motion, "rotation", 0.04, 1.1)
	_idle_tween.tween_property(_motion, "position:y", 0.0, 1.1)
	_idle_tween.parallel().tween_property(_motion, "rotation", -0.03, 1.1)


func _play_react() -> void:
	if _react_tween and _react_tween.is_valid():
		_react_tween.kill()
	_motion.scale = Vector2.ONE
	_react_tween = create_tween()
	_react_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_react_tween.tween_property(_motion, "scale", Vector2(1.16, 1.16), 0.14)
	_react_tween.tween_property(_motion, "scale", Vector2.ONE, 0.18)


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

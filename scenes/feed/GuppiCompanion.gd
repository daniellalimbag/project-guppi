extends CanvasLayer
class_name GuppiCompanion

signal hint_requested

## Assign a Texture2D here (Inspector or set_sprite) when the entity art is ready.
@export var sprite_texture: Texture2D

const CATEGORY_INFO: Array[Dictionary] = [
	{
		"name": "Misinformation",
		"blurb": "• Old photos reused as if current\n• Flat-out denials of what happened\n• Numbers that don't match other outlets",
	},
	{
		"name": "Scams",
		"blurb": "• Urgent donation asks from new accounts\n• Requests for card numbers or personal info\n• QR codes or photos that don't add up",
	},
	{
		"name": "Ai Generated Post",
		"blurb": "• Impossible feats or too-dramatic scenes\n• Warped or inconsistent details\n• Poster admits the art is AI-made",
	},
]

@onready var _root: Control = %Root
@onready var _entity: Control = %Entity
@onready var _motion: Control = %Motion
@onready var _body: TextureRect = %Body
@onready var _placeholder: Panel = %Placeholder
@onready var _hit_area: Button = %HitArea
@onready var _tooltip_panel: PanelContainer = %TooltipPanel
@onready var _tooltip_label: Label = %TooltipLabel
@onready var _tooltip_category_panel: PanelContainer = %TooltipCategoryPanel
@onready var _tooltip_category_label: Label = %TooltipCategoryLabel
@onready var _tooltip_close_button: Button = %TooltipCloseButton
@onready var _tooltip_cycle_button: Button = %TooltipCycleButton
@onready var _arrow_row: Control = %ArrowRow

var _last_hint_post_id: String = ""
var _idle_tween: Tween
var _react_tween: Tween
var _category_cycle_index: int = -1


func _ready() -> void:
	_tooltip_panel.visible = false
	_arrow_row.visible = false
	_hit_area.pressed.connect(_on_hit_area_pressed)
	_tooltip_close_button.pressed.connect(_hide_tooltip)
	_tooltip_cycle_button.pressed.connect(_cycle_category)
	_clear_hit_area_chrome()
	_apply_sprite(sprite_texture)
	SettingsStore.settings_changed.connect(_apply_theme)
	_apply_theme()
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


func _apply_theme() -> void:
	var palette := SettingsStore.get_palette()
	var accent_dark: Color = palette.get("accent_dark", Color(0.16, 0.45, 0.42, 1))
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = accent_dark
	badge_style.corner_radius_top_left = 6
	badge_style.corner_radius_top_right = 6
	badge_style.corner_radius_bottom_right = 6
	badge_style.corner_radius_bottom_left = 6
	badge_style.content_margin_left = 8
	badge_style.content_margin_top = 3
	badge_style.content_margin_right = 8
	badge_style.content_margin_bottom = 3
	_tooltip_category_panel.add_theme_stylebox_override("panel", badge_style)


func show_hint(post_id: String, hint_text: String, category: String = "GUPPI") -> void:
	if hint_text.strip_edges().is_empty():
		return
	_last_hint_post_id = post_id
	_category_cycle_index = -1
	_tooltip_label.text = hint_text
	_tooltip_category_label.text = category.strip_edges().to_upper() if not category.strip_edges().is_empty() else "GUPPI"
	_play_react()
	_show_tooltip()


func _cycle_category() -> void:
	_category_cycle_index = (_category_cycle_index + 1) % CATEGORY_INFO.size()
	var info: Dictionary = CATEGORY_INFO[_category_cycle_index]
	_tooltip_category_label.text = str(info.get("name", "")).to_upper()
	_tooltip_label.text = str(info.get("blurb", ""))
	if not _tooltip_panel.visible:
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


func _on_hit_area_pressed() -> void:
	if _tooltip_panel.visible:
		_hide_tooltip()
	else:
		_cycle_category()


func _show_tooltip() -> void:
	_tooltip_panel.visible = true
	_arrow_row.visible = true
	_tooltip_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_tooltip_panel, "modulate:a", 1.0, 0.14)


func _hide_tooltip() -> void:
	if not _tooltip_panel.visible:
		return
	var tween := create_tween()
	tween.tween_property(_tooltip_panel, "modulate:a", 0.0, 0.16)
	tween.tween_callback(func() -> void:
		_tooltip_panel.visible = false
		_arrow_row.visible = false
		_category_cycle_index = -1
	)

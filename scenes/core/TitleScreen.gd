extends Control

signal request_go_to_difficulty
signal request_go_to_shifts

const SETTINGS_SCENE := preload("res://scenes/ui/SettingsPanel.tscn")

@onready var _background: ColorRect = %Background
@onready var _glow_top: ColorRect = %GlowTop
@onready var _glow_orb: ColorRect = %GlowOrb
@onready var _wave: ColorRect = %Wave
@onready var _brand: Label = %Brand
@onready var _title: Label = %TitleLabel
@onready var _tagline: Label = %Tagline
@onready var _new_game_button: Button = %NewGameButton
@onready var _continue_button: Button = %ContinueButton
@onready var _settings_button: Button = %SettingsButton
@onready var _how_to_button: Button = %HowToButton
@onready var _quit_button: Button = %QuitButton
@onready var _how_to_overlay: ColorRect = %HowToOverlay
@onready var _how_to_close: Button = %HowToClose
@onready var _no_save_overlay: ColorRect = %NoSaveOverlay
@onready var _no_save_close: Button = %NoSaveClose

var _settings_panel: SettingsPanel
var _primary_style: StyleBoxFlat
var _primary_hover: StyleBoxFlat
var _ghost_style: StyleBoxFlat


func _ready() -> void:
	_cache_styles()
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_settings_button.pressed.connect(_open_settings)
	_how_to_button.pressed.connect(_show_how_to)
	_how_to_close.pressed.connect(_hide_how_to)
	_no_save_close.pressed.connect(_hide_no_save)
	_quit_button.pressed.connect(_on_quit)
	_how_to_overlay.visible = false
	_no_save_overlay.visible = false

	_settings_panel = SETTINGS_SCENE.instantiate()
	_settings_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_settings_panel)

	SettingsStore.settings_changed.connect(_apply_theme)
	_apply_theme()
	_refresh_continue_label()
	_play_intro()


func _cache_styles() -> void:
	_primary_style = StyleBoxFlat.new()
	_primary_style.corner_radius_top_left = 14
	_primary_style.corner_radius_top_right = 14
	_primary_style.corner_radius_bottom_right = 14
	_primary_style.corner_radius_bottom_left = 14
	_primary_style.content_margin_left = 14
	_primary_style.content_margin_top = 16
	_primary_style.content_margin_right = 14
	_primary_style.content_margin_bottom = 16
	_primary_hover = _primary_style.duplicate() as StyleBoxFlat
	_ghost_style = StyleBoxFlat.new()
	_ghost_style.bg_color = Color(1, 1, 1, 0.1)
	_ghost_style.border_width_left = 1
	_ghost_style.border_width_top = 1
	_ghost_style.border_width_right = 1
	_ghost_style.border_width_bottom = 1
	_ghost_style.border_color = Color(1, 1, 1, 0.28)
	_ghost_style.corner_radius_top_left = 14
	_ghost_style.corner_radius_top_right = 14
	_ghost_style.corner_radius_bottom_right = 14
	_ghost_style.corner_radius_bottom_left = 14
	_ghost_style.content_margin_left = 14
	_ghost_style.content_margin_top = 14
	_ghost_style.content_margin_right = 14
	_ghost_style.content_margin_bottom = 14


func _play_intro() -> void:
	_brand.modulate.a = 0.0
	_title.modulate.a = 0.0
	_tagline.modulate.a = 0.0
	%Actions.modulate.a = 0.0
	modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(_brand, "modulate:a", 1.0, 0.35)
	tween.tween_property(_title, "modulate:a", 1.0, 0.35)
	tween.parallel().tween_property(_tagline, "modulate:a", 1.0, 0.4)
	tween.tween_property(%Actions, "modulate:a", 1.0, 0.35)


func _refresh_continue_label() -> void:
	_continue_button.text = SettingsStore.continue_label()


func _apply_theme() -> void:
	var palette := SettingsStore.get_palette()
	_background.color = palette.get("wash", Color(0.08, 0.28, 0.32))
	_glow_top.color = palette.get("glow", Color(0.2, 0.55, 0.58, 0.45))
	_glow_orb.color = palette.get("orb", Color(0.35, 0.75, 0.78, 0.18))
	_wave.color = Color(
		palette.get("accent_dark", Color(0.1, 0.3, 0.34)).r,
		palette.get("accent_dark", Color(0.1, 0.3, 0.34)).g,
		palette.get("accent_dark", Color(0.1, 0.3, 0.34)).b,
		0.55
	)

	var accent: Color = palette.get("accent", Color(0.18, 0.55, 0.58))
	var hover: Color = palette.get("accent_hover", accent.lightened(0.1))
	_primary_style.bg_color = accent
	_primary_hover.bg_color = hover
	_brand.add_theme_color_override("font_color", accent.lightened(0.35))
	_title.add_theme_color_override("font_color", Color(0.96, 0.99, 1.0))
	_tagline.add_theme_color_override("font_color", Color(0.78, 0.9, 0.92, 0.95))

	_new_game_button.add_theme_stylebox_override("normal", _primary_style)
	_new_game_button.add_theme_stylebox_override("hover", _primary_hover)
	_new_game_button.add_theme_stylebox_override("pressed", _primary_style)
	for btn in [_continue_button, _settings_button, _how_to_button]:
		btn.add_theme_stylebox_override("normal", _ghost_style)
		btn.add_theme_stylebox_override("hover", _ghost_style)
		btn.add_theme_stylebox_override("pressed", _ghost_style)
		btn.add_theme_color_override("font_color", Color(0.92, 0.97, 0.98))
		btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))

	_how_to_close.add_theme_stylebox_override("normal", _primary_style)
	_how_to_close.add_theme_stylebox_override("hover", _primary_hover)
	_how_to_close.add_theme_stylebox_override("pressed", _primary_style)
	_no_save_close.add_theme_stylebox_override("normal", _primary_style)
	_no_save_close.add_theme_stylebox_override("hover", _primary_hover)
	_no_save_close.add_theme_stylebox_override("pressed", _primary_style)
	_refresh_continue_label()


func _on_new_game_pressed() -> void:
	SettingsStore.menu_continue_mode = false
	request_go_to_difficulty.emit()


func _on_continue_pressed() -> void:
	if not SettingsStore.has_continue():
		_show_no_save()
		return
	SettingsStore.menu_continue_mode = true
	SettingsStore.menu_difficulty = SettingsStore.last_difficulty
	request_go_to_shifts.emit()


func _open_settings() -> void:
	_settings_panel.open()


func _show_how_to() -> void:
	_how_to_overlay.visible = true


func _hide_how_to() -> void:
	_how_to_overlay.visible = false


func _show_no_save() -> void:
	_no_save_overlay.visible = true


func _hide_no_save() -> void:
	_no_save_overlay.visible = false


func _on_quit() -> void:
	get_tree().quit()

extends Control
class_name PhoneStatusBar

## Top phone chrome: shift clock (9→5) · sky icon · SHIFT · status icons.

@onready var _sky_label: Label = %SkyLabel
@onready var _clock_label: Label = %ClockLabel
@onready var _shift_label: Label = %ShiftLabel


func _ready() -> void:
	_refresh_clock()
	var timer := Timer.new()
	timer.wait_time = 0.25
	timer.autostart = true
	timer.timeout.connect(_refresh_clock)
	add_child(timer)
	set_shift_status(GameState.shift_status_text())
	SettingsStore.settings_changed.connect(_apply_theme)
	_apply_theme()


func set_shift_status(text: String) -> void:
	if _shift_label:
		_shift_label.text = text


func set_shift(level: int) -> void:
	set_shift_status("SHIFT %d" % maxi(level, 1))


func _apply_theme() -> void:
	var palette := SettingsStore.get_palette()
	var dark: Color = palette.get("accent_dark", Color(0.12, 0.42, 0.45))
	add_theme_stylebox_override("panel", SettingsStore.make_flat_style(dark, 0, 6.0))
	var ink := Color(0.94, 0.97, 0.98, 1)
	_clock_label.add_theme_color_override("font_color", ink)
	_shift_label.add_theme_color_override("font_color", ink)
	_sky_label.add_theme_color_override("font_color", ink)


func _refresh_clock() -> void:
	if _clock_label == null:
		return
	_clock_label.text = GameState.get_shift_clock_text()
	_sky_label.text = GameState.get_shift_sky_icon()
	GameState.poll_shift_time_up()

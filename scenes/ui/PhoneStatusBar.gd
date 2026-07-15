extends Control
class_name PhoneStatusBar

## Top phone chrome: system clock · DIFFICULTY · SHIFT N · status icons.

@onready var _clock_label: Label = %ClockLabel
@onready var _shift_label: Label = %ShiftLabel


func _ready() -> void:
	_refresh_clock()
	var timer := Timer.new()
	timer.wait_time = 1.0
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


func _refresh_clock() -> void:
	if _clock_label == null:
		return
	var dt := Time.get_datetime_dict_from_system()
	_clock_label.text = "%d:%02d" % [int(dt.hour), int(dt.minute)]

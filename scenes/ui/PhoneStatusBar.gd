extends Control
class_name PhoneStatusBar

## Top phone chrome: system clock · SHIFT N · status icons.

@onready var _clock_label: Label = %ClockLabel
@onready var _shift_label: Label = %ShiftLabel


func _ready() -> void:
	_refresh_clock()
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_refresh_clock)
	add_child(timer)
	set_shift(GameState.current_level)


func set_shift(level: int) -> void:
	if _shift_label:
		_shift_label.text = "SHIFT %d" % maxi(level, 1)


func _refresh_clock() -> void:
	if _clock_label == null:
		return
	var dt := Time.get_datetime_dict_from_system()
	_clock_label.text = "%d:%02d" % [int(dt.hour), int(dt.minute)]

extends PanelContainer
class_name BottomNavBar

signal back_pressed
signal home_pressed
signal guppi_pressed

@onready var _back_button: Button = %BackButton
@onready var _home_button: Button = %HomeButton
@onready var _guppi_button: Button = %GuppiButton


func _ready() -> void:
	custom_minimum_size.y = UIConstants.BOTTOM_NAV_HEIGHT
	_back_button.custom_minimum_size = UIConstants.BOTTOM_NAV_BUTTON_MIN
	_home_button.custom_minimum_size = UIConstants.BOTTOM_NAV_BUTTON_MIN
	_guppi_button.custom_minimum_size = UIConstants.BOTTOM_NAV_BUTTON_MIN

	_back_button.pressed.connect(func() -> void: back_pressed.emit())
	_home_button.pressed.connect(func() -> void: home_pressed.emit())
	_guppi_button.pressed.connect(func() -> void: guppi_pressed.emit())

	set_back_enabled(false)


func set_back_enabled(enabled: bool) -> void:
	_back_button.disabled = not enabled
	_back_button.modulate = Color(1, 1, 1, 1) if enabled else Color(1, 1, 1, 0.35)

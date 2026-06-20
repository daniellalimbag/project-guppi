extends Control
class_name AppScreenBase

@export var app_id: AppId.Screen = AppId.Screen.HOME
@export var title: String = "App"
@export var header_color: Color = Color(0.18, 0.2, 0.26, 1)
@export var accent_color: Color = Color(0.45, 0.82, 0.98, 1)

@onready var _header: PanelContainer = %AppHeader
@onready var _header_icon: Label = %HeaderIcon
@onready var _header_title: Label = %HeaderTitle


func _ready() -> void:
	_header.custom_minimum_size.y = UIConstants.APP_HEADER_HEIGHT
	_header.add_theme_stylebox_override("panel", _make_header_style())
	_header_icon.text = _header_icon_text()
	_header_icon.add_theme_color_override("font_color", accent_color)
	_header_title.text = title


func _make_header_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = header_color
	style.border_width_bottom = 1
	style.border_color = Color(0.1, 0.11, 0.14, 1)
	return style


func _header_icon_text() -> String:
	match app_id:
		AppId.Screen.MAIL:
			return "M"
		AppId.Screen.MESSAGES:
			return "💬"
		AppId.Screen.SOCIAL_STREAM:
			return "◎"
		AppId.Screen.FILES:
			return "📄"
		_:
			return "•"

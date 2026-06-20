extends Control

signal app_launched(app_id: AppId.Screen)

const LAUNCHER_APPS: Array[Dictionary] = [
	{
		"app_id": AppId.Screen.MAIL,
		"icon_text": "M",
		"icon_color": Color(0.22, 0.52, 0.96, 1),
		"app_name": "Mail",
		"badge_count": 3,
	},
	{
		"app_id": AppId.Screen.MESSAGES,
		"icon_text": "💬",
		"icon_color": Color(0.2, 0.78, 0.48, 1),
		"app_name": "Messages",
		"badge_count": 1,
	},
	{
		"app_id": AppId.Screen.SOCIAL_STREAM,
		"icon_text": "◎",
		"icon_color": Color(0.58, 0.38, 0.92, 1),
		"app_name": "SocialStream",
		"badge_count": 0,
	},
	{
		"app_id": AppId.Screen.FILES,
		"icon_text": "F",
		"icon_color": Color(0.95, 0.62, 0.18, 1),
		"app_name": "Files",
		"badge_count": 0,
	},
]

@onready var _grid: GridContainer = %AppGrid


func _ready() -> void:
	_build_launcher_grid()


func _build_launcher_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()

	for config in LAUNCHER_APPS:
		var icon_button: AppIconButton = preload("res://scenes/ui/AppIconButton.tscn").instantiate()
		icon_button.configure(config)
		icon_button.icon_pressed.connect(_on_app_icon_pressed)
		_grid.add_child(icon_button)


func _on_app_icon_pressed(app_id: AppId.Screen) -> void:
	app_launched.emit(app_id)

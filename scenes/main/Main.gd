extends Control

const APP_SCENES: Array[PackedScene] = [
	preload("res://scenes/apps/HomeScreen.tscn"),
	preload("res://scenes/apps/MailApp.tscn"),
	preload("res://scenes/apps/MessagesApp.tscn"),
	preload("res://scenes/apps/SocialStreamApp.tscn"),
	preload("res://scenes/apps/FilesApp.tscn"),
]

@onready var _screen_host: Control = %ScreenHost
@onready var _bottom_nav: BottomNavBar = %BottomNavBar
@onready var _day_label: Label = %DayLabel

var _active_screen: Control
var _active_app_id: AppId.Screen = AppId.Screen.HOME


func _ready() -> void:
	_bottom_nav.back_pressed.connect(_on_back_pressed)
	_bottom_nav.home_pressed.connect(_go_home)
	_bottom_nav.guppi_pressed.connect(_open_guppi)
	GameState.stats_updated.connect(_refresh_status_bar)
	_refresh_status_bar()
	_go_home()


func _on_back_pressed() -> void:
	if _active_app_id != AppId.Screen.HOME:
		_go_home()


func _go_home() -> void:
	_show_app(AppId.Screen.HOME)


func _open_guppi() -> void:
	_show_app(AppId.Screen.MESSAGES)


func _show_app(app_id: AppId.Screen) -> void:
	if _active_screen:
		_active_screen.queue_free()
		_active_screen = null

	var scene: PackedScene = APP_SCENES[app_id]
	_active_screen = scene.instantiate()
	_screen_host.add_child(_active_screen)
	_active_app_id = app_id
	_bottom_nav.set_back_enabled(app_id != AppId.Screen.HOME)

	if _active_screen.has_signal("app_launched"):
		_active_screen.app_launched.connect(_on_app_launched)


func _on_app_launched(app_id: AppId.Screen) -> void:
	_show_app(app_id)


func _refresh_status_bar() -> void:
	_day_label.text = "Day %d" % GameState.current_day

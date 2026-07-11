extends Control

enum Screen {
	TITLE,
	FEED,
	RESULTS,
}

const SCREEN_SCENES: Dictionary = {
	Screen.TITLE: preload("res://scenes/core/TitleScreen.tscn"),
	Screen.FEED: preload("res://scenes/core/FeedScreen.tscn"),
	Screen.RESULTS: preload("res://scenes/core/ResultsScreen.tscn"),
}

@onready var _screen_host: Control = %ScreenHost

var _active_screen: Control


func _ready() -> void:
	_show_screen(Screen.TITLE)


func _show_screen(screen: Screen) -> void:
	if _active_screen:
		_active_screen.queue_free()

	var scene: PackedScene = SCREEN_SCENES[screen]
	_active_screen = scene.instantiate()
	_screen_host.add_child(_active_screen)

	if _active_screen.has_signal("request_go_to_feed"):
		_active_screen.request_go_to_feed.connect(func() -> void: _show_screen(Screen.FEED))
	if _active_screen.has_signal("request_go_to_results"):
		_active_screen.request_go_to_results.connect(func() -> void: _show_screen(Screen.RESULTS))
	if _active_screen.has_signal("request_go_to_title"):
		_active_screen.request_go_to_title.connect(func() -> void: _show_screen(Screen.TITLE))

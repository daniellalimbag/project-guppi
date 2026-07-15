extends Control

enum Screen {
	TITLE,
	DIFFICULTY,
	SHIFTS,
	FEED,
	RESULTS,
}

const SCREEN_SCENES: Dictionary = {
	Screen.TITLE: preload("res://scenes/core/TitleScreen.tscn"),
	Screen.DIFFICULTY: preload("res://scenes/core/DifficultyScreen.tscn"),
	Screen.SHIFTS: preload("res://scenes/core/ShiftSelectScreen.tscn"),
	Screen.FEED: preload("res://scenes/core/FeedScreen.tscn"),
	Screen.RESULTS: preload("res://scenes/core/ResultsScreen.tscn"),
}

@onready var _background: ColorRect = $Background
@onready var _screen_host: Control = %ScreenHost

var _active_screen: Control


func _ready() -> void:
	SettingsStore.settings_changed.connect(_apply_theme)
	_apply_theme()
	_show_screen(Screen.TITLE)


func _apply_theme() -> void:
	var palette := SettingsStore.get_palette()
	_background.color = palette.get("app_wash", _background.color)


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
	if _active_screen.has_signal("request_go_to_difficulty"):
		_active_screen.request_go_to_difficulty.connect(func() -> void: _show_screen(Screen.DIFFICULTY))
	if _active_screen.has_signal("request_go_to_shifts"):
		_active_screen.request_go_to_shifts.connect(func() -> void: _show_screen(Screen.SHIFTS))

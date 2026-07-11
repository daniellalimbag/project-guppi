extends Control

signal request_go_to_feed


func _ready() -> void:
	%StartButton.pressed.connect(_on_start_pressed)
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.35)


func _on_start_pressed() -> void:
	GameState.reset_run()
	GameState.current_level = 1
	request_go_to_feed.emit()

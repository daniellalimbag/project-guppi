extends Control

signal request_go_to_level_select
signal request_go_to_feed
signal request_go_to_title

@onready var _header_label: Label = %HeaderLabel
@onready var _summary_label: Label = %SummaryLabel
@onready var _continue_button: Button = %ContinueButton
@onready var _replay_button: Button = %ReplayButton


func _ready() -> void:
	_continue_button.pressed.connect(_on_continue_pressed)
	_replay_button.pressed.connect(func() -> void: request_go_to_feed.emit())
	%LevelsButton.pressed.connect(func() -> void: request_go_to_level_select.emit())
	_refresh_summary()
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.28)


func _refresh_summary() -> void:
	var before_pct := int(round(GameState.guppi_accuracy_before * 100.0))
	var after_pct := int(round(GameState.guppi_accuracy_after * 100.0))
	var delta := after_pct - before_pct
	var arrow := "▲" if delta >= 0 else "▼"
	var delta_text := "+%d" % delta if delta >= 0 else str(delta)
	var level := GameState.current_level

	_header_label.text = "Shift %d report" % level
	_summary_label.text = (
		"Your hit rate\n%d / %d tickets cleared correctly\n\n"
		+ "GUPPI sync\n%d%% → %d%%  %s %s\n\n"
		+ "Most missed pattern\n%s"
	) % [
		GameState.correct_this_level,
		GameState.total_posts_this_level,
		before_pct,
		after_pct,
		arrow,
		delta_text,
		GameState.most_missed_insight,
	]

	if GameState.has_next_level():
		_continue_button.text = "Clock into Shift %d →" % (level + 1)
	else:
		_continue_button.text = "End of roster · clock out"


func _on_continue_pressed() -> void:
	if GameState.advance_to_next_level():
		request_go_to_feed.emit()
	else:
		request_go_to_title.emit()

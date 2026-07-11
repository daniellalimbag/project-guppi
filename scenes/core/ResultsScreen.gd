extends Control

signal request_go_to_feed
signal request_go_to_title

@onready var _header_label: Label = %HeaderLabel
@onready var _summary_label: Label = %SummaryLabel
@onready var _continue_button: Button = %ContinueButton
@onready var _replay_button: Button = %ReplayButton


func _ready() -> void:
	_continue_button.pressed.connect(_on_continue_pressed)
	_replay_button.pressed.connect(func() -> void: request_go_to_feed.emit())
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
	var used_sec := int(round(GameState.time_limit_sec - GameState.time_remaining_sec))
	var used_min := used_sec / 60
	var used_rem := used_sec % 60
	var time_line := "Time used\n%d:%02d" % [used_min, used_rem]
	if GameState.timed_out:
		time_line += " · timed out"

	_header_label.text = "Shift %d report" % level
	_summary_label.text = (
		"Your hit rate\n%d / %d tickets cleared correctly\n\n"
		+ "%s\n\n"
		+ "GUPPI sync\n%d%% → %d%%  %s %s\n\n"
		+ "Most missed pattern\n%s"
	) % [
		GameState.correct_this_level,
		GameState.total_posts_this_level,
		time_line,
		before_pct,
		after_pct,
		arrow,
		delta_text,
		GameState.most_missed_insight,
	]

	if GameState.has_next_level():
		_continue_button.text = "Continue to Shift %d →" % (level + 1)
	else:
		_continue_button.text = "Return to title"


func _on_continue_pressed() -> void:
	if GameState.advance_to_next_level():
		request_go_to_feed.emit()
	else:
		request_go_to_title.emit()

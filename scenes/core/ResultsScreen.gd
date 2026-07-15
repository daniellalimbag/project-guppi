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
	SettingsStore.settings_changed.connect(_apply_theme)
	SettingsStore.unlock_next_after(GameState.current_difficulty, GameState.current_shift)
	_apply_theme()
	_refresh_summary()
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.28)


func _apply_theme() -> void:
	var palette := SettingsStore.get_palette()
	var results: Color = palette.get("results", Color(0.05, 0.08, 0.1))
	var accent: Color = palette.get("accent", Color(0.18, 0.55, 0.82))
	var hover: Color = palette.get("accent_hover", accent.lightened(0.1))
	$Background.add_theme_stylebox_override("panel", SettingsStore.make_flat_style(results))
	var primary := SettingsStore.make_flat_style(accent, 10)
	var primary_hover := SettingsStore.make_flat_style(hover, 10)
	_continue_button.add_theme_stylebox_override("normal", primary)
	_continue_button.add_theme_stylebox_override("hover", primary_hover)
	_continue_button.add_theme_stylebox_override("pressed", primary)


func _refresh_summary() -> void:
	var before_pct := int(round(GameState.guppi_accuracy_before * 100.0))
	var after_pct := int(round(GameState.guppi_accuracy_after * 100.0))
	var delta := after_pct - before_pct
	var arrow := "▲" if delta >= 0 else "▼"
	var delta_text := "+%d" % delta if delta >= 0 else str(delta)
	var difficulty_label := LevelManager.get_difficulty_label(GameState.current_difficulty)
	var shift := GameState.current_shift

	_header_label.text = "%s · Shift %d report" % [difficulty_label, shift]
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
		_continue_button.text = "Continue to Shift %d →" % (shift + 1)
	else:
		_continue_button.text = "Return to title"


func _on_continue_pressed() -> void:
	if GameState.advance_to_next_level():
		SettingsStore.mark_shift_started(GameState.current_difficulty, GameState.current_shift)
		request_go_to_feed.emit()
	else:
		request_go_to_title.emit()

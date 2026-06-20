extends Node
## Global game state for Project GUPPI.
## Tracks player performance, day progression, and per-post evidence usage.

signal day_changed(day: int)
signal stats_updated

const MAX_DAYS := 5

var accuracy: float = 1.0
var trust_score: float = 1.0
var correction_tokens: int = 0
var current_day: int = 1
var guppi_drift: float = 0.0
var evidence_checked_this_post: int = 0


func _ready() -> void:
	reset_session()


func reset_session() -> void:
	accuracy = 1.0
	trust_score = 1.0
	correction_tokens = 0
	current_day = 1
	guppi_drift = 0.0
	evidence_checked_this_post = 0
	stats_updated.emit()


func reset_evidence_for_post() -> void:
	evidence_checked_this_post = 0


func register_evidence_checked() -> void:
	evidence_checked_this_post += 1


func start_new_day() -> void:
	if current_day >= MAX_DAYS:
		return
	current_day += 1
	evidence_checked_this_post = 0
	day_changed.emit(current_day)
	stats_updated.emit()

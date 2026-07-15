extends Node
## Global run state for the Tideline feed loop.

signal level_changed(difficulty_id: String, shift: int)
signal state_updated

var current_difficulty: String = "easy"
var current_shift: int = 1
var current_score: int = 0
var total_posts_this_level: int = 0
var correct_this_level: int = 0
var guppi_accuracy_before: float = 0.55
var guppi_accuracy_after: float = 0.55
var hint_frequency: float = 1.0
var miss_tags: Dictionary = {}
var most_missed_insight: String = "None this round"


func _ready() -> void:
	reset_run()


func reset_run() -> void:
	current_difficulty = "easy"
	current_shift = 1
	current_score = 0
	total_posts_this_level = 0
	correct_this_level = 0
	guppi_accuracy_before = 0.55
	guppi_accuracy_after = 0.55
	hint_frequency = 1.0
	miss_tags.clear()
	most_missed_insight = "None this round"
	state_updated.emit()


func get_max_shifts() -> int:
	return maxi(LevelManager.get_shift_count(current_difficulty), 1)


func start_at_shift(difficulty_id: String, shift: int) -> void:
	reset_run()
	current_difficulty = difficulty_id
	current_shift = clampi(shift, 1, get_max_shifts())
	level_changed.emit(current_difficulty, current_shift)
	state_updated.emit()


func begin_level(difficulty_id: String, shift: int, total_posts: int, level_hint_frequency: float) -> void:
	current_difficulty = difficulty_id
	current_shift = clampi(shift, 1, get_max_shifts())
	total_posts_this_level = maxi(total_posts, 0)
	correct_this_level = 0
	current_score = 0
	hint_frequency = clampf(level_hint_frequency, 0.0, 1.0)
	guppi_accuracy_before = guppi_accuracy_after
	miss_tags.clear()
	most_missed_insight = "None this round"
	level_changed.emit(current_difficulty, current_shift)
	state_updated.emit()


func register_label_result(is_correct: bool, miss_tag: String = "") -> void:
	if is_correct:
		correct_this_level += 1
		current_score += 1
	elif not miss_tag.is_empty():
		miss_tags[miss_tag] = int(miss_tags.get(miss_tag, 0)) + 1
	state_updated.emit()


func finalize_level_stats() -> void:
	most_missed_insight = _compute_most_missed_insight()
	if total_posts_this_level <= 0:
		guppi_accuracy_after = guppi_accuracy_before
	else:
		var ratio := float(correct_this_level) / float(total_posts_this_level)
		guppi_accuracy_after = clampf(guppi_accuracy_before * 0.7 + ratio * 0.3, 0.0, 1.0)
	state_updated.emit()


func has_next_level() -> bool:
	return current_shift < get_max_shifts()


func advance_to_next_level() -> bool:
	if not has_next_level():
		return false
	current_shift += 1
	level_changed.emit(current_difficulty, current_shift)
	state_updated.emit()
	return true


func shift_status_text() -> String:
	var label := LevelManager.get_difficulty_label(current_difficulty).to_upper()
	return "%s · SHIFT %d" % [label, maxi(current_shift, 1)]


func _compute_most_missed_insight() -> String:
	if miss_tags.is_empty():
		return "None this round — strong work"
	var best_tag := ""
	var best_count := 0
	for tag in miss_tags.keys():
		var count := int(miss_tags[tag])
		if count > best_count:
			best_count = count
			best_tag = str(tag)
	return best_tag

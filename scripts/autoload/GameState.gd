extends Node
## Global run state for the Tideline feed loop.

signal level_changed(difficulty_id: String, shift: int)
signal state_updated
signal shift_time_up

## In-world shift clock: 9:00 → 17:00, 1 real minute = 1 game hour.
const SHIFT_START_HOUR := 9
const SHIFT_END_HOUR := 17
const REAL_SECONDS_PER_GAME_HOUR := 60.0

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

var _shift_clock_started_msec: int = 0
var _shift_clock_paused: bool = false
var _shift_pause_started_msec: int = 0
var _shift_paused_total_msec: int = 0
var _shift_time_up_emitted: bool = false


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
	_reset_shift_clock()
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
	_reset_shift_clock()
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


func pause_shift_clock() -> void:
	if _shift_clock_paused:
		return
	_shift_clock_paused = true
	_shift_pause_started_msec = Time.get_ticks_msec()


func resume_shift_clock() -> void:
	if not _shift_clock_paused:
		return
	_shift_paused_total_msec += Time.get_ticks_msec() - _shift_pause_started_msec
	_shift_clock_paused = false


func get_shift_elapsed_real_sec() -> float:
	var now := Time.get_ticks_msec()
	var paused := _shift_paused_total_msec
	if _shift_clock_paused:
		paused += now - _shift_pause_started_msec
	return maxf(0.0, float(now - _shift_clock_started_msec - paused) / 1000.0)


func get_shift_game_minutes() -> int:
	## 1 real minute = 1 in-world hour → 1 real second = 1 in-world minute.
	var minutes_per_real_sec := 60.0 / REAL_SECONDS_PER_GAME_HOUR
	return int(floor(get_shift_elapsed_real_sec() * minutes_per_real_sec))


func get_shift_clock_hour_minute() -> Vector2i:
	var start_min := SHIFT_START_HOUR * 60
	var end_min := SHIFT_END_HOUR * 60
	var total_min := mini(start_min + get_shift_game_minutes(), end_min)
	return Vector2i(total_min / 60, total_min % 60)


func get_shift_clock_text() -> String:
	var hm := get_shift_clock_hour_minute()
	var hour12 := hm.x % 12
	if hour12 == 0:
		hour12 = 12
	var suffix := "AM" if hm.x < 12 else "PM"
	return "%d:%02d %s" % [hour12, hm.y, suffix]


func get_shift_sky_icon() -> String:
	var hour := get_shift_clock_hour_minute().x
	if hour < 11:
		return "🌅"
	if hour < 15:
		return "☀️"
	return "🌇"


func is_shift_time_up() -> bool:
	var span_min := (SHIFT_END_HOUR - SHIFT_START_HOUR) * 60
	return get_shift_game_minutes() >= span_min


func poll_shift_time_up() -> void:
	if _shift_time_up_emitted or not is_shift_time_up():
		return
	_shift_time_up_emitted = true
	shift_time_up.emit()


func _reset_shift_clock() -> void:
	_shift_clock_started_msec = Time.get_ticks_msec()
	_shift_clock_paused = false
	_shift_pause_started_msec = 0
	_shift_paused_total_msec = 0
	_shift_time_up_emitted = false


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

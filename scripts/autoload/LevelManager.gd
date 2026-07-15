extends Node
## Loads difficulty/shift config and post pools from JSON.

signal level_loaded(difficulty_id: String, shift: int, selected_posts: Array[Dictionary])
signal level_completed(difficulty_id: String, shift: int)

const LEVELS_PATH := "res://data/levels.json"
const POSTS_DIR := "res://data/posts"

var level_config: Dictionary = {}
var current_posts: Array[Dictionary] = []
var current_post_index: int = 0


func _ready() -> void:
	level_config = load_levels_config()


func load_levels_config() -> Dictionary:
	if not FileAccess.file_exists(LEVELS_PATH):
		push_warning("Missing levels config at %s" % LEVELS_PATH)
		return {}

	var file := FileAccess.open(LEVELS_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("levels.json is invalid JSON dictionary")
		return {}
	return parsed


func get_difficulties() -> Array:
	if level_config.is_empty():
		level_config = load_levels_config()
	return level_config.get("difficulties", [])


func get_difficulty(difficulty_id: String) -> Dictionary:
	for item in get_difficulties():
		if typeof(item) == TYPE_DICTIONARY and str(item.get("id", "")) == difficulty_id:
			return item
	return {}


func get_difficulty_label(difficulty_id: String) -> String:
	var cfg := get_difficulty(difficulty_id)
	return str(cfg.get("label", difficulty_id.capitalize()))


func get_shifts(difficulty_id: String) -> Array:
	var cfg := get_difficulty(difficulty_id)
	return cfg.get("shifts", [])


func get_shift_config(difficulty_id: String, shift: int) -> Dictionary:
	for item in get_shifts(difficulty_id):
		if typeof(item) == TYPE_DICTIONARY and int(item.get("shift", -1)) == shift:
			return item
	return {}


func get_shift_count(difficulty_id: String) -> int:
	return get_shifts(difficulty_id).size()


func load_pool(pool_name: String) -> Array[Dictionary]:
	var path := "%s/%s.json" % [POSTS_DIR, pool_name]
	if not FileAccess.file_exists(path):
		push_warning("Missing post pool at %s" % path)
		return []

	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_warning("Expected an array in %s" % path)
		return []

	var posts: Array[Dictionary] = []
	for item in parsed:
		if typeof(item) == TYPE_DICTIONARY:
			posts.append(item)
	return posts


func start_shift(difficulty_id: String, shift: int) -> Array[Dictionary]:
	var cfg := get_shift_config(difficulty_id, shift)
	if cfg.is_empty():
		push_warning("Missing shift config %s/%d" % [difficulty_id, shift])
		current_posts = []
		current_post_index = 0
		return current_posts

	var pool_name := str(cfg.get("posts_pool", "level_01"))
	var pool := load_pool(pool_name)
	var posts_to_show: int = int(cfg.get("posts_shown", pool.size()))
	current_posts = sample_posts(pool, posts_to_show)
	current_post_index = 0
	level_loaded.emit(difficulty_id, shift, current_posts)
	return current_posts


func sample_posts(pool: Array[Dictionary], count: int) -> Array[Dictionary]:
	if pool.is_empty():
		return []
	var copy := pool.duplicate()
	copy.shuffle()
	return copy.slice(0, mini(count, copy.size()))


func get_current_post() -> Dictionary:
	if current_post_index < 0 or current_post_index >= current_posts.size():
		return {}
	return current_posts[current_post_index]


func advance_post() -> Dictionary:
	current_post_index += 1
	if current_post_index >= current_posts.size():
		level_completed.emit(GameState.current_difficulty, GameState.current_shift)
		return {}
	return get_current_post()


func is_level_complete() -> bool:
	return current_post_index >= current_posts.size()

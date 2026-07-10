extends Node
## Loads level config and post pools from JSON, then serves sampled posts for a run.

signal level_loaded(level: int, selected_posts: Array[Dictionary])
signal level_completed(level: int)

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


func load_level_pool(level: int) -> Array[Dictionary]:
	var path := "%s/level_%02d.json" % [POSTS_DIR, level]
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


func start_level(level: int) -> Array[Dictionary]:
	if level_config.is_empty():
		level_config = load_levels_config()

	var levels: Array = level_config.get("levels", [])
	var cfg := _find_level_config(level, levels)
	var pool := load_level_pool(level)
	var posts_to_show: int = int(cfg.get("posts_shown", pool.size()))
	current_posts = sample_posts(pool, posts_to_show)
	current_post_index = 0
	level_loaded.emit(level, current_posts)
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
		level_completed.emit(GameState.current_level)
		return {}
	return get_current_post()


func is_level_complete() -> bool:
	return current_post_index >= current_posts.size()


func _find_level_config(level: int, levels: Array) -> Dictionary:
	for cfg in levels:
		if typeof(cfg) == TYPE_DICTIONARY and int(cfg.get("level", -1)) == level:
			return cfg
	return {}


func get_level_config(level: int) -> Dictionary:
	if level_config.is_empty():
		level_config = load_levels_config()
	var levels: Array = level_config.get("levels", [])
	return _find_level_config(level, levels)
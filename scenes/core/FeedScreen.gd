extends Control

signal request_go_to_results
signal request_go_to_title

const POST_CARD_SCENE := preload("res://scenes/feed/PostCard.tscn")
const PROFILE_SCENE := preload("res://scenes/feed/ProfileScreen.tscn")
const PAUSE_MENU_SCENE := preload("res://scenes/ui/PauseMenu.tscn")

## Drop a custom star PNG here (or replace assets/icons/icon_quota_star.png).
@export var quota_star_texture: Texture2D

@onready var _status_bar: PhoneStatusBar = %PhoneStatusBar
@onready var _header_label: Label = %HeaderLabel
@onready var _progress_label: Label = %ProgressLabel
@onready var _star_texture: TextureRect = %StarTexture
@onready var _background_image: TextureRect = %BackgroundImage
@onready var _music_player: AudioStreamPlayer = %MusicPlayer
@onready var _feed_list: VBoxContainer = %FeedList
@onready var _queue_done_label: Label = %QueueDoneLabel
@onready var _guppi: GuppiCompanion = %GuppiCompanion
@onready var _overlay_host: Control = %OverlayHost

var _labeled_count: int = 0
var _level_finished: bool = false
var _cards_by_id: Dictionary = {}
var _profile_screen: ProfileScreen
var _pause_menu: PauseMenu
var _active_context_post: Dictionary = {}


func _ready() -> void:
	_queue_done_label.visible = false
	%MenuButton.pressed.connect(_on_menu_pressed)
	if quota_star_texture != null:
		_star_texture.texture = quota_star_texture
	_profile_screen = PROFILE_SCENE.instantiate()
	_profile_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay_host.add_child(_profile_screen)
	_profile_screen.closed.connect(_on_profile_closed)
	_profile_screen.opened.connect(_on_profile_opened)
	_profile_screen.exit_requested.connect(func() -> void: request_go_to_title.emit())
	_profile_screen.menu_requested.connect(_on_menu_pressed)
	_pause_menu = PAUSE_MENU_SCENE.instantiate()
	_pause_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_pause_menu)
	_pause_menu.give_up_requested.connect(func() -> void: request_go_to_title.emit())
	_pause_menu.resume_requested.connect(func() -> void: GameState.resume_shift_clock())
	_guppi.hint_requested.connect(_on_guppi_hint_requested)
	SettingsStore.settings_changed.connect(_apply_theme)
	GameState.shift_time_up.connect(_on_shift_time_up)
	_apply_theme()
	modulate.a = 0.0
	_load_feed()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25)


func _exit_tree() -> void:
	_stop_music()


func _apply_theme() -> void:
	var palette := SettingsStore.get_palette()
	var accent: Color = palette.get("accent", Color(0.22, 0.55, 0.58))
	var accent_dark: Color = palette.get("accent_dark", Color(0.12, 0.42, 0.45))
	# Keep feed backdrop transparent so the shift art shows through.
	$Background.add_theme_stylebox_override(
		"panel", SettingsStore.make_flat_style(Color(0, 0, 0, 0))
	)
	$MainCol/HeaderBar.add_theme_stylebox_override(
		"panel", SettingsStore.make_flat_style(accent, 0, 6.0)
	)
	$MainCol/FooterBar.add_theme_stylebox_override(
		"panel", SettingsStore.make_flat_style(accent_dark, 0, 10.0)
	)


func _load_feed() -> void:
	_clear_feed()
	_labeled_count = 0
	_level_finished = false
	_cards_by_id.clear()
	_active_context_post = {}
	_queue_done_label.visible = false

	var difficulty := GameState.current_difficulty
	var shift := maxi(GameState.current_shift, 1)
	var posts := LevelManager.start_shift(difficulty, shift)
	var cfg: Dictionary = LevelManager.get_shift_config(difficulty, shift)
	var hint_frequency := float(cfg.get("hint_frequency", 1.0))
	GameState.begin_level(difficulty, shift, posts.size(), hint_frequency)
	_apply_shift_ambiance(cfg)

	_header_label.text = "SEA CORP."
	_status_bar.set_shift_status(GameState.shift_status_text())
	_update_progress()

	if posts.is_empty():
		return

	for post_data in posts:
		var card: FeedPostCard = POST_CARD_SCENE.instantiate()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_feed_list.add_child(card)
		card.set_post(post_data)
		var post_id := str(post_data.get("id", ""))
		_cards_by_id[post_id] = post_data
		card.labeled.connect(_on_post_labeled.bind(post_id))
		card.collapsed.connect(_on_post_collapsed)
		card.profile_requested.connect(_on_profile_requested)

	_refresh_active_context()


func _apply_shift_ambiance(cfg: Dictionary) -> void:
	var bg_path := str(cfg.get("background", "")).strip_edges()
	if not bg_path.is_empty() and ResourceLoader.exists(bg_path):
		_background_image.texture = load(bg_path) as Texture2D
	_play_music(str(cfg.get("music", "")).strip_edges())


func _play_music(path: String) -> void:
	_stop_music()
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		return
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_music_player.stream = stream
	_music_player.volume_db = -6.0
	_music_player.play()


func _stop_music() -> void:
	if _music_player == null:
		return
	if _music_player.playing:
		_music_player.stop()
	_music_player.stream = null


func _clear_feed() -> void:
	for child in _feed_list.get_children():
		child.queue_free()


func _update_progress() -> void:
	var total := GameState.total_posts_this_level
	_progress_label.text = "QUOTA\n%d/%d" % [_labeled_count, total]


func _on_menu_pressed() -> void:
	if _level_finished:
		return
	if _pause_menu.is_open():
		_pause_menu.close()
		GameState.resume_shift_clock()
	else:
		GameState.pause_shift_clock()
		_pause_menu.move_to_front()
		_pause_menu.open()


func _on_shift_time_up() -> void:
	if _level_finished:
		return
	if _pause_menu != null and _pause_menu.is_open():
		_pause_menu.close()
	_queue_done_label.visible = true
	_queue_done_label.text = "Shift over — clocked out at 5:00 PM."
	_finish_level()


func set_quota_star(texture: Texture2D) -> void:
	quota_star_texture = texture
	if _star_texture:
		_star_texture.texture = texture


func _on_post_labeled(_selected_real: bool, is_correct: bool, post_id: String) -> void:
	if _level_finished:
		return
	var miss_tag := ""
	if not is_correct:
		var post: Dictionary = _cards_by_id.get(post_id, {})
		miss_tag = _infer_miss_tag(post)
	GameState.register_label_result(is_correct, miss_tag)
	_labeled_count += 1
	LevelManager.advance_post()
	_update_progress()
	_refresh_active_context()


func _infer_miss_tag(post: Dictionary) -> String:
	var explicit := str(post.get("insight_tag", "")).strip_edges()
	if not explicit.is_empty():
		return explicit
	var content := str(post.get("content", "")).to_upper()
	var account_age := str(post.get("account_age", "")).to_lower()
	if "OTP" in content or "SEND YOUR" in content or "CLAIM" in content:
		return "Scam / urgency tactics"
	if "DOCTOR" in content or "CURE" in content or "HATE THIS" in content:
		return "Posts with emotional language"
	if "day" in account_age or "week" in account_age:
		return "New / unverified accounts"
	if not bool(post.get("verified", false)):
		return "Unverified sources"
	return "Subtle credibility cues"


func _on_post_collapsed() -> void:
	if _level_finished:
		return
	if _labeled_count < GameState.total_posts_this_level:
		_refresh_active_context()
		return
	_finish_level()


func _finish_level() -> void:
	if _level_finished:
		return
	_level_finished = true
	_stop_music()
	GameState.finalize_level_stats()
	_queue_done_label.visible = true
	_queue_done_label.text = "Quota filled."
	await get_tree().create_timer(1.0).timeout
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	request_go_to_results.emit()


func _get_next_active_card() -> FeedPostCard:
	for child in _feed_list.get_children():
		if child is FeedPostCard:
			return child
	return null


func _refresh_active_context() -> void:
	if _profile_screen != null and _profile_screen.is_open():
		_active_context_post = _profile_screen.get_post_data()
		return
	var card := _get_next_active_card()
	_active_context_post = card.get_post_data() if card != null else {}


func _on_profile_requested(post_data: Dictionary) -> void:
	_profile_screen.open(post_data)


func _on_profile_opened(post_data: Dictionary) -> void:
	_active_context_post = post_data.duplicate(true)
	_guppi.visible = true
	var profile: Dictionary = post_data.get("profile", {})
	var bot_raw := str(profile.get("bot_followers_pct", "")).strip_edges()
	if not bot_raw.is_empty() and bot_raw != "Unknown" and int(bot_raw.trim_suffix("%")) >= 40:
		_guppi.nudge()


func _on_profile_closed() -> void:
	_refresh_active_context()


func _on_guppi_hint_requested() -> void:
	_refresh_active_context()
	if not SettingsStore.guppi_tips_enabled:
		_guppi.show_hint("", "Tips are off — turn them on in Settings.")
		return
	if _active_context_post.is_empty():
		_guppi.show_hint("", "Nothing queued — open a post or profile.")
		return

	if randf() > maxf(GameState.hint_frequency, 0.15):
		_guppi.show_hint(
			str(_active_context_post.get("id", "")),
			"Hmm… still looking. Check account age and the replies."
		)
		return

	var tip := _build_subtle_tip(_active_context_post, _profile_screen.is_open())
	_guppi.show_hint(str(_active_context_post.get("id", "")), tip)


func _build_subtle_tip(post: Dictionary, viewing_profile: bool) -> String:
	var profile: Dictionary = post.get("profile", {})
	var bot_raw := str(profile.get("bot_followers_pct", "")).strip_edges()
	var joined := str(profile.get("joined", post.get("account_age", ""))).to_lower()
	var verified := bool(post.get("verified", false))
	var authored_hint := str(post.get("guppi_hint", "")).strip_edges()

	if viewing_profile:
		if not bot_raw.is_empty() and bot_raw != "Unknown":
			var bot_pct := bot_raw.trim_suffix("%")
			return "Follower scan: ~%s%% look inactive or automated." % bot_pct
		if "day" in joined or "week" in joined:
			return "This account looks pretty new for that follower count…"
		if verified:
			return "Badge and post history look consistent to me."
		return "Compare follower count to how long they've been posting."

	if not authored_hint.is_empty():
		return authored_hint
	if not bot_raw.is_empty() and int(bot_raw.trim_suffix("%")) >= 50:
		return "Something about the engagement on this one feels off."
	var comments: Array = post.get("comments", [])
	var bot_comments := 0
	for c in comments:
		if bool(c.get("is_bot", false)):
			bot_comments += 1
	if bot_comments >= 2:
		return "A few replies here sound weirdly similar…"
	if "day" in joined or "week" in joined:
		return "I'd peek at the profile before deciding."
	return "Check who wrote this, then skim the comments."

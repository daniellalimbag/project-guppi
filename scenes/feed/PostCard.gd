extends PanelContainer
class_name FeedPostCard

signal labeled(is_real_selected: bool, is_correct: bool)
signal collapsed
signal profile_requested(post_data: Dictionary)

const COMMENTS_OPEN_HEIGHT := 240.0
const COLLAPSE_DELAY := 1.15

@onready var _avatar_button: Button = %AvatarButton
@onready var _avatar_label: Label = %AvatarLabel
@onready var _username_button: Button = %UsernameButton
@onready var _handle_label: Label = %HandleLabel
@onready var _verified_label: Label = %VerifiedLabel
@onready var _timestamp_label: Label = %TimestampLabel
@onready var _content_label: Label = %ContentLabel
@onready var _likes_label: Label = %LikesLabel
@onready var _comments_toggle_button: Button = %CommentsToggleButton
@onready var _shares_label: Label = %SharesLabel
@onready var _view_profile_button: Button = %ViewProfileButton
@onready var _real_button: Button = %LooksRealButton
@onready var _flag_button: Button = %FlagThisButton
@onready var _feedback_overlay: PanelContainer = %FeedbackOverlay
@onready var _feedback_card: PanelContainer = %FeedbackCard
@onready var _feedback_title: Label = %FeedbackTitle
@onready var _feedback_label: Label = %FeedbackLabel
@onready var _comments_section: PanelContainer = %CommentsSection
@onready var _comments_list: VBoxContainer = %CommentsList
@onready var _media_button: Control = %MediaButton
@onready var _media_hit_button: Button = %MediaHitButton
@onready var _media_texture: TextureRect = %MediaTexture
@onready var _media_placeholder: Label = %MediaPlaceholderLabel
@onready var _media_detail: PanelContainer = %MediaDetail
@onready var _media_detail_texture: TextureRect = %MediaDetailTexture
@onready var _media_detail_texture_2: TextureRect = %MediaDetailTexture2
@onready var _media_detail_label: Label = %MediaDetailLabel
@onready var _media_count_badge: Label = %MediaCountBadge

var _post_data: Dictionary = {}
var _comments_open := false
var _is_locked := false
var _post_texture: Texture2D = null
var _post_texture_2: Texture2D = null


func _ready() -> void:
	_avatar_button.custom_minimum_size = Vector2(48, 48)
	_username_button.custom_minimum_size.y = 28
	_comments_toggle_button.custom_minimum_size = Vector2(44, 44)
	_view_profile_button.custom_minimum_size = Vector2(0, 40)
	_real_button.custom_minimum_size = Vector2(40, 40)
	_flag_button.custom_minimum_size = Vector2(40, 40)
	_media_button.custom_minimum_size.y = 132
	_style_icon_button(_real_button)
	_style_icon_button(_flag_button)
	_real_button.text = ""
	_flag_button.text = ""

	_avatar_button.pressed.connect(_request_profile)
	_username_button.pressed.connect(_request_profile)
	_view_profile_button.pressed.connect(_request_profile)
	_comments_toggle_button.pressed.connect(_toggle_comments)
	_real_button.pressed.connect(func() -> void: _submit_label(true))
	_flag_button.pressed.connect(func() -> void: _submit_label(false))
	_media_hit_button.pressed.connect(_on_media_tapped)
	%CloseMediaButton.pressed.connect(func() -> void: _media_detail.visible = false)

	_feedback_overlay.visible = false
	_media_detail.visible = false
	_set_comments_height(0.0)


func _style_icon_button(button: Button) -> void:
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("disabled", empty)
	button.add_theme_constant_override("icon_max_width", 32)


func set_post(data: Dictionary) -> void:
	_post_data = data.duplicate(true)
	_is_locked = false
	_comments_open = false
	if is_node_ready():
		_feedback_overlay.visible = false
		_media_detail.visible = false
		_real_button.disabled = false
		_flag_button.disabled = false
		_set_comments_height(0.0)
		_apply_post_data()
	else:
		ready.connect(_apply_post_data, CONNECT_ONE_SHOT)


func _apply_post_data() -> void:
	if _post_data.is_empty():
		return

	_username_button.text = str(_post_data.get("username", "Unknown"))
	_handle_label.text = str(_post_data.get("handle", "@unknown"))
	var verified := bool(_post_data.get("verified", false))
	_verified_label.visible = verified
	_verified_label.text = "✔"
	_timestamp_label.text = str(_post_data.get("timestamp", "now"))
	_content_label.text = str(_post_data.get("content", ""))
	_likes_label.text = str(_post_data.get("likes", "0"))
	_comments_toggle_button.text = str(_post_data.get("comments_count", "0"))
	_shares_label.text = str(_post_data.get("shares", "0"))
	_real_button.text = ""
	_flag_button.text = ""
	_view_profile_button.text = "Open account"

	var avatar_color := Color(0.38, 0.42, 0.52, 1.0)
	var avatar_color_hex := str(_post_data.get("avatar_color", ""))
	if not avatar_color_hex.is_empty():
		avatar_color = Color.from_string(avatar_color_hex, avatar_color)
	var avatar_style := StyleBoxFlat.new()
	avatar_style.bg_color = avatar_color
	avatar_style.corner_radius_top_left = 6
	avatar_style.corner_radius_top_right = 6
	avatar_style.corner_radius_bottom_left = 6
	avatar_style.corner_radius_bottom_right = 6
	%AvatarPanel.add_theme_stylebox_override("panel", avatar_style)
	_avatar_label.text = str(_post_data.get("username", "U")).left(1)

	_post_texture = _load_post_texture("image")
	_post_texture_2 = _load_post_texture("image_2")
	var has_image := _post_texture != null
	var has_image_2 := _post_texture_2 != null
	_media_button.visible = has_image or _expects_photo("image")
	_media_texture.texture = _post_texture
	_media_texture.visible = has_image
	_media_placeholder.visible = not has_image
	_media_placeholder.text = "Photo"
	_media_count_badge.visible = has_image_2
	_media_count_badge.text = "+1 photo"
	_media_detail_texture.texture = _post_texture
	_media_detail_texture.visible = has_image
	_media_detail_texture_2.texture = _post_texture_2
	_media_detail_texture_2.visible = has_image_2
	_media_detail_label.text = _format_media_detail(has_image)
	_rebuild_comments(_post_data.get("comments", []))


func _image_path(field: String) -> String:
	var raw = _post_data.get(field)
	if raw == null:
		return ""
	var path := str(raw).strip_edges()
	if path.is_empty() or path.to_lower() == "pending":
		return ""
	if path.begins_with("assets/"):
		return "res://" + path
	return path


func _expects_photo(field: String) -> bool:
	var raw = _post_data.get(field)
	if raw == null:
		return false
	var path := str(raw).strip_edges()
	return not path.is_empty()


func _load_post_texture(field: String) -> Texture2D:
	var path := _image_path(field)
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var loaded := load(path)
		if loaded is Texture2D:
			return loaded as Texture2D
	# Fallback for newly added PNGs that Godot hasn't imported yet.
	if not FileAccess.file_exists(path):
		push_warning("Post image missing: %s" % path)
		return null
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		push_warning("Post image empty: %s" % path)
		return null
	var img := Image.new()
	var err := img.load_png_from_buffer(bytes)
	if err != OK:
		err = img.load_jpg_from_buffer(bytes)
	if err != OK:
		err = img.load_webp_from_buffer(bytes)
	if err != OK:
		push_warning("Post image decode failed: %s" % path)
		return null
	return ImageTexture.create_from_image(img)


func _format_media_detail(has_image: bool) -> String:
	# Keep media details observational — no investigation coaching here.
	var watermark := str(_post_data.get("image_date_watermark", "")).strip_edges()
	if not has_image and watermark.is_empty():
		return "No photo attached."
	var parts: PackedStringArray = []
	if has_image:
		parts.append("Photo attached")
	else:
		parts.append("No photo attached")
	if not watermark.is_empty():
		parts.append("Date on image: %s" % watermark)
	return "\n".join(parts)


func _rebuild_comments(comments: Array) -> void:
	for child in _comments_list.get_children():
		child.queue_free()

	if comments.is_empty():
		var empty := Label.new()
		empty.text = "No comments yet."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.add_theme_color_override("font_color", Color(0.62, 0.66, 0.74))
		_comments_list.add_child(empty)
		return

	for c in comments:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var avatar := PanelContainer.new()
		avatar.custom_minimum_size = Vector2(28, 28)
		var av_style := StyleBoxFlat.new()
		av_style.bg_color = Color(0.28, 0.32, 0.4, 1)
		av_style.corner_radius_top_left = 14
		av_style.corner_radius_top_right = 14
		av_style.corner_radius_bottom_left = 14
		av_style.corner_radius_bottom_right = 14
		avatar.add_theme_stylebox_override("panel", av_style)
		var av_label := Label.new()
		av_label.text = str(c.get("username", "u")).left(1).to_upper()
		av_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		av_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		avatar.add_child(av_label)

		var text_col := VBoxContainer.new()
		text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_col.add_theme_constant_override("separation", 2)

		var author := Label.new()
		author.text = "@%s" % str(c.get("username", "user"))
		author.add_theme_font_size_override("font_size", 12)
		author.add_theme_color_override("font_color", Color(0.4, 0.45, 0.52, 1.0))

		var body := Label.new()
		body.text = str(c.get("content", ""))
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_color_override("font_color", Color(0.15, 0.17, 0.22, 1.0))

		text_col.add_child(author)
		text_col.add_child(body)
		row.add_child(avatar)
		row.add_child(text_col)
		_comments_list.add_child(row)


func _request_profile() -> void:
	if _is_locked:
		return
	profile_requested.emit(_post_data.duplicate(true))


func _toggle_comments() -> void:
	if _is_locked:
		return
	_comments_open = not _comments_open
	_animate_comments(COMMENTS_OPEN_HEIGHT if _comments_open else 0.0)
	var count_text := str(_post_data.get("comments_count", "0"))
	_comments_toggle_button.text = "%s  ▲" % count_text if _comments_open else count_text


func _animate_comments(target_height: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_comments_height, _comments_section.custom_minimum_size.y, target_height, 0.24)


func _set_comments_height(h: float) -> void:
	_comments_section.custom_minimum_size.y = maxf(h, 0.0)
	_comments_section.visible = h > 0.1


func _submit_label(selected_real: bool) -> void:
	if _is_locked:
		return
	_is_locked = true
	_real_button.disabled = true
	_flag_button.disabled = true

	var is_fake := bool(_post_data.get("is_fake", false))
	var is_correct := (selected_real and not is_fake) or ((not selected_real) and is_fake)
	var msg := str(_post_data.get("feedback_correct", "Correct.")) if is_correct else str(_post_data.get("feedback_wrong", "Wrong."))
	_show_feedback(is_correct, msg)
	labeled.emit(selected_real, is_correct)


func _show_feedback(is_correct: bool, message: String) -> void:
	# Dim the whole post lightly; keep the message card readable.
	var overlay_style := StyleBoxFlat.new()
	overlay_style.bg_color = Color(0.05, 0.07, 0.1, 0.45)
	_feedback_overlay.add_theme_stylebox_override("panel", overlay_style)

	var card_style := StyleBoxFlat.new()
	if is_correct:
		card_style.bg_color = Color(0.94, 0.98, 0.95, 1)
		card_style.border_color = Color(0.25, 0.62, 0.45, 1)
		_feedback_title.text = "Match"
		_feedback_title.add_theme_color_override("font_color", Color(0.12, 0.45, 0.3, 1))
		_feedback_label.add_theme_color_override("font_color", Color(0.18, 0.28, 0.24, 1))
	else:
		card_style.bg_color = Color(0.99, 0.95, 0.94, 1)
		card_style.border_color = Color(0.78, 0.35, 0.32, 1)
		_feedback_title.text = "Mismatch"
		_feedback_title.add_theme_color_override("font_color", Color(0.65, 0.22, 0.2, 1))
		_feedback_label.add_theme_color_override("font_color", Color(0.3, 0.2, 0.2, 1))
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(14)
	card_style.shadow_color = Color(0, 0, 0, 0.18)
	card_style.shadow_size = 8
	card_style.shadow_offset = Vector2(0, 3)
	_feedback_card.add_theme_stylebox_override("panel", card_style)

	_feedback_label.custom_minimum_size = Vector2(244, 0)
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback_label.text = message

	_feedback_overlay.modulate.a = 0.0
	_feedback_card.scale = Vector2(0.94, 0.94)
	_feedback_card.pivot_offset = _feedback_card.size * 0.5
	_feedback_overlay.visible = true
	# Pivot after one frame once size is known.
	await get_tree().process_frame
	if not is_instance_valid(_feedback_card):
		return
	_feedback_card.pivot_offset = _feedback_card.size * 0.5

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_feedback_overlay, "modulate:a", 1.0, 0.14)
	tween.tween_property(_feedback_card, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_interval(COLLAPSE_DELAY)
	tween.tween_callback(_collapse_card)


func _collapse_card() -> void:
	var start_height := size.y
	clip_contents = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.28)
	tween.tween_property(self, "custom_minimum_size:y", 0.0, 0.28).from(start_height)
	tween.set_parallel(false)
	tween.tween_callback(func() -> void:
		collapsed.emit()
		queue_free()
	)


func _on_media_tapped() -> void:
	if _is_locked:
		return
	_media_detail.visible = true


func get_post_data() -> Dictionary:
	return _post_data.duplicate(true)

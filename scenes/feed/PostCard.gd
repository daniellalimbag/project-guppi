extends PanelContainer
class_name FeedPostCard

signal labeled(is_real_selected: bool, is_correct: bool)
signal collapsed
signal profile_requested(post_data: Dictionary)

const COMMENTS_OPEN_HEIGHT := 240.0
const COLLAPSE_DELAY := 0.9

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
@onready var _feedback_label: Label = %FeedbackLabel
@onready var _comments_section: PanelContainer = %CommentsSection
@onready var _comments_list: VBoxContainer = %CommentsList
@onready var _media_button: Button = %MediaButton
@onready var _media_detail: PanelContainer = %MediaDetail
@onready var _media_detail_label: Label = %MediaDetailLabel

var _post_data: Dictionary = {}
var _comments_open := false
var _is_locked := false


func _ready() -> void:
	_avatar_button.custom_minimum_size = Vector2(48, 48)
	_username_button.custom_minimum_size.y = 28
	_comments_toggle_button.custom_minimum_size = Vector2(44, 44)
	_view_profile_button.custom_minimum_size = Vector2(0, 40)
	_real_button.custom_minimum_size.y = 44
	_flag_button.custom_minimum_size.y = 44
	_media_button.custom_minimum_size.y = 120

	_avatar_button.pressed.connect(_request_profile)
	_username_button.pressed.connect(_request_profile)
	_view_profile_button.pressed.connect(_request_profile)
	_comments_toggle_button.pressed.connect(_toggle_comments)
	_real_button.pressed.connect(func() -> void: _submit_label(true))
	_flag_button.pressed.connect(func() -> void: _submit_label(false))
	_media_button.pressed.connect(_on_media_tapped)
	%CloseMediaButton.pressed.connect(func() -> void: _media_detail.visible = false)

	_feedback_overlay.visible = false
	_media_detail.visible = false
	_set_comments_height(0.0)


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
	_likes_label.text = "♥  %s" % str(_post_data.get("likes", "0"))
	_comments_toggle_button.text = "💬  %s" % str(_post_data.get("comments_count", "0"))
	_shares_label.text = "↗  %s" % str(_post_data.get("shares", "0"))
	_view_profile_button.text = "Open account"

	var avatar_color := Color(0.38, 0.42, 0.52, 1.0)
	var avatar_color_hex := str(_post_data.get("avatar_color", ""))
	if not avatar_color_hex.is_empty():
		avatar_color = Color.from_string(avatar_color_hex, avatar_color)
	var avatar_style := StyleBoxFlat.new()
	avatar_style.bg_color = avatar_color
	avatar_style.corner_radius_top_left = 24
	avatar_style.corner_radius_top_right = 24
	avatar_style.corner_radius_bottom_left = 24
	avatar_style.corner_radius_bottom_right = 24
	%AvatarPanel.add_theme_stylebox_override("panel", avatar_style)
	_avatar_label.text = str(_post_data.get("username", "U")).left(1)

	var has_image := _post_data.get("image") != null and str(_post_data.get("image", "")).strip_edges() != ""
	_media_button.visible = true
	_media_button.text = ""
	%MediaPlaceholderLabel.text = "📷  Photo" if has_image else "📷  No photo attached"
	_media_detail_label.text = _format_media_detail(has_image)
	_rebuild_comments(_post_data.get("comments", []))


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
		author.add_theme_color_override("font_color", Color(0.72, 0.76, 0.86, 1.0))

		var body := Label.new()
		body.text = str(c.get("content", ""))
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_color_override("font_color", Color(0.86, 0.9, 0.95, 1.0))

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
	_comments_toggle_button.text = (
		"💬  %s  ▲" % str(_post_data.get("comments_count", "0"))
		if _comments_open
		else "💬  %s" % str(_post_data.get("comments_count", "0"))
	)


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
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.42, 0.22, 0.92) if is_correct else Color(0.55, 0.14, 0.14, 0.92)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	_feedback_overlay.add_theme_stylebox_override("panel", style)
	_feedback_label.text = message
	_feedback_overlay.modulate.a = 0.0
	_feedback_overlay.visible = true

	var tween := create_tween()
	tween.tween_property(_feedback_overlay, "modulate:a", 1.0, 0.12)
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

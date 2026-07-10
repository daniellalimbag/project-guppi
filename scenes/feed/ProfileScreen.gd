extends Control
class_name ProfileScreen

signal closed
signal opened(post_data: Dictionary)

@onready var _back_button: Button = %BackButton
@onready var _avatar_label: Label = %AvatarLabel
@onready var _avatar_panel: PanelContainer = %AvatarPanel
@onready var _display_name: Label = %DisplayName
@onready var _handle_label: Label = %HandleLabel
@onready var _verified_badge: Label = %VerifiedBadge
@onready var _bio_label: Label = %BioLabel
@onready var _posts_count: Label = %PostsCount
@onready var _followers_count: Label = %FollowersCount
@onready var _following_count: Label = %FollowingCount
@onready var _joined_label: Label = %JoinedLabel
@onready var _recent_list: VBoxContainer = %RecentList
@onready var _root: Control = %Root

var _post_data: Dictionary = {}


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back_button.pressed.connect(_on_back)
	_back_button.custom_minimum_size = Vector2(44, 44)


func open(post_data: Dictionary) -> void:
	_post_data = post_data.duplicate(true)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var profile: Dictionary = _post_data.get("profile", {})
	var verified := bool(_post_data.get("verified", false))

	_display_name.text = str(_post_data.get("username", "Unknown"))
	_handle_label.text = str(_post_data.get("handle", "@unknown"))
	_verified_badge.visible = verified
	_verified_badge.text = "✔"
	_bio_label.text = str(profile.get("bio", ""))

	_posts_count.text = str(profile.get("post_count", "0"))
	_followers_count.text = str(profile.get("followers", "0"))
	_following_count.text = str(profile.get("following", "0"))
	_joined_label.text = "Joined %s" % str(profile.get("joined", _post_data.get("account_age", "Unknown")))

	var avatar_color := Color(0.38, 0.42, 0.52, 1.0)
	var hex := str(_post_data.get("avatar_color", ""))
	if not hex.is_empty():
		avatar_color = Color.from_string(hex, avatar_color)
	var style := StyleBoxFlat.new()
	style.bg_color = avatar_color
	style.corner_radius_top_left = 48
	style.corner_radius_top_right = 48
	style.corner_radius_bottom_left = 48
	style.corner_radius_bottom_right = 48
	_avatar_panel.add_theme_stylebox_override("panel", style)
	_avatar_label.text = str(_post_data.get("username", "U")).left(1)

	_fill_recent_posts(profile.get("recent_posts", []))

	visible = true
	opened.emit(_post_data)
	_root.position.x = size.x if size.x > 0 else 400.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_root, "position:x", 0.0, 0.28)


func get_post_data() -> Dictionary:
	return _post_data.duplicate(true)


func is_open() -> bool:
	return visible


func _fill_recent_posts(items: Array) -> void:
	for child in _recent_list.get_children():
		child.queue_free()
	if items.is_empty():
		var empty := Label.new()
		empty.text = "No posts yet."
		empty.add_theme_color_override("font_color", Color(0.62, 0.66, 0.74))
		_recent_list.add_child(empty)
		return

	for item in items:
		var panel := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.14, 0.15, 0.19, 1)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		style.content_margin_left = 10
		style.content_margin_top = 8
		style.content_margin_right = 10
		style.content_margin_bottom = 8
		panel.add_theme_stylebox_override("panel", style)

		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6)

		var text := ""
		var likes := ""
		if typeof(item) == TYPE_DICTIONARY:
			text = str(item.get("text", item.get("content", "")))
			likes = str(item.get("likes", ""))
		else:
			text = str(item)

		var body := Label.new()
		body.text = text
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_color_override("font_color", Color(0.9, 0.92, 0.96, 1))
		col.add_child(body)

		if not likes.is_empty():
			var meta := Label.new()
			meta.text = "♥  %s" % likes
			meta.add_theme_font_size_override("font_size", 11)
			meta.add_theme_color_override("font_color", Color(0.62, 0.66, 0.74))
			col.add_child(meta)

		panel.add_child(col)
		_recent_list.add_child(panel)


func _on_back() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(_root, "position:x", size.x if size.x > 0 else 400.0, 0.22)
	tween.tween_callback(func() -> void:
		visible = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		closed.emit()
	)

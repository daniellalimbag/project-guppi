extends Control
class_name ProfileScreen

signal closed
signal opened(post_data: Dictionary)
signal exit_requested
signal menu_requested

@onready var _back_button: Button = %BackButton
@onready var _exit_button: Button = %ExitButton
@onready var _status_bar: PhoneStatusBar = %PhoneStatusBar
@onready var _avatar_label: Label = %AvatarLabel
@onready var _avatar_panel: PanelContainer = %AvatarPanel
@onready var _display_name: Label = %DisplayName
@onready var _verified_badge: Label = %VerifiedBadge
@onready var _bio_label: Label = %BioLabel
@onready var _posts_stat: Label = %PostsStat
@onready var _followers_stat: Label = %FollowersStat
@onready var _following_stat: Label = %FollowingStat
@onready var _handle_joined: Label = %HandleJoined
@onready var _recent_list: VBoxContainer = %RecentList
@onready var _root: Control = %Root

var _post_data: Dictionary = {}


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back_button.pressed.connect(_on_back)
	_exit_button.pressed.connect(func() -> void: exit_requested.emit())
	_back_button.custom_minimum_size = Vector2(72, 44)
	%MenuButton.text = ""
	%MenuButton.pressed.connect(func() -> void: menu_requested.emit())
	_style_menu_button(%MenuButton)
	_exit_button.text = "Give up"
	SettingsStore.settings_changed.connect(_apply_theme)
	_apply_theme()


func _apply_theme() -> void:
	var palette := SettingsStore.get_palette()
	var screen: Color = palette.get("screen", Color(0.97, 0.98, 0.99))
	var accent: Color = palette.get("accent", Color(0.22, 0.55, 0.58))
	var accent_dark: Color = palette.get("accent_dark", Color(0.12, 0.42, 0.45))
	$Root.add_theme_stylebox_override("panel", SettingsStore.make_flat_style(screen))
	$Root/VBox/TopBar.add_theme_stylebox_override(
		"panel", SettingsStore.make_flat_style(accent, 0, 6.0)
	)
	$Root/VBox/FooterBar.add_theme_stylebox_override(
		"panel", SettingsStore.make_flat_style(accent_dark, 0, 10.0)
	)


func open(post_data: Dictionary) -> void:
	_post_data = post_data.duplicate(true)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var profile: Dictionary = _post_data.get("profile", {})
	var verified := bool(_post_data.get("verified", false))
	var handle := str(_post_data.get("handle", "@unknown"))
	var joined := str(profile.get("joined", _post_data.get("account_age", "Unknown")))

	_display_name.text = str(_post_data.get("username", "Unknown"))
	_verified_badge.visible = verified
	_verified_badge.text = "✔"
	_bio_label.text = str(profile.get("bio", ""))
	_posts_stat.text = "%s Posts" % str(profile.get("post_count", "0"))
	_followers_stat.text = "%s Followers" % str(profile.get("followers", "0"))
	_following_stat.text = "%s Following" % str(profile.get("following", "0"))
	_handle_joined.text = "%s · joined %s" % [handle, joined]
	_status_bar.set_shift_status(GameState.shift_status_text())

	var avatar_color := Color(0.38, 0.42, 0.52, 1.0)
	var hex := str(_post_data.get("avatar_color", ""))
	if not hex.is_empty():
		avatar_color = Color.from_string(hex, avatar_color)
	var style := StyleBoxFlat.new()
	style.bg_color = avatar_color
	style.set_corner_radius_all(44)
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


func _style_menu_button(button: Button) -> void:
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_constant_override("icon_max_width", 28)


func _fill_recent_posts(items: Array) -> void:
	for child in _recent_list.get_children():
		child.queue_free()
	if items.is_empty():
		var empty := Label.new()
		empty.text = "No posts yet."
		empty.add_theme_color_override("font_color", Color(0.45, 0.5, 0.56))
		_recent_list.add_child(empty)
		return

	var username := str(_post_data.get("username", "User"))
	var handle := str(_post_data.get("handle", "@user"))
	var avatar_color := Color(0.38, 0.42, 0.52, 1.0)
	var hex := str(_post_data.get("avatar_color", ""))
	if not hex.is_empty():
		avatar_color = Color.from_string(hex, avatar_color)

	for item in items:
		var text := ""
		var likes := ""
		if typeof(item) == TYPE_DICTIONARY:
			text = str(item.get("text", item.get("content", "")))
			likes = str(item.get("likes", ""))
		else:
			text = str(item)

		var card := PanelContainer.new()
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(1, 1, 1, 1)
		card_style.border_color = Color(0.85, 0.88, 0.92, 1)
		card_style.set_border_width_all(0)
		card_style.border_width_bottom = 1
		card_style.content_margin_left = 0
		card_style.content_margin_top = 10
		card_style.content_margin_right = 0
		card_style.content_margin_bottom = 12
		card.add_theme_stylebox_override("panel", card_style)

		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 8)

		var header := HBoxContainer.new()
		header.add_theme_constant_override("separation", 8)

		var av := PanelContainer.new()
		av.custom_minimum_size = Vector2(36, 36)
		var av_style := StyleBoxFlat.new()
		av_style.bg_color = avatar_color
		av_style.set_corner_radius_all(6)
		av.add_theme_stylebox_override("panel", av_style)
		var av_label := Label.new()
		av_label.text = username.left(1)
		av_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		av_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		av_label.add_theme_color_override("font_color", Color.WHITE)
		av.add_child(av_label)

		var name_col := VBoxContainer.new()
		name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_col.add_theme_constant_override("separation", 0)
		var name_l := Label.new()
		name_l.text = "%s  %s" % [username, handle]
		name_l.add_theme_font_size_override("font_size", 12)
		name_l.add_theme_color_override("font_color", Color(0.15, 0.17, 0.22))
		name_col.add_child(name_l)

		var time_l := Label.new()
		time_l.text = "recently"
		time_l.add_theme_font_size_override("font_size", 11)
		time_l.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))

		header.add_child(av)
		header.add_child(name_col)
		header.add_child(time_l)
		col.add_child(header)

		var body := Label.new()
		body.text = text
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_color_override("font_color", Color(0.12, 0.14, 0.18))
		col.add_child(body)

		var photo := PanelContainer.new()
		photo.custom_minimum_size = Vector2(0, 120)
		var photo_style := StyleBoxFlat.new()
		photo_style.bg_color = Color(0.12, 0.13, 0.16, 1)
		photo_style.set_corner_radius_all(4)
		photo.add_theme_stylebox_override("panel", photo_style)
		var photo_label := Label.new()
		photo_label.text = "Photo"
		photo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		photo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		photo_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.35))
		photo.add_child(photo_label)
		col.add_child(photo)

		var stats := Label.new()
		stats.text = "♥  %s    💬  —    ↗  —" % (likes if not likes.is_empty() else "0")
		stats.add_theme_font_size_override("font_size", 12)
		stats.add_theme_color_override("font_color", Color(0.35, 0.4, 0.46))
		col.add_child(stats)

		card.add_child(col)
		_recent_list.add_child(card)


func _on_back() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(_root, "position:x", size.x if size.x > 0 else 400.0, 0.22)
	tween.tween_callback(func() -> void:
		visible = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		closed.emit()
	)

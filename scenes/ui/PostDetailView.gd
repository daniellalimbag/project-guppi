extends Control
class_name PostDetailView

signal closed

@onready var _back_button: Button = %BackButton
@onready var _author_label: Label = %AuthorLabel
@onready var _time_label: Label = %TimeLabel
@onready var _body_label: Label = %BodyLabel
@onready var _likes_label: Label = %LikesLabel
@onready var _comments_label: Label = %CommentsLabel
@onready var _shares_label: Label = %SharesLabel
@onready var _comments_list: VBoxContainer = %CommentsList
@onready var _avatar_label: Label = %AvatarLabel


func _ready() -> void:
	visible = false
	_back_button.pressed.connect(_close)


func open(post_data: Dictionary) -> void:
	_author_label.text = str(post_data.get("author", "@unknown"))
	_time_label.text = str(post_data.get("timestamp", ""))
	_body_label.text = str(post_data.get("body", ""))
	_likes_label.text = "♥  %s" % SocialFormat.format_count(int(post_data.get("likes", 0)))
	_comments_label.text = "💬  %s" % SocialFormat.format_count(int(post_data.get("comments", 0)))
	_shares_label.text = "↗  %s" % SocialFormat.format_count(int(post_data.get("shares", 0)))
	_avatar_label.text = str(post_data.get("avatar_text", "?")).left(2)
	_populate_comments(post_data.get("comment_thread", []))
	visible = true


func _populate_comments(comments: Array) -> void:
	for child in _comments_list.get_children():
		child.queue_free()

	if comments.is_empty():
		var empty := Label.new()
		empty.text = "No comments yet."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.add_theme_color_override("font_color", Color(0.55, 0.58, 0.65))
		_comments_list.add_child(empty)
		return

	for entry in comments:
		var panel := PanelContainer.new()
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_bottom", 8)
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)

		var author := Label.new()
		author.text = str(entry.get("author", "user"))
		author.add_theme_font_size_override("font_size", 12)
		author.add_theme_color_override("font_color", Color(0.72, 0.76, 0.86))

		var body := Label.new()
		body.text = str(entry.get("text", ""))
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_color_override("font_color", Color(0.86, 0.88, 0.92))

		vbox.add_child(author)
		vbox.add_child(body)
		margin.add_child(vbox)
		panel.add_child(margin)
		_comments_list.add_child(panel)


func _close() -> void:
	visible = false
	closed.emit()

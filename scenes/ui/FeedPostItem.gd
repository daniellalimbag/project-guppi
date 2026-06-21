extends PanelContainer
class_name FeedPostItem

signal profile_requested(post_data: Dictionary)
signal post_open_requested(post_data: Dictionary)
signal verdict_committed(post_data: Dictionary, verdict: PostVerdict.Type)

@onready var _avatar_button: Button = %AvatarButton
@onready var _avatar_label: Label = %AvatarLabel
@onready var _author_label: Label = %AuthorLabel
@onready var _time_label: Label = %TimeLabel
@onready var _body_button: Button = %BodyButton
@onready var _body_label: Label = %BodyLabel
@onready var _likes_label: Label = %LikesLabel
@onready var _comments_label: Label = %CommentsLabel
@onready var _shares_label: Label = %SharesLabel
@onready var _credible_button: Button = %CredibleButton
@onready var _harmful_button: Button = %HarmfulButton

var _post_data: Dictionary = {}
var _pending_post_data: Dictionary = {}
var _resolved: bool = false


func _ready() -> void:
	_avatar_button.pressed.connect(_on_profile_pressed)
	_body_button.pressed.connect(_on_post_pressed)
	_credible_button.pressed.connect(_on_credible_pressed)
	_harmful_button.pressed.connect(_on_harmful_pressed)

	_credible_button.custom_minimum_size.y = UIConstants.VERDICT_BUTTON_MIN.y
	_harmful_button.custom_minimum_size.y = UIConstants.VERDICT_BUTTON_MIN.y
	_avatar_button.custom_minimum_size = Vector2(40, 40)

	if not _pending_post_data.is_empty():
		_apply_post(_pending_post_data)


func set_post(data: Dictionary) -> void:
	_pending_post_data = data.duplicate(true)
	if is_node_ready():
		_apply_post(_pending_post_data)


func _apply_post(data: Dictionary) -> void:
	_post_data = data.duplicate(true)
	_resolved = false
	_author_label.text = str(data.get("author", "@unknown"))
	_time_label.text = str(data.get("timestamp", "2h"))
	_body_label.text = str(data.get("body", ""))
	_likes_label.text = "♥  %s" % SocialFormat.format_count(int(data.get("likes", 0)))
	_comments_label.text = "💬  %s" % SocialFormat.format_count(int(data.get("comments", 0)))
	_shares_label.text = "↗  %s" % SocialFormat.format_count(int(data.get("shares", 0)))
	_avatar_label.text = str(data.get("avatar_text", "?")).left(2)
	_set_resolved(false)


func get_post_id() -> String:
	return str(_post_data.get("id", ""))


func _set_resolved(resolved: bool) -> void:
	_resolved = resolved
	modulate = Color(0.55, 0.58, 0.62, 1) if resolved else Color.WHITE
	_credible_button.disabled = resolved
	_harmful_button.disabled = resolved
	_body_button.disabled = resolved
	_avatar_button.disabled = resolved


func _on_profile_pressed() -> void:
	if _resolved:
		return
	profile_requested.emit(_post_data)


func _on_post_pressed() -> void:
	if _resolved:
		return
	post_open_requested.emit(_post_data)


func _on_credible_pressed() -> void:
	_submit_verdict(PostVerdict.Type.CREDIBLE)


func _on_harmful_pressed() -> void:
	_submit_verdict(PostVerdict.Type.HARMFUL)


func _submit_verdict(verdict: PostVerdict.Type) -> void:
	if _resolved:
		return
	_set_resolved(true)
	verdict_committed.emit(_post_data, verdict)

extends Control
class_name ProfileView

signal closed

@onready var _back_button: Button = %BackButton
@onready var _avatar_label: Label = %AvatarLabel
@onready var _username_label: Label = %UsernameLabel
@onready var _bio_label: Label = %BioLabel
@onready var _followers_label: Label = %FollowersLabel
@onready var _account_age_label: Label = %AccountAgeLabel
@onready var _verified_label: Label = %VerifiedLabel
@onready var _engagement_label: Label = %EngagementLabel


func _ready() -> void:
	visible = false
	_back_button.pressed.connect(_close)


func open(post_data: Dictionary) -> void:
	var profile: Dictionary = post_data.get("profile", {})
	_avatar_label.text = str(post_data.get("avatar_text", "?")).left(2)
	_username_label.text = str(post_data.get("author", "@unknown"))
	_bio_label.text = str(profile.get("bio", "No bio provided."))
	_followers_label.text = "Followers: %s" % SocialFormat.format_count(int(profile.get("followers", 0)))
	_account_age_label.text = "Account age: %s" % str(profile.get("account_age", "Unknown"))
	_verified_label.text = "Verified: %s" % ("Yes" if profile.get("verified", false) else "No")
	_engagement_label.text = str(profile.get("engagement_note", ""))
	visible = true


func _close() -> void:
	visible = false
	closed.emit()

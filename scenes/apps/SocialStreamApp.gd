extends AppScreenBase

func _ready() -> void:
	app_id = AppId.Screen.SOCIAL_STREAM
	title = "Social Media"
	header_color = Color(0.16, 0.14, 0.24, 1)
	accent_color = Color(0.72, 0.55, 1, 1)
	super._ready()
	%SubtitleLabel.text = "Your moderation queue — verify posts and label them Real, Misleading, Scam, or Needs Review."

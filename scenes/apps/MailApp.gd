extends AppScreenBase

func _ready() -> void:
	app_id = AppId.Screen.MAIL
	title = "Mail"
	header_color = Color(0.14, 0.17, 0.24, 1)
	accent_color = Color(0.45, 0.72, 1, 1)
	super._ready()
	%SubtitleLabel.text = "Inbox will list work mail, phishing attempts, and promos mixed together."

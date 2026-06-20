extends AppScreenBase

func _ready() -> void:
	app_id = AppId.Screen.MESSAGES
	title = "Messages"
	header_color = Color(0.12, 0.2, 0.16, 1)
	accent_color = Color(0.35, 0.92, 0.62, 1)
	super._ready()
	%SubtitleLabel.text = "GUPPI, coworkers, and scam DMs will appear here. The ◆ GUPPI shortcut opens this app."

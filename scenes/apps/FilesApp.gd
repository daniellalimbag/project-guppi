extends AppScreenBase

func _ready() -> void:
	app_id = AppId.Screen.FILES
	title = "Files"
	header_color = Color(0.2, 0.16, 0.12, 1)
	accent_color = Color(1, 0.72, 0.28, 1)
	super._ready()
	%SubtitleLabel.text = "GUPPI model cards and daily performance reports will live here."

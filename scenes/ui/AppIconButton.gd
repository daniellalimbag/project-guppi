extends MarginContainer
class_name AppIconButton

signal icon_pressed(app_id: AppId.Screen)

@export var app_id: AppId.Screen = AppId.Screen.MAIL
@export var icon_text: String = "?"
@export var icon_color: Color = Color(0.35, 0.55, 0.95, 1)
@export var app_name: String = "App"
@export var badge_count: int = 0

@onready var _icon_label: Label = %IconLabel
@onready var _name_label: Label = %NameLabel
@onready var _badge: PanelContainer = %Badge
@onready var _badge_label: Label = %BadgeLabel
@onready var _tap_button: Button = %TapButton


func _ready() -> void:
	custom_minimum_size = UIConstants.LAUNCHER_CELL_MIN_SIZE
	_apply_config()
	_tap_button.pressed.connect(_on_tap)


func configure(config: Dictionary) -> void:
	if config.has("app_id"):
		app_id = config["app_id"]
	if config.has("icon_text"):
		icon_text = config["icon_text"]
	if config.has("icon_color"):
		icon_color = config["icon_color"]
	if config.has("app_name"):
		app_name = config["app_name"]
	if config.has("badge_count"):
		badge_count = config["badge_count"]
	if is_node_ready():
		_apply_config()


func _apply_config() -> void:
	_icon_label.text = icon_text
	_name_label.text = app_name
	%IconPanel.add_theme_stylebox_override("panel", _make_icon_style())
	_badge.visible = badge_count > 0
	_badge_label.text = str(mini(badge_count, 99))


func _make_icon_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = icon_color
	style.corner_radius_top_left = UIConstants.LAUNCHER_ICON_CORNER_RADIUS
	style.corner_radius_top_right = UIConstants.LAUNCHER_ICON_CORNER_RADIUS
	style.corner_radius_bottom_right = UIConstants.LAUNCHER_ICON_CORNER_RADIUS
	style.corner_radius_bottom_left = UIConstants.LAUNCHER_ICON_CORNER_RADIUS
	return style


func _on_tap() -> void:
	icon_pressed.emit(app_id)

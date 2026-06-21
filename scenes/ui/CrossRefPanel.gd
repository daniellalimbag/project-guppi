extends Control
class_name CrossRefPanel

signal closed

@onready var _back_button: Button = %BackButton
@onready var _query_label: Label = %QueryLabel
@onready var _results_list: VBoxContainer = %ResultsList


func _ready() -> void:
	visible = false
	_back_button.pressed.connect(_close)


func show_results(query: String, results: Array) -> void:
	_query_label.text = 'Results for "%s"' % query
	for child in _results_list.get_children():
		child.queue_free()

	if results.is_empty():
		var empty := Label.new()
		empty.text = "No cross-reference matches found. Try keywords from the posts in your feed."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.add_theme_color_override("font_color", Color(0.62, 0.65, 0.72))
		_results_list.add_child(empty)
	else:
		for result in results:
			var panel := PanelContainer.new()
			var margin := MarginContainer.new()
			margin.add_theme_constant_override("margin_left", 10)
			margin.add_theme_constant_override("margin_top", 8)
			margin.add_theme_constant_override("margin_right", 10)
			margin.add_theme_constant_override("margin_bottom", 8)
			var vbox := VBoxContainer.new()
			vbox.add_theme_constant_override("separation", 4)

			var title := Label.new()
			title.text = str(result.get("title", "Match"))
			title.add_theme_font_size_override("font_size", 13)
			title.add_theme_color_override("font_color", Color(0.78, 0.82, 0.92))

			var body := Label.new()
			body.text = str(result.get("body", ""))
			body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			body.add_theme_color_override("font_color", Color(0.68, 0.71, 0.78))

			vbox.add_child(title)
			vbox.add_child(body)
			margin.add_child(vbox)
			panel.add_child(margin)
			_results_list.add_child(panel)

	visible = true


func _close() -> void:
	visible = false
	closed.emit()

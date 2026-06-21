extends Control
class_name PostCard

signal verdict_committed(verdict: PostVerdict.Type, evidence_checked: int)
signal swipe_skipped(evidence_checked: int)

const SWIPE_DISTANCE_THRESHOLD := 96.0
const DRAG_START_THRESHOLD := 8.0
const MAX_DRAG_ROTATION := 0.12

@export var swipe_enabled: bool = true

@onready var _card_drag_host: Control = %CardDragHost
@onready var _card_panel: PanelContainer = %CardPanel
@onready var _author_button: Button = %AuthorButton
@onready var _avatar_label: Label = %AvatarLabel
@onready var _author_label: Label = %AuthorLabel
@onready var _body_label: Label = %BodyLabel
@onready var _profile_btn: Button = %ProfileBtn
@onready var _comments_btn: Button = %CommentsBtn
@onready var _cross_ref_btn: Button = %CrossRefBtn
@onready var _verdict_buttons: Array[Button] = [
	%VerdictReal,
	%VerdictMisleading,
	%VerdictScam,
	%VerdictNeedsReview,
]
@onready var _evidence_popup: EvidencePopup = %EvidencePopup
@onready var _swipe_hint: Label = %SwipeHint

var _post_id: String = ""
var _evidence_checked: Dictionary = {}
var _pointer_down: bool = false
var _dragging: bool = false
var _drag_start: Vector2 = Vector2.ZERO
var _drag_offset: Vector2 = Vector2.ZERO
var _input_locked: bool = false


func _ready() -> void:
	_card_panel.gui_input.connect(_on_card_gui_input)
	_card_drag_host.resized.connect(_update_drag_pivot)
	_update_drag_pivot()
	_author_button.pressed.connect(_open_evidence.bind(PostEvidenceType.Type.PROFILE))
	_profile_btn.pressed.connect(_open_evidence.bind(PostEvidenceType.Type.PROFILE))
	_comments_btn.pressed.connect(_open_evidence.bind(PostEvidenceType.Type.COMMENTS))
	_cross_ref_btn.pressed.connect(_open_evidence.bind(PostEvidenceType.Type.CROSS_REFERENCE))

	for index in _verdict_buttons.size():
		_verdict_buttons[index].custom_minimum_size.y = UIConstants.VERDICT_BUTTON_MIN.y
		_verdict_buttons[index].pressed.connect(_on_verdict_pressed.bind(index))

	_set_evidence_button_sizes()
	reset_card()


func set_post(data: Dictionary) -> void:
	_post_id = str(data.get("id", ""))
	_author_label.text = str(data.get("author", "@unknown"))
	_body_label.text = str(data.get("body", ""))
	_avatar_label.text = str(data.get("avatar_text", "?")).left(2)
	reset_card()


func reset_card() -> void:
	_evidence_checked.clear()
	_drag_offset = Vector2.ZERO
	_pointer_down = false
	_dragging = false
	_input_locked = false
	_profile_btn.text = PostEvidenceType.LABELS[PostEvidenceType.Type.PROFILE]
	_comments_btn.text = PostEvidenceType.LABELS[PostEvidenceType.Type.COMMENTS]
	_cross_ref_btn.text = PostEvidenceType.LABELS[PostEvidenceType.Type.CROSS_REFERENCE]
	_apply_drag_transform()
	_set_card_interactive(true)
	GameState.reset_evidence_for_post()


func _update_drag_pivot() -> void:
	_card_drag_host.pivot_offset = _card_drag_host.size * 0.5


func get_evidence_checked_count() -> int:
	return _evidence_checked.size()


func _set_evidence_button_sizes() -> void:
	var min_size := UIConstants.EVIDENCE_BUTTON_MIN
	_profile_btn.custom_minimum_size = min_size
	_comments_btn.custom_minimum_size = min_size
	_cross_ref_btn.custom_minimum_size = min_size
	_author_button.custom_minimum_size = Vector2(0, min_size.y)


func _set_card_interactive(enabled: bool) -> void:
	_card_panel.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	for button in _verdict_buttons:
		button.disabled = not enabled
	_author_button.disabled = not enabled
	_profile_btn.disabled = not enabled
	_comments_btn.disabled = not enabled
	_cross_ref_btn.disabled = not enabled


func _open_evidence(evidence_type: PostEvidenceType.Type) -> void:
	if _input_locked:
		return
	_evidence_popup.open(
		PostEvidenceType.PLACEHOLDER_TITLES[evidence_type],
		PostEvidenceType.PLACEHOLDER_BODIES[evidence_type],
	)
	if not _evidence_checked.has(evidence_type):
		_evidence_checked[evidence_type] = true
		GameState.register_evidence_checked()
	_mark_evidence_checked(evidence_type)


func _mark_evidence_checked(evidence_type: PostEvidenceType.Type) -> void:
	match evidence_type:
		PostEvidenceType.Type.PROFILE:
			_profile_btn.text = "Profile ✓"
		PostEvidenceType.Type.COMMENTS:
			_comments_btn.text = "Comments ✓"
		PostEvidenceType.Type.CROSS_REFERENCE:
			_cross_ref_btn.text = "Cross-Ref ✓"


func _on_verdict_pressed(verdict_index: int) -> void:
	if _input_locked:
		return
	_commit_verdict(verdict_index as PostVerdict.Type, false)


func _commit_verdict(verdict: PostVerdict.Type, from_swipe: bool) -> void:
	_input_locked = true
	_set_card_interactive(false)
	if from_swipe:
		swipe_skipped.emit(get_evidence_checked_count())
	else:
		verdict_committed.emit(verdict, get_evidence_checked_count())
	_animate_card_offscreen(_drag_offset.normalized() if _drag_offset.length() > 1.0 else Vector2.RIGHT)


func _on_card_gui_input(event: InputEvent) -> void:
	if _input_locked or not swipe_enabled or _evidence_popup.visible:
		return

	if _is_press_event(event):
		_pointer_down = true
		_dragging = false
		_drag_start = _event_position(event)
		accept_event()
	elif _is_release_event(event):
		if _dragging:
			_finish_drag()
		_pointer_down = false
		_dragging = false
		accept_event()
	elif _pointer_down and _is_motion_event(event):
		var current_pos := _event_position(event)
		var delta := current_pos - _drag_start
		if not _dragging and delta.length() >= DRAG_START_THRESHOLD:
			_dragging = true
		if _dragging:
			_drag_offset = delta
			_apply_drag_transform()
			accept_event()


func _finish_drag() -> void:
	if _drag_offset.length() >= SWIPE_DISTANCE_THRESHOLD:
		_commit_verdict(PostVerdict.Type.REAL, true)
	else:
		_snap_back()


func _snap_back() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_drag_offset, _drag_offset, Vector2.ZERO, 0.2)
	tween.tween_callback(_apply_drag_transform)


func _set_drag_offset(value: Vector2) -> void:
	_drag_offset = value
	_apply_drag_transform()


func _apply_drag_transform() -> void:
	_card_drag_host.position = _drag_offset
	var width := maxf(_card_drag_host.size.x, 1.0)
	var rotation_factor := clampf(_drag_offset.x / width, -1.0, 1.0)
	_card_drag_host.rotation = rotation_factor * MAX_DRAG_ROTATION
	_swipe_hint.modulate.a = 1.0 - clampf(_drag_offset.length() / SWIPE_DISTANCE_THRESHOLD, 0.0, 0.85)


func _animate_card_offscreen(direction: Vector2) -> void:
	var target := direction.normalized() * 520.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_method(_set_drag_offset, _drag_offset, target, 0.22)


func _is_press_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	if event is InputEventScreenTouch:
		return event.pressed
	return false


func _is_release_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.button_index == MOUSE_BUTTON_LEFT and not event.pressed
	if event is InputEventScreenTouch:
		return not event.pressed
	return false


func _is_motion_event(event: InputEvent) -> bool:
	return event is InputEventMouseMotion or event is InputEventScreenDrag


func _event_position(event: InputEvent) -> Vector2:
	return _card_panel.make_input_local(event).position

extends AppScreenBase

const DEMO_POSTS: Array[Dictionary] = [
	{
		"id": "demo_1",
		"author": "@city_news_alert",
		"avatar_text": "CN",
		"timestamp": "1h",
		"body": "BREAKING: City announces free transit for all residents starting Monday. Share before they delete this!",
		"likes": 4821,
		"comments": 312,
		"shares": 891,
		"profile": {
			"bio": "Unofficial city updates and alerts.",
			"followers": 12,
			"account_age": "3 days",
			"verified": false,
			"engagement_note": "Red flag: 4.8K likes with only 12 followers — unusual engagement ratio.",
		},
		"comment_thread": [
			{"author": "@commuter_jen", "text": "Is this on the official city website? I cannot find it."},
			{"author": "@transit_fan", "text": "Shared!!! Everyone needs to see this!!!"},
			{"author": "@factcheck_local", "text": "No record of this policy on gov.ca — likely false."},
		],
		"cross_ref": {
			"free transit": {
				"title": "No official transit announcement",
				"body": "The city transit authority has no press release about free service. This claim appears only on social reposts.",
			},
			"city transit": {
				"title": "Older unrelated image",
				"body": "The attached graphic first appeared in a 2019 festival promotion post.",
			},
		},
	},
	{
		"id": "demo_2",
		"author": "@aegis_hr",
		"avatar_text": "HR",
		"timestamp": "3h",
		"body": "Reminder: Submit your timesheet by 5 PM today through the official Aegis portal.",
		"likes": 24,
		"comments": 2,
		"shares": 0,
		"profile": {
			"bio": "Official HR communications for Aegis employees.",
			"followers": 1840,
			"account_age": "2 years",
			"verified": true,
			"engagement_note": "Verified company account with normal engagement for an internal announcement.",
		},
		"comment_thread": [
			{"author": "@dev_ana", "text": "Thanks for the reminder!"},
			{"author": "@ops_mike", "text": "Link works fine for me."},
		],
		"cross_ref": {
			"timesheet": {
				"title": "Matches internal policy email",
				"body": "Same deadline appears in this week's official Aegis HR bulletin.",
			},
			"aegis portal": {
				"title": "Legitimate domain",
				"body": "Portal URL uses the verified aegis.com domain, not a lookalike.",
			},
		},
	},
	{
		"id": "demo_3",
		"author": "@wellness_daily",
		"avatar_text": "WD",
		"timestamp": "5h",
		"body": "Doctors HATE this one trick — miracle supplement cures everything in 48 hours!!!",
		"likes": 9200,
		"comments": 540,
		"shares": 2100,
		"profile": {
			"bio": "Daily wellness tips and natural cures.",
			"followers": 890,
			"account_age": "6 months",
			"verified": false,
			"engagement_note": "High share count with sensational language — common misinformation pattern.",
		},
		"comment_thread": [
			{"author": "@health_teacher", "text": "Please check WHO guidance before sharing medical claims."},
			{"author": "@bot_48291", "text": "This changed my life!! Link in bio!!"},
			{"author": "@bot_48292", "text": "This changed my life!! Link in bio!!"},
			{"author": "@skeptic_sam", "text": "Copy-paste replies and no sources — suspicious thread."},
		],
		"cross_ref": {
			"miracle supplement": {
				"title": "Debunked by health agencies",
				"body": "No clinical evidence supports '48 hour cure' claims. Similar posts flagged by fact-checkers last month.",
			},
			"doctors hate": {
				"title": "Known scam phrase pattern",
				"body": "This headline format is commonly used in misleading wellness ads and phishing funnels.",
			},
		},
	},
]

var _posts: Array[Dictionary] = []
var _post_evidence: Dictionary = {}
var _active_post_id: String = ""

var _feed_scroll: ScrollContainer
var _feed_vbox: VBoxContainer
var _search_field: LineEdit
var _post_detail: PostDetailView
var _profile_view: ProfileView
var _cross_ref_panel: CrossRefPanel
var _status_label: Label


func _ready() -> void:
	app_id = AppId.Screen.SOCIAL_STREAM
	title = "SocialStream"
	header_color = Color(0.16, 0.14, 0.24, 1)
	accent_color = Color(0.72, 0.55, 1, 1)
	super._ready()
	_posts = DEMO_POSTS.duplicate(true)
	_build_ui()


func _build_ui() -> void:
	$AppVBox/ContentScroll.visible = false
	$AppVBox.add_theme_constant_override("separation", 0)

	var search_row := _build_search_row()
	$AppVBox.add_child(search_row)
	$AppVBox.move_child(search_row, 1)

	_feed_scroll = ScrollContainer.new()
	_feed_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_feed_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_feed_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	$AppVBox.add_child(_feed_scroll)
	$AppVBox.move_child(_feed_scroll, 2)

	var feed_margin := MarginContainer.new()
	feed_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feed_margin.add_theme_constant_override("margin_bottom", 8)
	_feed_scroll.add_child(feed_margin)

	_feed_vbox = VBoxContainer.new()
	_feed_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_feed_vbox.add_theme_constant_override("separation", 0)
	feed_margin.add_child(_feed_vbox)

	_status_label = Label.new()
	_status_label.visible = false
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_color_override("font_color", Color(0.55, 0.82, 0.62))
	_status_label.add_theme_constant_override("margin_left", 12)
	_status_label.add_theme_constant_override("margin_right", 12)
	$AppVBox.add_child(_status_label)
	$AppVBox.move_child(_status_label, 3)

	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 20
	add_child(overlay)

	_post_detail = preload("res://scenes/ui/PostDetailView.tscn").instantiate()
	_post_detail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_post_detail.closed.connect(_on_detail_closed)
	overlay.add_child(_post_detail)

	_profile_view = preload("res://scenes/ui/ProfileView.tscn").instantiate()
	_profile_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_profile_view.closed.connect(_on_profile_closed)
	overlay.add_child(_profile_view)

	_cross_ref_panel = preload("res://scenes/ui/CrossRefPanel.tscn").instantiate()
	_cross_ref_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cross_ref_panel.closed.connect(_on_cross_ref_closed)
	overlay.add_child(_cross_ref_panel)

	_populate_feed()


func _build_search_row() -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 4)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	_search_field = LineEdit.new()
	_search_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search_field.custom_minimum_size.y = 44
	_search_field.placeholder_text = "Search to cross-reference claims..."
	_search_field.text_submitted.connect(_on_search_submitted)

	var search_button := Button.new()
	search_button.custom_minimum_size = Vector2(72, 44)
	search_button.text = "Search"
	search_button.pressed.connect(_on_search_pressed)

	row.add_child(_search_field)
	row.add_child(search_button)
	margin.add_child(row)
	return margin


func _populate_feed() -> void:
	for child in _feed_vbox.get_children():
		child.queue_free()

	for post in _posts:
		var item: FeedPostItem = preload("res://scenes/ui/FeedPostItem.tscn").instantiate()
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item.profile_requested.connect(_on_profile_requested)
		item.post_open_requested.connect(_on_post_open_requested)
		item.verdict_committed.connect(_on_verdict_committed)
		_feed_vbox.add_child(item)
		item.set_post(post)
		_ensure_evidence_entry(str(post.get("id", "")))


func _ensure_evidence_entry(post_id: String) -> void:
	if post_id.is_empty():
		return
	if not _post_evidence.has(post_id):
		_post_evidence[post_id] = {
			PostEvidenceType.Type.PROFILE: false,
			PostEvidenceType.Type.COMMENTS: false,
			PostEvidenceType.Type.CROSS_REFERENCE: false,
		}


func _mark_evidence(post_id: String, evidence_type: PostEvidenceType.Type) -> void:
	_ensure_evidence_entry(post_id)
	var entry: Dictionary = _post_evidence[post_id]
	if entry.get(evidence_type, false):
		return
	entry[evidence_type] = true


func _count_evidence(post_id: String) -> int:
	if not _post_evidence.has(post_id):
		return 0
	var total := 0
	for checked in _post_evidence[post_id].values():
		if checked:
			total += 1
	return total


func _find_post(post_id: String) -> Dictionary:
	for post in _posts:
		if str(post.get("id", "")) == post_id:
			return post
	return {}


func _on_profile_requested(post_data: Dictionary) -> void:
	var post_id := str(post_data.get("id", ""))
	_active_post_id = post_id
	_mark_evidence(post_id, PostEvidenceType.Type.PROFILE)
	_profile_view.open(post_data)


func _on_post_open_requested(post_data: Dictionary) -> void:
	var post_id := str(post_data.get("id", ""))
	_active_post_id = post_id
	_mark_evidence(post_id, PostEvidenceType.Type.COMMENTS)
	_post_detail.open(post_data)


func _on_verdict_committed(post_data: Dictionary, verdict: PostVerdict.Type) -> void:
	var post_id := str(post_data.get("id", ""))
	var label := PostVerdict.LABELS[verdict]
	var evidence := _count_evidence(post_id)
	GameState.reset_evidence_for_post()
	for _i in evidence:
		GameState.register_evidence_checked()
	_show_status("Marked %s as %s (%d evidence checked)" % [post_data.get("author", "post"), label, evidence])


func _on_search_pressed() -> void:
	_run_search(_search_field.text.strip_edges())


func _on_search_submitted(query: String) -> void:
	_run_search(query.strip_edges())


func _run_search(query: String) -> void:
	if query.is_empty():
		_show_status("Enter a keyword or phrase to cross-reference.")
		return

	var results: Array = []
	for post in _posts:
		var cross_ref: Dictionary = post.get("cross_ref", {})
		for key in cross_ref.keys():
			if query.to_lower() in str(key).to_lower() or query.to_lower() in str(post.get("body", "")).to_lower():
				var hit: Dictionary = cross_ref[key]
				results.append({
					"title": "%s — %s" % [post.get("author", "post"), hit.get("title", "Match")],
					"body": hit.get("body", ""),
				})
				_mark_evidence(str(post.get("id", "")), PostEvidenceType.Type.CROSS_REFERENCE)

	if results.is_empty():
		for post in _posts:
			if query.to_lower() in str(post.get("body", "")).to_lower():
				results.append({
					"title": "Mention in %s" % post.get("author", "post"),
					"body": "This phrase appears in the post: \"%s\"" % str(post.get("body", "")).left(120),
				})
				_mark_evidence(str(post.get("id", "")), PostEvidenceType.Type.CROSS_REFERENCE)

	_cross_ref_panel.show_results(query, results)


func _show_status(message: String) -> void:
	_status_label.text = message
	_status_label.visible = true


func _on_detail_closed() -> void:
	_active_post_id = ""


func _on_profile_closed() -> void:
	_active_post_id = ""


func _on_cross_ref_closed() -> void:
	pass

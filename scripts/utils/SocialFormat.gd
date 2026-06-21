class_name SocialFormat
extends RefCounted

static func format_count(value: int) -> String:
	if value >= 1_000_000:
		return "%.1fM" % (value / 1_000_000.0)
	if value >= 10_000:
		return "%.0fK" % (value / 1_000.0)
	if value >= 1_000:
		return "%.1fK" % (value / 1_000.0)
	return str(value)

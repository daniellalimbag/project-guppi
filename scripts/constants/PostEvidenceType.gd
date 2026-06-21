class_name PostEvidenceType
extends RefCounted

enum Type {
	PROFILE,
	COMMENTS,
	CROSS_REFERENCE,
}

const LABELS: Array[String] = [
	"Profile",
	"Comments",
	"Cross-Ref",
]

const PLACEHOLDER_TITLES: Array[String] = [
	"Account Profile",
	"Comment Thread",
	"Cross-Reference",
]

const PLACEHOLDER_BODIES: Array[String] = [
	"Account created 3 days ago. No verified badge. 12 followers, 4,800 likes on this post.",
	"Mixed replies — one user links an official source; several copy-paste bot-style comments.",
	"Image first appeared in a 2019 unrelated post. Claimed event date does not match post timestamp.",
]

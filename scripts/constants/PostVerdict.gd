class_name PostVerdict
extends RefCounted

enum Type {
	CREDIBLE,
	HARMFUL,
}

const LABELS: Array[String] = [
	"Credible",
	"Harmful",
]

const BUTTON_LABELS: Array[String] = [
	"✓  Credible",
	"⚠  Harmful",
]

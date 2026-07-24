#!/usr/bin/env python3
"""Convert HACKATHON MASTERSHEET CSVs into game post JSON pools."""

from __future__ import annotations

import csv
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
POSTS_DIR = DATA / "posts"

FAKE_CSV = DATA / "HACKATHON MASTERSHEET - FAKE POSTS.csv"
LEGIT_CSV = DATA / "HACKATHON MASTERSHEET - LEGIT POSTS.csv"

AVATAR_COLORS = [
	"#E91E63",
	"#3F51B5",
	"#009688",
	"#FF5722",
	"#607D8B",
	"#8BC34A",
	"#9C27B0",
	"#795548",
	"#00BCD4",
	"#FF9800",
]


def slug_handle(username: str) -> str:
	slug = re.sub(r"[^a-zA-Z0-9_]+", "", username.replace(" ", "_"))
	slug = slug.strip("_") or "user"
	return f"@{slug.lower()[:24]}"


def avatar_color(username: str) -> str:
	digest = hashlib.md5(username.encode("utf-8")).hexdigest()
	return AVATAR_COLORS[int(digest[:8], 16) % len(AVATAR_COLORS)]


def looks_like_org(username: str) -> bool:
	markers = (
		"news",
		"times",
		"bulletin",
		"watch",
		"bureau",
		"authority",
		"network",
		"alert",
		"aviation",
		"institute",
		"star",
		"curious",
		"relief",
	)
	low = username.lower()
	return any(m in low for m in markers)


def has_photo_attachment(attachment: str) -> bool:
	low = attachment.lower()
	return any(token in low for token in ("photo", "photos", "graphic", "map", "qr", "pubmat", "art"))


def format_timestamp(date_raw: str, day: str) -> str:
	date_raw = (date_raw or "").strip()
	if date_raw:
		return date_raw
	return f"Day {day}" if day else "recently"


def insight_from_type(fake_type: str) -> str:
	fake_type = (fake_type or "").strip()
	if not fake_type:
		return "Mixed signals"
	primary = fake_type.split(",")[0].strip().title()
	return primary


def build_feedback(is_fake: bool, fake_type: str, evidence: str, attachment: str) -> tuple[str, str, str]:
	fake_type = (fake_type or "").strip()
	evidence = (evidence or "").strip()
	attachment = (attachment or "").strip()

	if is_fake:
		why = evidence or fake_type or "Suspicious claim or presentation."
		correct = why
		wrong = f"Should escalate — {why}"
		hint = {
			"AI GENERATED POST": "Something about that image feels off…",
			"MISINFORMATION": "I'd double-check whether this matches other reports.",
			"SCAMS": "Donation asks with thin proof always make me pause.",
		}.get(fake_type.split(",")[0].strip().upper(), "I'd peek at the account before deciding.")
		return correct, wrong, hint

	correct = "Looks consistent with verified reporting or community updates."
	wrong = "That one looked legitimate — no clear escalation signal."
	hint = "Profile and tone look pretty ordinary to me."
	if attachment:
		hint = "Photo and write-up seem to line up."
	return correct, wrong, hint


def build_profile(username: str, is_fake: bool, fake_type: str, day: str) -> dict:
	verified = (not is_fake) and looks_like_org(username)
	if is_fake:
		joined = "2 weeks ago" if "SCAM" in (fake_type or "").upper() else "1 month ago"
		followers = "12.4K" if "AI" in (fake_type or "").upper() else "3.1K"
		bot = "54" if "SCAM" in (fake_type or "").upper() else "31"
		bio = "Just posting what they won't tell you."
		posts = 8
		following = "420"
	else:
		joined = "4 years ago" if looks_like_org(username) else "1 year ago"
		followers = "128K" if looks_like_org(username) else "2.4K"
		bot = "4"
		bio = "Local updates from the reef." if looks_like_org(username) else "Sharing what I see around the reef."
		posts = 640 if looks_like_org(username) else 86
		following = "210" if looks_like_org(username) else "340"

	return {
		"bio": bio,
		"post_count": posts,
		"followers": followers,
		"following": following,
		"joined": joined,
		"engagement_ratio": "Unknown",
		"bot_followers_pct": bot,
		"follower_quality_note": "",
		"red_flags": [],
		"recent_posts": [
			{"text": "Another update from around the city.", "likes": "120"},
			{"text": "Stay safe out there.", "likes": "84"},
		],
	}


def default_comments(is_fake: bool) -> list[dict]:
	if is_fake:
		return [
			{"username": "tide_watcher", "content": "Source? This doesn't match other reports.", "is_bot": False},
			{"username": "reefuser8821", "content": "Sharing everywhere!!!", "is_bot": True},
		]
	return [
		{"username": "coral_neighbor", "content": "Thanks for the update.", "is_bot": False},
		{"username": "fin_local", "content": "Stay safe everyone.", "is_bot": False},
	]


def row_to_post(row: dict, *, is_fake: bool, index: int) -> dict | None:
	caption = (row.get("Caption") or "").strip()
	username = (row.get("User") or "").strip()
	if not caption or not username:
		return None

	day = (row.get("DAY") or "1").strip() or "1"
	likes = (row.get("Num of likes") or "0").strip() or "0"
	shares = (row.get("Num of shares") or "0").strip() or "0"
	attachment = (row.get("Attachment (optional)") or "").strip()
	date_raw = (row.get("Date") or row.get("DATE") or "").strip()
	fake_type = (row.get("FAKE NEWS TYPE") or "").strip()
	evidence = (row.get("EVIDENCE/REASON WHY FAKE") or "").strip()
	art_link = (row.get("Art Assets [GDRIVE Link]") or "").strip()
	reference = (row.get("REFERENCE") or "").strip()
	post_id_raw = (row.get("POST ID") or "").strip()

	prefix = "fake" if is_fake else "legit"
	post_id = post_id_raw or f"d{day}_{prefix}_{index:03d}"

	correct, wrong, hint = build_feedback(is_fake, fake_type, evidence, attachment)
	photo = has_photo_attachment(attachment)

	return {
		"id": post_id,
		"username": username,
		"handle": slug_handle(username),
		"verified": (not is_fake) and looks_like_org(username),
		"account_age": "2 weeks" if is_fake else ("4 years" if looks_like_org(username) else "1 year"),
		"avatar_color": avatar_color(username),
		"content": caption,
		"image": "pending" if photo else None,
		"image_date_watermark": "",
		"image_note": attachment if attachment else ("No photo attached." if not photo else "Photo attached."),
		"likes": likes,
		"comments_count": str(max(2, min(999, int(re.sub(r"[^\d]", "", likes) or "0") // 50 or 2))),
		"shares": shares,
		"timestamp": format_timestamp(date_raw, day),
		"is_fake": is_fake,
		"feedback_correct": correct,
		"feedback_wrong": wrong,
		"guppi_hint": hint,
		"insight_tag": insight_from_type(fake_type) if is_fake else "Trusted reporting",
		"day": int(day),
		"fake_news_type": fake_type,
		"art_asset_link": art_link,
		"reference": reference,
		"comments": default_comments(is_fake),
		"profile": build_profile(username, is_fake, fake_type, day),
	}


def load_posts(path: Path, *, is_fake: bool) -> list[dict]:
	posts: list[dict] = []
	with path.open(newline="", encoding="utf-8-sig") as handle:
		reader = csv.DictReader(handle)
		index = 1
		for row in reader:
			post = row_to_post(row, is_fake=is_fake, index=index)
			if post is None:
				continue
			posts.append(post)
			index += 1
	return posts


def write_json(path: Path, data) -> None:
	path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
	print(f"Wrote {path.relative_to(ROOT)} ({len(data) if isinstance(data, list) else 'obj'} items)")


def main() -> None:
	fake_posts = load_posts(FAKE_CSV, is_fake=True)
	legit_posts = load_posts(LEGIT_CSV, is_fake=False)
	all_posts = fake_posts + legit_posts

	by_day: dict[int, list[dict]] = {}
	for post in all_posts:
		by_day.setdefault(int(post["day"]), []).append(post)

	POSTS_DIR.mkdir(parents=True, exist_ok=True)

	# Stable order within a day: legit first then fake, then by id.
	for day, posts in sorted(by_day.items()):
		posts.sort(key=lambda p: (p["is_fake"], p["id"]))
		out = POSTS_DIR / f"level_{day:02d}.json"
		write_json(out, posts)
		fake_n = sum(1 for p in posts if p["is_fake"])
		legit_n = len(posts) - fake_n
		print(f"  day {day}: {len(posts)} posts ({legit_n} legit / {fake_n} fake)")

	# Drop unused legacy pools so LevelManager can't accidentally load stale content.
	for stale in (POSTS_DIR / "level_04.json", POSTS_DIR / "level_05.json"):
		if stale.exists():
			stale.unlink()
			print(f"Removed {stale.relative_to(ROOT)}")

	# Easy/medium/hard now map onto the three mastersheet days.
	# Shift 1 always uses the Day 1 pool with quota 8 (12 fake + 4 legit in pool).
	# Shifts 2–3 reuse shift-1 ambiance as placeholders until unique art/music lands.
	var ambiance := {
		"background": "res://assets/backgrounds/level1-bg.png",
		"music": "res://assets/music/AvapXia - Icarus.mp3",
	}
	levels = {
		"difficulties": [
			{
				"id": "easy",
				"label": "Easy",
				"blurb": "Shorter queues and clearer tells. GUPPI talks a lot.",
				"shifts": [
					{"shift": 1, "posts_pool": "level_01", "posts_shown": 8, "hint_frequency": 1.0, "note": "Day 1 — morning intake", **ambiance},
					{"shift": 2, "posts_pool": "level_02", "posts_shown": 8, "hint_frequency": 0.9, "note": "Day 2 — midday desk", **ambiance},
					{"shift": 3, "posts_pool": "level_03", "posts_shown": 8, "hint_frequency": 0.8, "note": "Day 3 — closing queue", **ambiance},
				],
			},
			{
				"id": "medium",
				"label": "Medium",
				"blurb": "Standard load. Tips get quieter.",
				"shifts": [
					{"shift": 1, "posts_pool": "level_01", "posts_shown": 8, "hint_frequency": 0.7, "note": "Day 1 — open desk", **ambiance},
					{"shift": 2, "posts_pool": "level_02", "posts_shown": 10, "hint_frequency": 0.55, "note": "Day 2 — contested hour", **ambiance},
					{"shift": 3, "posts_pool": "level_03", "posts_shown": 12, "hint_frequency": 0.4, "note": "Day 3 — rush window", **ambiance},
				],
			},
			{
				"id": "hard",
				"label": "Hard",
				"blurb": "Longer queues. Near-misses. Quiet GUPPI.",
				"shifts": [
					{"shift": 1, "posts_pool": "level_01", "posts_shown": 8, "hint_frequency": 0.35, "note": "Day 1 — deep current", **ambiance},
					{"shift": 2, "posts_pool": "level_02", "posts_shown": 12, "hint_frequency": 0.2, "note": "Day 2 — near-miss flood", **ambiance},
					{"shift": 3, "posts_pool": "level_03", "posts_shown": 14, "hint_frequency": 0.1, "note": "Day 3 — peak traffic", **ambiance},
				],
			},
		]
	}
	write_json(DATA / "levels.json", levels)
	print(f"Converted {len(all_posts)} posts from mastersheet CSVs.")


if __name__ == "__main__":
	main()

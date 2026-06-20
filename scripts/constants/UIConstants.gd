class_name UIConstants
extends RefCounted

## Launcher grid — swap ColorRect placeholders for TextureRect icons at these sizes.
const LAUNCHER_ICON_SIZE := Vector2(56, 56)
const LAUNCHER_ICON_CORNER_RADIUS := 12
const LAUNCHER_CELL_MIN_SIZE := Vector2(72, 88)
const LAUNCHER_GRID_COLUMNS := 4

## System navigation bar at the bottom of the phone shell.
const BOTTOM_NAV_HEIGHT := 56
const BOTTOM_NAV_BUTTON_MIN := Vector2(48, 48)
const BOTTOM_NAV_ICON_SIZE := Vector2(24, 24)

## In-app chrome.
const APP_HEADER_HEIGHT := 48
const STATUS_BAR_HEIGHT := 36

## Notification badge on launcher icons.
const BADGE_SIZE := Vector2(18, 18)

## Export launcher icons at 2x/3x for crisp mobile: 112×112 and 168×168.
const LAUNCHER_ICON_EXPORT_2X := Vector2(112, 112)
const LAUNCHER_ICON_EXPORT_3X := Vector2(168, 168)

## Export bottom-nav icons at 48×48 (2x of 24px logical).
const BOTTOM_NAV_ICON_EXPORT := Vector2(48, 48)

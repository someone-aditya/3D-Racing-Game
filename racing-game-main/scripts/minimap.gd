extends Control

## Draws an oval track minimap with a player dot.

const MAP_SIZE := 100.0
const TRACK_COLOR := Color(0.3, 0.3, 0.35)
const ROAD_COLOR := Color(0.5, 0.5, 0.55)
const PLAYER_COLOR := Color(1, 0.2, 0.15)
const BG_COLOR := Color(0.08, 0.08, 0.12, 0.7)

var player_angle: float = 0.0


func _draw() -> void:
	var center := Vector2(MAP_SIZE / 2.0, MAP_SIZE / 2.0)
	var rx := MAP_SIZE * 0.4
	var rz := MAP_SIZE * 0.3

	# Background circle
	draw_circle(center, MAP_SIZE * 0.48, BG_COLOR)

	# Track oval (draw as thick line segments)
	var points: PackedVector2Array = []
	for i in range(65):
		var angle := float(i) / 64.0 * TAU
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * rz))

	# Road width
	for i in range(64):
		draw_line(points[i], points[i + 1], ROAD_COLOR, 6.0, true)

	# Track center line
	for i in range(64):
		draw_line(points[i], points[i + 1], TRACK_COLOR, 2.0, true)

	# Player dot
	var hud := get_parent()
	if hud and hud.has_method("_format_time"):
		player_angle = hud.player_track_angle
	var player_pos := center + Vector2(cos(player_angle) * rx, sin(player_angle) * rz)
	draw_circle(player_pos, 5.0, PLAYER_COLOR)
	# White outline
	draw_arc(player_pos, 5.5, 0, TAU, 16, Color.WHITE, 1.5)

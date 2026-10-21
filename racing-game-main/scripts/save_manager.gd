extends Node

const SAVE_PATH := "user://best_times.json"

static var best_lap: float = INF
static var best_total: float = INF


static func load_times() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK:
		var data: Dictionary = json.data
		best_lap = data.get("best_lap", INF)
		best_total = data.get("best_total", INF)


static func save_times(lap: float, total: float) -> void:
	var changed := false
	if lap < best_lap:
		best_lap = lap
		changed = true
	if total < best_total:
		best_total = total
		changed = true
	if not changed:
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data := {"best_lap": best_lap, "best_total": best_total}
		file.store_string(JSON.stringify(data))

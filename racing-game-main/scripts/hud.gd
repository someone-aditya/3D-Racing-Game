extends Control

@onready var speed_label: Label = $SpeedPanel/SpeedLabel
@onready var speed_unit: Label = $SpeedPanel/SpeedUnit
@onready var lap_label: Label = $LapLabel
@onready var time_label: Label = $TimeLabel
@onready var countdown_label: Label = $CountdownLabel
@onready var message_label: Label = $MessageLabel
@onready var total_time_label: Label = $TotalTimeLabel
@onready var checkpoint_bar: ProgressBar = $CheckpointBar

var message_timer: float = 0.0


func _ready() -> void:
	# Hide unused elements
	if checkpoint_bar:
		checkpoint_bar.visible = false


func _process(delta: float) -> void:
	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0 and message_label:
			message_label.visible = false


func update_speed(kmh: float) -> void:
	if speed_label:
		speed_label.text = "%d" % int(kmh)


func update_distance(meters: float) -> void:
	if lap_label:
		if meters > 1000:
			lap_label.text = "%.1f km" % (meters / 1000.0)
		else:
			lap_label.text = "%d m" % int(meters)


func update_time(seconds: float) -> void:
	if time_label:
		time_label.text = _format_time(seconds)


func show_countdown(number: int) -> void:
	if countdown_label:
		countdown_label.text = str(number)
		countdown_label.visible = true
		match number:
			3: countdown_label.modulate = Color(1, 0.2, 0.2)
			2: countdown_label.modulate = Color(1, 0.85, 0.1)
			1: countdown_label.modulate = Color(0.2, 1, 0.3)
			_: countdown_label.modulate = Color.WHITE


func hide_countdown() -> void:
	if countdown_label:
		countdown_label.visible = false


func show_message(text: String, duration: float) -> void:
	if message_label:
		message_label.text = text
		message_label.visible = true
		message_timer = duration
		if text == "GO!":
			message_label.modulate = Color(0.2, 1, 0.3)
		else:
			message_label.modulate = Color.WHITE


func _format_time(seconds: float) -> String:
	var mins := int(seconds) / 60
	var secs := fmod(seconds, 60.0)
	return "%d:%05.2f" % [mins, secs]

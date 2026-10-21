extends CharacterBody3D

## AI racer that follows the oval track. Uses CharacterBody3D for
## simple, reliable movement without physics jank.

const TRACK_RADIUS_X := 120.0
const TRACK_RADIUS_Z := 80.0

@export var base_speed: float = 18.0      # base m/s
@export var speed_variation: float = 3.0  # random +/- per AI
@export var color: Color = Color.RED

var track_angle: float = 0.0   # current position on oval (radians)
var actual_speed: float = 0.0
var ai_speed: float = 0.0
var lap_count: int = 0
var race_started: bool = false
var car_name: String = ""
var _wobble_phase: float = 0.0
var _lane_offset: float = 0.0  # offset from center of road


func _ready() -> void:
	# Randomize speed slightly so AIs don't all bunch up
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	ai_speed = base_speed + rng.randf_range(-speed_variation, speed_variation)
	_wobble_phase = rng.randf_range(0, TAU)
	_lane_offset = rng.randf_range(-5.0, 5.0)

	collision_layer = 2
	collision_mask = 1


func _physics_process(delta: float) -> void:
	if not race_started:
		return

	# Slight speed wobble for natural feel
	_wobble_phase += delta * 0.5
	actual_speed = ai_speed + sin(_wobble_phase) * 1.5

	# Calculate how fast to advance the angle based on the oval's circumference
	# Approximate: circumference ~ 2π * avg_radius
	var avg_radius := (TRACK_RADIUS_X + TRACK_RADIUS_Z) / 2.0
	var angular_speed := actual_speed / avg_radius
	track_angle += angular_speed * delta

	if track_angle >= TAU:
		track_angle -= TAU
		lap_count += 1

	# Position on oval + lane offset
	var center := _oval_point(track_angle)
	var normal := _oval_outward(track_angle)
	var target_pos := center + normal * _lane_offset
	target_pos.y = 0.3

	# Face forward along track
	var tangent := _oval_tangent(track_angle)
	var yaw := atan2(tangent.x, tangent.z)

	# Smooth position (don't teleport)
	global_position = global_position.lerp(target_pos, delta * 10.0)
	global_rotation.y = lerp_angle(global_rotation.y, yaw, delta * 8.0)
	global_rotation.x = 0.0
	global_rotation.z = 0.0

	# Move via CharacterBody3D
	velocity = tangent * actual_speed
	velocity.y = -5.0  # stay on ground
	move_and_slide()


func _oval_point(angle: float) -> Vector3:
	return Vector3(cos(angle) * TRACK_RADIUS_X, 0, sin(angle) * TRACK_RADIUS_Z)


func _oval_outward(angle: float) -> Vector3:
	var t := _oval_tangent(angle)
	return Vector3(-t.z, 0, t.x)


func _oval_tangent(angle: float) -> Vector3:
	var dx := -sin(angle) * TRACK_RADIUS_X
	var dz := cos(angle) * TRACK_RADIUS_Z
	return Vector3(dx, 0, dz).normalized()

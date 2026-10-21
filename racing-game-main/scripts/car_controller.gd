extends VehicleBody3D

@export var max_engine_force: float = 800.0
@export var max_brake_force: float = 150.0
@export var max_steer_angle: float = 0.35
@export var steer_speed: float = 2.5
@export var top_speed_kmh: float = 9999.0  # no limit

@onready var camera: Camera3D = $ChaseCamera

@export var cam_height: float = 3.0
@export var cam_distance: float = 7.0
@export var cam_follow_speed: float = 5.0

var current_steer: float = 0.0
var current_speed: float = 0.0
var current_speed_kmh: float = 0.0
var lap_count: int = 0
var last_checkpoint: int = -1
var total_checkpoints: int = 0
var lap_time: float = 0.0
var best_lap: float = INF
var race_started: bool = false
var _cam_yaw: float = 0.0
var boost_timer: float = 0.0  # seconds of boost remaining

signal lap_completed(lap_number: int, lap_time: float)
signal checkpoint_hit(index: int)


func _ready() -> void:
	if camera:
		camera.top_level = true


func _physics_process(delta: float) -> void:
	current_speed = linear_velocity.length()
	current_speed_kmh = current_speed * 3.6

	# --- KEEP CAR ON GROUND ---
	# Only apply downforce when moving forward, not reverse
	var fwd_speed := -global_basis.z.dot(linear_velocity)
	if fwd_speed > 1.0:
		apply_central_force(Vector3.DOWN * fwd_speed * 15.0)
	if global_position.y > 1.0 and linear_velocity.y > 0:
		linear_velocity.y = 0.0
	global_rotation.x = lerp_angle(global_rotation.x, 0.0, 0.3)
	global_rotation.z = lerp_angle(global_rotation.z, 0.0, 0.3)

	# --- BOOST ---
	if boost_timer > 0:
		boost_timer -= delta
		# Boost adds force in forward direction
		var forward := -global_basis.z
		apply_central_force(forward * 1200.0)

	# --- STEERING ---
	var steer_input := Input.get_axis("steer_right", "steer_left")
	var speed_factor := clampf(1.0 - current_speed_kmh / 250.0, 0.35, 1.0)
	var target_steer := steer_input * max_steer_angle * speed_factor
	current_steer = lerp(current_steer, target_steer, delta * steer_speed)
	steering = current_steer

	# --- ENGINE ---
	var accel := Input.get_action_strength("accelerate")
	var braking := Input.get_action_strength("brake")

	if accel > 0.0:
		# More force = more speed, no limit
		engine_force = accel * max_engine_force
		brake = 0.0
	elif braking > 0.0:
		var forward_speed := -global_basis.z.dot(linear_velocity)
		if forward_speed > 2.0:
			# Braking while moving forward
			engine_force = 0.0
			brake = braking * max_brake_force
		else:
			# Reverse — directly override position, nothing can stop this
			engine_force = 0.0
			brake = 0.0
			var back_dir := global_basis.z
			back_dir.y = 0.0
			back_dir = back_dir.normalized()
			var reverse_speed: float = braking * 15.0 * delta  # ~54 km/h max
			global_position += back_dir * reverse_speed
	else:
		engine_force = 0.0
		brake = 3.0 if current_speed > 0.5 else 0.0

	# --- ENGINE SOUND ---
	var eng_sound := get_node_or_null("EngineSound")
	if eng_sound and eng_sound.has_method("update_speed"):
		eng_sound.update_speed(clampf(current_speed_kmh / top_speed_kmh, 0.0, 1.0))

	# --- CAMERA ---
	if camera:
		var car_yaw := global_rotation.y + PI
		var vel_flat := linear_velocity
		vel_flat.y = 0.0
		if vel_flat.length() > 2.0:
			var vel_yaw := atan2(-vel_flat.x, -vel_flat.z)
			_cam_yaw = lerp_angle(_cam_yaw, lerp_angle(car_yaw, vel_yaw, 0.3), delta * cam_follow_speed)
		else:
			_cam_yaw = lerp_angle(_cam_yaw, car_yaw, delta * cam_follow_speed)

		var speed_zoom := clampf(current_speed_kmh / 120.0, 0.0, 1.0)
		var dist := cam_distance + speed_zoom * 3.0
		var height := cam_height + speed_zoom * 1.0
		var offset := Vector3(sin(_cam_yaw) * dist, height, cos(_cam_yaw) * dist)
		camera.global_position = camera.global_position.lerp(global_position + offset, delta * cam_follow_speed)
		camera.look_at(global_position + Vector3.UP * 0.5, Vector3.UP)
		camera.fov = lerp(camera.fov, 70.0 + speed_zoom * 15.0, delta * 3.0)

	if Input.is_action_just_pressed("reset_car"):
		_reset_position()

	if race_started:
		lap_time += delta


func apply_boost(duration: float) -> void:
	boost_timer = duration


func _reset_position() -> void:
	global_rotation = Vector3.ZERO
	global_position.y = 0.5
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO


func on_checkpoint(checkpoint_index: int, is_finish_line: bool) -> void:
	if is_finish_line and last_checkpoint >= total_checkpoints - 1:
		lap_count += 1
		if lap_time < best_lap:
			best_lap = lap_time
		lap_completed.emit(lap_count, lap_time)
		lap_time = 0.0
		last_checkpoint = -1
	elif checkpoint_index == last_checkpoint + 1:
		last_checkpoint = checkpoint_index
		checkpoint_hit.emit(checkpoint_index)

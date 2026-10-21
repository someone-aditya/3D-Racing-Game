extends Node

## Race manager for infinite track — tracks distance and time.

@export var countdown_time: float = 3.0

@onready var hud: Control = $"../UI/HUD"
@onready var car: VehicleBody3D = $"../Car"

var race_active: bool = false
var countdown_remaining: float = 0.0
var total_race_time: float = 0.0
var distance_traveled: float = 0.0
var last_car_pos: Vector3 = Vector3.ZERO


func _ready() -> void:
	if car:
		car.race_started = false
	start_countdown()


func start_countdown() -> void:
	countdown_remaining = countdown_time
	race_active = false
	if car:
		car.race_started = false
		car.engine_force = 0.0
		car.brake = 100.0


func _process(delta: float) -> void:
	if countdown_remaining > 0.0:
		countdown_remaining -= delta
		if hud:
			hud.show_countdown(ceili(countdown_remaining))
		if countdown_remaining <= 0.0:
			race_active = true
			if car:
				car.race_started = true
				car.brake = 0.0
				last_car_pos = car.global_position
			if hud:
				hud.hide_countdown()
				hud.show_message("GO!", 1.0)

	if race_active:
		total_race_time += delta
		if car:
			distance_traveled += car.global_position.distance_to(last_car_pos)
			last_car_pos = car.global_position
		_update_hud()


func _update_hud() -> void:
	if not hud or not car:
		return
	hud.update_speed(car.current_speed * 3.6)
	hud.update_distance(distance_traveled)
	hud.update_time(total_race_time)

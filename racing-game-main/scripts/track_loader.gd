extends Node3D

## Infinite procedural race track. Generates road ahead of the car,
## removes road behind. Random curves and straights.

const ROAD_WIDTH := 24.0
const SEGMENT_LENGTH := 20.0
const BARRIER_HEIGHT := 1.8
const BARRIER_THICKNESS := 0.7
const GENERATE_AHEAD := 40      # segments ahead of car
const REMOVE_BEHIND := 15       # segments behind car to keep
const BOOST_INTERVAL := 25      # place a boost pad every N segments

var segments: Array[Dictionary] = []  # {position, direction, index, node}
var current_direction: float = 0.0    # yaw angle in radians
var next_position: Vector3 = Vector3.ZERO
var next_index: int = 0
var car_segment: int = 0
var rng := RandomNumberGenerator.new()
var ground_body: StaticBody3D = null

@onready var car: Node = null


func _ready() -> void:
	rng.seed = 42
	car = get_node_or_null("../Car")

	# Create ground
	_create_ground()

	# Generate initial track
	for i in range(GENERATE_AHEAD + REMOVE_BEHIND):
		_generate_next_segment()

	# Position car on first segment
	_position_car()
	_attach_car_model()


func _process(_delta: float) -> void:
	if not car:
		return

	# Move ground to follow car
	if ground_body and car:
		ground_body.position.x = car.global_position.x
		ground_body.position.z = car.global_position.z

	# Find which segment the car is on
	_update_car_segment()

	# Generate more track ahead if needed
	while next_index - car_segment < GENERATE_AHEAD:
		_generate_next_segment()

	# Remove old segments behind
	while segments.size() > 0 and segments[0].index < car_segment - REMOVE_BEHIND:
		var seg: Dictionary = segments[0]
		if seg.node and is_instance_valid(seg.node):
			seg.node.queue_free()
		segments.pop_front()


func _update_car_segment() -> void:
	var car_pos: Vector3 = car.global_position
	var best_dist := INF
	var best_idx := car_segment

	for seg in segments:
		var dist: float = car_pos.distance_to(seg.position)
		if dist < best_dist:
			best_dist = dist
			best_idx = seg.index

	car_segment = best_idx


func _generate_next_segment() -> void:
	# Decide curve: mostly straight, sometimes turn
	var turn := rng.randf_range(-0.08, 0.08)  # gentle base curve
	if rng.randf() < 0.15:
		turn = rng.randf_range(-0.25, 0.25)   # sharper turn sometimes
	if rng.randf() < 0.05:
		turn = rng.randf_range(-0.4, 0.4)     # rare hairpin-ish

	current_direction += turn

	var dir_vec := Vector3(sin(current_direction), 0, cos(current_direction))
	var pos: Vector3 = next_position
	next_position = pos + dir_vec * SEGMENT_LENGTH

	var seg_node := Node3D.new()
	seg_node.name = "Seg_%d" % next_index
	add_child(seg_node)

	# Build road, barriers, markings for this segment
	var next_dir := current_direction
	var next_dir_vec := Vector3(sin(next_dir), 0, cos(next_dir))
	var mid := (pos + next_position) / 2.0

	_build_road_segment(seg_node, pos, next_position, dir_vec, next_dir_vec)
	_build_barriers(seg_node, pos, next_position, dir_vec, next_dir_vec)
	_build_markings(seg_node, pos, next_position, dir_vec, next_dir_vec, next_index)

	# Boost pad
	if next_index > 0 and next_index % BOOST_INTERVAL == 0:
		_build_boost_pad(seg_node, mid, dir_vec)

	# Scenery
	if next_index % 3 == 0:
		_place_segment_scenery(seg_node, mid, dir_vec)

	var seg_data := {
		"position": mid,
		"direction": current_direction,
		"index": next_index,
		"node": seg_node
	}
	segments.append(seg_data)
	next_index += 1


func _build_road_segment(parent: Node3D, from: Vector3, to: Vector3,
		dir_from: Vector3, dir_to: Vector3) -> void:
	var right_from := Vector3(-dir_from.z, 0, dir_from.x)
	var right_to := Vector3(-dir_to.z, 0, dir_to.x)
	var hw := ROAD_WIDTH / 2.0

	# Asphalt
	var road_mat := StandardMaterial3D.new()
	road_mat.albedo_color = Color(0.14, 0.14, 0.16)
	road_mat.roughness = 0.85
	_add_quad(parent, from - right_from * hw, from + right_from * hw,
		to + right_to * hw, to - right_to * hw, 0.005, road_mat)

	# Shoulder strips
	var shoulder_mat := StandardMaterial3D.new()
	shoulder_mat.albedo_color = Color(0.22, 0.22, 0.24)
	var sh := 1.5
	_add_quad(parent, from - right_from * (hw + sh), from - right_from * hw,
		to - right_to * hw, to - right_to * (hw + sh), 0.006, shoulder_mat)
	_add_quad(parent, from + right_from * hw, from + right_from * (hw + sh),
		to + right_to * (hw + sh), to + right_to * hw, 0.006, shoulder_mat)

	# Curbs
	var curb_mat := StandardMaterial3D.new()
	curb_mat.albedo_color = Color(0.85, 0.12, 0.08) if next_index % 2 == 0 else Color(0.92, 0.92, 0.90)
	var cw := 1.2
	_add_quad(parent, from - right_from * (hw + sh + cw), from - right_from * (hw + sh),
		to - right_to * (hw + sh), to - right_to * (hw + sh + cw), 0.008, curb_mat)
	_add_quad(parent, from + right_from * (hw + sh), from + right_from * (hw + sh + cw),
		to + right_to * (hw + sh + cw), to + right_to * (hw + sh), 0.008, curb_mat)


func _build_barriers(parent: Node3D, from: Vector3, to: Vector3,
		dir_from: Vector3, _dir_to: Vector3) -> void:
	var right := Vector3(-dir_from.z, 0, dir_from.x)
	var mid := (from + to) / 2.0
	var length := from.distance_to(to) + 0.2
	var yaw := atan2(dir_from.x, dir_from.z)
	var barrier_offset := ROAD_WIDTH / 2.0 + 3.5

	for side in [-1.0, 1.0]:
		var pos: Vector3 = mid + right * barrier_offset * side
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 2
		body.position = pos
		body.rotation.y = yaw

		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(BARRIER_THICKNESS, BARRIER_HEIGHT, length)
		col.shape = shape
		col.position = Vector3(0, BARRIER_HEIGHT / 2.0, 0)
		body.add_child(col)

		# Concrete
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(BARRIER_THICKNESS, BARRIER_HEIGHT * 0.75, length)
		mesh.mesh = box
		mesh.position = Vector3(0, BARRIER_HEIGHT * 0.375, 0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.65, 0.65, 0.68)
		mesh.material_override = mat
		body.add_child(mesh)

		# Red stripe
		var stripe := MeshInstance3D.new()
		var sbox := BoxMesh.new()
		sbox.size = Vector3(BARRIER_THICKNESS + 0.02, 0.3, length)
		stripe.mesh = sbox
		stripe.position = Vector3(0, BARRIER_HEIGHT * 0.75, 0)
		var smat := StandardMaterial3D.new()
		smat.albedo_color = Color(0.9, 0.15, 0.1)
		stripe.material_override = smat
		body.add_child(stripe)

		parent.add_child(body)


func _build_markings(parent: Node3D, from: Vector3, to: Vector3,
		dir_from: Vector3, dir_to: Vector3, idx: int) -> void:
	var right_from := Vector3(-dir_from.z, 0, dir_from.x)
	var right_to := Vector3(-dir_to.z, 0, dir_to.x)
	var hw := ROAD_WIDTH / 2.0
	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.85, 0.85, 0.85)

	# Dashed lane lines (3 lanes = 2 dividers)
	if idx % 3 == 0:
		for frac in [-1.0 / 3.0, 1.0 / 3.0]:
			var off_from: Vector3 = right_from * hw * frac
			var off_to: Vector3 = right_to * hw * frac
			_add_quad(parent,
				from + off_from - right_from * 0.12, from + off_from + right_from * 0.12,
				to + off_to + right_to * 0.12, to + off_to - right_to * 0.12,
				0.009, line_mat)

	# Solid edge lines
	for side_val in [-1.0, 1.0]:
		_add_quad(parent,
			from + right_from * (hw * side_val - 0.15 * side_val),
			from + right_from * hw * side_val,
			to + right_to * hw * side_val,
			to + right_to * (hw * side_val - 0.15 * side_val),
			0.009, line_mat)


func _build_boost_pad(parent: Node3D, pos: Vector3, dir: Vector3) -> void:
	var yaw := atan2(dir.x, dir.z)
	var pad_w := ROAD_WIDTH * 0.5
	var pad_l := 8.0

	var boost_mat := StandardMaterial3D.new()
	boost_mat.albedo_color = Color(0.0, 0.7, 1.0, 0.8)
	boost_mat.emission_enabled = true
	boost_mat.emission = Color(0.0, 0.5, 1.0)
	boost_mat.emission_energy_multiplier = 1.5

	var vis := MeshInstance3D.new()
	var vbox := BoxMesh.new()
	vbox.size = Vector3(pad_w, 0.02, pad_l)
	vis.mesh = vbox
	vis.position = pos + Vector3(0, 0.015, 0)
	vis.rotation.y = yaw
	vis.material_override = boost_mat
	parent.add_child(vis)

	# Arrow chevrons
	var arrow_mat := StandardMaterial3D.new()
	arrow_mat.albedo_color = Color(0.0, 0.9, 1.0)
	arrow_mat.emission_enabled = true
	arrow_mat.emission = Color(0.0, 0.8, 1.0)
	arrow_mat.emission_energy_multiplier = 2.0
	for k in range(3):
		var arrow := MeshInstance3D.new()
		var abox := BoxMesh.new()
		abox.size = Vector3(pad_w * 0.5, 0.025, 0.4)
		arrow.mesh = abox
		arrow.position = pos + dir * (-2.5 + k * 2.5) + Vector3(0, 0.02, 0)
		arrow.rotation.y = yaw
		arrow.material_override = arrow_mat
		parent.add_child(arrow)

	var trigger := Area3D.new()
	trigger.collision_layer = 4
	trigger.collision_mask = 2
	trigger.set_script(load("res://scripts/boost_pad.gd"))
	var tcol := CollisionShape3D.new()
	var tshape := BoxShape3D.new()
	tshape.size = Vector3(pad_w, 2.0, pad_l)
	tcol.shape = tshape
	tcol.position = Vector3(0, 1.0, 0)
	trigger.add_child(tcol)
	trigger.position = pos
	trigger.rotation.y = yaw
	parent.add_child(trigger)


func _place_segment_scenery(parent: Node3D, pos: Vector3, dir: Vector3) -> void:
	var right := Vector3(-dir.z, 0, dir.x)
	var offset := ROAD_WIDTH / 2.0 + rng.randf_range(15.0, 60.0)
	var side := 1.0 if rng.randf() > 0.5 else -1.0
	var tree_pos := pos + right * offset * side

	var tree := _load_model("res://models/tree.glb")
	if tree:
		var s := rng.randf_range(5.0, 14.0)
		tree.scale = Vector3(s, s, s)
		tree.position = tree_pos
		tree.rotation.y = rng.randf_range(0, TAU)
		tree.reparent(parent)

	# Occasional building
	if rng.randf() < 0.1:
		var bldg := _load_model("res://models/building.glb")
		if bldg:
			bldg.scale = Vector3(14, 14, 14)
			bldg.position = pos + right * (ROAD_WIDTH / 2.0 + rng.randf_range(30.0, 80.0)) * -side
			bldg.rotation.y = rng.randf_range(0, TAU)
			bldg.reparent(parent)


func _create_ground() -> void:
	# Huge ground plane that follows camera roughly
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(5000, 1, 5000)
	col.shape = shape
	col.position = Vector3(0, -0.5, 0)
	body.add_child(col)

	var mesh := MeshInstance3D.new()
	var gbox := BoxMesh.new()
	gbox.size = Vector3(5000, 0.02, 5000)
	mesh.mesh = gbox
	mesh.position = Vector3(0, -0.01, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.38, 0.08)
	mesh.material_override = mat
	body.add_child(mesh)

	add_child(body)
	ground_body = body


func _attach_car_model() -> void:
	if not car:
		return
	var CarBuilder := load("res://scripts/car_mesh_builder.gd")
	var car_model: Node3D = CarBuilder.create_car(Color(0.9, 0.1, 0.1))
	car_model.name = "CarModel"
	car_model.position = Vector3(0, -0.15, 0)
	var body_node := car.get_node_or_null("CarBody")
	if body_node:
		body_node.add_child(car_model)
	else:
		car.add_child(car_model)


func _position_car() -> void:
	if not car or segments.is_empty():
		return
	var first: Dictionary = segments[0]
	var dir_vec: Vector3 = Vector3(sin(first.direction), 0, cos(first.direction))
	var right := Vector3(-dir_vec.z, 0, dir_vec.x)
	car.global_position = first.position - right * 4.0 + Vector3(0, 0.5, 0)
	car.global_rotation.y = first.direction


# --- HELPERS ---

func _add_quad(parent: Node3D, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		y_offset: float, mat: StandardMaterial3D) -> void:
	var mesh := MeshInstance3D.new()
	var imm := ImmediateMesh.new()
	imm.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	imm.surface_add_vertex(a + Vector3(0, y_offset, 0))
	imm.surface_add_vertex(b + Vector3(0, y_offset, 0))
	imm.surface_add_vertex(c + Vector3(0, y_offset, 0))
	imm.surface_add_vertex(a + Vector3(0, y_offset, 0))
	imm.surface_add_vertex(c + Vector3(0, y_offset, 0))
	imm.surface_add_vertex(d + Vector3(0, y_offset, 0))
	imm.surface_end()
	imm.surface_set_material(0, mat)
	mesh.mesh = imm
	parent.add_child(mesh)


func _load_model(path: String) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var scene: PackedScene = load(path)
	if not scene:
		return null
	var instance := scene.instantiate() as Node3D
	add_child(instance)
	return instance

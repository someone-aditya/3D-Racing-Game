extends Node3D

## Builds a simple race car from basic meshes — no external model needed.


static func create_car(color: Color = Color(0.9, 0.1, 0.1)) -> Node3D:
	var car := Node3D.new()

	# Body - main lower part
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(2.0, 0.5, 4.5)
	body.mesh = body_mesh
	body.position = Vector3(0, 0.45, 0)
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = color
	body_mat.metallic = 0.3
	body_mat.roughness = 0.4
	body.material_override = body_mat
	car.add_child(body)

	# Cabin / cockpit
	var cabin := MeshInstance3D.new()
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(1.6, 0.45, 2.0)
	cabin.mesh = cabin_mesh
	cabin.position = Vector3(0, 0.92, -0.3)
	var cabin_mat := StandardMaterial3D.new()
	cabin_mat.albedo_color = color.darkened(0.3)
	cabin_mat.metallic = 0.2
	cabin.material_override = cabin_mat
	car.add_child(cabin)

	# Windshield
	var windshield := MeshInstance3D.new()
	var ws_mesh := BoxMesh.new()
	ws_mesh.size = Vector3(1.5, 0.4, 0.08)
	windshield.mesh = ws_mesh
	windshield.position = Vector3(0, 0.95, 0.7)
	windshield.rotation.x = -0.3
	var ws_mat := StandardMaterial3D.new()
	ws_mat.albedo_color = Color(0.3, 0.5, 0.8, 0.6)
	ws_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ws_mat.metallic = 0.8
	windshield.material_override = ws_mat
	car.add_child(windshield)

	# Rear windshield
	var rw := MeshInstance3D.new()
	var rw_mesh := BoxMesh.new()
	rw_mesh.size = Vector3(1.5, 0.35, 0.08)
	rw.mesh = rw_mesh
	rw.position = Vector3(0, 0.9, -1.3)
	rw.rotation.x = 0.3
	rw.material_override = ws_mat
	car.add_child(rw)

	# Spoiler
	var spoiler := MeshInstance3D.new()
	var sp_mesh := BoxMesh.new()
	sp_mesh.size = Vector3(1.8, 0.06, 0.4)
	spoiler.mesh = sp_mesh
	spoiler.position = Vector3(0, 1.2, -2.1)
	var sp_mat := StandardMaterial3D.new()
	sp_mat.albedo_color = Color(0.15, 0.15, 0.15)
	spoiler.material_override = sp_mat
	car.add_child(spoiler)

	# Spoiler stands
	for x in [-0.6, 0.6]:
		var stand := MeshInstance3D.new()
		var st_mesh := BoxMesh.new()
		st_mesh.size = Vector3(0.08, 0.3, 0.08)
		stand.mesh = st_mesh
		stand.position = Vector3(x, 1.05, -2.1)
		stand.material_override = sp_mat
		car.add_child(stand)

	# Headlights
	var hl_mat := StandardMaterial3D.new()
	hl_mat.albedo_color = Color(1, 1, 0.9)
	hl_mat.emission_enabled = true
	hl_mat.emission = Color(1, 1, 0.8)
	hl_mat.emission_energy_multiplier = 2.0
	for x in [-0.7, 0.7]:
		var hl := MeshInstance3D.new()
		var hl_mesh := BoxMesh.new()
		hl_mesh.size = Vector3(0.35, 0.15, 0.05)
		hl.mesh = hl_mesh
		hl.position = Vector3(x, 0.5, 2.26)
		hl.material_override = hl_mat
		car.add_child(hl)

	# Tail lights
	var tl_mat := StandardMaterial3D.new()
	tl_mat.albedo_color = Color(1, 0.1, 0.05)
	tl_mat.emission_enabled = true
	tl_mat.emission = Color(1, 0, 0)
	tl_mat.emission_energy_multiplier = 1.5
	for x in [-0.7, 0.7]:
		var tl := MeshInstance3D.new()
		var tl_mesh := BoxMesh.new()
		tl_mesh.size = Vector3(0.4, 0.12, 0.05)
		tl.mesh = tl_mesh
		tl.position = Vector3(x, 0.5, -2.26)
		tl.material_override = tl_mat
		car.add_child(tl)

	# Wheels
	var wheel_mat := StandardMaterial3D.new()
	wheel_mat.albedo_color = Color(0.15, 0.15, 0.15)
	var rim_mat := StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.7, 0.7, 0.72)
	rim_mat.metallic = 0.9

	var wheel_positions := [
		Vector3(-1.05, 0.3, 1.5),
		Vector3(1.05, 0.3, 1.5),
		Vector3(-1.05, 0.3, -1.5),
		Vector3(1.05, 0.3, -1.5),
	]
	for wpos in wheel_positions:
		# Tire
		var wheel := MeshInstance3D.new()
		var w_mesh := CylinderMesh.new()
		w_mesh.top_radius = 0.3
		w_mesh.bottom_radius = 0.3
		w_mesh.height = 0.25
		wheel.mesh = w_mesh
		wheel.position = wpos
		wheel.rotation.z = PI / 2.0
		wheel.material_override = wheel_mat
		car.add_child(wheel)

		# Rim
		var rim := MeshInstance3D.new()
		var r_mesh := CylinderMesh.new()
		r_mesh.top_radius = 0.15
		r_mesh.bottom_radius = 0.15
		r_mesh.height = 0.26
		rim.mesh = r_mesh
		rim.position = wpos
		rim.rotation.z = PI / 2.0
		rim.material_override = rim_mat
		car.add_child(rim)

	return car

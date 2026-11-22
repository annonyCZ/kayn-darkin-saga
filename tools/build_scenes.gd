extends SceneTree
## Generates the project's .tscn scenes. Run:
##   godot --headless --path . --script res://tools/build_scenes.gd
## Scenes are real files committed to the project; edit them freely in the editor
## afterwards (re-running this overwrites them).

func _own(node: Node, root: Node) -> void:
	for c in node.get_children():
		c.owner = root
		if c.scene_file_path == "":
			_own(c, root)

func _save(root: Node, path: String) -> void:
	_own(root, root)
	var ps := PackedScene.new()
	var err := ps.pack(root)
	assert(err == OK)
	err = ResourceSaver.save(ps, path)
	print("saved ", path, " -> ", error_string(err))
	root.free()

func _mat(color: Color, rough: float = 0.8, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	return m

func _mesh(shape: Mesh, mat: Material, pos: Vector3 = Vector3.ZERO, name := "Mesh") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = shape
	mi.material_override = null
	shape.surface_set_material(0, mat) if shape.get_surface_count() > 0 else null
	mi.position = pos
	return mi

func _capsule(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	return c

func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b

func _hitbox(mask: int, size: Vector3, pos: Vector3) -> Hitbox:
	var hb := Hitbox.new()
	hb.name = "Hitbox"
	hb.collision_layer = 0
	hb.collision_mask = mask
	hb.position = pos
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	hb.add_child(cs)
	return hb

func _init() -> void:
	_build_player()
	_build_enemy()
	_build_camera_rig()
	_build_hud()
	_build_pause_menu()
	_build_altar()
	_build_arena()
	_build_main()
	quit()

func _build_player() -> void:
	var p := Player.new()
	p.name = "Player"
	p.collision_layer = 2
	p.collision_mask = 1 | 4
	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	cs.shape = cap
	cs.position.y = 0.9
	p.add_child(cs)
	var h := HealthComponent.new()
	h.name = "Health"
	h.max_health = 120.0
	h.max_poise = 45.0
	p.add_child(h)
	var model := Node3D.new()
	model.name = "Model"
	p.add_child(model)
	var body := _mesh(_capsule(0.38, 1.7), _mat(Color(0.18, 0.12, 0.28), 0.6), Vector3(0, 0.9, 0), "Body")
	model.add_child(body)
	# Placeholder face marker so facing is readable
	var visor := _mesh(_box(Vector3(0.36, 0.08, 0.1)), _mat(Color(0.9, 0.2, 0.3)), Vector3(0, 1.5, -0.34), "Visor")
	model.add_child(visor)
	var pivot := Node3D.new()
	pivot.name = "SwordPivot"
	pivot.position = Vector3(0.45, 1.25, -0.1)
	model.add_child(pivot)
	pivot.add_child(_mesh(_box(Vector3(0.09, 0.05, 1.5)), _mat(Color(0.75, 0.75, 0.85), 0.25, 0.9), Vector3(0, 0, -0.75), "Blade"))
	pivot.add_child(_mesh(_box(Vector3(0.3, 0.07, 0.1)), _mat(Color(0.3, 0.2, 0.1)), Vector3(0, 0, -0.05), "Guard"))
	model.add_child(_hitbox(4, Vector3(2.4, 1.6, 2.4), Vector3(0, 1.0, -1.2)))
	_save(p, "res://scenes/characters/player.tscn")

func _build_enemy() -> void:
	var e := Enemy.new()
	e.name = "Enemy"
	e.collision_layer = 4
	e.collision_mask = 1 | 2 | 4
	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.9
	cs.shape = cap
	cs.position.y = 0.95
	e.add_child(cs)
	var h := HealthComponent.new()
	h.name = "Health"
	h.max_health = 70.0
	h.max_poise = 30.0
	e.add_child(h)
	var agent := NavigationAgent3D.new()
	agent.name = "Agent"
	agent.radius = 0.5
	agent.path_desired_distance = 0.6
	agent.target_desired_distance = 0.5
	e.add_child(agent)
	var model := Node3D.new()
	model.name = "Model"
	e.add_child(model)
	model.add_child(_mesh(_capsule(0.45, 1.9), _mat(Color(0.35, 0.33, 0.3), 0.9), Vector3(0, 0.95, 0), "Body"))
	model.add_child(_mesh(_box(Vector3(0.4, 0.1, 0.1)), _mat(Color(0.9, 0.7, 0.2)), Vector3(0, 1.6, -0.4), "Eyes"))
	var pivot := Node3D.new()
	pivot.name = "WeaponPivot"
	pivot.position = Vector3(0.5, 1.2, -0.1)
	model.add_child(pivot)
	pivot.add_child(_mesh(_box(Vector3(0.14, 0.14, 1.3)), _mat(Color(0.25, 0.2, 0.15)), Vector3(0, 0, -0.65), "Club"))
	model.add_child(_hitbox(2, Vector3(2.2, 1.6, 2.2), Vector3(0, 1.0, -1.2)))
	_save(e, "res://scenes/enemies/enemy.tscn")

func _build_camera_rig() -> void:
	var r := CameraRig.new()
	r.name = "CameraRig"
	var yaw := Node3D.new(); yaw.name = "Yaw"; r.add_child(yaw)
	var pitch := Node3D.new(); pitch.name = "Pitch"; yaw.add_child(pitch)
	var arm := SpringArm3D.new(); arm.name = "SpringArm3D"
	arm.spring_length = 4.6
	arm.margin = 0.3
	arm.collision_mask = 1
	var sph := SphereShape3D.new(); sph.radius = 0.25
	arm.shape = sph
	arm.position = Vector3(0.7, 0.2, 0)   # over-the-shoulder offset
	pitch.add_child(arm)
	var cam := Camera3D.new(); cam.name = "Camera3D"
	cam.fov = 70.0
	cam.current = true
	arm.add_child(cam)
	_save(r, "res://scenes/characters/camera_rig.tscn")

func _build_altar() -> void:
	var a := PathAltar.new()
	a.name = "PathAltar"
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 2.8
	sh.height = 3.0
	cs.shape = sh
	cs.position.y = 1.5
	a.add_child(cs)
	var pillar := _mesh(_box(Vector3(0.9, 1.4, 0.9)), _mat(Color(0.2, 0.2, 0.25), 0.5), Vector3(0, 0.7, 0), "Pillar")
	a.add_child(pillar)
	var orb_mat := _mat(Color(0.6, 0.1, 0.9), 0.2)
	orb_mat.emission_enabled = true
	orb_mat.emission = Color(0.6, 0.15, 0.95)
	orb_mat.emission_energy_multiplier = 2.0
	var sph := SphereMesh.new(); sph.radius = 0.25; sph.height = 0.5
	a.add_child(_mesh(sph, orb_mat, Vector3(0, 1.7, 0), "Orb"))
	var lbl := Label3D.new()
	lbl.name = "Prompt"
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0, 2.6, 0)
	lbl.font_size = 36
	lbl.outline_size = 12
	lbl.visible = false
	a.add_child(lbl)
	var lt := OmniLight3D.new(); lt.name = "Glow"; lt.light_color = Color(0.6, 0.2, 1.0)
	lt.position = Vector3(0, 1.7, 0); lt.omni_range = 7.0
	a.add_child(lt)
	_save(a, "res://scenes/interactables/path_altar.tscn")

func _build_pause_menu() -> void:
	var pm := PauseMenu.new()
	pm.name = "PauseMenu"
	_save(pm, "res://scenes/ui/pause_menu.tscn")

func _build_hud() -> void:
	var h := Hud.new()
	h.name = "Hud"
	_save(h, "res://scenes/ui/hud.tscn")

func _build_arena() -> void:
	var a := ArenaNav.new()
	a.name = "TestArena"
	# Procedural terrain (flat arena plateau + hills), generated at load by TerrainGen
	var terrain := TerrainGen.new(); terrain.name = "Terrain"
	a.add_child(terrain)
	# Invisible boundary walls well outside the rim cliffs
	for i in 4:
		var w := StaticBody3D.new(); w.name = "Wall%d" % i; w.collision_layer = 1
		var ws := CollisionShape3D.new(); var wb := BoxShape3D.new(); wb.size = Vector3(230, 80, 1); ws.shape = wb
		w.add_child(ws)
		w.position = Vector3(0, 40, -108).rotated(Vector3.UP, i * PI / 2.0)
		w.rotation.y = i * PI / 2.0
		a.add_child(w)
	var forest := Forest.new(); forest.name = "Forest"
	a.add_child(forest)
	# Real rock assets (CC0 Terrain3D demo models) as landmarks / cover
	var rocks := ["RockA", "RockB", "RockC"]
	var spots := [Vector3(-12, 0, -14), Vector3(14, 0, -10), Vector3(-18, 0, 8), Vector3(20, 0, 14), Vector3(0, 0, -26), Vector3(-26, 0, -4), Vector3(27, 0, -3)]
	for i in spots.size():
		var ps: PackedScene = load("res://assets/environments/terrain3d_demo/models/%s.tscn" % rocks[i % 3])
		if ps:
			# The demo rock scenes carry a collision *shape* but no body, so wrap them in a StaticBody3D.
			var inst := ps.instantiate() as Node3D
			var body := StaticBody3D.new()
			body.name = "Rock%d" % i
			body.collision_layer = 1
			body.position = Vector3(spots[i].x, TerrainGen.height_at(spots[i].x, spots[i].z), spots[i].z)
			body.rotation.y = i * 1.3
			body.scale = Vector3.ONE * 1.4
			body.add_child(inst)
			var src := inst.get_node_or_null("CollisionShape3D") as CollisionShape3D
			if src:
				var cs2 := CollisionShape3D.new()
				cs2.name = "CollisionShape3D"
				cs2.shape = src.shape
				body.add_child(cs2)
			a.add_child(body)
	# Light + environment: low golden sun, filmic grade, bloom, AO, fog
	var sun := DirectionalLight3D.new(); sun.name = "Sun"
	sun.rotation_degrees = Vector3(-24, -40, 0)
	sun.light_color = Color(1.0, 0.88, 0.72)
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 130.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.shadow_blur = 1.2
	a.add_child(sun)
	var env := WorldEnvironment.new(); env.name = "WorldEnvironment"
	var e := Environment.new()
	var sky := Sky.new(); var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = Color(0.16, 0.26, 0.5)
	psm.sky_horizon_color = Color(0.95, 0.62, 0.4)
	psm.sky_curve = 0.18
	psm.ground_horizon_color = Color(0.6, 0.42, 0.32)
	psm.ground_bottom_color = Color(0.12, 0.1, 0.1)
	psm.sun_angle_max = 25.0
	psm.sun_curve = 0.1
	sky.sky_material = psm
	e.sky = sky
	e.background_mode = Environment.BG_SKY
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.8
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_exposure = 0.9
	e.glow_enabled = true
	e.glow_intensity = 0.9
	e.glow_bloom = 0.08
	e.glow_hdr_threshold = 1.0
	e.ssao_enabled = true
	e.ssao_radius = 1.6
	e.ssao_intensity = 2.0
	e.ssil_enabled = false
	e.fog_enabled = true
	e.fog_light_color = Color(0.82, 0.62, 0.5)
	e.fog_light_energy = 1.0
	e.fog_sun_scatter = 0.35
	e.fog_density = 0.0025
	e.fog_aerial_perspective = 0.5
	e.volumetric_fog_enabled = true
	e.volumetric_fog_density = 0.006
	e.volumetric_fog_albedo = Color(0.9, 0.75, 0.65)
	e.volumetric_fog_length = 90.0
	e.adjustment_enabled = true
	e.adjustment_contrast = 1.12
	e.adjustment_saturation = 1.12
	env.environment = e
	a.add_child(env)
	# Markers
	var sp := Marker3D.new(); sp.name = "PlayerSpawn"; sp.position = Vector3(0, 0.1, 10); a.add_child(sp)
	_save(a, "res://scenes/levels/test_arena.tscn")

func _build_main() -> void:
	var m := Node3D.new()
	m.name = "Main"
	var arena: Node3D = load("res://scenes/levels/test_arena.tscn").instantiate()
	m.add_child(arena)
	var pl: Player = load("res://scenes/characters/player.tscn").instantiate()
	pl.position = Vector3(0, 0.1, 10)
	m.add_child(pl)
	var rig: CameraRig = load("res://scenes/characters/camera_rig.tscn").instantiate()
	m.add_child(rig)
	var altar: Node3D = load("res://scenes/interactables/path_altar.tscn").instantiate()
	altar.position = Vector3(7, 0, 8)
	m.add_child(altar)
	var enemy_ps: PackedScene = load("res://scenes/enemies/enemy.tscn")
	var defs := [
		["Training Dummy", false, Vector3(-4, 0.1, 2)],
		["Husk Soldier", true, Vector3(8, 0.1, -8)],
		["Husk Soldier", true, Vector3(-9, 0.1, -10)],
		["Husk Brute", true, Vector3(0, 0.1, -18)],
	]
	for i in defs.size():
		var en: Enemy = enemy_ps.instantiate()
		en.name = "Enemy%d" % i
		en.display_name = defs[i][0]
		en.aggressive = defs[i][1]
		en.position = defs[i][2]
		m.add_child(en)
	m.add_child(load("res://scenes/ui/pause_menu.tscn").instantiate())
	var hud: Hud = load("res://scenes/ui/hud.tscn").instantiate()
	m.add_child(hud)
	# Wire camera to player at runtime
	var boot := Node.new(); boot.name = "Boot"
	boot.set_script(load("res://scripts/core/main_boot.gd"))
	m.add_child(boot)
	_save(m, "res://scenes/main/main.tscn")

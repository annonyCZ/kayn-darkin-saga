class_name VillageElder
extends Area3D
## Elder Lin: a robed NPC on the plaza. Interact (G) to talk; at the end he refills the player's healing
## gourd. Model is built from primitives (robe, hood, beard, staff) - no external assets.

const LINES: Array[String] = [
	"Cizinče... ten pach popela znám. Neseš s sebou stín, který není tvůj.",
	"Tohle údolí kdysi patřilo rolníkům. Pak přišly Schránky - prázdné slupky, které chodí a nikdy nespí.",
	"Oltář na planině chce svou cenu. Až si vybereš cestu, zpátky už nepůjdeš.",
	"Vem si tuhle tykev. Naplnil jsem ji hořkým odvarem, aby ti zavřel rány. Vrať se, až bude prázdná.",
]

var _player_inside: bool = false
var _talking: bool = false
var _prompt: Label3D
var talked: int = 0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 3.2
	cs.shape = sph
	cs.position = Vector3(0, 1.0, 0)
	add_child(cs)
	body_entered.connect(func(b: Node3D) -> void: if b is Player: _player_inside = true)
	body_exited.connect(func(b: Node3D) -> void: if b is Player: _player_inside = false)
	_build_model()
	_prompt = Label3D.new()
	_prompt.text = "[G] Promluvit - Starší Lin"
	_prompt.position = Vector3(0, 2.7, 0)
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.no_depth_test = true
	_prompt.font_size = 40
	_prompt.pixel_size = 0.004
	_prompt.modulate = Color(1, 0.9, 0.6)
	_prompt.visible = false
	add_child(_prompt)
	# a solid body so nobody walks through him
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var bs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	bs.shape = cap
	bs.position = Vector3(0, 0.9, 0)
	body.add_child(bs)
	add_child(body)

func _process(_delta: float) -> void:
	_prompt.visible = _player_inside and not _talking
	if _player_inside:
		var pl := get_tree().get_first_node_in_group("player") as Node3D
		if pl != null:
			var d := pl.global_position - global_position
			rotation.y = lerp_angle(rotation.y, atan2(d.x, d.z), 0.08)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		talk()

func talk() -> bool:
	if not _player_inside or _talking:
		return false
	_talking = true
	var box := DialogueBox.new("Starší Lin", LINES)
	box.finished.connect(_on_done)
	get_tree().root.add_child(box)
	return true

func _on_done() -> void:
	_talking = false
	talked += 1
	var pl := get_tree().get_first_node_in_group("player") as Player
	if pl != null:
		pl.refill_gourd()
		Sfx.play("heal", pl.global_position, -4.0)

func _build_model() -> void:
	var robe := StandardMaterial3D.new(); robe.albedo_color = Color(0.2, 0.17, 0.15); robe.roughness = 0.9
	var trim := StandardMaterial3D.new(); trim.albedo_color = Color(0.4, 0.07, 0.07); trim.roughness = 0.8
	var skin := StandardMaterial3D.new(); skin.albedo_color = Color(0.62, 0.5, 0.42); skin.roughness = 0.8
	var white := StandardMaterial3D.new(); white.albedo_color = Color(0.82, 0.82, 0.8); white.roughness = 0.9
	var wood := StandardMaterial3D.new(); wood.albedo_color = Color(0.22, 0.14, 0.09); wood.roughness = 0.7
	_add(CylinderMesh.new(), robe, Vector3(0, 0.8, 0), Vector3(0.9, 1.6, 0.8), 0.18, 0.34)
	_add(CylinderMesh.new(), trim, Vector3(0, 1.08, 0), Vector3(0.5, 0.12, 0.45), 0.25, 0.26)
	_add(SphereMesh.new(), skin, Vector3(0, 1.78, 0), Vector3(0.28, 0.3, 0.28))
	_add(SphereMesh.new(), white, Vector3(0, 1.62, -0.1), Vector3(0.22, 0.34, 0.14))   # long beard
	var hat := CylinderMesh.new(); hat.top_radius = 0.02; hat.bottom_radius = 0.5; hat.height = 0.3; hat.radial_segments = 14
	_add(hat, wood, Vector3(0, 1.98, 0), Vector3.ONE)
	_add(CylinderMesh.new(), wood, Vector3(0.42, 1.0, -0.12), Vector3(0.05, 1.0, 0.05))   # staff
	_add(SphereMesh.new(), trim, Vector3(0.42, 2.06, -0.12), Vector3(0.1, 0.1, 0.1))

func _add(m: Mesh, mat: Material, pos: Vector3, scl: Vector3, top: float = -1.0, bottom: float = -1.0) -> void:
	if m is CylinderMesh and top >= 0.0:
		(m as CylinderMesh).top_radius = top
		(m as CylinderMesh).bottom_radius = bottom
		(m as CylinderMesh).height = 1.0
		scl = Vector3(1, scl.y, 1)
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl if not (m is CylinderMesh and top >= 0.0) else scl
	add_child(mi)

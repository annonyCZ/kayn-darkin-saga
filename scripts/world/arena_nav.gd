class_name ArenaNav
extends Node3D
## Bakes a navigation mesh from the level's static colliders at load time and
## exposes it through a NavigationRegion3D, so enemies path around rocks and walls.

@export var agent_radius: float = 0.6
@export var agent_height: float = 1.9

@export var rock_radius: float = 4.6
var region: NavigationRegion3D

func _ready() -> void:
	var nm := NavigationMesh.new()
	nm.agent_radius = agent_radius
	nm.agent_height = agent_height
	# 0.3 (not the 0.25 default): at 0.25 the denser village obstacles produced "More than 2 edges
	# tried to occupy the same map rasterization space" and a fragmented navmesh. The map must use the same cells.
	nm.cell_size = 0.3
	nm.cell_height = 0.3
	var map := get_world_3d().navigation_map
	NavigationServer3D.map_set_cell_size(map, nm.cell_size)
	NavigationServer3D.map_set_cell_height(map, nm.cell_height)
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = 1
	nm.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	# Only the playable valley needs navigation (not the rim hills or boundary walls).
	nm.filter_baking_aabb = AABB(Vector3(-95, -3, -95), Vector3(190, 30, 190))
	region = NavigationRegion3D.new()
	region.name = "NavRegion"
	region.navigation_mesh = nm
	add_child(region)
	# Re-parent level geometry under the region so it is parsed as source geometry.
	for c in get_children():
		if c != region and c is StaticBody3D and not String(c.name).begins_with("Wall") and not String(c.name).begins_with("Rock"):
			c.reparent(region)
	# Rocks are not parsed as walkable geometry (overlapping the terrain breaks the bake);
	# instead each carves a circular hole via a NavigationObstacle3D.
	for c in get_children():
		if String(c.name).begins_with("Rock") and c is Node3D:
			var ob := NavigationObstacle3D.new()
			ob.name = "Carve_" + String(c.name)
			ob.affect_navigation_mesh = true
			ob.carve_navigation_mesh = true
			ob.height = 6.0
			var pts := PackedVector3Array()
			for i in 12:
				var a := TAU * i / 12.0
				pts.append(Vector3(cos(a), 0.0, sin(a)) * rock_radius)
			ob.vertices = pts
			region.add_child(ob)
			ob.global_position = (c as Node3D).global_position
	# Village props that declare a "carve_radius" meta also carve holes (houses, stalls, trees...).
	var village := get_node_or_null("Village")
	if village:
		for c in village.get_children():
			if c is Node3D and c.has_meta("carve_radius"):
				var vob := NavigationObstacle3D.new()
				vob.name = "Carve_" + String(c.name)
				vob.affect_navigation_mesh = true
				vob.carve_navigation_mesh = true
				vob.height = 6.0
				var vr: float = c.get_meta("carve_radius")
				var vpts := PackedVector3Array()
				for i in 10:
					var va := TAU * i / 10.0
					vpts.append(Vector3(cos(va), 0.0, sin(va)) * vr)
				vob.vertices = vpts
				region.add_child(vob)
				vob.global_position = (c as Node3D).global_position
	region.bake_navigation_mesh(false)

class_name ArenaNav
extends Node3D
## Bakes a navigation mesh from the level's static colliders at load time and
## exposes it through a NavigationRegion3D, so enemies path around rocks and walls.

@export var agent_radius: float = 0.6
@export var agent_height: float = 1.9

var region: NavigationRegion3D

func _ready() -> void:
	var nm := NavigationMesh.new()
	nm.agent_radius = agent_radius
	nm.agent_height = agent_height
	nm.cell_size = 0.25
	nm.cell_height = 0.2
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = 1
	nm.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	region = NavigationRegion3D.new()
	region.name = "NavRegion"
	region.navigation_mesh = nm
	add_child(region)
	# Re-parent level geometry under the region so it is parsed as source geometry.
	for c in get_children():
		if c != region and (c is StaticBody3D or c.get_class() == "StaticBody3D"):
			c.reparent(region)
	region.bake_navigation_mesh(false)

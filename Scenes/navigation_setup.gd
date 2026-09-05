extends NavigationRegion2D

@export var platforms_node : Node2D
@export var floor_y : float = 181.0
@export var floor_width : float = 4000.0
@export var surface_height : float = 4.0

func _ready() -> void:
	call_deferred("_build_navigation_mesh")

func _build_navigation_mesh() -> void:
	var nav_poly = NavigationPolygon.new()
	var vertex_offset : int = 0

	nav_poly.add_outline(_make_rect(-floor_width / 2.0, floor_y, floor_width, surface_height))
	nav_poly.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	vertex_offset = 4

	if platforms_node:
		for child in platforms_node.get_children():
			if child is Node2D:
				var pos = child.global_position
				nav_poly.add_outline(_make_rect(pos.x - 100, pos.y - 10, 200, surface_height))
				nav_poly.add_polygon(PackedInt32Array([
					vertex_offset, vertex_offset + 1,
					vertex_offset + 2, vertex_offset + 3
				]))
				vertex_offset += 4

	navigation_polygon = nav_poly

func _make_rect(x : float, y : float, w : float, h : float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(x, y),
		Vector2(x + w, y),
		Vector2(x + w, y + h),
		Vector2(x, y + h)
	])

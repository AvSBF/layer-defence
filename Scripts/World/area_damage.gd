class_name AreaDamage
extends RefCounted

## Shape-query based AoE damage. Used by slams, bombs, death explosions and
## the hammer's ground pound - anything that hits everything in a radius.

static func explode(source : Node, pos : Vector2, radius : float, damage : float,
		friendly : bool, exclude : Node = null) -> Array:
	var hit_nodes : Array = []
	if source == null or not source.is_inside_tree():
		return hit_nodes
	var world : World2D = source.get_world_2d()
	if world == null:
		return hit_nodes
	var space : PhysicsDirectSpaceState2D = world.direct_space_state
	if space == null:
		return hit_nodes
	var shape := CircleShape2D.new()
	shape.radius = radius
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, pos)
	params.collision_mask = 4 if friendly else 2
	params.collide_with_areas = false
	params.collide_with_bodies = true
	if exclude != null and exclude is CollisionObject2D:
		params.exclude = [exclude.get_rid()]
	var results : Array = space.intersect_shape(params, 24)
	for r in results:
		var body : Node = r.get("collider")
		if body == null or hit_nodes.has(body):
			continue
		hit_nodes.append(body)
		if friendly:
			if body.has_method("take_damage"):
				var kb : Vector2 = (body.global_position - pos).normalized() * 260.0
				body.call("take_damage", damage, kb)
		elif body.is_in_group("player"):
			if body.has_method("take_damage"):
				var kb2 : Vector2 = (body.global_position - pos).normalized() * 220.0
				body.call("take_damage", damage, kb2)
	return hit_nodes

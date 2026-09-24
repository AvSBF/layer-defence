extends Node2D

## Aim helper drawn on the floor under the player: a soft wedge for melee
## weapons (exact reach + swing arc) and a dashed beam for ranged ones. Purely
## cosmetic, but it is the difference between "I think I can hit that" and
## "I know I can hit that".

const MELEE_COLOR := Color(0.55, 0.95, 1.0)
const RANGED_COLOR := Color(1.0, 0.86, 0.45)

var player : Player

func _ready() -> void:
	player = get_parent() as Player
	# drawn above the ground/hills but under the knight, so it never gets
	# swallowed by the parallax background
	z_index = 1
	z_as_relative = false
	queue_redraw()

func _process(_delta : float) -> void:
	queue_redraw()

func _draw() -> void:
	if player == null or not is_instance_valid(player) or player.is_dead:
		return
	if player.weapon.is_empty():
		return
	if GameState.health <= 0:
		return
	var aim : Vector2 = player.aim_direction()
	var range_stat : float = 1.0 + GameState.get_stat("range_mult")
	if str(player.weapon.get("kind", "melee")) == "melee":
		_draw_melee(aim, range_stat)
	else:
		_draw_ranged(aim)

func _draw_melee(aim : Vector2, range_stat : float) -> void:
	var reach : float = float(player.weapon.get("range", 40.0)) * range_stat
	var arc : float = deg_to_rad(float(player.weapon.get("arc", 110.0)))
	var base : float = aim.angle()
	var steps : int = 16
	# translucent wedge = the actual hit zone
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)
	for i in steps + 1:
		var a : float = base - arc * 0.5 + arc * (float(i) / float(steps))
		points.append(Vector2(cos(a), sin(a)) * reach)
	draw_colored_polygon(points, Color(MELEE_COLOR.r, MELEE_COLOR.g, MELEE_COLOR.b, 0.10))
	# outline arc + side edges
	draw_arc(Vector2.ZERO, reach, base - arc * 0.5, base + arc * 0.5, 26,
		Color(MELEE_COLOR.r, MELEE_COLOR.g, MELEE_COLOR.b, 0.42), 1.8, true)
	var side := Color(MELEE_COLOR.r, MELEE_COLOR.g, MELEE_COLOR.b, 0.24)
	draw_line(Vector2.ZERO, Vector2.from_angle(base - arc * 0.5) * reach, side, 1.0)
	draw_line(Vector2.ZERO, Vector2.from_angle(base + arc * 0.5) * reach, side, 1.0)
	# small tick right in front, so the "sweet spot" reads at a glance
	draw_circle(aim * reach, 2.2, Color(MELEE_COLOR.r, MELEE_COLOR.g, MELEE_COLOR.b, 0.6))

func _draw_ranged(aim : Vector2) -> void:
	var reach : float = minf(float(player.weapon.get("range", 400.0)), 300.0)
	var seg : float = 16.0
	var count : int = maxi(3, int(reach / seg))
	for i in count:
		var t0 : float = float(i) / float(count)
		var alpha : float = 0.34 * (1.0 - t0 * 0.75)
		draw_line(aim * seg * i, aim * seg * (i + 1),
			Color(RANGED_COLOR.r, RANGED_COLOR.g, RANGED_COLOR.b, alpha), 2.0)
	draw_arc(aim * reach, 5.0, 0.0, TAU, 14,
		Color(RANGED_COLOR.r, RANGED_COLOR.g, RANGED_COLOR.b, 0.24), 1.5, true)

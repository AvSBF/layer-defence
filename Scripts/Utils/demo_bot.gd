extends Node

## Attract-mode / smoke-test bot. Enabled with `godot -- --autotest`.
## It literally presses the same input actions a player would, so a headless
## run exercises the real gameplay code paths - a cheap way to catch runtime
## errors across waves, bosses, shop and drops.

var world : Node
var player : Node2D
var wave_manager : Node
var shop : Node

var _t : float = 0.0
var _holding : bool = false
var _jump_timer : float = 0.0
var _dash_timer : float = 0.0
var _shop_timer : float = 0.0
var _aim_angle : float = 0.0
var _debug_timer : float = 0.0

func setup(world_node : Node) -> void:
	world = world_node
	player = world.get_node_or_null("Player")
	wave_manager = world.get_node_or_null("WaveManager")
	shop = world.get_node_or_null("UI/Shop")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.action_press("attack")

func _process(delta : float) -> void:
	_t += delta
	_debug_timer += delta
	if player == null or not is_instance_valid(player):
		player = world.get_node_or_null("Player")
		if player == null:
			return
	_aim()
	if _debug_timer > 5.0:
		_debug_timer = 0.0
		print("[autotest] t=%.0f wave=%d state=%d hp=%d coins=%d enemies=%d" % [_t, GameState.wave,
			wave_manager.state, GameState.health, GameState.coins,
			get_tree().get_nodes_in_group("enemy").size()])
		for e in get_tree().get_nodes_in_group("enemy"):
			print("    ", e.type_id, " pos=", e.global_position, " hp=%.0f" % e.hp,
				" vel=", e.velocity, " attacking=", e.attacking, " dead=", e.is_dead,
				" player=", player.global_position)
	_handle_shop(delta)
	if wave_manager != null and wave_manager.is_between_waves():
		if wave_manager.can_start_wave():
			_wait_at_gate(delta)
		else:
			_collect_loot(delta)
		return
	_holding = false
	_move(delta)

## During the loot window / arena reshaping: chase the nearest pickup instead
## of standing at the gate.
func _collect_loot(delta : float) -> void:
	_holding = false
	var best : Node2D = null
	var best_d : float = 1e9
	for p in get_tree().get_nodes_in_group("pickup"):
		var d : float = p.global_position.distance_squared_to(player.global_position)
		if d < best_d:
			best_d = d
			best = p
	if best == null:
		_set_action("key_right", false)
		_set_action("key_left", false)
		return
	var dx : float = best.global_position.x - player.global_position.x
	_set_action("key_right", dx > 6.0)
	_set_action("key_left", dx < -6.0)
	_jump_timer -= delta
	if _jump_timer <= 0.0 and absf(dx) < 200.0:
		_jump_timer = 0.8
		_tap("jump")

# ------------------------------------------------------------------ behaviour
func _aim() -> void:
	var target := _closest_enemy()
	var aim := Vector2(1, 0)
	if target != null:
		aim = (target.global_position - player.global_position).normalized()
	_aim_angle = lerp_angle(_aim_angle, aim.angle(), 0.12)
	if "aim_override" in player:
		player.aim_override = Vector2.from_angle(_aim_angle)
	var vp := get_viewport()
	if vp != null:
		var want : Vector2 = player.global_position + Vector2.from_angle(_aim_angle) * 120.0
		vp.warp_mouse(vp.get_screen_transform().affine_inverse() * want)

func _move(delta : float) -> void:
	var dir : float = 1.0 if cos(_aim_angle) >= 0.0 else -1.0
	_set_action("key_right", dir > 0.0)
	_set_action("key_left", dir < 0.0)
	_jump_timer -= delta
	_dash_timer -= delta
	if _jump_timer <= 0.0:
		_jump_timer = randf_range(0.6, 1.6)
		_tap("jump")
	if _dash_timer <= 0.0:
		_dash_timer = randf_range(1.4, 2.8)
		_tap("dash")

## Walks to the green gate like a player would (no teleporting, so the physics
## overlap is genuinely earned) and then stands still until the wave starts.
func _wait_at_gate(delta : float) -> void:
	var gate := world.get_node_or_null("WaveGate")
	if gate == null:
		return
	var dx : float = gate.global_position.x - player.global_position.x
	var close : bool = absf(dx) < 8.0 and absf(gate.global_position.y - player.global_position.y) < 90.0
	if close:
		if not _holding:
			_holding = true
			print("[autotest] reached the gate at %.0f" % _t)
		_set_action("key_right", false)
		_set_action("key_left", false)
		return
	_holding = false
	_set_action("key_right", dx > 0.0)
	_set_action("key_left", dx < 0.0)
	_jump_timer -= delta
	if _jump_timer <= 0.0:
		_jump_timer = 0.5
		_tap("jump")
		_tap("key_down")

func _handle_shop(delta : float) -> void:
	if shop == null or not shop.visible:
		_shop_timer = 0.0
		return
	_shop_timer += delta
	if _shop_timer > 0.6 and _shop_timer < 0.9:
		shop.call("autobuy")
	if _shop_timer > 1.5:
		_shop_timer = 0.0
		shop.call("close")

func _closest_enemy() -> Node2D:
	var best : Node2D = null
	var best_d : float = 1e9
	for e in get_tree().get_nodes_in_group("enemy"):
		var d : float = e.global_position.distance_squared_to(player.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best

func _set_action(action : String, pressed : bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)

func _tap(action : String) -> void:
	Input.action_press(action)
	await get_tree().create_timer(0.12, true, false, true).timeout
	Input.action_release(action)

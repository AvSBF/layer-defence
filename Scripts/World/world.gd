class_name World
extends Node2D

## Wires the arena together: title -> run -> waves -> shop -> banners -> death.
## Keeps every UI node listening to the systems instead of the systems poking
## the UI directly.

@export var title_path : NodePath = ^"UI/Title"
@export var hud_path : NodePath = ^"UI/HUD"
@export var shop_path : NodePath = ^"UI/Shop"
@export var banner_path : NodePath = ^"UI/WaveBanner"
@export var wave_manager_path : NodePath = ^"WaveManager"
@export var camera_path : NodePath = ^"Camera2D"
@export var player_path : NodePath = ^"Player"

var title : Node
var hud : Node
var shop : Node
var banner : Node
var wave_manager : WaveManager
var camera : Node2D
var player : Player
var _run_active : bool = false

func _ready() -> void:
	player = get_node_or_null(player_path)
	wave_manager = get_node_or_null(wave_manager_path)
	camera = get_node_or_null(camera_path)
	title = get_node_or_null(title_path)
	hud = get_node_or_null(hud_path)
	shop = get_node_or_null(shop_path)
	banner = get_node_or_null(banner_path)

	if camera != null and player != null:
		camera.call("set_target", player)
	if title != null:
		title.connect("start_requested", Callable(self, "_on_start_requested"))
	if wave_manager != null:
		wave_manager.wave_started.connect(_on_wave_started)
		wave_manager.wave_cleared.connect(_on_wave_cleared)
		wave_manager.enemies_changed.connect(_on_enemies_changed)
		wave_manager.hint_changed.connect(_on_hint_changed)
		wave_manager.shop_requested.connect(_on_shop_requested)
	if shop != null:
		shop.connect("visibility_changed", Callable(self, "_on_shop_visibility"))
	if OS.get_cmdline_user_args().has("--autotest"):
		_start_autotest()

func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F10:
		# attract mode / demo bot toggle
		GameState.autotest = true
		if not _run_active and title != null and title.visible:
			title.call("_start")
		_start_bot()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact") and _run_active:
		if shop != null and not shop.call("is_open") and not get_tree().paused:
			shop.call("open")
			get_viewport().set_input_as_handled()

func _start_bot() -> void:
	if has_node("DemoBot"):
		return
	var bot_script : GDScript = load("res://Scripts/Utils/demo_bot.gd")
	var bot : Node = bot_script.new()
	bot.name = "DemoBot"
	add_child(bot)
	bot.call("setup", self)

func _start_autotest() -> void:
	GameState.autotest = true
	GameState.autotest_mortal = OS.get_cmdline_user_args().has("--mortal")
	print("[autotest] starting demo bot")
	_start_bot()
	var shot_interval := 0.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots"):
			shot_interval = 2.0
			if arg.contains("="):
				shot_interval = maxf(0.1, float(arg.split("=")[1]))
	if shot_interval > 0.0:
		_screenshot_loop(shot_interval)
	if OS.get_cmdline_user_args().has("--batcheck"):
		for i in 3:
			SpawnHelper.spawn_enemy(self, "bat", Vector2(-220.0 + i * 220.0, -150.0), 3, false)
	if OS.get_cmdline_user_args().has("--pots"):
		for i in 5:
			var x := -560.0 + i * 280.0
			Pot.spawn(self, Vector2(x, -200.0), 140.0, "chest" if i == 2 else "pot")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--aim="):
			match arg.split("=")[1]:
				"left": GameState.aim_lock = Vector2(-1, 0)
				"right": GameState.aim_lock = Vector2(1, 0)
				"up": GameState.aim_lock = Vector2(0, -1)
		if arg.begins_with("--weapon="):
			var wanted : String = arg.split("=")[1]
			if player != null:
				player.weapon_id = wanted
				player.call("equip", wanted)
	if title != null and title.visible:
		_dbg("pressing start")
		title.call("_start")
	else:
		_dbg("title missing or hidden: " + str(title))

## Autotest helper: grabs a series of frames so the visuals can be verified
## without a human at the keyboard.
func _screenshot_loop(interval : float = 2.0) -> void:
	var shot := 0
	while shot < 24:
		await get_tree().create_timer(interval, true, false, true).timeout
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		if img != null:
			img.save_png("user://shot_%02d.png" % shot)
			print("[autotest] saved screenshot %d" % shot)
		shot += 1

func _on_start_requested() -> void:
	_dbg("run started")
	_run_active = true
	Audio.play("wave_start", 0.0, -6.0)
	GameState.start_run()
	if GameState.autotest and OS.get_cmdline_user_args().has("--rich"):
		GameState.add_coins(600)   # test budget: exercised by the shop smoke test
	if wave_manager != null:
		wave_manager.start_run()

func _on_hint_changed(text : String, visible : bool) -> void:
	if hud != null:
		hud.call("set_hint", text, visible)

func _on_wave_cleared(_wave : int) -> void:
	pass

## Frame the sky portal while enemies are dropping: the camera leans slightly
## towards the portal (not just straight up), then settles back on the player.
func _process(_delta : float) -> void:
	if camera == null or wave_manager == null:
		return
	if wave_manager.state == WaveManager.State.SPAWNING:
		camera.call("set_look_offset", -90.0)
		var portal := get_node_or_null("Portal")
		if portal != null:
			camera.call("set_focus_point", portal.global_position)
	else:
		camera.call("set_look_offset", -50.0)
		camera.call("clear_focus")

func _on_wave_started(wave : int, is_boss : bool, info : Dictionary) -> void:
	if banner != null:
		banner.call("show_wave", info)
	if camera != null:
		camera.call("add_trauma", 0.25 if not is_boss else 0.6)

func _on_enemies_changed(alive : int, total : int) -> void:
	if hud != null:
		hud.call("set_enemies", alive, total)

func _on_shop_requested(_reason : String) -> void:
	if shop == null or banner == null:
		return
	if GameState.run_active and not shop.call("is_open"):
		shop.call("open")

func _on_shop_visibility() -> void:
	if hud == null or shop == null or wave_manager == null:
		return
	var open_now : bool = shop.visible
	_dbg("shop visibility -> open=%s, between_waves=%s" % [str(open_now), str(wave_manager.is_between_waves())])
	wave_manager.set_gate(not open_now and wave_manager.is_between_waves())
	if not open_now and wave_manager.can_start_wave():
		hud.call("set_hint", "STEP INTO THE GREEN GATE", true)

func _dbg(msg : String) -> void:
	if GameState.autotest:
		print("[autotest] ", msg)


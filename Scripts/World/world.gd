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
		wave_manager.shop_requested.connect(_on_shop_requested)
	if shop != null:
		shop.connect("visibility_changed", Callable(self, "_on_shop_visibility"))
	if OS.get_cmdline_user_args().has("--autotest"):
		_start_autotest()

func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_pressed("interact") and _run_active:
		if shop != null and not shop.call("is_open") and not get_tree().paused:
			shop.call("open")
			get_viewport().set_input_as_handled()

func _start_autotest() -> void:
	GameState.autotest = true
	GameState.autotest_mortal = OS.get_cmdline_user_args().has("--mortal")
	print("[autotest] starting demo bot")
	var bot_script : GDScript = load("res://Scripts/Utils/demo_bot.gd")
	var bot : Node = bot_script.new()
	bot.name = "DemoBot"
	add_child(bot)
	bot.call("setup", self)
	if OS.get_cmdline_user_args().has("--shots"):
		_screenshot_loop()
	if title != null and title.visible:
		_dbg("pressing start")
		title.call("_start")
	else:
		_dbg("title missing or hidden: " + str(title))

## Autotest helper: grabs a series of frames so the visuals can be verified
## without a human at the keyboard.
func _screenshot_loop() -> void:
	var shot := 0
	while shot < 24:
		await get_tree().create_timer(2.0, true, false, true).timeout
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
	if wave_manager != null:
		wave_manager.start_run()

func _on_wave_started(wave : int, is_boss : bool, info : Dictionary) -> void:
	if banner != null:
		banner.call("show_wave", info)
	if hud != null:
		hud.call("show_gate_hint", false)
	if camera != null:
		camera.call("add_trauma", 0.25 if not is_boss else 0.6)

func _on_wave_cleared(_wave : int) -> void:
	if hud != null:
		hud.call("show_gate_hint", true)

func _on_enemies_changed(alive : int, total : int) -> void:
	if hud != null:
		hud.call("set_enemies", alive, total)

func _on_shop_requested(_reason : String) -> void:
	if shop == null or banner == null:
		return
	if hud != null:
		hud.call("show_gate_hint", false)
	if GameState.run_active and not shop.call("is_open"):
		shop.call("open")

func _on_shop_visibility() -> void:
	if hud == null or shop == null or wave_manager == null:
		return
	var open_now : bool = shop.visible
	_dbg("shop visibility -> open=%s, between_waves=%s" % [str(open_now), str(wave_manager.is_between_waves())])
	wave_manager.set_gate(not open_now and wave_manager.is_between_waves())
	if not open_now and wave_manager.is_between_waves():
		hud.call("show_gate_hint", true)

func _dbg(msg : String) -> void:
	if GameState.autotest:
		print("[autotest] ", msg)


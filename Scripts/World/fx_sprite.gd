extends Node2D

## One-shot animated effect sprite. Sheets are looked up in ART_INFO so any
## system can request `FX.play("explosion", pos)` and never touch resources.

const ART := "res://Aseprites/Generated/"

const ART_INFO := {
	"hit": ["FX/hit.png", 16, 16, 18.0],
	"death": ["FX/death.png", 20, 20, 16.0],
	"explosion": ["FX/explosion.png", 36, 36, 16.0],
	"dust": ["FX/dust.png", 16, 16, 14.0],
	"dust_big": ["FX/dust_big.png", 16, 16, 13.0],
	"shockwave": ["FX/shockwave.png", 48, 24, 14.0],
	"teleport": ["FX/teleport.png", 24, 26, 16.0],
	"spawn": ["FX/spawn.png", 26, 26, 16.0],
	"heal": ["FX/heal.png", 16, 18, 12.0],
	"coin_pop": ["FX/coin_pop.png", 12, 12, 14.0],
	"freeze_spark": ["FX/freeze_spark.png", 18, 18, 14.0],
	"telegraph": ["FX/telegraph.png", 56, 20, 12.0],
	"slash_steel": ["FX/slash_steel.png", 36, 36, 20.0],
	"slash_gold": ["FX/slash_gold.png", 36, 36, 20.0],
	"slash_magic": ["FX/slash_magic.png", 36, 36, 20.0],
}

@export var anim_name : String = "hit"
@export var flip_h : bool = false
@export var fps : float = 0.0
@export var autofree : bool = true

@onready var anim : AnimatedSprite2D = $anim

func _ready() -> void:
	var info : Array = ART_INFO.get(anim_name, ART_INFO["hit"])
	var framerate : float = fps if fps > 0.0 else float(info[3])
	anim.sprite_frames = SheetAnim.build([
		SheetAnim.sheet(ART + str(info[0]), int(info[1]), int(info[2]), "play", framerate, false),
	])
	anim.flip_h = flip_h
	anim.play("play")
	anim.animation_finished.connect(_on_finished, CONNECT_ONE_SHOT)

func _on_finished() -> void:
	if autofree:
		queue_free()

class_name WeaponCatalog
extends RefCounted

## Weapons are the "class" of the run: a melee arc hitbox or a projectile
## emitter, plus a visual swing sheet. Stats are deliberately small numbers so
## damage readouts stay legible at pixel-art scale.

const ART := "res://Aseprites/Generated/Weapons/"

const WEAPONS := {
	"sword": {
		"name": "SWORD", "kind": "melee", "price": 0,
		"damage": 12.0, "cooldown": 0.40, "range": 40.0, "arc": 110.0,
		"knockback": 190.0, "desc": "RELIABLE ARC. NO FRILLS.",
		"swing_fps": 22.0, "hit_frame": 0.4, "slash": "slash_steel",
	},
	"dagger": {
		"name": "TWIN DAGGER", "kind": "melee", "price": 40,
		"damage": 7.0, "cooldown": 0.18, "range": 30.0, "arc": 80.0,
		"knockback": 70.0, "crit_bonus": 0.12, "desc": "FAST. INFERNO OF STABS.",
		"swing_fps": 30.0, "hit_frame": 0.35, "slash": "slash_steel",
	},
	"spear": {
		"name": "WAR SPEAR", "kind": "melee", "price": 45,
		"damage": 17.0, "cooldown": 0.56, "range": 62.0, "arc": 40.0,
		"knockback": 150.0, "pierce": true, "desc": "LONG THRUST. HITS EVERYTHING.",
		"swing_fps": 20.0, "hit_frame": 0.42, "slash": "slash_steel",
	},
	"hammer": {
		"name": "WAR HAMMER", "kind": "melee", "price": 55,
		"damage": 30.0, "cooldown": 0.95, "range": 48.0, "arc": 140.0,
		"knockback": 430.0, "stun": 0.55, "shake": 0.35, "desc": "SLOW. SPLITS THE GROUND.",
		"swing_fps": 16.0, "hit_frame": 0.45, "slash": "slash_gold",
	},
	"scythe": {
		"name": "BONE SCYTHE", "kind": "melee", "price": 60,
		"damage": 20.0, "cooldown": 0.62, "range": 56.0, "arc": 230.0,
		"knockback": 160.0, "lifesteal": 0.16, "desc": "WIDE SWEEP. DRINKS LIFE.",
		"swing_fps": 18.0, "hit_frame": 0.4, "slash": "slash_magic",
	},
	"bow": {
		"name": "HUNTER BOW", "kind": "ranged", "price": 50,
		"damage": 15.0, "cooldown": 0.46, "range": 520.0, "arc": 0.0,
		"knockback": 90.0, "projectile": "arrow", "projectile_speed": 760.0,
		"pierce_count": 0, "desc": "PIERCES THE ARENA.",
		"swing_fps": 20.0, "hit_frame": 0.5, "slash": "",
	},
	"staff": {
		"name": "ARCANE STAFF", "kind": "ranged", "price": 65,
		"damage": 11.0, "cooldown": 0.34, "range": 460.0, "arc": 0.0,
		"knockback": 60.0, "projectile": "orb", "projectile_speed": 520.0,
		"pierce_count": 2, "homing": 2.4, "desc": "HOMING ORBS. PIERCES TWICE.",
		"swing_fps": 20.0, "hit_frame": 0.45, "slash": "",
	},
}

static func get_weapon(id : String) -> Dictionary:
	return WEAPONS.get(id, WEAPONS["sword"]).duplicate(true)

static func all_ids() -> Array:
	return WEAPONS.keys()

static func swing_path(id : String) -> String:
	return ART + id + "_swing.png"

static func icon_path(id : String) -> String:
	return ART + "icon_" + id + ".png"

static func anim_specs(id : String) -> Array:
	var w := get_weapon(id)
	var fps := float(w.get("swing_fps", 20.0))
	return [SheetAnim.sheet(swing_path(id), 40, 40, "swing", fps, false)]

class_name UpgradeCatalog
extends RefCounted

## Shop pool. Each entry is pure data: an effect dictionary that GameState
## accumulates into the run's stat block, plus presentation for the UI card.

const ICONS := "res://Aseprites/Generated/UI/icons/"

const UPGRADES := [
	{"id": "damage", "name": "SHARP BLADES", "desc": "+15% DAMAGE", "icon": "damage",
	 "cost": 14, "max": 6, "rarity": 0, "effects": {"damage_mult": 0.15}},
	{"id": "attack_speed", "name": "SWIFT STRIKES", "desc": "+12% ATTACK SPEED", "icon": "attack_speed",
	 "cost": 15, "max": 6, "rarity": 0, "effects": {"attack_speed_mult": 0.12}},
	{"id": "speed", "name": "WIND BOOTS", "desc": "+8% MOVE SPEED", "icon": "speed",
	 "cost": 12, "max": 5, "rarity": 0, "effects": {"move_speed_mult": 0.08}},
	{"id": "vitality", "name": "VITALITY", "desc": "+1 MAX HEART, HEAL 1", "icon": "health",
	 "cost": 18, "max": 6, "rarity": 0, "effects": {"max_hp_bonus": 1.0}, "special": "heal_2"},
	{"id": "crit", "name": "KEEN EYE", "desc": "+8% CRIT CHANCE", "icon": "crit",
	 "cost": 16, "max": 5, "rarity": 1, "effects": {"crit_chance": 0.08}},
	{"id": "crit_power", "name": "EXECUTIONER", "desc": "+35% CRIT DAMAGE", "icon": "crit",
	 "cost": 20, "max": 4, "rarity": 1, "effects": {"crit_mult": 0.35}},
	{"id": "lifesteal", "name": "VAMPIRISM", "desc": "+6% LIFESTEAL", "icon": "lifesteal",
	 "cost": 22, "max": 4, "rarity": 1, "effects": {"lifesteal": 0.06}},
	{"id": "magnet", "name": "LOOT MAGNET", "desc": "+45 PICKUP RADIUS", "icon": "magnet",
	 "cost": 12, "max": 4, "rarity": 0, "effects": {"magnet_radius": 45.0}},
	{"id": "armor", "name": "THICK HIDE", "desc": "-12% DAMAGE TAKEN", "icon": "armor",
	 "cost": 24, "max": 4, "rarity": 1, "effects": {"damage_reduction": 0.12}},
	{"id": "greed", "name": "GREED", "desc": "+25% COINS DROPPED", "icon": "coin",
	 "cost": 14, "max": 4, "rarity": 0, "effects": {"coin_mult": 0.25}},
	{"id": "dash", "name": "SHADOW STEP", "desc": "-22% DASH COOLDOWN", "icon": "dash",
	 "cost": 16, "max": 4, "rarity": 0, "effects": {"dash_cooldown_mult": -0.22}},
	{"id": "dash_charge", "name": "PHANTOM CHARGE", "desc": "+1 DASH CHARGE", "icon": "dash",
	 "cost": 32, "max": 2, "rarity": 2, "effects": {"dash_charges": 1.0}},
	{"id": "jump", "name": "FEATHER FALL", "desc": "+1 JUMP, +8% JUMP HEIGHT", "icon": "speed",
	 "cost": 28, "max": 2, "rarity": 1, "effects": {"extra_jumps": 1.0, "jump_mult": 0.08}},
	{"id": "reach", "name": "LONG REACH", "desc": "+18% WEAPON RANGE", "icon": "damage",
	 "cost": 18, "max": 4, "rarity": 1, "effects": {"range_mult": 0.18}},
	{"id": "knockback", "name": "WRATH", "desc": "+30% KNOCKBACK + 6% DAMAGE", "icon": "damage",
	 "cost": 15, "max": 4, "rarity": 0, "effects": {"knockback_mult": 0.30, "damage_mult": 0.06}},
	{"id": "pierce", "name": "PIERCING SHOT", "desc": "+1 PROJECTILE PIERCE", "icon": "weapon",
	 "cost": 26, "max": 3, "rarity": 1, "effects": {"pierce_bonus": 1.0}},
	{"id": "multishot", "name": "MULTISHOT", "desc": "+1 PROJECTILE", "icon": "weapon",
	 "cost": 34, "max": 3, "rarity": 2, "effects": {"projectile_bonus": 1.0}},
	{"id": "shield", "name": "ELVEN WARD", "desc": "BLOCK FIRST HIT EACH WAVE", "icon": "shield",
	 "cost": 30, "max": 1, "rarity": 2, "effects": {}, "special": "shield"},
	{"id": "revive", "name": "SECOND WIND", "desc": "REVIVE ONCE WITH 2 HEARTS", "icon": "health",
	 "cost": 45, "max": 1, "rarity": 2, "effects": {"revives": 1.0}},
	{"id": "heal", "name": "HEALING DRAUGHT", "desc": "RESTORE 3 HEARTS", "icon": "potion",
	 "cost": 14, "max": 99, "rarity": 0, "effects": {}, "special": "heal_3"},
	{"id": "feast", "name": "FULL FEAST", "desc": "HEAL TO FULL", "icon": "potion",
	 "cost": 30, "max": 99, "rarity": 1, "effects": {}, "special": "heal_full"},
	{"id": "pickup", "name": "SOUL HARVEST", "desc": "PICKUPS HEAL 1 HEART", "icon": "heal",
	 "cost": 28, "max": 1, "rarity": 2, "effects": {"pickup_heal": 1.0}},
]

const RARITY_COLORS := [
	Color("#8fa2c0"),
	Color("#6fa8ff"),
	Color("#e0a2ff"),
]

static func all() -> Array:
	return UPGRADES

static func get_upgrade(id : String) -> Dictionary:
	for u in UPGRADES:
		if u["id"] == id:
			return u
	return UPGRADES[0]

static func rarity_color(rarity : int) -> Color:
	return RARITY_COLORS[clampi(rarity, 0, RARITY_COLORS.size() - 1)]

static func icon_path(icon : String) -> String:
	return ICONS + icon + ".png"

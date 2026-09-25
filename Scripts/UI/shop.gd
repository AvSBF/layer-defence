extends CanvasLayer

## Between-wave upgrade shop. Offers 3 random upgrades (sometimes a weapon),
## paid for with the coins that just dropped out of the mobs. The tree is
## paused while it is open, so the arena freezes behind the panel.

const CARDS := 3

var _root : Control
var _cards_box : HBoxContainer
var _coins_label : Label
var _title : Label
var _subtitle : Label
var _reroll_btn : Button
var _continue_btn : Button
var _offers : Array = []
var _card_nodes : Array = []
var _is_open : bool = false

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	GameState.coins_changed.connect(_on_coins_changed)
	hide()

# ------------------------------------------------------------------- building
func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = PixelUI.theme()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.03, 0.08, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var panel := PixelUI.panel()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(940, 470)
	panel.position = Vector2(-470, -235)
	panel.pivot_offset = Vector2(470, 235)
	_root.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 16)
	col.add_child(header)
	_title = PixelUI.label("UPGRADES", PixelUI.HUGE, PixelUI.COL_GOLD)
	header.add_child(_title)
	var coin_row := HBoxContainer.new()
	coin_row.add_theme_constant_override("separation", 6)
	header.add_child(coin_row)
	coin_row.add_child(PixelUI.icon_rect("coin", 32))
	_coins_label = PixelUI.label("0", PixelUI.LARGE, PixelUI.COL_GOLD)
	coin_row.add_child(_coins_label)

	_subtitle = PixelUI.label("SPEND COINS ON PERMANENT DEATH-DEFYING POWER", PixelUI.SMALL, PixelUI.COL_DIM)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_subtitle)

	_cards_box = HBoxContainer.new()
	_cards_box.add_theme_constant_override("separation", 14)
	_cards_box.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(_cards_box)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 18)
	col.add_child(footer)
	_reroll_btn = PixelUI.button("REROLL", PixelUI.SMALL)
	_reroll_btn.pressed.connect(_on_reroll)
	footer.add_child(_reroll_btn)
	_continue_btn = PixelUI.button("CONTINUE", PixelUI.NORMAL)
	_continue_btn.pressed.connect(close)
	footer.add_child(_continue_btn)

	var hint_row := HBoxContainer.new()
	hint_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hint_row.add_theme_constant_override("separation", 6)
	col.add_child(hint_row)
	hint_row.add_child(PixelUI.keycap("TAB"))
	var hint1 := PixelUI.label("SHOP", PixelUI.SMALL, PixelUI.COL_DIM)
	hint1.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_row.add_child(hint1)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(16, 0)
	hint_row.add_child(gap)
	hint_row.add_child(PixelUI.keycap("ESC"))
	var hint2 := PixelUI.label("CONTINUE", PixelUI.SMALL, PixelUI.COL_DIM)
	hint2.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_row.add_child(hint2)

func _input(event : InputEvent) -> void:
	if event.is_action_pressed("pause") and _is_open:
		close()
		get_viewport().set_input_as_handled()

# ------------------------------------------------------------------- open/close
func open() -> void:
	if _is_open:
		return
	_is_open = true
	show()
	get_tree().paused = true
	_root.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_root, "modulate:a", 1.0, 0.25)
	_title.text = "WAVE %d CLEARED" % GameState.wave
	_generate_offers()
	_populate()
	Audio.play("level_up", 0.05, -2.0)
	if GameState.autotest:
		print("[autotest] shop opened (coins=%d)" % GameState.coins)

func close() -> void:
	if not _is_open:
		return
	_is_open = false
	Audio.play("click", 0.0, -2.0)
	get_tree().paused = false
	hide()
	_root.modulate.a = 0.0

func toggle() -> void:
	if _is_open:
		close()
	else:
		open()

func is_open() -> bool:
	return _is_open

# ------------------------------------------------------------------- offering
func _generate_offers() -> void:
	_offers.clear()
	var pool := UpgradeCatalog.all().duplicate()
	pool.shuffle()
	# weapon offer chance - tempt the player with new toys
	var want_weapon := randf() < 0.45
	if want_weapon:
		var choices : Array = []
		for id in WeaponCatalog.all_ids():
			if id != str(GameState.player.weapon_id if GameState.player != null else ""):
				choices.append(id)
		if not choices.is_empty():
			_offers.append({"type": "weapon", "id": choices.pick_random()})
	for u in pool:
		if _offers.size() >= CARDS:
			break
		var up : Dictionary = u
		if GameState.can_take_upgrade(up):
			_offers.append({"type": "upgrade", "id": up["id"]})
	while _offers.size() < CARDS:
		_offers.append({"type": "upgrade", "id": "heal"})

func _populate() -> void:
	for n in _card_nodes:
		n.queue_free()
	_card_nodes.clear()
	for i in _offers.size():
		var card := _build_card(_offers[i], i)
		_cards_box.add_child(card)
		_card_nodes.append(card)
	# refresh *after* the cards exist, otherwise prices never leave their
	# construction defaults
	_refresh_coins()

func _build_card(offer : Dictionary, index : int) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(272, 300)
	var panel := PixelUI.card()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	# "sold" cards keep showing what they were, not whatever id happens to
	# resolve next
	var is_weapon : bool = str(offer.get("was", offer["type"])) == "weapon"
	var data : Dictionary
	if is_weapon:
		data = WeaponCatalog.get_weapon(offer["id"])
	else:
		data = UpgradeCatalog.get_upgrade(offer["id"])

	var rarity := 0
	if is_weapon:
		rarity = 1
	else:
		rarity = int(data.get("rarity", 0))
	var accent := UpgradeCatalog.rarity_color(rarity)

	var title := PixelUI.label(str(data.get("name", "?")), PixelUI.NORMAL, accent)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)

	var icon_row := CenterContainer.new()
	box.add_child(icon_row)
	var icon := TextureRect.new()
	icon.texture = load(WeaponCatalog.icon_path(offer["id"])) if is_weapon else PixelUI.icon(str(data.get("icon", "damage")))
	icon.custom_minimum_size = Vector2(72, 72)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_row.add_child(icon)

	var desc_text : String = str(data.get("desc", ""))
	if is_weapon:
		var wdata := WeaponCatalog.get_weapon(offer["id"])
		var kind : String = "RANGED" if str(wdata.get("kind", "melee")) == "ranged" else "MELEE"
		desc_text = "%s  %d DMG  %s" % [kind, int(round(float(wdata.get("damage", 0.0)))), desc_text]
	else:
		var lvl := GameState.upgrade_level(offer["id"])
		if lvl > 0:
			desc_text += "   [LV %d]" % lvl
	var desc := PixelUI.label(desc_text, PixelUI.SMALL, PixelUI.COL_DIM)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(240, 60)
	box.add_child(desc)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	# --- explicit price row: the cost must be readable *before* buying, so it
	# lives on the card and not inside the button label
	var price_row := HBoxContainer.new()
	price_row.name = "PriceRow"
	price_row.alignment = BoxContainer.ALIGNMENT_CENTER
	price_row.add_theme_constant_override("separation", 6)
	box.add_child(price_row)
	var coin_icon := PixelUI.icon_rect("coin", 20)
	coin_icon.name = "PriceCoin"
	price_row.add_child(coin_icon)
	var price_label := PixelUI.label("0", PixelUI.NORMAL, PixelUI.COL_GOLD)
	price_label.name = "PriceLabel"
	price_label.custom_minimum_size = Vector2(56, 0)
	price_row.add_child(price_label)

	var cost_text := "EQUIP" if is_weapon else "BUY"
	var buy := PixelUI.button(cost_text, PixelUI.SMALL)
	buy.name = "BuyButton"
	buy.set_meta("offer", offer)
	buy.pressed.connect(func(): _buy(index))
	box.add_child(buy)

	# entrance animation: staggered pop-in
	holder.modulate.a = 0.0
	holder.scale = Vector2(0.85, 0.85)
	holder.pivot_offset = Vector2(136, 150)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(holder, "modulate:a", 1.0, 0.22).set_delay(index * 0.08)
	t.tween_property(holder, "scale", Vector2.ONE, 0.35).set_delay(index * 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# hover animation
	holder.mouse_entered.connect(func(): _animate_card(holder, Vector2.ONE * 1.05))
	holder.mouse_exited.connect(func(): _animate_card(holder, Vector2.ONE))
	return holder

func _animate_card(card : Control, target : Vector2) -> void:
	var t := create_tween()
	t.tween_property(card, "scale", target, 0.12)

func _buy(index : int) -> void:
	if index < 0 or index >= _offers.size():
		return
	var offer : Dictionary = _offers[index]
	if offer["type"] == "sold":
		return
	var cost : int = _cost_of(offer)
	# cost 0 still has to go through (re-equipping an owned weapon is free) -
	# GameState.spend(0) reports false, so it is handled explicitly here
	if cost > 0:
		if GameState.coins < cost:
			GameState.spend(cost)  # plays the "NOT ENOUGH COINS" feedback
			_shake_card(index)
			return
		if not GameState.spend(cost):
			return
	if offer["type"] == "weapon":
		if GameState.player != null and is_instance_valid(GameState.player):
			if str(GameState.player.weapon_id) == str(offer["id"]):
				return  # already in hand
			GameState.player.equip(offer["id"])
		GameState.mark_weapon_owned(offer["id"])
		Audio.play("buy", 0.05, 2.0)
	else:
		var up := UpgradeCatalog.get_upgrade(offer["id"])
		GameState.apply_upgrade(up)
		Audio.play("buy")
	FX.flash(Color("#ffd34d"), 0.12)
	# card becomes SOLD (remembering what it was, for the card face)
	_offers[index] = {"type": "sold", "id": offer["id"], "was": offer["type"]}
	_repopulate_card(index)
	_refresh_coins()
	Audio.play("coin", 0.05, -2.0)
	_flash_card(index)

## Little "no" wiggle for a card the player cannot afford yet.
func _shake_card(index : int) -> void:
	if index >= _card_nodes.size():
		return
	var card : Node = _card_nodes[index]
	if not is_instance_valid(card) or not (card is Control):
		return
	var c := card as Control
	var base := c.position
	var t := create_tween()
	for i in 3:
		t.tween_property(c, "position:x", base.x + (6.0 if i % 2 == 0 else -6.0), 0.05)
	t.tween_property(c, "position:x", base.x, 0.05)

## Little pop on the card that was just bought.
func _flash_card(index : int) -> void:
	if index >= _card_nodes.size():
		return
	var card : Node = _card_nodes[index]
	if not is_instance_valid(card):
		return
	var t := create_tween()
	card.scale = Vector2(1.08, 1.08)
	t.tween_property(card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _cost_of(offer : Dictionary) -> int:
	if offer["type"] == "weapon":
		if GameState.weapon_owned(offer["id"]):
			return 0
		return int(WeaponCatalog.get_weapon(offer["id"]).get("price", 50))
	if offer["type"] == "upgrade":
		return GameState.upgrade_cost(UpgradeCatalog.get_upgrade(offer["id"]))
	return 0

func _repopulate_card(index : int) -> void:
	if index >= _card_nodes.size():
		return
	_card_nodes[index].queue_free()
	var card := _build_card(_offers[index], index)
	_cards_box.add_child(card)
	_cards_box.move_child(card, index)
	_card_nodes[index] = card

## Used by the demo bot / attract mode: weapons first (that also keeps the
## EQUIP path exercised on every smoke test), then whatever is affordable.
func autobuy() -> void:
	for wanted in ["weapon", "upgrade"]:
		for i in _offers.size():
			var offer : Dictionary = _offers[i]
			if offer["type"] != wanted:
				continue
			if GameState.coins >= _cost_of(offer):
				_buy(i)
				return

func _on_reroll() -> void:
	var cost := 4 + GameState.shop_rerolls * 3
	if not GameState.spend(cost):
		return
	GameState.shop_rerolls += 1
	Audio.play("reroll")
	_generate_offers()
	_populate()
	_update_reroll_label()

func _update_reroll_label() -> void:
	var cost := 4 + GameState.shop_rerolls * 3
	_reroll_btn.text = "REROLL  %d" % cost

func _refresh_coins() -> void:
	_coins_label.text = str(GameState.coins)
	_update_reroll_label()
	for i in _card_nodes.size():
		var card : Node = _card_nodes[i]
		if not is_instance_valid(card):
			continue
		var offer : Dictionary = _offers[i]
		var btn : Button = null
		var found := card.find_child("BuyButton", true, false)
		if found is Button:
			btn = found
		if btn == null:
			continue
		var price_label : Label = null
		var price_found := card.find_child("PriceLabel", true, false)
		if price_found is Label:
			price_label = price_found
		var price_row : Control = null
		var row_found := card.find_child("PriceRow", true, false)
		if row_found is Control:
			price_row = row_found
		if offer["type"] == "sold":
			btn.text = "SOLD"
			btn.disabled = true
			if price_row != null:
				price_row.visible = false
			continue
		var cost := _cost_of(offer)
		# never hard-disable: a click on an unaffordable card must explain
		# itself ("NOT ENOUGH COINS") instead of doing nothing
		var affordable : bool = GameState.coins >= cost
		btn.modulate = Color.WHITE if affordable else Color(0.55, 0.55, 0.65)
		if price_row != null:
			price_row.visible = true
		if price_label != null:
			if cost <= 0:
				price_label.text = "FREE"
				price_label.add_theme_color_override("font_color", PixelUI.COL_GOOD)
			else:
				price_label.text = str(cost)
				price_label.add_theme_color_override("font_color",
					PixelUI.COL_GOLD if affordable else Color(1.0, 0.5, 0.45))
		if offer["type"] == "weapon":
			var equipped_now : bool = (GameState.player != null
				and is_instance_valid(GameState.player)
				and str(GameState.player.weapon_id) == str(offer["id"]))
			if equipped_now:
				btn.text = "EQUIPPED"
				btn.modulate = Color(0.75, 1.0, 0.85)
			else:
				btn.text = "EQUIP"
		else:
			btn.text = "BUY"

func _on_coins_changed(_total : int, _delta : int) -> void:
	if _is_open:
		_refresh_coins()

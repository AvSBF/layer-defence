class_name SheetAnim
extends RefCounted

## Builds SpriteFrames from horizontally stripped pixel-art sheets.
## Every animation sheet exported by Tools/artgen is a 1-row strip, so slicing
## is just `frames = texture.width / frame_width`.

static func build(specs : Array) -> SpriteFrames:
	var sf := SpriteFrames.new()
	for anim_name in sf.get_animation_names():
		sf.remove_animation(anim_name)
	for spec in specs:
		add(sf, spec)
	return sf


static func add(sf : SpriteFrames, spec : Dictionary) -> void:
	var anim_name : String = spec.get("name", "default")
	var path : String = spec.get("path", "")
	var fw : int = int(spec.get("fw", 16))
	var fh : int = int(spec.get("fh", 16))
	var fps : float = float(spec.get("fps", 8.0))
	var loop : bool = bool(spec.get("loop", true))
	if not ResourceLoader.exists(path):
		push_warning("[SheetAnim] missing sheet: " + path)
		return
	var tex : Texture2D = load(path)
	if tex == null:
		push_warning("[SheetAnim] could not load sheet: " + path)
		return
	var count : int = max(1, int(tex.get_width() / float(fw)))
	if not sf.has_animation(anim_name):
		sf.add_animation(anim_name)
	sf.set_animation_speed(anim_name, fps)
	sf.set_animation_loop(anim_name, loop)
	for i in count:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * fw, 0, fw, fh)
		sf.add_frame(anim_name, at, 1.0, i)
	if count == 1:
		# single frame sheets still need a frame
		if sf.get_frame_count(anim_name) == 0:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(0, 0, fw, fh)
			sf.add_frame(anim_name, at)


static func sheet(path : String, fw : int, fh : int, anim_name : String, fps : float, loop : bool = true) -> Dictionary:
	return {"name": anim_name, "path": path, "fw": fw, "fh": fh, "fps": fps, "loop": loop}

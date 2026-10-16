class_name Wizard
extends Actor
## A player's wizard. Face buttons conjure elements, triggers and RB cast them.
##
##   A Life / Void     B Fire / Frost     X Water / Lightning   Y Earth / Air
##   (hold LB for the second of each pair, its opposite)
##   RT  cast ahead (hold for sprays, beams and arcs, release to throw)
##   LT  burst around you            RB  plant on the ground ahead
##   RS click or D-pad down  ward yourself
##   D-pad up  conjure your last spell again
##   D-pad left / right  tap to conjure a saved spell, hold to save the queue
##   LS click  dash

const REVIVE_NEED := 40.0
const DASH_COOLDOWN := 1.4
const SAVE_HOLD := 0.6

var player_name := "Wizard"
var robe := Color(0.6, 0.15, 0.15)
var pad: Pad
var queue := SpellQueue.new()
var aim_dir := Vector3.FORWARD
var relics: Array = []
var saved := {Pad.LEFT: [], Pad.RIGHT: []}
var last_cast: Array = []
var bot: Bot

var channel: SpellFx
var _channel_button := -1
var _charging := {}
var _charge_t := 0.0
var _dash_cd := 0.0
var _save_t := {}
var _revive := 0.0
var _swing_t := 0.0
var _cast_anim := 0.0
var _walk := 0.0

var model: Dictionary
var _orbs: Array[MeshInstance3D] = []
var _label: Label3D
var _name_label: Label3D
var _light: OmniLight3D
var _ward_shell: MeshInstance3D
var _tomb: Node3D
var _charge_ring: MeshInstance3D
var _ring: MeshInstance3D


func _ready() -> void:
	team = 0
	max_hp = 100.0 + float(_mod("hp", 0.0))
	hp = max_hp
	radius = 0.45
	speed = 5.2
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = radius
	cap.height = 1.6
	shape.shape = cap
	shape.position = Vector3.UP * 0.8
	add_child(shape)
	model = Art.wizard(robe)
	add_child(model.root)
	meshes = model.meshes
	setup_status_fx()
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.82, 0.6)
	_light.light_energy = 1.6
	_light.omni_range = 9.0
	_light.omni_attenuation = 1.0
	_light.position = Vector3(0, 2.6, 0)
	_light.shadow_enabled = false
	add_child(_light)
	# A ring on the ground in the player's colour, so you find yourself.
	_ring = MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.55
	tor.outer_radius = 0.66
	tor.rings = 28
	tor.ring_segments = 4
	_ring.mesh = tor
	_ring.material_override = Fx.glow(robe.lightened(0.25), 1.6)
	_ring.scale = Vector3(1, 0.05, 1)
	_ring.position.y = 0.04
	add_child(_ring)
	for i in 6:
		var o := Art.part(self, Art.sphere(0.12, 8), Fx.glow(Color.WHITE, 3.0))
		o.visible = false
		o.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_orbs.append(o)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.font = Art.title_font()
	_label.font_size = 44
	_label.outline_size = 12
	_label.outline_modulate = Color(0, 0, 0, 0.9)
	_label.pixel_size = 0.006
	_label.position = Vector3(0, 2.75, 0)
	add_child(_label)
	_name_label = Label3D.new()
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.no_depth_test = true
	_name_label.font = Art.body_font()
	_name_label.font_size = 34
	_name_label.outline_size = 10
	_name_label.outline_modulate = Color(0, 0, 0, 0.9)
	_name_label.modulate = robe.lightened(0.4)
	_name_label.pixel_size = 0.006
	_name_label.position = Vector3(0, -0.35, 0.6)
	_name_label.text = player_name
	add_child(_name_label)
	_ward_shell = MeshInstance3D.new()
	_ward_shell.mesh = Art.sphere(1.0, 16)
	_ward_shell.position = Vector3.UP * 0.9
	_ward_shell.visible = false
	_ward_shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ward_shell)
	_charge_ring = MeshInstance3D.new()
	_charge_ring.mesh = tor
	_charge_ring.position.y = 0.06
	_charge_ring.visible = false
	add_child(_charge_ring)


func _mod(key: String, default: Variant = 1.0) -> Variant:
	var v = default
	for r in relics:
		if r.has(key):
			if typeof(v) == TYPE_BOOL or typeof(r[key]) == TYPE_BOOL:
				v = r[key]
			elif typeof(default) == TYPE_FLOAT and default == 0.0:
				v += r[key]
			else:
				v *= r[key]
	return v


func mods() -> Dictionary:
	var m := {}
	for r in relics:
		for k in r:
			if k in ["name", "text", "icon"]:
				continue
			if typeof(r[k]) == TYPE_BOOL:
				m[k] = r[k]
			elif k in ["hp", "hops", "slots"]:
				m[k] = m.get(k, 0) + r[k]
			else:
				m[k] = m.get(k, 1.0) * r[k]
	return m


func reset_relics() -> void:
	relics.clear()
	give_relic({})
	relics.clear()


func give_relic(r: Dictionary) -> void:
	if not r.is_empty():
		relics.append(r)
	speed = 5.2 * float(_mod("speed", 1.0))
	var old := max_hp
	max_hp = 100.0 + float(_mod("hp", 0.0))
	hp += max_hp - old
	queue.size = SpellQueue.SIZE + int(_mod("slots", 0.0))


func staff_tip() -> Vector3:
	return model.gem.global_position if model else global_position + Vector3.UP * 1.6


func holding(fx: SpellFx) -> bool:
	return channel == fx and _channel_button != -1 and pad.down(_channel_button) and alive


func _physics_process(dt: float) -> void:
	tick_status(dt)
	if bot:
		bot.think(self, dt)
	elif pad:
		if pad.source == Pad.Source.KEYBOARD and Game.I and Game.I.camera:
			pad.mouse_origin = Game.I.camera.unproject_position(global_position + Vector3.UP)
		pad.poll()
	_dash_cd = maxf(0.0, _dash_cd - dt)
	_swing_t = maxf(0.0, _swing_t - dt)
	_cast_anim = maxf(0.0, _cast_anim - dt)
	if not alive:
		drive(Vector3.ZERO, dt)
		return
	if Game.I and Game.I.paused_play:
		drive(Vector3.ZERO, dt)
		_visuals(dt)
		return
	_read_input(dt)
	var mv := Vector3(pad.move.x, 0, pad.move.y)
	var spd := move_speed()
	if channel and is_instance_valid(channel) and channel.is_physics_processing():
		spd *= 0.55
	elif not _charging.is_empty():
		spd *= 0.6
	drive(mv * spd, dt)
	_visuals(dt)


func _read_input(dt: float) -> void:
	if pad.aim.length() > 0.3:
		aim_dir = Vector3(pad.aim.x, 0, pad.aim.y).normalized()
	elif pad.move.length() > 0.3 and (channel == null or not is_instance_valid(channel)) and _charging.is_empty():
		aim_dir = Vector3(pad.move.x, 0, pad.move.y).normalized()
	if not can_act():
		_charging = {}
		return
	var flip := pad.down(Pad.LB)
	for b in [Pad.A, Pad.B, Pad.X, Pad.Y]:
		if pad.pressed(b):
			conjure(El.PAIRS[["A", "B", "X", "Y"][b]][1 if flip else 0])
	# Projectiles charge while RT is held and fly on release.
	if not _charging.is_empty():
		_charge_t += dt
		if pad.released(Pad.RT):
			_throw()
	if pad.pressed(Pad.RT):
		cast("cast", Pad.RT)
	if pad.pressed(Pad.LT):
		cast("nova", Pad.LT)
	if pad.pressed(Pad.RB):
		cast("plant", Pad.RB)
	if pad.pressed(Pad.RS) or pad.pressed(Pad.DOWN):
		cast("ward", -1)
	if pad.pressed(Pad.UP) and not last_cast.is_empty():
		queue.set_slots(last_cast)
		_conjure_fx()
	for b in [Pad.LEFT, Pad.RIGHT]:
		if pad.down(b):
			_save_t[b] = _save_t.get(b, 0.0) + dt
			if _save_t[b] >= SAVE_HOLD and _save_t[b] - dt < SAVE_HOLD and not queue.is_empty():
				saved[b] = queue.copy()
				Fx.text(global_position + Vector3.UP * 3.2, "Saved: " + preview("cast").name, Color(1, 0.85, 0.4), 40)
		elif pad.released(b):
			if _save_t.get(b, 0.0) < SAVE_HOLD and not saved[b].is_empty():
				queue.set_slots(saved[b])
				_conjure_fx()
			_save_t[b] = 0.0
	if pad.pressed(Pad.LS) and _dash_cd <= 0.0:
		_dash_cd = DASH_COOLDOWN
		var d := Vector3(pad.move.x, 0, pad.move.y)
		if d.length() < 0.2:
			d = aim_dir
		push += d.normalized() * 15.0
		Fx.puff(global_position + Vector3.UP * 0.4, Color(0.6, 0.6, 0.65, 0.5), 0.8)


func conjure(e: int) -> void:
	var what := queue.add(e)
	var c: Color = El.COLOR[e]
	match what:
		"cancel":
			Fx.burst(global_position + Vector3.UP * 1.9, c, 8, 2.0, 0.2)
		"fuse":
			Fx.burst(global_position + Vector3.UP * 1.9, c, 12, 2.5, 0.25)
	_conjure_fx()


func _conjure_fx() -> void:
	pass


func preview(form: String) -> Dictionary:
	return Grammar.compose(queue.copy(), form, mods())


## Cast what is queued in [param form]. [param button] is held to channel.
func cast(form: String, button: int) -> void:
	if channel and is_instance_valid(channel) and channel.is_physics_processing():
		return
	if not _charging.is_empty():
		return
	var s := preview(form)
	if s.shape == "fizzle":
		return
	if not queue.is_empty():
		last_cast = queue.copy()
	queue.clear()
	_cast_anim = 0.3
	if Game.I:
		Game.I.on_cast(self, s)
	var tip := staff_tip()
	var ahead := global_position + aim_dir * 2.2
	match s.shape:
		"spray":
			_channel(SprayFx.new().setup(self, s), button, tip)
		"beam":
			_channel(BeamFx.new().setup(self, s), button, tip)
		"arc":
			_channel(ArcFx.new().setup(self, s), button, tip)
		"projectile":
			_charging = s
			_charge_t = 0.0
			_charge_ring.material_override = Fx.glow(El.COLOR[s.primary], 2.0)
		"nova":
			Game.I.spawn(NovaFx.new().setup(self, s), global_position)
			if _mod("echo", false):
				var again := NovaFx.new().setup(self, s) as NovaFx
				get_tree().create_timer(0.35).timeout.connect(func(): if is_instance_valid(self): Game.I.spawn(again, global_position))
		"wall":
			Game.I.spawn(WallFx.new().setup(self, s), Game.I.arena.clamp_inside(global_position + aim_dir * 2.6))
		"field":
			var f: Field = Game.I.arena.add_field(Game.I.arena.clamp_inside(global_position + aim_dir * (2.0 + s.n.radius)), s.primary, s.n.radius, s.n.duration, self)
			f.spell = s
			f.rate = s.n.rate
			# Planting into an existing field mixes: fire planted on a puddle boils it.
		"totem":
			Game.I.spawn(TotemFx.new().setup(self, s), Game.I.arena.clamp_inside(global_position + aim_dir * 2.4))
		"rune":
			Game.I.spawn(RuneFx.new().setup(self, s), Game.I.arena.clamp_inside(global_position + aim_dir * 2.4))
		"ward":
			_ward(s)
		"overload":
			var at := global_position + aim_dir * 7.0
			if s.primary in [El.EARTH, El.LIFE, El.WATER]:
				at = global_position
			Game.I.spawn(OverloadFx.new().setup(self, s), Game.I.arena.clamp_inside(at))
		"staff", "stomp":
			_swing(s)


func _channel(fx: SpellFx, button: int, at: Vector3) -> void:
	channel = fx
	_channel_button = button
	Game.I.spawn(fx, at)


func _throw() -> void:
	var s := _charging
	_charging = {}
	_charge_ring.visible = false
	var charge := clampf(_charge_t / float(s.n.charge_time), 0.0, 1.0)
	var count: int = s.n.pieces
	for i in count:
		var spread: float = 0.0 if count == 1 else deg_to_rad(s.n.spread) * ((float(i) / (count - 1)) - 0.5)
		var dir := aim_dir.rotated(Vector3.UP, spread)
		var p := ProjectileFx.new().setup(self, s) as ProjectileFx
		p.launch(dir, charge)
		Game.I.spawn(p, staff_tip() + dir * 0.3)
	_cast_anim = 0.3


func _ward(s: Dictionary) -> void:
	ward = s
	ward_time = s.n.duration
	armor = 1.0
	haste = 1.0
	for e in s.counts:
		var k: int = s.counts[e]
		if El.contains(e, El.EARTH):
			armor *= pow(0.75, k)
		if El.contains(e, El.AIR):
			haste += 0.15 * k
	if s.counts.has(El.LIFE):
		hp = minf(max_hp, hp + El.EFFECT[El.LIFE].heal * 2.2 * s.counts[El.LIFE] * float(_mod("heal", 1.0)))
		Fx.burst(global_position + Vector3.UP, El.COLOR[El.LIFE], 24, 3.0)
	if s.counts.size() == 1 and s.counts.has(El.LIFE):
		ward = {}
		ward_time = 0.0
		return
	var m := StandardMaterial3D.new()
	var mixed: Color = El.COLOR[s.primary]
	for e in s.payload:
		mixed = mixed.lerp(El.COLOR[e], 0.35)
	m.albedo_color = Color(mixed.r, mixed.g, mixed.b, 0.18)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = mixed
	m.emission_energy_multiplier = 0.6
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_ward_shell.material_override = m
	Fx.ring(global_position, mixed, 1.6, 0.4)


func _swing(s: Dictionary) -> void:
	if _swing_t > 0.0:
		return
	_swing_t = 0.45
	var bonk := {counts = {El.EARTH: 1}, payload = [], primary = El.EARTH, n = {}}
	for a in Game.I.living():
		if a == self:
			continue
		var to: Vector3 = a.global_position - global_position
		to.y = 0
		var reach := 1.9 if s.shape == "staff" else 2.6
		if to.length() > reach + a.radius:
			continue
		if s.shape == "staff" and absf(aim_dir.signed_angle_to(to, Vector3.UP)) > 1.1:
			continue
		a.hit_spell(bonk, 0.55, self, to.normalized(), Game.I.ff)
	if s.shape == "stomp":
		Fx.ring(global_position, Color(0.7, 0.6, 0.5), 2.6, 0.3)
	else:
		Fx.burst(global_position + aim_dir * 1.4 + Vector3.UP, Color(0.9, 0.85, 0.7), 8, 3.0, 0.2)


func on_dealt(dmg: float, spell: Dictionary) -> void:
	var siphon := float(_mod("siphon", 0.0))
	if siphon > 0.0 and spell.counts.has(El.VOID):
		hp = minf(max_hp, hp + dmg * siphon)


func die(src: Actor) -> void:
	super.die(src)
	_charging = {}
	channel = null
	queue.clear()
	burn = 0.0
	model.root.visible = false
	_ring.visible = false
	_light.light_energy = 0.4
	_tomb = Art.tombstone()
	add_child(_tomb)
	_revive = 0.0
	Fx.burst(global_position + Vector3.UP, Color(0.7, 0.05, 0.05), 30, 4.0)
	Fx.text(global_position + Vector3.UP * 2.5, player_name + " has fallen", Color(0.85, 0.1, 0.1), 52, 2.5)


func revive_progress(amount: float) -> void:
	_revive += amount
	if _revive >= REVIVE_NEED:
		revive(0.4)


func revive(frac: float) -> void:
	if alive:
		return
	alive = true
	hp = max_hp * frac
	model.root.visible = true
	_ring.visible = true
	_light.light_energy = 1.3
	if _tomb:
		_tomb.queue_free()
		_tomb = null
	frozen = 0.0
	chill = 0.0
	stun = 0.0
	Fx.burst(global_position + Vector3.UP, El.COLOR[El.LIFE], 40, 4.0)
	Fx.light_pop(global_position, El.COLOR[El.LIFE], 3.0, 6.0, 0.8)
	Fx.text(global_position + Vector3.UP * 2.5, "Revived", El.COLOR[El.LIFE], 52)


func _visuals(dt: float) -> void:
	var body: Node3D = model.body
	var target_yaw := atan2(aim_dir.x, aim_dir.z)
	body.rotation.y = lerp_angle(body.rotation.y, target_yaw, 14.0 * dt)
	var moving := velocity.length() > 0.5
	_walk += dt * (9.0 if moving else 0.0)
	body.position.y = absf(sin(_walk)) * 0.07 if moving else 0.0
	body.rotation.z = sin(_walk) * 0.05 if moving else 0.0
	var staff: Node3D = model.staff
	var lift := 0.0
	if _cast_anim > 0.0 or (channel and is_instance_valid(channel)) or not _charging.is_empty():
		lift = 1.0
	staff.rotation.x = lerpf(staff.rotation.x, -1.1 * lift, 12.0 * dt)
	staff.position.z = lerpf(staff.position.z, 0.18 + 0.25 * lift, 12.0 * dt)
	if _swing_t > 0.0:
		staff.rotation.y = sin(_swing_t / 0.45 * PI) * 1.6
	else:
		staff.rotation.y = 0.0
	# Orbs circle the hat, one per queued element.
	var slots := queue.slots
	var gem_color := Color(0.9, 0.85, 0.7)
	for i in _orbs.size():
		var o := _orbs[i]
		if i < slots.size():
			o.visible = true
			var c: Color = El.COLOR[slots[i]]
			o.material_override = Fx.glow(c, 3.0)
			var ang := Time.get_ticks_msec() / 1000.0 * 2.2 + i * TAU / maxf(slots.size(), 1)
			o.position = Vector3(cos(ang) * 0.62, 2.1 + sin(ang * 2.0) * 0.05, sin(ang) * 0.62)
			var big := 1.25 if El.is_fused(slots[i]) else 1.0
			o.scale = Vector3.ONE * big
		else:
			o.visible = false
	if not slots.is_empty():
		gem_color = El.COLOR[slots[0]]
	model.gem.material_override = Fx.glow(gem_color, 3.0)
	# Say what RT will do, so every spell is predictable before you cast it.
	if slots.is_empty():
		_label.text = ""
	else:
		var s := preview("cast")
		_label.text = s.name
		_label.modulate = El.COLOR[s.primary].lightened(0.3)
	_ward_shell.visible = ward_time > 0.0
	if ward_time > 0.0:
		var pulse := 0.95 + 0.05 * sin(Time.get_ticks_msec() / 150.0)
		_ward_shell.scale = Vector3(0.95, 1.05, 0.95) * pulse
	_charge_ring.visible = not _charging.is_empty()
	if _charge_ring.visible:
		var c := clampf(_charge_t / float(_charging.n.charge_time), 0.0, 1.0)
		var sc := 0.6 + c * 1.1
		_charge_ring.scale = Vector3(sc, 0.05, sc)

class_name Wizard
extends Actor
## A player's wizard. Twin-stick at heart: the left stick walks, the right
## stick aims and shoots staff bolts. Face buttons load elements into the
## queue for a little mana, and the queue is ammunition: every bolt carries
## its mix (water and fire loaded shoot steam bolts), and the oldest element
## burns out after a few bolts and drops off. RT spends what is left at once
## as a spell, for mana per element. An empty queue shoots plain bolts.
##
##   A Poison / Void   B Fire / Frost     X Water / Air         Y Lightning / Earth
##   (hold LB for the second of each pair, its opposite)
##   right stick  aim and shoot bolts (free)
##   RB  staff swing, knocks bullets back (free); hold and let go: burst
##   LT  dodge roll, monsters cannot touch you while you roll (free)
##   RT  cast the queue ahead: it winds up first, with a line on the ground
##       showing everyone where it will go; a tap fires it as soon as it is
##       ready, holding RT keeps it while you aim and fires on release
##   LS click  plant the queue at your feet: a trap, or a sentry when full
##   RS click  ward yourself
##   D-pad up  conjure your last spell again
##   D-pad left / right  tap to conjure a saved spell, hold to save the queue

const REVIVE_NEED := 40.0
const SAVE_HOLD := 0.6

## The mana economy lives in Balance, next to the damage budget it pays for.
const MANA_MAX := Balance.MANA_MAX
const MANA_REGEN := Balance.MANA_REGEN
const MANA_PER_LOAD := Balance.MANA_PER_LOAD
const MANA_PER_ELEMENT := Balance.MANA_PER_ELEMENT
const OVERLOAD_COST := Balance.OVERLOAD_COST
## Bolts each loaded element is good for. The oldest one burns first and
## drops out of the queue when it is spent.
const BOLTS_PER_ELEMENT := 8
## Plain bolts when the queue is empty: weak, so loading is worth it.
const PLAIN_BOLT := Balance.PLAIN_BOLT
const MANA_PER_SWING := Balance.MANA_PER_SWING
const MANA_PER_DEFLECT := Balance.MANA_PER_DEFLECT
const BOLT_RATE := Balance.BOLT_RATE
const SWING_COOLDOWN := 0.34
## After a swing the staff needs this long before it can swing again, so
## knocking bullets back is a timed choice, not a shield. The gem goes dark
## while it recovers and flashes when it is ready.
const SWING_RECOVER := 0.7
const SWING_REACH := 2.3
## Half the angle of the swing, each side of where you aim: what it hits and
## the bullets it knocks back.
const SWING_ARC := 1.3
const NOVA_HOLD := 0.45
const ROLL_TIME := 0.32
const ROLL_SPEED := 14.0
const ROLL_COOLDOWN := 0.75
const BOLT := Balance.BOLT

var player_name := "Wizard"
var robe := Color(0.6, 0.15, 0.15)
var pad: Pad
var queue := SpellQueue.new()
var aim_dir := Vector3.FORWARD
var relics: Array = []
var saved := {Pad.LEFT: [], Pad.RIGHT: []}
var last_cast: Array = []
var bot: Bot
## The element the staff's bolts look like: the front of the queue, -1 plain.
var bolt_el := -1
## Bolts left in the front element of the queue.
var ammo := 0
var mana := MANA_MAX
## Set briefly when a spell was too dear, so the HUD can flash the orb.
var no_mana := 0.0

var channel: SpellFx
var _channel_button := -1
## The spell winding up on RT, how long it has wound up and how long it needs.
## Winding up never makes a spell stronger: it is the warning before it goes.
var _charging := {}
var _charge_t := 0.0
var _charge_need := 0.5
const WINDUP := {spray = 0.4, beam = 0.55, arc = 0.45, projectile = 0.65, overload = 1.0}
## The line on the ground ahead of a winding-up spell: a dim track for its
## reach, filling bright as it gets ready.
var _aim_line: Node3D
var _aim_track: MeshInstance3D
var _aim_fill: MeshInstance3D
var _bolt_t := 0.0
var _roll_t := 0.0
var _roll_cd := 0.0
var _roll_dir := Vector3.ZERO
var _rb_t := -1.0
var _traced := {}
var _save_t := {}
var _revive := 0.0
var _swing_t := 0.0
var _swing_cd := 0.0
var _swing_dir := Vector3.FORWARD
var _cast_anim := 0.0
var _walk := 0.0

var model: Dictionary
var _orbs: Array[MeshInstance3D] = []
var _name_label: Label3D
var _light: OmniLight3D
var _ward_shell: MeshInstance3D
var _tomb: Node3D
var _remains: Remains
var _charge_ring: MeshInstance3D
## The swing's arc on the ground: sweeps open on a swing, and shows faintly
## while a bullet is close so you can see what you would knock back.
var _zone: MeshInstance3D
var _zone_mat: ShaderMaterial


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
	_remains = Remains.new().setup(self, model)
	add_child(_remains)
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
	var tor := TorusMesh.new()
	tor.inner_radius = 0.55
	tor.outer_radius = 0.66
	tor.rings = 28
	tor.ring_segments = 4
	for i in 6:
		var o := Art.part(self, Art.sphere(0.13, 12), Fx.element(El.FIRE, 1.3))
		o.visible = false
		o.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_orbs.append(o)
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
	_zone = MeshInstance3D.new()
	_zone.mesh = _arc_mesh(0.55, SWING_REACH + 0.3, SWING_ARC)
	_zone_mat = ShaderMaterial.new()
	_zone_mat.shader = preload("res://src/fx/slash.gdshader")
	_zone.material_override = _zone_mat
	_zone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_zone.position.y = 0.06
	_zone.top_level = true
	_zone.visible = false
	add_child(_zone)
	_aim_line = Node3D.new()
	_aim_line.top_level = true
	_aim_line.visible = false
	add_child(_aim_line)
	_aim_track = MeshInstance3D.new()
	_aim_track.mesh = Art.box(1.0, 0.02, 1.0)
	_aim_track.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_aim_line.add_child(_aim_track)
	_aim_fill = MeshInstance3D.new()
	_aim_fill.mesh = Art.box(1.0, 0.02, 1.0)
	_aim_fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_aim_line.add_child(_aim_fill)
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
			elif k in ["hp", "hops"]:
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
	queue.size = SpellQueue.SIZE


func staff_tip() -> Vector3:
	return model.gem.global_position if model else global_position + Vector3.UP * 1.6


## A stream runs its whole time once started (one tap of RT); tapping RT
## again or rolling stops it early.
func holding(fx: SpellFx) -> bool:
	return channel == fx and alive


## How much of the running stream is left, 1 to 0, or -1 when none runs.
func channel_left() -> float:
	if channel == null or not is_instance_valid(channel) or not channel.is_physics_processing():
		return -1.0
	return clampf(1.0 - channel.t / maxf(float(channel.n.get("duration", 1.0)), 0.01), 0.0, 1.0)


func _physics_process(dt: float) -> void:
	tick_status(dt)
	if bot:
		bot.think(self, dt)
	elif pad:
		if pad.source == Pad.Source.KEYBOARD and Game.I and Game.I.camera:
			pad.mouse_origin = Game.I.camera.unproject_position(global_position + Vector3.UP)
		pad.poll()
	if _swing_t > 0.0:
		_deflect_sweep()
	_swing_t = maxf(0.0, _swing_t - dt)
	if _swing_cd > 0.0:
		_swing_cd -= dt
		if _swing_cd <= 0.0 and model:
			Fx.burst(staff_tip(), Color(1.0, 0.9, 0.6), 8, 1.5, 0.12)
	_cast_anim = maxf(0.0, _cast_anim - dt)
	_roll_cd = maxf(0.0, _roll_cd - dt)
	no_mana = maxf(0.0, no_mana - dt)
	if not alive:
		drive(Vector3.ZERO, dt)
		_raise(dt)
		return
	if Game.I and Game.I.paused_play:
		drive(Vector3.ZERO, dt)
		_visuals(dt)
		return
	mana = minf(MANA_MAX, mana + MANA_REGEN * dt)
	bolt_el = queue.slots[0] if not queue.is_empty() else -1
	_read_input(dt)
	if _roll_t > 0.0:
		_roll_t -= dt
		drive(_roll_dir * ROLL_SPEED, dt)
		_visuals(dt)
		return
	var mv := Vector3(pad.move.x, 0, pad.move.y)
	var spd := move_speed()
	if channel and is_instance_valid(channel) and channel.is_physics_processing():
		spd *= 0.55
	elif not _charging.is_empty():
		spd *= 0.6
	drive(_leash(mv) * spd, dt)
	_visuals(dt)


func on_shield_hit(amount: float) -> void:
	_shield_flash = 1.0
	if amount > 1.0 and ward.has("primary"):
		Fx.burst(global_position + Vector3.UP, El.COLOR[ward.primary], 6, 2.5, 0.2)


## The shield breaks with a burst of its elements round you.
func shield_broke() -> void:
	var s := ward
	super.shield_broke()
	if s.is_empty() or not Game.I:
		return
	var nova := NovaFx.new()
	nova.setup(self, {counts = s.counts, payload = s.get("payload", []), primary = s.primary, key = "", name = "", n = {radius = 3.2, rate = 0.5 * s.slots.size()}})
	Game.I.spawn(nova, global_position)
	Game.I.shake(0.2)


var _shield_flash := 0.0


## A frozen wizard can do nothing, so it never lasts long and never chains:
## a short freeze, then a few seconds where frost only slows.
func freeze_time() -> float:
	return 0.9


func freeze_immunity() -> float:
	return 4.0


## Couch co-op shares one screen: nobody walks further than LEASH from
## another wizard, or the camera could not show everyone.
const LEASH := 15.0


func _leash(mv: Vector3) -> Vector3:
	if not Game.I:
		return mv
	for w in Game.I.wizards:
		if w == self or not w.alive:
			continue
		var away: Vector3 = global_position - w.global_position
		away.y = 0.0
		if away.length() > LEASH and mv.dot(away) > 0.0:
			var n: Vector3 = away.normalized()
			mv -= n * mv.dot(n)
	return mv


func _read_input(dt: float) -> void:
	if pad.aim.length() > 0.3:
		aim_dir = Vector3(pad.aim.x, 0, pad.aim.y).normalized()
	elif pad.move.length() > 0.3 and (channel == null or not is_instance_valid(channel)) and _charging.is_empty():
		aim_dir = Vector3(pad.move.x, 0, pad.move.y).normalized()
	if not can_act():
		return
	var flip := pad.down(Pad.LB)
	for b in [Pad.A, Pad.B, Pad.X, Pad.Y]:
		if pad.pressed(b):
			conjure(El.PAIRS[["A", "B", "X", "Y"][b]][1 if flip else 0])
	if pad.pressed(Pad.LT):
		roll()
	if _roll_t > 0.0:
		return
	# A spell winds up, then goes as soon as it is ready and RT is let go.
	if not _charging.is_empty():
		_charge_t += dt
		if _charge_t >= _charge_need and not pad.down(Pad.RT):
			_release()
	if pad.pressed(Pad.RT):
		cast("cast", Pad.RT)
	# RB: a tap swings the staff, holding it and letting go bursts the queue.
	if pad.pressed(Pad.RB):
		melee()
		_rb_t = 0.0
	elif pad.down(Pad.RB) and _rb_t >= 0.0:
		_rb_t += dt
	if pad.released(Pad.RB):
		if _rb_t >= NOVA_HOLD:
			cast("nova", -1)
		_rb_t = -1.0
	if pad.pressed(Pad.LS):
		cast("plant", -1)
	if pad.pressed(Pad.RS):
		cast("ward", -1)
	_bolt_t -= dt
	# Swinging the staff stops the bolts for a moment: your hands are busy.
	if pad.fire and _bolt_t <= 0.0 and not busy() and _swing_t <= 0.0:
		_bolt_t = 1.0 / BOLT_RATE
		shoot()
	if pad.pressed(Pad.UP) and not last_cast.is_empty():
		load_slots(last_cast)
		_conjure_fx()
	for b in [Pad.LEFT, Pad.RIGHT]:
		if pad.down(b):
			_save_t[b] = _save_t.get(b, 0.0) + dt
			if _save_t[b] >= SAVE_HOLD and _save_t[b] - dt < SAVE_HOLD and not queue.is_empty():
				saved[b] = queue.copy()
				Fx.text(global_position + Vector3.UP * 3.2, "Saved", Color(1, 0.85, 0.4), 40)
		elif pad.released(b):
			if _save_t.get(b, 0.0) < SAVE_HOLD and not saved[b].is_empty():
				load_slots(saved[b])
				_conjure_fx()
			_save_t[b] = 0.0


## Channelling a stream or charging a throw keeps the staff busy.
func busy() -> bool:
	return (channel != null and is_instance_valid(channel) and channel.is_physics_processing()) or not _charging.is_empty() or _roll_t > 0.0


func add_mana(amount: float) -> void:
	mana = minf(MANA_MAX, mana + amount)


## What a spell costs: per element still in it, an overload a fixed sum.
func cost(s: Dictionary) -> float:
	if s.shape == "overload":
		return OVERLOAD_COST
	if s.shape == "sentry":
		return Balance.SENTRY_COST
	if s.shape in ["staff", "stomp", "fizzle"]:
		return 0.0
	return MANA_PER_ELEMENT * s.power


func _trace_once(what: String) -> void:
	if not _traced.has(what) and Game.I:
		_traced[what] = true
		Game.I._trace("%s %s" % [what, player_name])


## What one bolt carries: every loaded element, a little stronger for each
## copy, split across the mix so a mixed bolt is not simply stronger.
func bolt_spell() -> Dictionary:
	if queue.is_empty():
		return {counts = {}, payload = [], primary = -1, n = {}, scales = {}}
	var counts := {}
	for e in queue.slots:
		counts[e] = int(counts.get(e, 0)) + 1
	var scales := {}
	var split := 1.0 / sqrt(float(counts.size()))
	for e in counts:
		scales[e] = BOLT[e] * (0.6 + 0.4 * counts[e]) * split
	return {counts = counts, payload = [], primary = queue.slots[0], n = {}, scales = scales}


func shoot() -> void:
	var dir := aim_dir.rotated(Vector3.UP, randf_range(-0.03, 0.03))
	var b := BoltFx.new().setup(self, bolt_spell(), dir)
	Game.I.spawn(b, staff_tip() + dir * 0.1)
	if not queue.is_empty():
		ammo -= 1
		if ammo <= 0:
			var gone: int = queue.slots.pop_front()
			ammo = BOLTS_PER_ELEMENT if not queue.is_empty() else 0
			Fx.burst(global_position + Vector3.UP * 2.1, El.COLOR[gone], 8, 2.0, 0.2)
	_cast_anim = maxf(_cast_anim, 0.12)
	_trace_once("shoot")
	Game.I.count("shots")


## The staff swing: hits monsters in front with your element and knocks
## their bullets back the way you aim.
func melee() -> void:
	if _swing_t > 0.0 or _swing_cd > 0.0 or busy():
		return
	_swing_t = SWING_COOLDOWN
	_swing_cd = SWING_COOLDOWN + SWING_RECOVER
	_trace_once("melee")
	Game.I.count("swings")
	var bonk := {counts = {El.EARTH: 1}, payload = [], primary = El.EARTH, n = {}}
	var touch := bolt_spell()
	for a in Game.I.enemies:
		if not is_instance_valid(a) or not a.alive:
			continue
		var to: Vector3 = a.global_position - global_position
		to.y = 0
		if to.length() > SWING_REACH + a.radius or absf(aim_dir.signed_angle_to(to, Vector3.UP)) > SWING_ARC + atan2(a.radius, maxf(to.length(), 0.1)):
			continue
		a.hit_spell(bonk, 0.4, self, to.normalized())
		BoltFx.strike(a, touch, 2.5, self, to.normalized())
		add_mana(MANA_PER_SWING)
	# The staff smashes what stands in the arc too.
	for p in Game.I.arena.props.duplicate():
		if not is_instance_valid(p):
			continue
		var tp: Vector3 = p.global_position - global_position
		tp.y = 0
		if tp.length() < SWING_REACH + 0.6 and absf(aim_dir.signed_angle_to(tp, Vector3.UP)) < SWING_ARC + 0.3:
			p.damage(4.0, aim_dir)
	_swing_dir = aim_dir
	_deflect_sweep()
	var sc: Color = El.COLOR[bolt_el] if bolt_el >= 0 else Color(1.0, 0.85, 0.5)
	Fx.burst(global_position + aim_dir * 1.4 + Vector3.UP, sc.lerp(Color(0.95, 0.9, 0.75), 0.4), 10, 3.5, 0.22)
	_zone_mat.set_shader_parameter("color", sc.lerp(Color(1.0, 0.9, 0.6), 0.5))


## Knock back every enemy bullet inside the arc drawn on the ground. Runs
## on every tick of the swing, not just the first, so a bullet that flies
## into the arc while the staff is still sweeping goes back too.
func _deflect_sweep() -> void:
	for b in Bullet.all.duplicate():
		if not is_instance_valid(b) or b.team == team:
			continue
		var to2: Vector3 = b.global_position - global_position
		to2.y = 0
		var d := to2.length()
		# The drawn arc reaches SWING_REACH + 0.3; the bullet counts once its
		# edge is in, and anything right on top of the wizard counts too.
		if d > SWING_REACH + 0.3 + b.radius:
			continue
		if d > 0.6 and absf(_swing_dir.signed_angle_to(to2, Vector3.UP)) > SWING_ARC + atan2(b.radius, d):
			continue
		b.deflect(self, aim_dir)
		add_mana(MANA_PER_DEFLECT)
		Game.I.count("deflects")


func _place_zone(dir: Vector3) -> void:
	_zone.global_position = Vector3(global_position.x, 0.06, global_position.z)
	_zone.rotation = Vector3(0, atan2(dir.x, dir.z), 0)


## 1 when an enemy bullet is right on you, fading to 0 at six metres.
func _bullet_near() -> float:
	var best := 0.0
	for b in Bullet.all:
		if b.team == team:
			continue
		var d := Vector2(b.global_position.x - global_position.x, b.global_position.z - global_position.z).length()
		best = maxf(best, 1.0 - clampf((d - SWING_REACH) / 4.0, 0.0, 1.0))
	return best


## A flat ring sector on the ground, pointing along +Z: UV.x runs across it,
## UV.y from the inner radius out.
static func _arc_mesh(r0: float, r1: float, half: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 28
	for i in seg:
		var a0 := lerpf(half, -half, float(i) / seg)
		var a1 := lerpf(half, -half, float(i + 1) / seg)
		var u0 := float(i) / seg
		var u1 := float(i + 1) / seg
		var p := [Vector3(sin(a0) * r0, 0, cos(a0) * r0), Vector3(sin(a0) * r1, 0, cos(a0) * r1),
			Vector3(sin(a1) * r1, 0, cos(a1) * r1), Vector3(sin(a1) * r0, 0, cos(a1) * r0)]
		var uv := [Vector2(u0, 0), Vector2(u0, 1), Vector2(u1, 1), Vector2(u1, 0)]
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_uv(uv[k])
			st.add_vertex(p[k])
	return st.commit()


## A dodge roll the way you walk, untouchable for its length.
func roll() -> void:
	if _roll_cd > 0.0 or _roll_t > 0.0 or not can_act():
		return
	var d := Vector3(pad.move.x, 0, pad.move.y)
	if d.length() < 0.2:
		d = aim_dir
	_roll_dir = d.normalized()
	_roll_t = ROLL_TIME
	_roll_cd = ROLL_COOLDOWN
	invuln = ROLL_TIME + 0.06
	if channel and is_instance_valid(channel):
		channel = null
	_trace_once("dodge")
	Game.I.count("rolls")
	Fx.puff(global_position + Vector3.UP * 0.4, Color(0.6, 0.6, 0.65, 0.5), 0.8)


## Load one element for mana. Cancelling with an opposite is free.
func conjure(e: int) -> void:
	var trial := SpellQueue.new()
	trial.size = queue.size
	trial.set_slots(queue.copy())
	var would := trial.add(e)
	if would == "full":
		return
	if would != "cancel":
		if mana < MANA_PER_LOAD - 0.01:
			_no_mana()
			return
		mana -= MANA_PER_LOAD
	var front := queue.slots[0] if not queue.is_empty() else -1
	var what := queue.add(e)
	# A new or changed front element starts with a full charge.
	if queue.is_empty():
		ammo = 0
	elif queue.slots[0] != front:
		ammo = BOLTS_PER_ELEMENT
	var c: Color = El.COLOR[e]
	match what:
		"cancel":
			Fx.burst(global_position + Vector3.UP * 1.9, c, 8, 2.0, 0.2)
		"fuse":
			Fx.burst(global_position + Vector3.UP * 1.9, c, 12, 2.5, 0.25)
	_conjure_fx()


## Load a remembered queue (D-pad recast or a saved spell), paying for each slot.
func load_slots(slots: Array) -> void:
	var price := MANA_PER_LOAD * slots.size()
	if mana < price - 0.01:
		_no_mana()
		return
	mana -= price
	queue.set_slots(slots)
	ammo = BOLTS_PER_ELEMENT


func _no_mana() -> void:
	no_mana = 0.6
	Fx.text(global_position + Vector3.UP * 3.1, "Not enough mana", Color(0.45, 0.6, 1.0), 32, 0.9)
	_trace_once("no mana")
	if Game.I:
		Game.I.count("no_mana")


func _conjure_fx() -> void:
	pass


func preview(form: String) -> Dictionary:
	return Grammar.compose(queue.copy(), form, mods())


## Cast what is queued in [param form]. [param button] is held to channel.
func cast(form: String, button: int) -> void:
	if _swing_t > 0.0:
		return
	if channel and is_instance_valid(channel) and channel.is_physics_processing():
		# RT again ends the stream, and casts what you loaded since if any.
		if form != "cast" or queue.is_empty():
			if form == "cast":
				channel = null
			return
		channel = null
	if not _charging.is_empty():
		return
	var s := preview(form)
	if s.shape in ["fizzle", "staff"]:
		return
	var price := cost(s)
	if mana < price - 0.01:
		_no_mana()
		return
	mana -= price
	ammo = 0
	if not queue.is_empty():
		last_cast = queue.copy()
	queue.clear()
	_cast_anim = 0.3
	if Game.I:
		Game.I.on_cast(self, s)
	match s.shape:
		"spray", "beam", "arc", "projectile", "overload":
			_charging = s
			_charge_t = 0.0
			_charge_need = WINDUP[s.shape] * float(_mod("charge", 1.0))
			_charge_ring.material_override = Fx.glow(El.COLOR[s.primary], 2.0)
			var c: Color = El.COLOR[s.primary]
			_aim_track.material_override = Fx.additive(Color(c.r, c.g, c.b, 0.25), 0.8)
			_aim_fill.material_override = Fx.additive(Color(c.r, c.g, c.b, 0.6), 1.4)
		"nova":
			Game.I.spawn(NovaFx.new().setup(self, s), global_position)
			if _mod("echo", false):
				var again := NovaFx.new().setup(self, s) as NovaFx
				get_tree().create_timer(0.35).timeout.connect(func(): if is_instance_valid(self): Game.I.spawn(again, global_position))
		"trap":
			_plant(TrapFx.new().setup(self, s), _traps, MAX_TRAPS)
		"sentry":
			_plant(SentryFx.new().setup(self, s), _sentries, 1)
		"ward":
			_ward(s)
		"stomp":
			_swing(s)


## Traps and sentries go down at your feet. Each wizard keeps at most
## [param most] of a kind; planting another takes away the oldest.
const MAX_TRAPS := 3
var _traps: Array = []
var _sentries: Array = []


func _plant(fx: SpellFx, list: Array, most: int) -> void:
	for old in list.duplicate():
		if not is_instance_valid(old) or not old.is_physics_processing():
			list.erase(old)
	while list.size() >= most:
		list.pop_front().remove()
	list.append(fx)
	Game.I.spawn(fx, Game.I.arena.clamp_inside(global_position))


func _channel(fx: SpellFx, button: int, at: Vector3) -> void:
	channel = fx
	_channel_button = button
	Game.I.spawn(fx, at)


## The wound-up spell goes, the way you aim now.
func _release() -> void:
	var s := _charging
	_charging = {}
	_charge_ring.visible = false
	_aim_line.visible = false
	_cast_anim = 0.3
	match s.shape:
		"spray":
			_channel(SprayFx.new().setup(self, s), Pad.RT, staff_tip())
		"beam":
			_channel(BeamFx.new().setup(self, s), Pad.RT, staff_tip())
		"arc":
			_channel(ArcFx.new().setup(self, s), Pad.RT, staff_tip())
		"projectile":
			_throw(s)
		"overload":
			var at := global_position + aim_dir * OVERLOAD_REACH
			if _overload_here(s):
				at = global_position
			Game.I.spawn(OverloadFx.new().setup(self, s), Game.I.arena.clamp_inside(at))


const OVERLOAD_REACH := 7.0


func _overload_here(s: Dictionary) -> bool:
	return s.primary in [El.EARTH, El.WATER]


## How far ahead the wound-up spell reaches, for the line on the ground.
func _reach(s: Dictionary) -> float:
	match s.shape:
		"overload":
			return 0.0 if _overload_here(s) else OVERLOAD_REACH
		"projectile":
			return 10.0
	return float(s.n.get("range", 8.0))


func _throw(s: Dictionary) -> void:
	# Always a full throw: winding up is the warning, not extra strength.
	var charge := 1.0
	var count: int = s.n.pieces
	for i in count:
		var spread: float = 0.0 if count == 1 else deg_to_rad(s.n.spread) * ((float(i) / (count - 1)) - 0.5)
		var dir := aim_dir.rotated(Vector3.UP, spread)
		var p := ProjectileFx.new().setup(self, s) as ProjectileFx
		p.launch(dir, charge)
		Game.I.spawn(p, staff_tip() + dir * 0.1)
	_cast_anim = 0.3


## A ward is a shield round you: it soaks SHIELD_PER_ELEMENT damage of any
## kind for each element in it, and when it breaks it bursts outward with
## its elements. Earth also hardens you, Air speeds you up, and matching
## elements are resisted on top. Nothing heals you.
const SHIELD_PER_ELEMENT := 18.0


func _ward(s: Dictionary) -> void:
	ward = s
	ward_time = s.n.duration
	shield_max = SHIELD_PER_ELEMENT * s.slots.size()
	shield = shield_max
	armor = 1.0
	haste = 1.0
	for e in s.counts:
		var k: int = s.counts[e]
		if El.contains(e, El.EARTH):
			armor *= pow(0.75, k)
		if El.contains(e, El.AIR):
			haste += 0.15 * k
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
	_swing_t = SWING_COOLDOWN
	var bonk := {counts = {El.EARTH: 1}, payload = [], primary = El.EARTH, n = {}}
	for a in Game.I.living():
		if a == self:
			continue
		var to: Vector3 = a.global_position - global_position
		to.y = 0
		if to.length() > 2.6 + a.radius:
			continue
		a.hit_spell(bonk, 0.55, self, to.normalized(), Game.I.ff)
	Fx.ring(global_position, Color(0.7, 0.6, 0.5), 2.6, 0.3)


func die(src: Actor) -> void:
	var how := Remains.style_for(self, overkill)
	super.die(src)
	_charging = {}
	channel = null
	queue.clear()
	burn = 0.0
	poison = 0.0
	_light.light_energy = 0.4
	_remains.die(how, last_dir)
	_revive = 0.0
	# The grave rises beside the body once it has come down.
	_tomb = Art.tombstone()
	add_child(_tomb)
	_tomb.position = _remains.tomb_at + Vector3.DOWN * 1.2
	var tw := _tomb.create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(_tomb, "position:y", 0.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## A friend standing at your grave raises you: REVIVE_NEED in about three
## seconds with one, faster with more. Walking away lets it fade again.
const REVIVE_RATE := 14.0
const REVIVE_REACH := 1.9
var _raise_fx := 0.0


func _raise(dt: float) -> void:
	if not Game.I or Game.I.paused_play:
		return
	var n := 0
	for w in Game.I.wizards:
		if w != self and w.alive and w.global_position.distance_to(global_position) < REVIVE_REACH:
			n += 1
	if n == 0:
		_revive = maxf(0.0, _revive - REVIVE_RATE * 0.5 * dt)
		return
	_raise_fx -= dt
	if _raise_fx <= 0.0:
		_raise_fx = 0.35
		Fx.ring(global_position + Vector3.UP * 0.04, Color(1.0, 0.85, 0.5), REVIVE_REACH * (1.0 - _revive / REVIVE_NEED * 0.7), 0.35)
	revive_progress(REVIVE_RATE * n * dt)


func revive_progress(amount: float) -> void:
	_revive += amount
	if _revive >= REVIVE_NEED:
		revive(0.4)


func revive(frac: float) -> void:
	if alive:
		return
	alive = true
	hp = max_hp * frac
	_light.light_energy = 1.3
	if _tomb:
		var tomb := _tomb
		_tomb = null
		var tw := tomb.create_tween()
		tw.tween_property(tomb, "position:y", -1.3, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(tomb.queue_free)
	frozen = 0.0
	chill = 0.0
	stun = 0.0
	# A moment to stand up while the pieces fly back together.
	invuln = maxf(invuln, 1.2)
	_remains.revive()


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
	# Casting points the staff ahead (positive x tips the gem forward).
	staff.rotation.x = lerpf(staff.rotation.x, 0.95 * lift, 12.0 * dt)
	staff.position.z = lerpf(staff.position.z, 0.18 + 0.25 * lift, 12.0 * dt)
	# The swing: the staff sweeps flat from one side to the other, the body
	# twists with it, and the arc on the ground opens behind the staff.
	var sweep := 1.0 - _swing_t / SWING_COOLDOWN if _swing_t > 0.0 else -1.0
	if sweep >= 0.0:
		var e := 1.0 - pow(1.0 - minf(sweep * 1.6, 1.0), 3.0)
		staff.rotation.y = lerpf(1.9, -1.9, e)
		staff.rotation.x = lerpf(staff.rotation.x, 1.35, 30.0 * dt)
		body.rotation.y = target_yaw + lerpf(0.6, -0.6, e)
		_zone.visible = true
		_zone_mat.set_shader_parameter("progress", e)
		_zone_mat.set_shader_parameter("strength", 1.0 - smoothstep(0.55, 1.0, sweep))
		_place_zone(_swing_dir)
	else:
		staff.rotation.y = 0.0
		var near := _bullet_near() if _swing_cd <= 0.0 else 0.0
		_zone.visible = near > 0.0 and alive
		if _zone.visible:
			_zone_mat.set_shader_parameter("color", Color(1.0, 0.9, 0.6))
			_zone_mat.set_shader_parameter("progress", 1.0)
			_zone_mat.set_shader_parameter("strength", 0.22 * near)
			_place_zone(aim_dir)
	# Orbs circle the hat, one per queued element.
	var slots := queue.slots
	var gem_color := Color(0.9, 0.85, 0.7)
	for i in _orbs.size():
		var o := _orbs[i]
		if i < slots.size():
			o.visible = true
			o.material_override = Fx.element(slots[i], 1.3)
			var ang := Time.get_ticks_msec() / 1000.0 * 2.2 + i * TAU / maxf(slots.size(), 1)
			o.position = Vector3(cos(ang) * 0.62, 2.1 + sin(ang * 2.0) * 0.05, sin(ang) * 0.62)
			var big := 1.25 if El.is_fused(slots[i]) else 1.0
			o.scale = Vector3.ONE * big
		else:
			o.visible = false
	# The gem wears the element its bolts will be, dark while the swing recovers.
	if bolt_el >= 0:
		model.gem.material_override = Fx.element(bolt_el, 0.3 if _swing_cd > 0.0 else 1.3)
	else:
		model.gem.material_override = Fx.glow(gem_color.darkened(0.75), 0.5) if _swing_cd > 0.0 else Fx.glow(Color(1.0, 0.85, 0.5), 3.0)
	_ward_shell.visible = ward_time > 0.0
	_shield_flash = maxf(0.0, _shield_flash - dt * 4.0)
	if ward_time > 0.0:
		var pulse := 0.95 + 0.05 * sin(Time.get_ticks_msec() / 150.0)
		_ward_shell.scale = Vector3(0.95, 1.05, 0.95) * pulse * (1.0 + 0.08 * _shield_flash)
		# Bright when full, thin as it wears down, a flash on every hit.
		var m := _ward_shell.material_override as StandardMaterial3D
		if m:
			var k := shield / maxf(shield_max, 1.0)
			m.emission_energy_multiplier = 0.25 + 0.6 * k + 1.5 * _shield_flash
			m.albedo_color.a = 0.06 + 0.16 * k + 0.2 * _shield_flash
	# The roll: squashed low, spinning on the spot.
	if _roll_t > 0.0:
		var k := 1.0 - _roll_t / ROLL_TIME
		body.scale = Vector3(1.15, 0.62, 1.15)
		body.rotation.y += k * TAU
	else:
		body.scale = body.scale.lerp(Vector3.ONE, 14.0 * dt)
	var bursting := _rb_t > 0.12 and pad and pad.down(Pad.RB)
	_charge_ring.visible = not _charging.is_empty() or bursting
	if bursting:
		var k2 := clampf(_rb_t / NOVA_HOLD, 0.0, 1.0)
		var sc2 := 0.6 + k2 * 1.6
		_charge_ring.scale = Vector3(sc2, 0.05, sc2)
		var col: Color = El.COLOR[slots[0]] if not slots.is_empty() else Color(0.7, 0.6, 0.5)
		_charge_ring.material_override = Fx.glow(col, 2.0 if k2 >= 1.0 else 1.0)
	elif _charge_ring.visible:
		var c := clampf(_charge_t / _charge_need, 0.0, 1.0)
		var sc := 0.6 + c * 1.1
		_charge_ring.scale = Vector3(sc, 0.05, sc)
	_aim_line.visible = not _charging.is_empty() and _reach(_charging) > 0.0
	if _aim_line.visible:
		var k := clampf(_charge_t / _charge_need, 0.0, 1.0)
		var reach := _reach(_charging)
		var w := 0.7 if _charging.shape == "spray" else 0.32
		var start := 0.7
		_aim_line.global_transform = Transform3D(Basis(Vector3.UP, atan2(aim_dir.x, aim_dir.z)), global_position + Vector3.UP * 0.05)
		_aim_track.scale = Vector3(w, 1.0, reach)
		_aim_track.position = Vector3(0, 0, start + reach * 0.5)
		# Ready: the line is full and throbs while you hold it.
		var beat := 1.0 + (0.25 * sin(Time.get_ticks_msec() / 60.0) if k >= 1.0 else 0.0)
		_aim_fill.scale = Vector3(w * 0.7 * beat, 1.0, maxf(reach * k, 0.01))
		_aim_fill.position = Vector3(0, 0.01, start + reach * k * 0.5)

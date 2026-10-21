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
##   RT  cast the queue ahead: it winds up first, the staff held out at the
##       aim and its gem swelling with the element, so everyone sees where it
##       will go; a tap fires it as soon as it is ready, holding RT keeps it
##       while you aim and fires on release
##   LS click  plant the queue at your feet: a trap, or a sentry when full
##   RS click  enchant the staff: for a while your swing becomes an element
##             weapon (a fire sword, a thunder hammer), bolts stay as they are
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
## Plain bolts when the queue is empty: weak, so loading is worth it.
const PLAIN_BOLT := Balance.PLAIN_BOLT
const MANA_PER_SWING := Balance.MANA_PER_SWING
const MANA_PER_DEFLECT := Balance.MANA_PER_DEFLECT
const SWING_COOLDOWN := 0.34
## After a swing the staff needs this long before it can swing again, so
## knocking bullets back is a timed choice, not a shield. The gem goes dark
## while it recovers and flashes when it is ready.
const SWING_RECOVER := 0.7
const SWING_REACH := 1.7
## Half the angle of the swing, each side of where you aim: what it hits and
## the bullets it knocks back.
const SWING_ARC := 1.3
const NOVA_HOLD := 0.45
const HERO_LIGHT := 3.2
const GEM_WARM := Color(1.0, 0.8, 0.55)
const WIZARD_LAYER := 2
## The roll is a commitment, not a dash: it pushes off hard, then slows to
## a stop, and you are only untouchable for its first part. Afterwards you
## stumble for a moment, so rolling all the time is slower than walking.
const ROLL_TIME := 0.5
const ROLL_SPEED := 12.5
const ROLL_IFRAMES := 0.3
const ROLL_RECOVER := 0.15
const ROLL_COOLDOWN := 0.95

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
const WINDUP := Balance.WINDUP
## A winding-up spell shows on the staff alone: the gem swells and glows,
## the element pours off it, and it crackles once the spell is ready.
var _charge_halo: MeshInstance3D
var _charge_parts: CPUParticles3D
var _crackle_t := 0.0
var _bolt_t := 0.0
var _roll_t := 0.0
var _roll_cd := 0.0
var _roll_dir := Vector3.ZERO
var _roll_recover := 0.0
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
var _tomb: Node3D
var _remains: Remains
## The swing's arc on the ground: sweeps open on a swing, and shows faintly
## while a bullet is close so you can see what you would knock back.
var _zone: MeshInstance3D
## A little light at the staff's gem that blooms with every shot, and how
## far into its bloom the gem is (1 just fired, fading to 0).
## The colour of the bare gem, and the bloom of each shot (its colour).
var _flash_c := GEM_WARM
var _gem_halo: MeshInstance3D
## How bright the staff light is now, 1 = HERO_LIGHT; eased toward its target.
var _shine := 1.0
var _bloom := 0.0
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
	_size_sword()
	add_child(model.root)
	_remains = Remains.new().setup(self, model)
	add_child(_remains)
	meshes = model.meshes
	setup_status_fx()
	# The light round each wizard, Diablo style: the world is dark and you
	# carry a warm pool of it with you, casting real shadows. It comes from
	# the gem on the staff (Joep), so it follows the staff and lives with
	# what the wizard does (_staff_light).
	_light = OmniLight3D.new()
	_light.light_color = GEM_WARM
	_light.light_energy = HERO_LIGHT
	_light.omni_range = 12.0
	_light.omni_attenuation = 1.1
	_light.top_level = true
	_light.shadow_enabled = true
	_light.shadow_blur = 1.5
	# Two shadow passes instead of six: from above nobody sees the seams.
	_light.omni_shadow_mode = OmniLight3D.SHADOW_DUAL_PARABOLOID
	# The staff light sits by the wizard's own hat and shoulders: those would
	# throw a huge shadow round the feet. Wizards stand on render layer 2,
	# which casts in the moon's light but not in the staff lights.
	_light.shadow_caster_mask = 0xFFFFF & ~WIZARD_LAYER
	for g in (model.root as Node3D).find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).layers = WIZARD_LAYER
	add_child(_light)
	# Facing down, so all the ground below lies in one of the two halves.
	_light.global_rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	# The gem's glow: a soft bloom round it that swells with the light.
	_gem_halo = Fx.halo(GEM_WARM, 0.6, 0.8)
	_gem_halo.material_override = _gem_halo.material_override.duplicate()
	_gem_halo.top_level = true
	add_child(_gem_halo)
	# The queued elements ride on the staff, small balls circling its gem.
	for i in SpellQueue.SIZE:
		var o := Art.part(model.staff, Art.sphere(0.065, 10), Fx.element(El.FIRE, 1.3))
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
	if enchant_time > 0.0:
		enchant_time -= dt
		if enchant_time <= 0.0:
			_enchant_end()
	bolt_el = queue.slots[0] if not queue.is_empty() else -1
	_read_input(dt)
	if _roll_t > 0.0:
		_roll_t -= dt
		drive(_roll_dir * ROLL_SPEED * roll_speed(1.0 - _roll_t / ROLL_TIME), dt)
		if _roll_t <= 0.0:
			_roll_recover = ROLL_RECOVER
		_visuals(dt)
		return
	_roll_recover = maxf(0.0, _roll_recover - dt)
	var mv := Vector3(pad.move.x, 0, pad.move.y)
	var spd := move_speed()
	if channel and is_instance_valid(channel) and channel.is_physics_processing():
		spd *= 0.55
	elif not _charging.is_empty():
		spd *= 0.6
	if _roll_recover > 0.0:
		spd *= 0.7
	drive(_leash(mv) * spd, dt)
	_visuals(dt)


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
		cast("enchant", -1)
	_bolt_t -= dt
	# Swinging the staff stops the bolts for a moment: your hands are busy.
	if pad.fire and _bolt_t <= 0.0 and not busy() and _swing_t <= 0.0:
		_bolt_t = 1.0 / shot_rate()
		shoot()
	if pad.pressed(Pad.UP) and not last_cast.is_empty():
		load_slots(last_cast)
		_conjure_fx()
	for b in [Pad.LEFT, Pad.RIGHT]:
		if pad.down(b):
			_save_t[b] = _save_t.get(b, 0.0) + dt
			if _save_t[b] >= SAVE_HOLD and _save_t[b] - dt < SAVE_HOLD and not queue.is_empty():
				saved[b] = queue.copy()
				# Saved: a little gold sparkle off the gem, no words over your head.
				Fx.burst(staff_tip(), Color(1, 0.85, 0.4), 10, 2.0, 0.12)
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
	return {counts = counts, payload = [], primary = queue.slots[0], n = {}, scales = Balance.bolt_scales(counts, queue.slots[0], 1.0)}


## How many bolts a second the staff fires now: the front element's rate,
## or the enchantment's.
func shot_rate() -> float:
	if enchant_time > 0.0:
		return Balance.flight(enchant.primary).rate
	return Balance.flight(queue.slots[0] if not queue.is_empty() else -1).rate


## Bolts the front element of the queue is good for. The oldest one burns
## first and drops out of the queue when it is spent.
func full_ammo() -> int:
	return Balance.ammo(queue.slots[0]) if not queue.is_empty() else 0


## What an enchanted staff fires: the enchantment's elements, harder than
## a loaded bolt, costing nothing from the queue while it lasts.
func enchanted_bolt() -> Dictionary:
	var scales := Balance.bolt_scales(enchant.counts, enchant.primary, Balance.ENCHANT_BOLT)
	return {counts = enchant.counts, payload = [], primary = enchant.primary, n = {}, scales = scales}


func shoot() -> void:
	var dir := aim_dir.rotated(Vector3.UP, randf_range(-0.03, 0.03))
	# Fired steadily, the staff stays up instead of bobbing with every shot.
	_cast_anim = maxf(_cast_anim, 1.0 / shot_rate() + 0.1)
	if enchant_time > 0.0:
		_enchanted_shot(dir)
		return
	var bs := bolt_spell()
	var b := BoltFx.new().setup(self, bs, dir)
	Game.I.spawn(b, staff_tip() + dir * 0.1)
	_muzzle_flash(El.COLOR[bs.primary] if bs.primary >= 0 else Color.WHITE)
	if not queue.is_empty():
		ammo -= 1
		if ammo <= 0:
			var gone: int = queue.slots.pop_front()
			ammo = full_ammo()
			Fx.burst(global_position + Vector3.UP * 2.1, El.COLOR[gone], 8, 2.0, 0.2)
	_trace_once("shoot")
	Game.I.count("shots")


## The sword swing: hits monsters in front with your element and knocks
## their bullets back the way you aim.
func melee() -> void:
	# The sword is in the other hand: it swings while the staff pours out a
	# stream (Joep), just not mid-roll or mid-windup.
	if _swing_t > 0.0 or _swing_cd > 0.0 or not _charging.is_empty() or _roll_t > 0.0:
		return
	_swing_t = SWING_COOLDOWN
	_swing_cd = SWING_COOLDOWN + SWING_RECOVER
	_trace_once("melee")
	Game.I.count("swings")
	var bonk := {counts = {El.EARTH: 1}, payload = [], primary = El.EARTH, n = {}}
	var touch := bolt_spell()
	if enchant_time > 0.0:
		_enchanted_swing()
	for a in Game.I.enemies:
		if not is_instance_valid(a) or not a.alive:
			continue
		var to: Vector3 = a.global_position - global_position
		to.y = 0
		if to.length() > SWING_REACH + a.radius or absf(aim_dir.signed_angle_to(to, Vector3.UP)) > SWING_ARC + atan2(a.radius, maxf(to.length(), 0.1)):
			continue
		var whet := float(_mod("sword", 1.0))
		a.hit_spell(bonk, 0.4 * whet, self, to.normalized())
		if enchant_time <= 0.0:
			BoltFx.strike(a, touch, 2.5 * whet, self, to.normalized())
		add_mana(MANA_PER_SWING)
	# The sword smashes what stands in the arc too.
	var cut := enchant_reach() if enchant_time > 0.0 else SWING_REACH
	for p in Game.I.arena.props.duplicate():
		if not is_instance_valid(p):
			continue
		var tp: Vector3 = p.global_position - global_position
		tp.y = 0
		if tp.length() < cut + 0.6 and absf(aim_dir.signed_angle_to(tp, Vector3.UP)) < SWING_ARC + 0.3:
			p.damage(4.0, aim_dir)
	_swing_dir = aim_dir
	_deflect_sweep()
	var sc: Color = El.COLOR[bolt_el] if bolt_el >= 0 else Color(1.0, 0.85, 0.5)
	Fx.burst(global_position + aim_dir * 1.4 + Vector3.UP, sc.lerp(Color(0.95, 0.9, 0.75), 0.4), 10 if enchant.is_empty() else 22, 3.5, 0.22, int(enchant.get("primary", -1)))
	_zone_mat.set_shader_parameter("color", sc.lerp(Color(1.0, 0.9, 0.6), 0.5))
	if enchant_time > 0.0:
		_spend_enchant(Balance.enchant_swing(enchant))


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


var _stride := 0.0


## Legs step while walking, the free arm swings against them and reaches
## out to cast, and the staff arm follows the hand on the staff.
func _limbs(dt: float, moving: bool, lift: float) -> void:
	if not model.has("leg_l"):
		return
	_stride = lerpf(_stride, 1.0 if moving and _roll_t <= 0.0 else 0.0, 1.0 - exp(-10.0 * dt))
	var step := sin(_walk) * _stride
	var leg_l: Node3D = model.leg_l
	var leg_r: Node3D = model.leg_r
	leg_l.rotation.x = step * 0.6
	leg_r.rotation.x = -step * 0.6
	# Tucked in a roll.
	var tuck := sin((1.0 - _roll_t / ROLL_TIME) * PI) if _roll_t > 0.0 else 0.0
	leg_l.rotation.x -= tuck * 1.2
	leg_r.rotation.x -= tuck * 1.2
	# Each arm reaches for what its hand holds: the staff and the sword.
	for pair in [[model.arm_r, model.staff], [model.arm_l, model.sword]]:
		var arm: Node3D = pair[0]
		var held: Node3D = pair[1]
		var to_hand := held.position - arm.position
		if to_hand.length() > 0.01:
			arm.basis = Basis(Quaternion(Vector3.DOWN, to_hand.normalized()))



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


## How fast the roll goes at [param k] of the way through it, 0 to 1: a quick
## push off, then an even ease to a stop. About 3.3 m in half a second: a bit
## quicker than walking, not a dash (Joep: the heavier Dark Souls roll that
## covered less ground than walking was punished too hard).
static func roll_speed(k: float) -> float:
	if k < 0.15:
		return 0.4 + 0.6 * k / 0.15
	return clampf(1.0 - (k - 0.15) / 0.85, 0.0, 1.0)


## A dodge roll the way you walk, untouchable at its start.
func roll() -> void:
	if _roll_cd > 0.0 or _roll_t > 0.0 or not can_act():
		return
	var d := Vector3(pad.move.x, 0, pad.move.y)
	if d.length() < 0.2:
		d = aim_dir
	_roll_dir = d.normalized()
	_roll_t = ROLL_TIME
	_roll_cd = ROLL_COOLDOWN
	invuln = ROLL_IFRAMES
	if channel and is_instance_valid(channel):
		channel = null
	_trace_once("dodge")
	Game.I.count("rolls")


## Load one element for mana.
func conjure(e: int) -> void:
	var trial := SpellQueue.new()
	trial.size = queue.size
	trial.set_slots(queue.copy())
	if trial.add(e) == "full":
		return
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
		ammo = full_ammo()
	var c: Color = El.COLOR[e]
	if what == "fuse":
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
	ammo = full_ammo()


func _no_mana() -> void:
	no_mana = 0.6
	# The gem fizzles: a dull blue puff, and the mana bar flashes (no_mana).
	Fx.puff(staff_tip(), Color(0.3, 0.4, 0.75), 0.35)
	_trace_once("no mana")
	if Game.I:
		Game.I.count("no_mana")


func _conjure_fx() -> void:
	pass


## What [param form] would cast now. Short of mana for the whole queue it
## falls back to the biggest spell you can pay for: the front of the queue,
## the last elements left out (the HUD dims those). With no mana even for
## one element it is the whole queue again, and casting says no.
func preview(form: String) -> Dictionary:
	var slots := queue.copy()
	var n := affordable(form)
	return Grammar.compose(slots.slice(0, n) if n > 0 else slots, form, mods())


## How many of the queued elements, from the front, a [param form] cast can
## pay for right now.
func affordable(form: String) -> int:
	var slots := queue.copy()
	for n in range(slots.size(), 0, -1):
		var s := Grammar.compose(slots.slice(0, n), form, mods())
		if mana >= cost(s) - 0.01:
			return n
	return 0


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
	# What the spell did not use stays loaded, front first.
	var used: int = s.slots.size()
	var rest := queue.copy().slice(used)
	if used > 0:
		last_cast = queue.copy().slice(0, used)
	queue.clear()
	if not rest.is_empty():
		queue.set_slots(rest)
		ammo = full_ammo()
	_cast_anim = 0.3
	if Game.I:
		Game.I.on_cast(self, s)
	match s.shape:
		"spray", "beam", "strike", "projectile", "overload":
			_charging = s
			_charge_t = 0.0
			_charge_need = WINDUP[s.shape] * float(_mod("charge", 1.0))
			_charge_start(s.primary)
		"nova":
			Game.I.spawn(NovaFx.new().setup(self, s), global_position)
			if _mod("echo", false):
				var again := NovaFx.new().setup(self, s) as NovaFx
				get_tree().create_timer(0.35).timeout.connect(func(): if is_instance_valid(self): Game.I.spawn(again, global_position))
		"trap":
			_plant(TrapFx.new().setup(self, s), _traps, MAX_TRAPS + (2 if _mod("planter", false) else 0))
		"sentry":
			_plant(SentryFx.new().setup(self, s), _sentries, 2 if _mod("planter", false) else 1)
		"enchant":
			_enchant(s)
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
	_charge_stop()
	_cast_anim = 0.3
	# The spell leaves the staff with a flash.
	Fx.burst(staff_tip(), El.COLOR[s.primary], 14, 4.0, 0.14)
	match s.shape:
		"spray":
			_channel(SprayFx.new().setup(self, s), Pad.RT, staff_tip())
		"beam":
			_channel(BeamFx.new().setup(self, s), Pad.RT, staff_tip())
		"strike":
			Game.I.spawn(StrikeFx.new().setup(self, s), _cast_point(s))
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


## The gem lights up in the spell's element: a glow round it and the
## element streaming off it (fire licks up, frost and water drip, lightning
## and storm spit sparks).
func _charge_start(e: int) -> void:
	_charge_stop()
	var c: Color = El.COLOR[e]
	_charge_halo = Fx.halo(c, 0.4, 1.4, 1.0)
	model.staff.add_child(_charge_halo)
	_charge_halo.position = model.gem.position
	var energy: bool = El.KIND[e] == El.Kind.ENERGY
	_charge_parts = Fx.particles(c, 40, 0.35 if energy else 0.5, 0.13)
	_charge_parts.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_charge_parts.emission_sphere_radius = 0.12
	_charge_parts.direction = Vector3.UP
	_charge_parts.spread = 180.0 if energy else 35.0
	var rise := 2.5
	if e in [El.FROST, El.WATER, El.ICE, El.MUD, El.EARTH, El.POISON]:
		rise = -2.0
	_charge_parts.gravity = Vector3.UP * rise
	_charge_parts.initial_velocity_min = 0.3
	_charge_parts.initial_velocity_max = 2.5 if energy else 0.9
	Parts.style(_charge_parts, e)
	model.staff.add_child(_charge_parts)
	_charge_parts.position = model.gem.position
	_charge_parts.emitting = true
	if _charging.shape in REMOTE and Fx.root:
		_cast_mark = CastMark.new().setup(e, _mark_radius(_charging))
		Fx.root.add_child(_cast_mark)
		_cast_mark.global_position = _cast_point(_charging)
		if _rolls(_charging):
			_cast_mark.set_lane(OverloadFx.WAVE_WIDTH, OverloadFx.WAVE_RUN)
			_cast_mark.look_at(_cast_mark.global_position + aim_dir, Vector3.UP)


## Spells that strike away from you show where while they charge.
const REMOTE := ["projectile", "beam", "strike", "overload"]
var _cast_mark: CastMark


func _mark_radius(s: Dictionary) -> float:
	match s.shape:
		"overload":
			return OverloadFx.REACH.get(s.primary, 4.5)
		"projectile":
			return maxf(0.9, float(s.n.get("splash", 0.0)) * 0.8)
		"strike":
			return float(s.n.radius)
	return 0.9


## A tidal wave rolls forward from you instead of landing on a spot.
func _rolls(s: Dictionary) -> bool:
	return s.shape == "overload" and s.primary == El.WATER


## Where the charging spell would strike if let go now: an overload's
## spot, otherwise the first monster in line, a wall, or as far as it goes.
func _cast_point(s: Dictionary) -> Vector3:
	var at: Vector3
	if s.shape == "overload":
		if _rolls(s):
			# The middle of the strip the wave will sweep.
			at = global_position + aim_dir * (OverloadFx.WAVE_START + OverloadFx.WAVE_RUN * 0.5)
			return at * Vector3(1, 0, 1)
		at = global_position if _overload_here(s) else global_position + aim_dir * OVERLOAD_REACH
		return Game.I.arena.clamp_inside(at) * Vector3(1, 0, 1)
	var reach: float = 12.0 if s.shape == "projectile" else float(s.n.get("range", 10.0))
	var from := global_position + Vector3.UP * 1.1
	var best := reach
	for a in Game.I.enemies:
		if not is_instance_valid(a) or not a.alive:
			continue
		var to: Vector3 = a.global_position - global_position
		to.y = 0.0
		var along := to.dot(aim_dir)
		if along > 0.0 and along < best and (to - aim_dir * along).length() < a.radius + 0.5:
			best = along
	var wall: Dictionary = Game.I.arena.ray(from, from + aim_dir * best)
	if wall:
		best = minf(best, (wall.position - from).length() - 0.3)
	at = global_position + aim_dir * maxf(best, 1.0)
	return Vector3(at.x, 0.0, at.z)


func _charge_stop() -> void:
	if _cast_mark:
		_cast_mark.finish()
		_cast_mark = null
	if _charge_halo:
		_charge_halo.queue_free()
		_charge_halo = null
	if _charge_parts:
		_charge_parts.emitting = false
		_charge_parts.reparent(Fx.root if Fx.root else self)
		get_tree().create_timer(0.6).timeout.connect(_charge_parts.queue_free)
		_charge_parts = null
	if model:
		model.gem.scale = Vector3.ONE


## While a spell winds up the gem swells and burns brighter; once ready it
## throbs and crackles until you let go.
func _charge_look(dt: float) -> void:
	if _charging.is_empty() or not _charge_halo:
		return
	var k := clampf(_charge_t / _charge_need, 0.0, 1.0)
	var full := k >= 1.0
	var beat := 0.12 * sin(Time.get_ticks_msec() / 55.0) if full else 0.0
	model.gem.scale = Vector3.ONE * (1.0 + 0.9 * k + beat)
	model.gem.material_override = Fx.element(_charging.primary, 1.3 + 3.0 * k)
	_charge_halo.scale = Vector3.ONE * (0.35 + 1.1 * k + beat * 2.0)
	_charge_parts.speed_scale = 0.6 + 0.8 * k
	if _cast_mark:
		var want := _cast_point(_charging)
		# Glides after the aim instead of snapping between monsters.
		_cast_mark.global_position = _cast_mark.global_position.lerp(want, minf(1.0, 18.0 * dt))
		if _rolls(_charging):
			_cast_mark.global_position = want
			_cast_mark.look_at(want + aim_dir, Vector3.UP)
		_cast_mark.set_charge(k)
	_charge_parts.emission_sphere_radius = 0.1 + 0.12 * k
	if full:
		_crackle_t -= dt
		if _crackle_t <= 0.0:
			_crackle_t = randf_range(0.08, 0.16)
			Fx.burst(staff_tip(), El.COLOR[_charging.primary].lerp(Color.WHITE, 0.4), 5, 3.5, 0.08)


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


## An enchantment (RS) lays the queue on your sword for a while and turns
## the swing (RB) into an element weapon, close up and risky but strong:
## the sword grows (up to SWORD_MAX with five elements) and turns to the
## element, hits with it, and each element adds its own trick
## (_enchanted_swing). The bolts change too (_enchanted_shot). Nothing
## heals you.
var enchant := {}
var enchant_time := 0.0
var _enchant_parts: CPUParticles3D
## What is left of the enchantment's store of damage (Balance.enchant_store):
## every enchanted bolt and swing spends what it is worth.
var enchant_store := 0.0
var _enchant_full := 1.0
var _enchant_power := 0.0
## How far a full enchantment (five elements) makes the sword reach.
const SWORD_MAX := 3.0
## Where the sword's hilt is from the wizard's middle when it swings flat.
const SWORD_HAND := 0.62


## An enchanted staff shoots its element's own way (BoltFx.charmed): fire
## bolts burst, frost shards pierce, water sprays three, lightning jumps on,
## earth stuns, air hurls, void drags in, poison leaves a puddle.
func _enchanted_shot(dir: Vector3) -> void:
	var s := enchanted_bolt()
	var spend := Balance.enchant_shot(enchant, s.scales)
	var bases := {}
	for e in s.counts:
		for b in El.parts(e):
			bases[b] = true
	var dirs := [dir]
	if El.WATER in bases:
		dirs = [dir.rotated(Vector3.UP, -0.13), dir, dir.rotated(Vector3.UP, 0.13)]
		for e in s.scales:
			s.scales[e] *= 0.5
	for d: Vector3 in dirs:
		var b := BoltFx.new().setup(self, s, d)
		b.charmed = bases
		Game.I.spawn(b, staff_tip() + d * 0.1)
	_muzzle_flash(El.COLOR[s.primary] if s.primary >= 0 else Color.WHITE)
	_trace_once("enchanted shot")
	Game.I.count("shots")
	_spend_enchant(spend)


## Every shot makes the staff's gem bloom for a moment, in the element's
## colour: it swells a little, glows brighter and casts a soft light.
func _muzzle_flash(c: Color) -> void:
	_flash_c = c
	_bloom = 1.0


## How much of the enchantment is left, 1 to 0: whichever runs out first,
## its store (spent by every enchanted bolt and swing) or its time.
func enchant_left() -> float:
	if enchant_time <= 0.0 or enchant.is_empty():
		return 0.0
	var by_time := enchant_time / maxf(float(enchant.n.duration), 0.1)
	return minf(by_time, enchant_store / maxf(_enchant_full, 0.001))


## Take [param dmg] from the enchantment's store. As it runs low the
## element draws back to the sword's edges; spent, the sword is steel again.
func _spend_enchant(dmg: float) -> void:
	enchant_store -= dmg
	if enchant_store <= 0.0:
		_enchant_end()
		return
	if model.steel.material_override is ShaderMaterial:
		var left := enchant_store / _enchant_full
		(model.steel.material_override as ShaderMaterial).set_shader_parameter("power", _enchant_power * left)
		(model.steel.material_override as ShaderMaterial).set_shader_parameter("energy", 0.85 * (0.45 + 0.55 * left))


## How far an enchanted swing reaches: the blade grows with every element
## laid on the staff, and what you see is what it hits.
func enchant_reach() -> float:
	var n := 0
	for e in enchant.get("counts", {}):
		n += int(enchant.counts[e])
	if n <= 0:
		return SWING_REACH
	return SWING_REACH + (SWORD_MAX - SWING_REACH) * minf(n, SpellQueue.SIZE) / SpellQueue.SIZE


## The sword's blade as long as the swing reaches now.
func _size_sword() -> void:
	if model.has("steel"):
		(model.steel as MeshInstance3D).mesh = Art.blade_mesh(enchant_reach() - SWORD_HAND - Art.BLADE_AT)


## The enchanted swing: the staff's blade of elements lands on everything
## it sweeps through, and each element adds its trick. Bullets are still
## knocked back only as far as the bare staff reaches (_deflect_sweep).
func _enchanted_swing() -> void:
	var s := enchant
	var bases := {}
	for e in s.counts:
		for b in El.parts(e):
			bases[b] = true
	var reach := enchant_reach()
	var c: Color = El.COLOR[s.primary]
	if El.VOID in bases:
		# Void drags everything near into the arc first.
		for a in Game.I.enemies:
			if is_instance_valid(a) and a.alive and a.global_position.distance_to(global_position) < reach + 3.0:
				var d: Vector3 = global_position + aim_dir * 1.4 - a.global_position
				d.y = 0
				a.push += d.normalized() * 9.0
	var hit := 0
	for a in Game.I.enemies:
		if not is_instance_valid(a) or not a.alive:
			continue
		var to: Vector3 = a.global_position - global_position
		to.y = 0
		var ang := absf(aim_dir.signed_angle_to(to, Vector3.UP))
		if to.length() > reach + a.radius or ang > SWING_ARC + 0.2 + atan2(a.radius, maxf(to.length(), 0.1)):
			continue
		hit += 1
		var dir := to.normalized()
		a.hit_spell(s, Balance.ENCHANT_SWING, self, dir)
		if El.EARTH in bases:
			a.stun = maxf(a.stun, 0.8)
		if El.AIR in bases or El.WATER in bases:
			a.push += dir * (13.0 if El.AIR in bases else 8.0)
		if El.LIGHTNING in bases:
			# The hit jumps on to whoever stands near.
			for b in Game.I.enemies:
				if is_instance_valid(b) and b != a and b.alive and b.global_position.distance_to(a.global_position) < 3.0:
					b.hit_spell({counts = {El.LIGHTNING: 1}, payload = [], primary = El.LIGHTNING, n = {}}, 1.2, self, dir)
					Fx.burst(b.global_position + Vector3.UP, El.COLOR[El.LIGHTNING], 8, 5.0, 0.15, El.LIGHTNING)
	if El.FIRE in bases:
		var f: Field = Game.I.arena.add_field(Game.I.arena.clamp_inside(global_position + aim_dir * 2.2), El.FIRE, 1.3, 3.0, self)
		f.friendly = true
	if El.FROST in bases:
		Game.I.arena.touch_ground(global_position + aim_dir * 2.0, 2.0, El.FROST, self)
	# The blade's path: the element sprays off along the arc it cut.
	for i in 7:
		var k := (i - 3) / 3.0
		var at := global_position + aim_dir.rotated(Vector3.UP, k * SWING_ARC) * reach * 0.85 + Vector3.UP * 0.9
		Fx.burst(at, c, 10, 4.0, 0.25, s.primary)
	Fx.light_pop(global_position + aim_dir * 2.0, c, 2.5, 6.0, 0.2)
	if hit > 0:
		Game.I.shake(0.15)


func _enchant(s: Dictionary) -> void:
	_enchant_end()
	enchant = s
	enchant_time = s.n.duration
	enchant_store = Balance.enchant_store(s)
	_enchant_full = enchant_store
	var c: Color = El.COLOR[s.primary]
	var n := 0
	for e in s.counts:
		n += int(s.counts[e])
	# The sword takes the enchantment: it grows, the element runs along its
	# edges and up its ridge (sword.gdshader), the stone in its guard lights
	# and the element burns, sparks or drips off it along its whole length.
	_size_sword()
	var length := enchant_reach() - SWORD_HAND - Art.BLADE_AT
	var power := minf(n, SpellQueue.SIZE) / float(SpellQueue.SIZE)
	_enchant_power = power
	var sword: Node3D = model.sword
	(model.steel as MeshInstance3D).material_override = Fx.shader("sword", {
		element = s.primary, base = c, power = power, energy = 0.85})
	(model.stone as MeshInstance3D).material_override = Fx.glow(c, 3.0)
	_blade = Node3D.new()
	_blade.position.y = Art.BLADE_AT
	sword.add_child(_blade)
	var tip := Fx.halo(c, 0.3 + 0.08 * n, 0.55)
	tip.position.y = length
	_blade.add_child(tip)
	if s.primary in [El.FIRE, El.MAGMA]:
		# Tongues of fire licking up off both edges, more on a bigger sword.
		var flame := Fx.shader("flame")
		var q := QuadMesh.new()
		var count := 4 + n * 3
		for i in count:
			var f := MeshInstance3D.new()
			f.mesh = q
			f.material_override = flame
			var h := randf_range(0.3, 0.5) * (0.85 + 0.08 * n)
			f.scale = Vector3(h * 0.55, h, 1.0)
			var side := 1.0 if i % 2 == 0 else -1.0
			f.position = Vector3(side * 0.05, length * (0.15 + 0.85 * (float(i) + 0.5) / count), 0)
			f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_blade.add_child(f)
	_enchant_parts = Fx.particles(c, 10 + 6 * n, 0.4, 0.07 + 0.012 * n)
	_enchant_parts.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_enchant_parts.emission_box_extents = Vector3(0.05, length * 0.45, 0.02)
	_enchant_parts.position = Vector3(0, Art.BLADE_AT + length * 0.55, 0)
	_enchant_parts.direction = Vector3.UP
	_enchant_parts.spread = 40.0
	_enchant_parts.initial_velocity_min = 0.2
	_enchant_parts.initial_velocity_max = 0.5 + 0.12 * n
	Parts.style(_enchant_parts, s.primary, false)
	sword.add_child(_enchant_parts)
	_enchant_parts.emitting = true
	Fx.burst(sword.global_position + Vector3.UP * 0.5, c, 20, 4.0, 0.2, s.primary)


var _blade: Node3D


func _enchant_end() -> void:
	enchant = {}
	enchant_time = 0.0
	if _blade:
		_blade.queue_free()
		_blade = null
	if model and model.has("steel"):
		(model.steel as MeshInstance3D).material_override = Art.steel()
		(model.stone as MeshInstance3D).material_override = Fx.solid(Color(0.2, 0.22, 0.3), 0.2)
		_size_sword()
	if _enchant_parts:
		_enchant_parts.emitting = false
		var id := _enchant_parts.get_instance_id()
		get_tree().create_timer(0.8).timeout.connect(func():
			var p := instance_from_id(id)
			if p:
				p.queue_free())
		_enchant_parts = null


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
	_charge_stop()
	_enchant_end()
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
	_grave_lights()


## The grave calls out: a pillar of light up out of it you can find from
## anywhere, a glow on the stone, and motes that only rise while a friend
## stands close enough to raise you (Joep: clear where you are, and clear
## when it is working).
func _grave_lights() -> void:
	_grave_in = 0.0
	_grave_mat = Fx.shader("grave_beam", {color = GRAVE_CALM, strength = 0.0})
	var beam := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 0.7
	cyl.height = GRAVE_BEAM
	cyl.cap_top = false
	cyl.cap_bottom = false
	cyl.radial_segments = 20
	beam.mesh = cyl
	beam.material_override = _grave_mat
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.position.y = GRAVE_BEAM * 0.5
	_tomb.add_child(beam)
	# A soft pool of the same light on the ground round the stone.
	_grave_pool = Fx.halo(GRAVE_CALM, 4.5, 0.5)
	_grave_pool.material_override = _grave_pool.material_override.duplicate()
	_grave_pool.position.y = 0.3
	_tomb.add_child(_grave_pool)
	_grave_light = OmniLight3D.new()
	_grave_light.light_color = GRAVE_CALM
	_grave_light.light_energy = 0.0
	_grave_light.omni_range = 7.0
	_grave_light.position.y = 1.4
	_tomb.add_child(_grave_light)
	_grave_motes = Fx.particles(GRAVE_WARM, 24, 1.6, 0.14)
	_grave_motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	_grave_motes.emission_ring_axis = Vector3.UP
	_grave_motes.emission_ring_radius = 1.2
	_grave_motes.emission_ring_inner_radius = 0.9
	_grave_motes.emission_ring_height = 0.1
	_grave_motes.direction = Vector3.UP
	_grave_motes.spread = 10.0
	_grave_motes.gravity = Vector3.ZERO
	_grave_motes.initial_velocity_min = 1.5
	_grave_motes.initial_velocity_max = 3.0
	_grave_motes.radial_accel_min = -1.6
	_grave_motes.radial_accel_max = -1.0
	_grave_motes.emitting = false
	_tomb.add_child(_grave_motes)


## A friend standing at your grave raises you: REVIVE_NEED in about three
## seconds with one, faster with more. Walking away lets it fade again.
const REVIVE_RATE := 14.0
const REVIVE_REACH := 1.9
var _raise_fx := 0.0
const GRAVE_BEAM := 16.0
const GRAVE_CALM := Color(0.62, 0.8, 1.0)
const GRAVE_WARM := Color(1.0, 0.82, 0.45)
var _grave_mat: ShaderMaterial
var _grave_light: OmniLight3D
var _grave_pool: MeshInstance3D
var _grave_motes: CPUParticles3D
## Ramps up once the stone has risen, so the pillar fades in.
var _grave_in := 0.0


func _raise(dt: float) -> void:
	if not Game.I or Game.I.paused_play:
		return
	var n := 0
	for w in Game.I.wizards:
		if w != self and w.alive and _grave_dist(w.global_position) < REVIVE_REACH:
			n += 1
	_grave_look(n > 0, dt)
	if n == 0:
		_revive = maxf(0.0, _revive - REVIVE_RATE * 0.5 * dt)
		return
	_raise_fx -= dt
	if _raise_fx <= 0.0:
		_raise_fx = 0.35
		Fx.ring(global_position + Vector3.UP * 0.04, Color(1.0, 0.85, 0.5), REVIVE_REACH * (1.0 - _revive / REVIVE_NEED * 0.7), 0.35)
	revive_progress(REVIVE_RATE * n * dt)


## How far from the grave: the stone or the body beside it, whichever is nearer.
func _grave_dist(at: Vector3) -> float:
	var d := at.distance_to(global_position)
	if _tomb:
		d = minf(d, at.distance_to(_tomb.global_position))
	return d


## The pillar burns warmer and wider as you are raised, the stone lights up
## and motes stream in; walking away lets it all settle back.
func _grave_look(near: bool, dt: float) -> void:
	if _grave_mat == null or _tomb == null:
		return
	var k := clampf(_revive / REVIVE_NEED, 0.0, 1.0)
	var warm := 1.0 if near else k
	_grave_mat.set_shader_parameter("color", GRAVE_CALM.lerp(GRAVE_WARM, warm))
	if _tomb.position.y > -0.05:
		_grave_in = move_toward(_grave_in, 1.0, dt * 1.2)
	_grave_mat.set_shader_parameter("strength", _grave_in * (1.0 + (0.6 if near else 0.0) + 1.6 * k))
	_grave_light.light_color = GRAVE_CALM.lerp(GRAVE_WARM, warm)
	var pool := _grave_pool.material_override as ShaderMaterial
	pool.set_shader_parameter("color", GRAVE_CALM.lerp(GRAVE_WARM, warm))
	pool.set_shader_parameter("strength", _grave_in * (0.6 + (0.3 if near else 0.0) + 0.6 * k))
	var want := _grave_in * (1.5 + (1.5 if near else 0.0) + 3.0 * k)
	_grave_light.light_energy = lerpf(_grave_light.light_energy, want, minf(1.0, 6.0 * dt))
	_grave_motes.emitting = near
	_grave_motes.speed_scale = 1.0 + 1.5 * k


func revive_progress(amount: float) -> void:
	_revive += amount
	if _revive >= REVIVE_NEED:
		revive(0.4)


func revive(frac: float) -> void:
	if alive:
		return
	alive = true
	hp = max_hp * frac
	_light.light_energy = HERO_LIGHT
	if _tomb:
		var tomb := _tomb
		_tomb = null
		if _grave_mat:
			# One last flare up the pillar as you stand, then it goes out.
			Fx.light_pop(tomb.global_position, GRAVE_WARM, 4.0, 8.0, 0.6)
			var fl := tomb.create_tween()
			fl.tween_property(_grave_mat, "shader_parameter/strength", 5.0, 0.12)
			fl.tween_property(_grave_mat, "shader_parameter/strength", 0.0, 0.45)
			_grave_motes.emitting = false
			_grave_mat = null
		var tw := tomb.create_tween()
		tw.tween_property(tomb, "position:y", -1.3, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(tomb.queue_free)
	frozen = 0.0
	chill = 0.0
	stun = 0.0
	# A moment to stand up while the pieces fly back together.
	invuln = maxf(invuln, 1.2)
	_remains.revive()


## The gem is the light you carry, and it tells what the wizard is doing:
## each element gathered in the queue feeds it and tints it toward that
## element; winding up a charge or a burst swells it; every shot flares it
## in the spell's colour; it dims for a moment after a sword swing; and
## when hurt badly it gutters, flickering lower the closer death comes.
func _staff_light(dt: float, nova_k: float) -> void:
	var at := staff_tip() + Vector3.UP * 0.15
	_light.global_position = at
	_gem_halo.global_position = at - Vector3.UP * 0.15
	_gem_halo.visible = alive
	if not alive:
		return
	var slots := queue.slots
	var tint := GEM_WARM
	if not slots.is_empty():
		var mix := Color(0, 0, 0)
		for e in slots:
			mix += El.COLOR[e]
		mix /= slots.size()
		tint = GEM_WARM.lerp(mix, 0.35 + 0.1 * slots.size())
	var want := 1.0 + 0.12 * slots.size()
	var winding := not _charging.is_empty() or nova_k > 0.0
	if winding:
		var t := Time.get_ticks_msec() / 1000.0
		want += 0.45 * maxf(nova_k, 0.6) + 0.08 * sin(t * 18.0)
	if _swing_cd > 0.0:
		want *= 0.65
	var low := clampf(1.0 - hp / (max_hp * 0.35), 0.0, 1.0)
	if low > 0.0:
		var t2 := Time.get_ticks_msec() / 1000.0
		var gutter := 0.5 + 0.5 * sin(t2 * 11.0 + sin(t2 * 3.7) * 4.0)
		want *= 1.0 - low * (0.25 + 0.3 * gutter)
		tint = tint.lerp(Color(1.0, 0.45, 0.3), low * 0.5)
	_shine = lerpf(_shine, want, minf(1.0, 8.0 * dt))
	var shine := _shine + 0.7 * _bloom
	_light.light_energy = HERO_LIGHT * shine
	_light.light_color = tint.lerp(_flash_c, _bloom * 0.7)
	var hm := _gem_halo.material_override as ShaderMaterial
	hm.set_shader_parameter("color", _light.light_color)
	hm.set_shader_parameter("strength", 0.55 * shine)
	_gem_halo.scale = Vector3.ONE * (0.45 + 0.25 * shine)


func _visuals(dt: float) -> void:
	var body: Node3D = model.body
	var target_yaw := atan2(aim_dir.x, aim_dir.z)
	body.rotation.y = lerp_angle(body.rotation.y, target_yaw, 14.0 * dt)
	_bloom = maxf(0.0, _bloom - dt * 7.0)
	var moving := velocity.length() > 0.5
	_walk += dt * (9.0 if moving else 0.0)
	body.position.y = absf(sin(_walk)) * 0.07 if moving else 0.0
	body.rotation.z = sin(_walk) * 0.05 if moving else 0.0
	var staff: Node3D = model.staff
	var lift := 0.0
	if _cast_anim > 0.0 or (channel and is_instance_valid(channel)) or not _charging.is_empty():
		lift = 1.0
	# Casting points the staff ahead (positive x tips the gem forward).
	# Winding up holds it out level, the gem pointing where the spell goes.
	var point := 1.45 if not _charging.is_empty() else 0.95
	staff.rotation.x = lerpf(staff.rotation.x, point * lift, 12.0 * dt)
	staff.position.z = lerpf(staff.position.z, 0.18 + 0.25 * lift, 12.0 * dt)
	_limbs(dt, moving, lift)
	# The swing: the staff sweeps flat from one side to the other, the body
	# twists with it, and the arc on the ground opens behind the staff.
	var sweep := 1.0 - _swing_t / SWING_COOLDOWN if _swing_t > 0.0 else -1.0
	var sword: Node3D = model.sword
	if sweep >= 0.0:
		var e := 1.0 - pow(1.0 - minf(sweep * 1.6, 1.0), 3.0)
		# The sword arm thrown out, the blade flat, cutting from right to left:
		# the sword is in the right hand, so it comes across the body.
		sword.position = sword.position.lerp(Vector3(-0.15, 0.95, 0.5), 1.0 - exp(-30.0 * dt))
		sword.rotation = Vector3(PI * 0.5, lerpf(-1.9, 1.9, e), 0.0)
		body.rotation.y = target_yaw + lerpf(-0.6, 0.6, e)
		_zone.visible = true
		# An enchanted blade sweeps a wider arc on the floor too.
		var zs := (enchant_reach() + 0.3) / (SWING_REACH + 0.3) if enchant_time > 0.0 else 1.0
		# The arc opens the way the blade sweeps. Mirrored in the shader, not
		# by a negative scale, which turns the whole arc round behind you.
		_zone.scale = Vector3(zs, 1.0, zs)
		_zone_mat.set_shader_parameter("mirror", true)
		_zone_mat.set_shader_parameter("progress", e)
		_zone_mat.set_shader_parameter("strength", (1.0 - smoothstep(0.55, 1.0, sweep)) * (0.45 if enchant_time > 0.0 else 1.0))
		_place_zone(_swing_dir)
	else:
		staff.rotation.y = 0.0
		# At rest the sword is carried low at the side, the point forward and
		# down, held just off the floor: a longer blade is held flatter, so
		# its whole length shows from above. Walking swings it with the step.
		var rest := Vector3(-0.4, 0.74, 0.12 - sin(_walk) * _stride * 0.08)
		var length := enchant_reach() - SWORD_HAND + 0.05
		var dip := asin(clampf((rest.y - 0.12) / length, 0.0, 1.0)) * 0.9
		sword.position = sword.position.lerp(rest, 1.0 - exp(-12.0 * dt))
		sword.rotation = sword.rotation.lerp(Vector3(PI * 0.5 + dip, 0.0, 0.32 + sin(_walk) * _stride * 0.05), 1.0 - exp(-12.0 * dt))
		_zone.scale = Vector3.ONE
		# No hint when a bullet could be deflected (Joep): you know RB does it.
		_zone.visible = false
	# The queue rides on the staff: up to three small balls circling the gem,
	# which wears the element the bolts will be.
	var slots := queue.slots
	var gem_color := Color(0.9, 0.85, 0.7)
	var gem_at: Vector3 = model.gem.position
	# Holding RB to burst the queue: the balls spin faster and swing wider,
	# and the gem swells, so the windup shows on the staff.
	var nova_k := 0.0
	if _rb_t > 0.12 and pad and pad.down(Pad.RB) and not slots.is_empty():
		nova_k = clampf(_rb_t / NOVA_HOLD, 0.0, 1.0)
	for i in _orbs.size():
		var o := _orbs[i]
		if i < slots.size():
			o.visible = true
			o.material_override = Fx.element(slots[i], 1.5)
			var ang := Time.get_ticks_msec() / 1000.0 * (3.0 + 9.0 * nova_k) + i * TAU / maxf(slots.size(), 1)
			var r := 0.24 + 0.14 * nova_k
			o.position = gem_at + Vector3(cos(ang) * r, sin(ang * 2.0) * 0.03 - 0.02, sin(ang) * r)
			var big := 1.3 if El.is_fused(slots[i]) else 1.0
			o.scale = Vector3.ONE * big * (1.0 + 0.4 * nova_k)
		else:
			o.visible = false
	# The gem wears the element its bolts will be, dark while the swing recovers.
	if bolt_el >= 0:
		# Stepped, so the bloom reuses a handful of materials.
		var glow := snappedf(1.3 + 1.2 * _bloom, 0.2)
		model.gem.material_override = Fx.element(bolt_el, 0.3 if _swing_cd > 0.0 else glow)
		if _charging.is_empty():
			model.gem.scale = Vector3.ONE * (1.0 + 0.3 * _bloom + 0.6 * nova_k)
	else:
		model.gem.material_override = Fx.glow(gem_color.darkened(0.75), 0.5) if _swing_cd > 0.0 else Fx.glow(Color(1.0, 0.88, 0.6), 6.0)
	_staff_light(dt, nova_k)
	# The roll: one tucked somersault forward the way you roll, turning
	# round the middle of the body, quick at first and landing softly.
	if _roll_t > 0.0:
		var k := 1.0 - _roll_t / ROLL_TIME
		var ang := TAU * (1.0 - pow(1.0 - k, 2.0))
		var mid := 0.55
		var tuck := sin(k * PI)
		body.rotation = Vector3(ang, atan2(_roll_dir.x, _roll_dir.z), 0.0)
		var off := Vector3(0.0, mid * (1.0 - cos(ang)), -mid * sin(ang))
		# Lifted while upside down, so the hat clears the floor.
		body.position = off.rotated(Vector3.UP, body.rotation.y) + Vector3.UP * 0.5 * sin(ang * 0.5)
		body.scale = Vector3(1.0 + 0.08 * tuck, 1.0 - 0.35 * tuck, 1.0 + 0.08 * tuck)
	else:
		body.rotation.x = 0.0
		body.position.x = 0.0
		body.position.z = 0.0
		body.scale = body.scale.lerp(Vector3.ONE, 14.0 * dt)
	_charge_look(dt)

class_name TrapFx
extends SpellFx
## Planting one to four elements (LS click): a trap at your feet. It arms
## after a moment and goes off when a monster comes close; your side never
## sets it off and is never hurt by it. What it does follows the class of
## its lead element:
##   flow (fire, frost, water, steam, air)  a blast that spills a field
##   solid (earth, ice, mud, magma)         spikes that pin monsters down
##   energy (lightning, storm)              a blast
##   void                                   pulls monsters in, then blasts
##   life                                   a healing rune, not a trap: it
##                                          pulses for your side while it lasts

const ARM_TIME := 0.5
## Void drags monsters in for this long before it blows.
const PULL_TIME := 0.6

var _gem: MeshInstance3D
var _ring: MeshInstance3D
var _pulse_t := 0.0
var _pull := -1.0
var _done := false
var _lit := false


func _enemy_team() -> int:
	return 1 if caster.team == 0 else 0


func _ready() -> void:
	var c := color()
	_ring = MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.82
	tor.outer_radius = 1.0
	tor.rings = 24
	tor.ring_segments = 4
	_ring.mesh = tor
	_ring.material_override = Fx.glow(c, 0.6)
	var r := _trigger_r()
	_ring.scale = Vector3(r, 0.05, r)
	_ring.position.y = 0.05
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
	# The element itself sits in the middle, half sunk into the floor.
	_gem = Art.part(self, Art.sphere(0.22, 12), Fx.element(spell.primary, 0.5), Vector3(0, 0.05, 0), Vector3.ZERO, Vector3(1, 0.5, 1))
	_gem.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var i := 0
	for e in spell.payload:
		var a := i * TAU / maxf(spell.payload.size(), 1)
		Art.part(self, Art.sphere(0.09, 8), Fx.element(e, 0.8), Vector3(cos(a), 0.05, sin(a)) * r * 0.6).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		i += 1


## How close a monster has to come to set it off: the ring you see.
func _trigger_r() -> float:
	return 1.0 + 0.1 * spell.slots.size() if spell.primary != El.LIFE else n.radius * 0.7


func _physics_process(dt: float) -> void:
	t += dt
	if _done:
		return
	if t > n.duration or not is_instance_valid(caster):
		remove()
		return
	var armed := t >= ARM_TIME
	_gem.rotation.y += dt * 1.2
	if armed and not _lit:
		_lit = true
		_ring.material_override = Fx.glow(color(), 1.8)
		_gem.material_override = Fx.element(spell.primary, 1.2)
	if spell.primary == El.LIFE:
		_heal(dt)
		return
	if _pull >= 0.0:
		_pull -= dt
		for a in targets():
			if a.team != _enemy_team():
				continue
			var d: Vector3 = global_position - a.global_position
			d.y = 0
			if d.length() < n.radius * 2.0 and d.length() > 0.3:
				a.push = a.push.lerp(d.normalized() * 9.0, 6.0 * dt)
		if _pull < 0.0:
			_blast()
		return
	if not armed:
		return
	for a in targets():
		if a.team != _enemy_team():
			continue
		var d: Vector3 = a.global_position - global_position
		d.y = 0
		if d.length() < _trigger_r() + a.radius:
			_spring()
			return


func _spring() -> void:
	if spell.primary == El.VOID:
		# The mine opens: everything near is dragged onto it, then it blows.
		_pull = PULL_TIME
		Fx.ring(global_position, color(), n.radius * 2.0, PULL_TIME)
		return
	_blast()


func _blast() -> void:
	_done = true
	var at := global_position
	var nova := NovaFx.new().setup(caster, spell) as NovaFx
	nova.only_team = _enemy_team()
	nova.n = {radius = n.radius, rate = n.rate}
	Game.I.spawn(nova, at)
	match El.KIND[spell.primary]:
		El.Kind.FLOW:
			_spill(spell.primary, n.field)
		El.Kind.SOLID:
			if spell.primary == El.MUD:
				_spill(El.MUD, n.field)
			else:
				_spikes(at)
		El.Kind.ENERGY:
			Fx.light_pop(at, color(), 4.0, n.radius * 3.0, 0.3)
	Game.I.shake(0.25)
	finish()


## Leave a field behind that only hurts monsters.
func _spill(el: int, r: float) -> void:
	var f: Field = Game.I.arena.add_field(global_position, el, r, n.field_time, caster)
	f.spell = {counts = spell.counts, payload = spell.payload, primary = el, shape = "field", form = "plant", n = {rate = 0.35}}
	f.rate = 0.35
	f.friendly = true


## Stone or ice spikes shoot up and pin every monster in reach.
func _spikes(at: Vector3) -> void:
	for a in targets():
		if a.team != _enemy_team():
			continue
		var d: Vector3 = a.global_position - at
		d.y = 0
		if d.length() < n.radius + a.radius:
			a.stun = maxf(a.stun, n.stun)
	var spikes := Node3D.new()
	Fx.root.add_child(spikes)
	spikes.global_position = at
	var mat := Fx.element(spell.primary, 1.0)
	for i in 9:
		var a2 := i * TAU / 9.0 + randf() * 0.4
		var dist := randf_range(0.2, n.radius * 0.8)
		var s := Art.part(spikes, Art.cyl(0.0, 0.18, 1.1, 5), mat, Vector3(cos(a2) * dist, -0.6, sin(a2) * dist), Vector3(randf_range(-15, 15), 0, randf_range(-15, 15)))
		s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var tw := s.create_tween()
		tw.tween_property(s, "position:y", 0.45, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(n.stun)
		tw.tween_property(s, "position:y", -0.7, 0.4)
	var tw2 := spikes.create_tween()
	tw2.tween_interval(n.stun + 0.6)
	tw2.tween_callback(spikes.queue_free)


## A life rune: once a second it heals your side in reach and burns the undead.
func _heal(dt: float) -> void:
	_pulse_t -= dt
	if _pulse_t > 0.0:
		return
	_pulse_t = 1.0
	Fx.ring(global_position, color(), n.radius * 0.7, 0.5)
	for a in targets():
		var d: Vector3 = a.global_position - global_position
		d.y = 0
		if d.length() < n.radius * 0.7 + a.radius and (a.team == caster.team or a.undead):
			a.hit_spell(spell, 0.35 * n.rate, caster, d.normalized(), ff())


## Gone unsprung (it timed out, or a newer trap took its place): it sinks
## away without going off.
func remove() -> void:
	if _done:
		return
	_done = true
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(0.01, 1, 0.01), 0.3)
	tw.tween_callback(finish)

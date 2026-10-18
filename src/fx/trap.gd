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
##   poison                                 a blast that leaves a poison pool

const ARM_TIME := 0.5
## Void drags monsters in for this long before it blows.
const PULL_TIME := 0.6

var _mat: ShaderMaterial
var _ring: MeshInstance3D
var _pulse_t := 0.0
var _pull := -1.0
var _done := false
var _lit := false


func _enemy_team() -> int:
	return 1 if caster.team == 0 else 0


func _ready() -> void:
	# A circle of runes etched into the floor (trap.gdshader), faint until
	# it is armed. Its size is the reach that sets it off.
	_ring = MeshInstance3D.new()
	var q := PlaneMesh.new()
	var r := _trigger_r()
	q.size = Vector2.ONE * r * 2.0
	_ring.mesh = q
	var second: Color = El.COLOR[spell.payload[0]] if not spell.payload.is_empty() else color()
	_mat = Fx.shader("trap", {element = spell.primary, base = color(), second = second, armed = 0.0, seed = randf() * 10.0})
	_ring.material_override = _mat
	_ring.position.y = 0.04
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)


## How close a monster has to come to set it off: the ring you see.
func _trigger_r() -> float:
	return 1.0 + 0.1 * spell.slots.size() * Grammar.STEP


func _physics_process(dt: float) -> void:
	t += dt
	if _done:
		return
	if t > n.duration or not is_instance_valid(caster):
		remove()
		return
	var armed := t >= ARM_TIME
	if armed and not _lit:
		_lit = true
		create_tween().tween_property(_mat, "shader_parameter/armed", 1.0, 0.3)
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
		El.Kind.SPIRIT:
			if spell.primary == El.POISON:
				_spill(El.POISON, n.field)
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


## Gone unsprung (it timed out, or a newer trap took its place): it sinks
## away without going off.
func remove() -> void:
	if _done:
		return
	_done = true
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(0.01, 1, 0.01), 0.3)
	tw.tween_callback(finish)

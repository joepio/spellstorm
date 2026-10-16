class_name ArcFx
extends SpellFx
## Lightning that jumps from target to target. Wet targets conduct further,
## and a wet friend standing close is a conductor too.

var _mesh: MeshInstance3D
var _im: ImmediateMesh
var _zap_t := 0.0
var _show_t := 0.0
## A totem zaps from a fixed point and needs no caster input.
var from_point := Vector3.ZERO
var fixed := false


func _ready() -> void:
	_im = ImmediateMesh.new()
	_mesh = MeshInstance3D.new()
	_mesh.mesh = _im
	_mesh.material_override = Fx.glow(color().lightened(0.3), 5.0)
	_mesh.top_level = true
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)


func _physics_process(dt: float) -> void:
	t += dt
	var w := caster as Wizard
	if not fixed and (not caster.alive or (w and not w.holding(self)) or t > n.duration):
		finish()
		return
	_show_t -= dt
	if _show_t <= 0.0:
		_im.clear_surfaces()
	_zap_t -= dt
	if _zap_t > 0.0 or (not fixed and not caster.can_act()):
		return
	_zap_t = n.interval
	var origin: Vector3 = from_point if fixed else (w.staff_tip() if w else caster.global_position + Vector3.UP)
	var dir: Vector3 = w.aim_dir if (w and not fixed) else Vector3.ZERO
	zap(origin, dir)


## One strike and its chain. Returns how many it hit.
func zap(origin: Vector3, dir: Vector3) -> int:
	var chain: Array = []
	var first := _first(origin, dir)
	if first == null:
		if not fixed:
			_draw([origin, origin + dir * n.range * 0.6 + Vector3(randf() - 0.5, -0.8, randf() - 0.5)])
			Fx.light_pop(origin + dir * n.range * 0.6, color(), 1.5, 4.0, 0.15)
		return 0
	chain.append(first)
	while chain.size() < 1 + n.hops:
		var last: Actor = chain[-1]
		var best: Actor = null
		var best_d := INF
		var reach: float = n.hop_range * (1.8 if last.wet > 0.0 else 1.0)
		for a in targets():
			if a == caster or a in chain or not a.alive:
				continue
			# Lightning jumps between enemies of the caster, and through anyone wet.
			if a.team == caster.team and a.wet <= 0.0:
				continue
			var d: float = a.global_position.distance_to(last.global_position)
			if d < reach and d < best_d:
				best = a
				best_d = d
		if best == null:
			break
		chain.append(best)
	var pts: Array = [origin]
	var prev := origin
	for a in chain:
		var p: Vector3 = a.global_position + Vector3.UP * 0.9
		var d := (p - prev)
		a.hit_spell(spell, n.rate, caster, Vector3(d.x, 0, d.z).normalized(), ff())
		pts.append(p)
		prev = p
	_draw(pts)
	Fx.light_pop(chain[0].global_position, color(), 3.0, 6.0, 0.15)
	for a in chain:
		touch(a.global_position, 0.6)
	return chain.size()


func _first(origin: Vector3, dir: Vector3) -> Actor:
	var best: Actor = null
	var best_score := INF
	for a in targets():
		if a == caster or not a.alive:
			continue
		var to: Vector3 = a.global_position - Vector3(origin.x, 0, origin.z)
		to.y = 0.0
		var d := to.length()
		if d > n.range:
			continue
		var score := d
		if dir != Vector3.ZERO:
			var ang := absf(dir.signed_angle_to(to, Vector3.UP))
			if ang > deg_to_rad(55):
				continue
			score += ang * 4.0
		if a.team == caster.team:
			if a.wet <= 0.0:
				continue
			score += 3.0
		if score < best_score:
			best = a
			best_score = score
	return best


func _draw(pts: Array) -> void:
	_im.clear_surfaces()
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var steps := maxi(3, int(a.distance_to(b) / 0.6))
		var prev := a
		for s in range(1, steps + 1):
			var p := a.lerp(b, float(s) / steps)
			if s < steps:
				p += Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5) * 0.5
			_quad(prev, p, 0.07)
			prev = p
	_im.surface_end()
	_show_t = 0.1


func _quad(a: Vector3, b: Vector3, w: float) -> void:
	var side := (b - a).cross(Vector3.UP).normalized() * w
	if side.length() < 0.001:
		side = Vector3.RIGHT * w
	var up := Vector3.UP * w
	for off in [side, up]:
		_im.surface_add_vertex(a - off)
		_im.surface_add_vertex(b - off)
		_im.surface_add_vertex(b + off)
		_im.surface_add_vertex(a - off)
		_im.surface_add_vertex(b + off)
		_im.surface_add_vertex(a + off)

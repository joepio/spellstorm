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
	_mesh.material_override = Fx.shader("zap", {core = color().lerp(Color.WHITE, 0.8), edge = color()})
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
		_bolt(a, b, 0.5, 0.26, 1.0)
		# A couple of forks that crackle off the main strike and die out.
		for _f in randi_range(1, 2):
			var at := a.lerp(b, randf_range(0.2, 0.8))
			var off := Vector3(randf() - 0.5, randf() * 0.4 - 0.3, randf() - 0.5).normalized() * randf_range(0.6, 1.3)
			_bolt(at, at + off, 0.3, 0.14, 0.55)
	_im.surface_end()
	_show_t = 0.1
	for p: Vector3 in pts.slice(1):
		Fx.flash(p, color(), 1.6, 0.14)


## One jagged ribbon from [param a] to [param b].
func _bolt(a: Vector3, b: Vector3, jag: float, w: float, alpha: float) -> void:
	var steps := maxi(3, int(a.distance_to(b) / 0.5))
	var prev := a
	for s in range(1, steps + 1):
		var p := a.lerp(b, float(s) / steps)
		if s < steps:
			p += Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5) * jag
		_quad(prev, p, w, alpha)
		prev = p


## A ribbon piece, flat and upright so it shows from any side. UV.x runs
## across it for the core falloff in src/fx/zap.gdshader.
func _quad(a: Vector3, b: Vector3, w: float, alpha := 1.0) -> void:
	var side := (b - a).cross(Vector3.UP).normalized() * w
	if side.length() < 0.001:
		side = Vector3.RIGHT * w
	var up := Vector3.UP * w
	_im.surface_set_color(Color(1, 1, 1, alpha))
	for off in [side, up]:
		_v(a - off, 0.0)
		_v(b - off, 0.0)
		_v(b + off, 1.0)
		_v(a - off, 0.0)
		_v(b + off, 1.0)
		_v(a + off, 1.0)


func _v(p: Vector3, u: float) -> void:
	_im.surface_set_uv(Vector2(u, 0.0))
	_im.surface_add_vertex(p)

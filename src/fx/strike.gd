class_name StrikeFx
extends SpellFx
## Lightning's RT spell: one thunderbolt out of the sky, once, hard. It
## lands where the charge mark was (snapping onto a monster standing right
## there), hits that one in full and splashes whoever stands round it at
## SPLASH strength. A white flash, a crack of light, a ring on the floor.

## How hard the splash hits next to the one struck.
const SPLASH := 0.6
const SHOW := 0.3

var _mesh: MeshInstance3D
var _im: ImmediateMesh
var _top := Vector3.ZERO
var _at := Vector3.ZERO


func _ready() -> void:
	_im = ImmediateMesh.new()
	_mesh = MeshInstance3D.new()
	_mesh.mesh = _im
	_mesh.material_override = Fx.shader("zap", {core = color().lerp(Color.WHITE, 0.85), edge = color()})
	_mesh.top_level = true
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)
	_at = Vector3(global_position.x, 0.0, global_position.z)
	# Onto the monster nearest the mark, if one stands right there.
	var struck: Actor = null
	var best: float = n.radius + 0.6
	for a in targets():
		if a == caster or not a.alive or a.team == caster.team:
			continue
		var d := Vector2(a.global_position.x - _at.x, a.global_position.z - _at.z).length()
		if d < best:
			best = d
			struck = a
	if struck:
		_at = Vector3(struck.global_position.x, 0.0, struck.global_position.z)
	_top = _at + Vector3(randf_range(-1.5, 1.5), 16.0, randf_range(-1.0, 1.0))
	for a in targets():
		if a == caster or not a.alive:
			continue
		if a.team == caster.team and a.wet <= 0.0:
			continue
		var to: Vector3 = a.global_position - _at
		to.y = 0.0
		if a != struck and to.length() > n.radius + a.radius:
			continue
		a.hit_spell(spell, n.rate * (1.0 if a == struck else SPLASH), caster, to.normalized() if to.length() > 0.01 else Vector3.FORWARD, ff())
	touch(_at, n.radius)
	_draw()
	Fx.flash(_at + Vector3.UP * 0.5, Color.WHITE, 3.5 + n.radius, 0.18)
	Fx.flash(_at + Vector3.UP * 0.3, color(), 2.0 + n.radius * 1.5, 0.35)
	Fx.light_pop(_at + Vector3.UP * 2.0, color().lerp(Color.WHITE, 0.5), 9.0, 10.0 + n.radius * 2.0, 0.3)
	Fx.ring(_at, color(), n.radius + 0.4, 0.4)
	Fx.burst(_at + Vector3.UP * 0.3, color(), 40, 9.0, 0.22, spell.primary)
	if Game.I:
		Game.I.shake(0.35)


func _physics_process(dt: float) -> void:
	t += dt
	if t > SHOW:
		finish()
		return
	# It flickers: redrawn jagged a few times, gone between, then out.
	var f := int(t / 0.05)
	if f % 2 == 0:
		_draw()
	else:
		_im.clear_surfaces()


func _draw() -> void:
	_im.clear_surfaces()
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var w := 0.32 + 0.05 * float(spell.get("power", 1)) * Grammar.STEP
	_bolt(_top, _at, 1.2, w)
	# Forks crackling off the main bolt, and a few running along the floor.
	for i in 3:
		var at := _top.lerp(_at, randf_range(0.3, 0.85))
		_bolt(at, at + Vector3(randf() - 0.5, -randf() * 0.8, randf() - 0.5).normalized() * randf_range(1.5, 3.0), 0.5, w * 0.45)
	for i in 4:
		var a := randf() * TAU
		_bolt(_at + Vector3.UP * 0.1, _at + Vector3(cos(a), 0.05, sin(a)) * n.radius, 0.35, w * 0.35)
	_im.surface_end()


func _bolt(a: Vector3, b: Vector3, jag: float, w: float) -> void:
	var steps := maxi(3, int(a.distance_to(b) / 0.7))
	var prev := a
	for s in range(1, steps + 1):
		var p := a.lerp(b, float(s) / steps)
		if s < steps:
			p += Vector3(randf() - 0.5, (randf() - 0.5) * 0.3, randf() - 0.5) * jag
		_quad(prev, p, w)
		prev = p


## Two crossed ribbons, so a bolt shows from any side, straight down too.
func _quad(a: Vector3, b: Vector3, w: float) -> void:
	var along := (b - a).normalized()
	var s1 := along.cross(Vector3.FORWARD)
	if s1.length() < 0.1:
		s1 = along.cross(Vector3.RIGHT)
	s1 = s1.normalized() * w
	var s2 := along.cross(s1).normalized() * w
	_im.surface_set_color(Color.WHITE)
	for off in [s1, s2]:
		_v(a - off, 0.0)
		_v(b - off, 0.0)
		_v(b + off, 1.0)
		_v(a - off, 0.0)
		_v(b + off, 1.0)
		_v(a + off, 1.0)


func _v(p: Vector3, u: float) -> void:
	_im.surface_set_uv(Vector2(u, 0.0))
	_im.surface_add_vertex(p)

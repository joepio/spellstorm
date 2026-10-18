class_name Prop
extends StaticBody3D
## Something standing in a level that breaks when you hit it hard enough:
## graves, trees, pillars, pews, urns. Spells that hit it call damage().
##
## Its pieces are worked out when the level is built (prepare()): every part
## it is made of is cut into chunks, boxes into smaller boxes, cylinders into
## drums, spheres into lumps, with meshes shared between all props. Breaking
## then only hides the prop and throws those chunks about (Debris), so a
## break costs nothing to work out mid-fight.

## Chunks flying about at once, over all props: past this a break throws
## fewer, bigger pieces.
const MAX_LIVE := 360
static var live := 0
static var _meshes := {}

var kind := ""
var hp := 6.0
## What breaking it lets out: "souls" (mana), "globe" (health), "fire"
## (burning oil).
var spill := ""
var _chunks: Array[Dictionary] = []
var _broken := false


## Cut every part into chunks, in this prop's own space.
func prepare() -> void:
	_chunks.clear()
	for m in find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null:
			continue
		var xf := _local(mi)
		var mat := mi.material_override
		var mesh := mi.mesh
		if mesh is BoxMesh:
			var s: Vector3 = (mesh as BoxMesh).size
			var n := Vector3i(_cuts(s.x), _cuts(s.y), _cuts(s.z))
			var cs := Vector3(s.x / n.x, s.y / n.y, s.z / n.z)
			var piece := _box(cs * 0.97)
			for ix in n.x:
				for iy in n.y:
					for iz in n.z:
						var c := Vector3((ix + 0.5) * cs.x, (iy + 0.5) * cs.y, (iz + 0.5) * cs.z) - s * 0.5
						_chunks.append({mesh = piece, xf = xf * Transform3D(Basis(), c), mat = mat})
		elif mesh is CylinderMesh:
			var cy := mesh as CylinderMesh
			var n2 := clampi(ceili(cy.height / 0.45), 1, 6)
			var h := cy.height / n2
			for i in n2:
				var r0 := lerpf(cy.bottom_radius, cy.top_radius, float(i) / n2)
				var r1 := lerpf(cy.bottom_radius, cy.top_radius, float(i + 1) / n2)
				var piece2 := _drum(r1, r0, h * 0.97, cy.radial_segments)
				_chunks.append({mesh = piece2, xf = xf * Transform3D(Basis(), Vector3(0, -cy.height * 0.5 + (i + 0.5) * h, 0)), mat = mat})
		elif mesh is SphereMesh:
			var r := (mesh as SphereMesh).radius
			var piece3 := _box(Vector3.ONE * r * 0.8)
			for i in 6:
				var dir := Vector3(1 if i & 1 else -1, 1 if i & 2 else -1, 1 if i % 3 == 0 else -1).normalized()
				_chunks.append({mesh = piece3, xf = xf * Transform3D(Basis.from_euler(dir * 0.6), dir * r * 0.4), mat = mat})
		else:
			_chunks.append({mesh = mesh, xf = xf, mat = mat})


func _cuts(len: float) -> int:
	return clampi(ceili(len / 0.4), 1, 3)


## The transform of [param n] relative to this prop, before it is in the tree.
func _local(n: Node3D) -> Transform3D:
	var xf := n.transform
	var p := n.get_parent() as Node3D
	while p and p != self:
		xf = p.transform * xf
		p = p.get_parent() as Node3D
	return xf


static func _box(s: Vector3) -> Mesh:
	var key := "b%.2f,%.2f,%.2f" % [s.x, s.y, s.z]
	if not _meshes.has(key):
		_meshes[key] = Art.box(s.x, s.y, s.z)
	return _meshes[key]


static func _drum(top: float, bottom: float, h: float, seg: int) -> Mesh:
	var key := "c%.2f,%.2f,%.2f,%d" % [top, bottom, h, seg]
	if not _meshes.has(key):
		_meshes[key] = Art.cyl(top, bottom, h, seg)
	return _meshes[key]


## Take [param amount] from a hit travelling along [param dir] (zero for a
## blast from [param at], or for nothing in particular).
func damage(amount: float, dir := Vector3.ZERO, at := Vector3.INF) -> void:
	if _broken:
		return
	hp -= amount
	if hp <= 0.0:
		shatter(dir, at, amount)
	else:
		Fx.burst(global_position + Vector3.UP * 0.6, Color(0.5, 0.47, 0.42), 3, 2.0, 0.08)


## Break apart. Knocked along [param dir] the pieces fly on that way, harder
## for a harder hit (a boulder sends them far, the last bolt into a grave
## mostly topples it); a blast at [param at] throws them out from there.
func shatter(dir := Vector3.ZERO, at := Vector3.INF, force := 6.0) -> void:
	if _broken or not is_inside_tree():
		return
	_broken = true
	collision_layer = 0
	if Game.I and Game.I.arena:
		Game.I.arena.props.erase(self)
		Game.I.count("props_broken")
	var power := clampf(force * 0.35, 1.2, 8.0)
	dir.y = 0.0
	var from: Vector3
	if dir.length() > 0.05:
		# Behind the prop, so everything flies on the way the hit went.
		from = global_position - dir.normalized() * 1.6 + Vector3.UP * 0.3
	elif at != Vector3.INF:
		from = at
	else:
		from = global_position + Vector3.UP * 0.3
		power = 1.5
	var d := Debris.new()
	d._life = 3.0
	if Fx.root:
		Fx.root.add_child(d)
	# Keep to the budget: past it, every other chunk stays behind.
	var step := 1 if live + _chunks.size() < MAX_LIVE else 2
	var thrown := 0
	for i in range(0, _chunks.size(), step):
		var c: Dictionary = _chunks[i]
		var mi := MeshInstance3D.new()
		mi.mesh = c.mesh
		mi.material_override = c.mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		d.add_child(mi)
		mi.global_transform = global_transform * (c.xf as Transform3D)
		# Higher pieces fly further; the foot mostly drops where it stood.
		var lift := clampf(mi.global_position.y - global_position.y, 0.0, 2.0)
		d.add(mi, from, power * (0.4 + 0.5 * lift), 0.8 + power * 0.25)
		thrown += 1
	live += thrown
	d.tree_exited.connect(func() -> void: live -= thrown)
	d.bits(global_position + Vector3.UP * 0.4, Color(0.4, 0.37, 0.33), 6, 0.08, power, 1.5)
	_spill()
	queue_free()


func _spill() -> void:
	if not Game.I:
		return
	match spill:
		"souls":
			for i in 3:
				var s := Soul.new()
				s.mana = 4.0
				var a := randf() * TAU
				s.vel = Vector3(cos(a), 0, sin(a)) * randf_range(1.5, 3.5)
				Game.I.spawn(s, global_position + Vector3.UP * 0.6)
		"globe":
			if randf() < 0.6:
				Globe.drop(global_position)
		"fire":
			# Burning oil splashes out: it scorches whoever stands close and
			# sets the ground alight, and the blast breaks what is next to it.
			var at := Vector3(global_position.x, 0, global_position.z)
			Fx.flash(at + Vector3.UP * 0.6, El.COLOR[El.FIRE], 3.0, 0.3)
			Fx.burst(at + Vector3.UP * 0.5, El.COLOR[El.FIRE], 24, 6.0, 0.25)
			Game.I.arena.add_field(at, El.FIRE, 2.4, 6.0, null)
			for a in Game.I.living():
				var dd: Vector3 = a.global_position - at
				dd.y = 0.0
				if dd.length() < 2.8:
					a.hit_spell(Field.simple(El.FIRE), 1.6, null, dd.normalized() if dd.length() > 0.1 else Vector3.ZERO, 1.0)
			Game.I.shake(0.5)
			Game.I.arena.blast(at, 2.6, 8.0)

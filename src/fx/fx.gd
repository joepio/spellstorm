class_name Fx
## Shared particles, materials and one-shot effects.

static var root: Node3D
static var _mats := {}


static func glow(c: Color, energy := 2.0) -> StandardMaterial3D:
	var key := "g%s%.1f" % [c.to_html(), energy]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mats[key] = m
	return m


static func additive(c: Color, energy := 1.0) -> StandardMaterial3D:
	var key := "a%s%.1f" % [c.to_html(), energy]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r * energy, c.g * energy, c.b * energy, c.a)
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.vertex_color_use_as_albedo = true
	m.no_depth_test = false
	_mats[key] = m
	return m


static var _el_mats := {}


## Element [param e]'s own material (src/fx/element.gdshader): the same look
## as its ball in the HUD. Shared, so do not change its parameters.
static func element(e: int, energy := 1.0) -> ShaderMaterial:
	var key := "%d:%.2f" % [e, energy]
	if not _el_mats.has(key):
		var m := ShaderMaterial.new()
		m.shader = preload("res://src/fx/element.gdshader")
		m.set_shader_parameter("element", e)
		m.set_shader_parameter("base", El.COLOR[e])
		m.set_shader_parameter("energy", energy)
		_el_mats[key] = m
	return _el_mats[key]


static func solid(c: Color, rough := 0.85) -> StandardMaterial3D:
	var key := "s%s%.2f" % [c.to_html(), rough]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	_mats[key] = m
	return m


static func particle_mesh(size: float, c: Color, energy := 1.4) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var m := additive(Color(1, 1, 1, 1), energy)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_texture = _soft_dot()
	q.material = m
	return q


static var _dot: Texture2D
static func _soft_dot() -> Texture2D:
	if _dot:
		return _dot
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.35, Color(1, 1, 1, 0.75))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	_dot = t
	return t


static func ramp(c: Color) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(c.r, c.g, c.b, 0.0))
	g.set_color(1, Color(c.r * 0.5, c.g * 0.5, c.b * 0.5, 0.0))
	g.add_point(0.12, Color(c.r, c.g, c.b, 0.9))
	g.add_point(0.6, Color(c.r, c.g, c.b, 0.5))
	return g


static func particles(c: Color, amount := 32, life := 0.8, size := 0.4) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.mesh = particle_mesh(size, c)
	p.color_ramp = ramp(c)
	p.local_coords = false
	return p


static func flames(r: float) -> CPUParticles3D:
	var p := particles(El.COLOR[El.FIRE], 24, 0.6, 0.35)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = r
	p.position = Vector3.UP * 0.8
	p.direction = Vector3.UP
	p.spread = 20.0
	p.gravity = Vector3.UP * 2.0
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 1.5
	p.emitting = false
	return p


static var _halo_mats := {}


## A soft camera-facing glow of [param size] metres across, to put round
## anything bright (src/fx/halo.gdshader).
static func halo(c: Color, size: float, strength := 1.0, pulse := 0.0) -> MeshInstance3D:
	var key := "%s%.2f%.2f" % [c.to_html(), strength, pulse]
	if not _halo_mats.has(key):
		var m := ShaderMaterial.new()
		m.shader = preload("res://src/fx/halo.gdshader")
		m.set_shader_parameter("color", c)
		m.set_shader_parameter("strength", strength)
		m.set_shader_parameter("pulse", pulse)
		_halo_mats[key] = m
	var q := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2.ONE
	q.mesh = mesh
	q.scale = Vector3.ONE * size
	q.material_override = _halo_mats[key]
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return q


static func _spawn(n: Node3D, at: Vector3) -> void:
	if root == null:
		n.queue_free()
		return
	root.add_child(n)
	n.global_position = at


## A one-shot spray of sparks.
## With an element [param e] the sparks take its look (Parts.style).
static func burst(at: Vector3, c: Color, amount := 24, speed := 5.0, size := 0.35, e := -1) -> void:
	var p := particles(c, amount, 0.6, size)
	p.one_shot = true
	p.explosiveness = 0.95
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -6, 0)
	p.damping_min = 2.0
	p.damping_max = 4.0
	if e >= 0:
		Parts.style(p, e)
	_spawn(p, at)
	p.emitting = true
	p.finished.connect(p.queue_free)


static func puff(at: Vector3, c: Color, size := 1.2) -> void:
	var p := particles(c, 14, 1.4, size)
	p.one_shot = true
	p.explosiveness = 0.8
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 1.8
	p.gravity = Vector3.UP * 0.6
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	_spawn(p, at)
	p.emitting = true
	p.finished.connect(p.queue_free)


## A brief point light, for impacts.
static func light_pop(at: Vector3, c: Color, energy := 3.0, range_m := 6.0, time := 0.35) -> void:
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = energy
	l.omni_range = range_m
	_spawn(l, at + Vector3.UP * 1.0)
	var tw := l.create_tween()
	tw.tween_property(l, "light_energy", 0.0, time)
	tw.tween_callback(l.queue_free)
	flash(at + Vector3.UP * 0.8, c, range_m * 0.3 * clampf(energy / 3.0, 0.5, 1.2), time * 0.8)


## A bright glow that shrinks away, for the moment something lands.
static func flash(at: Vector3, c: Color, size := 2.0, time := 0.25) -> void:
	var h := halo(c, size, 0.9)
	_spawn(h, at)
	var tw := h.create_tween()
	tw.tween_property(h, "scale", Vector3.ONE * size * 0.15, time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(h.queue_free)


## A fresh material for one of the spell shaders in src/fx.
static func shader(name: String, params := {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://src/fx/%s.gdshader" % name)
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m


## An expanding flat ring on the ground.
static func ring(at: Vector3, c: Color, radius: float, time := 0.35) -> void:
	var m := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.82
	t.outer_radius = 1.0
	t.rings = 32
	t.ring_segments = 6
	m.mesh = t
	m.material_override = additive(c, 1.6)
	m.scale = Vector3(0.2, 0.05, 0.2)
	_spawn(m, at + Vector3.UP * 0.15)
	var tw := m.create_tween()
	tw.tween_property(m, "scale", Vector3(radius, 0.12, radius), time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.parallel().tween_property(m, "transparency", 1.0, time)
	tw.tween_callback(m.queue_free)


## Floating text above something, rising and fading.
static func text(at: Vector3, s: String, c: Color, size := 64, time := 1.4) -> void:
	var l := Label3D.new()
	l.text = s
	l.modulate = c
	l.font_size = size
	l.outline_size = 14
	l.outline_modulate = Color(0, 0, 0, 0.85)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = false
	l.pixel_size = 0.006
	l.font = Art.title_font()
	_spawn(l, at)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", at.y + 1.2, time)
	tw.parallel().tween_property(l, "modulate:a", 0.0, time).set_delay(time * 0.5)
	tw.tween_callback(l.queue_free)

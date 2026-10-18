class_name Parts
## Every element sheds its own particles, so you can tell a spell by its
## sparks alone: fire burns in shades of yellow, orange and red with smoke
## coming off it, water and poison throw droplets that fall, lightning and
## storm spit bright sparks, frost and ice glitter as flakes, earth and mud
## kick up chips of stone, void motes are drawn inward, air streaks round,
## steam stays a soft cloud. Use [method style] on any CPUParticles3D after
## setting its direction and speed; it keeps those and swaps the look.

enum Look { FLAME, DROP, SPARK, FLAKE, CHIP, MOTE, STREAK, PUFF, EMBER }

const LOOK := {
	El.FIRE: Look.FLAME, El.MAGMA: Look.EMBER,
	El.WATER: Look.DROP, El.POISON: Look.DROP, El.MUD: Look.CHIP,
	El.LIGHTNING: Look.SPARK, El.STORM: Look.SPARK,
	El.FROST: Look.FLAKE, El.ICE: Look.FLAKE,
	El.EARTH: Look.CHIP, El.VOID: Look.MOTE, El.AIR: Look.STREAK, El.STEAM: Look.PUFF,
}

static var _tex := {}
static var _mats := {}


## Give [param p] element [param e]'s look. Its size, colour ramp, gravity
## and spin change; its emission shape, direction and speed stay.
static func style(p: CPUParticles3D, e: int) -> void:
	if not LOOK.has(e):
		return
	var look: int = LOOK[e]
	var c: Color = El.COLOR[e]
	var size := 0.3
	if p.mesh is QuadMesh:
		size = (p.mesh as QuadMesh).size.x
	match look:
		Look.FLAME:
			p.mesh = _quad(size * 0.9, "flame", true)
			p.color_ramp = _ramp([Color(1.0, 0.95, 0.6, 0.0), Color(1.0, 0.85, 0.35, 1.0), Color(1.0, 0.45, 0.08, 0.85),
				Color(0.85, 0.12, 0.03, 0.5), Color(0.25, 0.05, 0.02, 0.0)], [0.0, 0.1, 0.35, 0.7, 1.0])
			p.color_initial_ramp = _ramp([Color(1, 1, 1), Color(1.0, 0.75, 0.6)], [0.0, 1.0])
			p.gravity = Vector3.UP * 3.0
			p.scale_amount_curve = _curve([1.0, 0.8, 0.2])
			p.angle_min = -15.0
			p.angle_max = 15.0
			_smoke(p, size)
		Look.EMBER:
			p.mesh = _quad(size * 0.4, "drop", true)
			p.color_ramp = _ramp([Color(1.0, 0.9, 0.5, 1.0), Color(1.0, 0.4, 0.05, 1.0), Color(0.5, 0.08, 0.02, 0.0)], [0.0, 0.5, 1.0])
			p.gravity = Vector3.DOWN * 6.0
			p.scale_amount_curve = _curve([1.0, 0.7])
			_smoke(p, size)
		Look.DROP:
			p.mesh = _quad(size * 0.38, "drop", false)
			var light := c.lerp(Color.WHITE, 0.55)
			p.color_ramp = _ramp([Color(light.r, light.g, light.b, 0.95), Color(c.r, c.g, c.b, 0.9), Color(c.r * 0.6, c.g * 0.6, c.b * 0.6, 0.0)], [0.0, 0.6, 1.0])
			p.color_initial_ramp = _ramp([Color(1, 1, 1), Color(0.75, 0.8, 0.75)], [0.0, 1.0])
			p.gravity = Vector3.DOWN * 12.0
			p.scale_amount_curve = _curve([0.8, 1.0, 0.6])
		Look.SPARK:
			p.mesh = _quad(size * 0.6, "spark", true)
			p.amount = int(p.amount * 1.5)
			var hot := c.lerp(Color.WHITE, 0.7)
			p.color_ramp = _ramp([Color(1, 1, 1, 1), Color(hot.r, hot.g, hot.b, 1.0), Color(c.r, c.g, c.b, 0.0)], [0.0, 0.4, 1.0])
			p.gravity = Vector3.DOWN * 4.0
			p.lifetime = minf(p.lifetime, 0.3)
			p.initial_velocity_min *= 1.6
			p.initial_velocity_max *= 2.2
			p.spread = maxf(p.spread, 70.0)
			p.damping_min = 4.0
			p.damping_max = 8.0
			p.scale_amount_curve = _curve([1.0, 0.4])
			p.angle_min = -180.0
			p.angle_max = 180.0
		Look.FLAKE:
			p.mesh = _quad(size * 0.42, "flake", true)
			var pale := c.lerp(Color.WHITE, 0.6)
			p.color_ramp = _ramp([Color(1, 1, 1, 0.0), Color(1, 1, 1, 1.0), Color(pale.r, pale.g, pale.b, 0.8), Color(c.r, c.g, c.b, 0.0)], [0.0, 0.1, 0.5, 1.0])
			p.gravity = Vector3.DOWN * 1.5
			p.angle_min = -180.0
			p.angle_max = 180.0
			p.angular_velocity_min = -360.0
			p.angular_velocity_max = 360.0
		Look.CHIP:
			p.mesh = _chip(size * 0.3, c)
			p.color_ramp = null
			p.gravity = Vector3.DOWN * 14.0
			p.scale_amount_curve = _curve([1.0, 1.0, 0.3])
		Look.MOTE:
			p.mesh = _quad(size * 0.5, "drop", true)
			var deep := c.darkened(0.3)
			p.color_ramp = _ramp([Color(c.r, c.g, c.b, 0.0), Color(1.0, 0.6, 1.0, 1.0), Color(deep.r, deep.g, deep.b, 0.7), Color(0.1, 0.0, 0.15, 0.0)], [0.0, 0.15, 0.6, 1.0])
			p.gravity = Vector3.ZERO
			p.radial_accel_min = -8.0
			p.radial_accel_max = -4.0
			p.scale_amount_curve = _curve([1.0, 0.6, 0.1])
		Look.STREAK:
			p.mesh = _quad(size * 0.7, "streak", true)
			p.color_ramp = _ramp([Color(1, 1, 1, 0.0), Color(0.9, 1.0, 0.95, 0.45), Color(c.r, c.g, c.b, 0.0)], [0.0, 0.3, 1.0])
			p.gravity = Vector3.ZERO
			p.tangential_accel_min = 6.0
			p.tangential_accel_max = 12.0
			p.angle_min = -180.0
			p.angle_max = 180.0
		Look.PUFF:
			pass


## Smoke curling off fire and lava: dark, slow, not glowing.
static func _smoke(p: CPUParticles3D, size: float) -> void:
	var s := CPUParticles3D.new()
	s.amount = maxi(4, p.amount / 3)
	s.lifetime = p.lifetime * 2.0
	s.one_shot = p.one_shot
	s.explosiveness = p.explosiveness
	s.local_coords = p.local_coords
	s.mesh = _quad(size * 1.3, "puff", false)
	s.color_ramp = _ramp([Color(0.2, 0.18, 0.17, 0.0), Color(0.22, 0.2, 0.19, 0.35), Color(0.3, 0.3, 0.3, 0.0)], [0.0, 0.25, 1.0])
	s.emission_shape = p.emission_shape
	s.emission_sphere_radius = p.emission_sphere_radius
	s.direction = p.direction
	s.spread = p.spread
	s.initial_velocity_min = p.initial_velocity_min * 0.5
	s.initial_velocity_max = p.initial_velocity_max * 0.5
	s.damping_min = p.damping_min
	s.damping_max = p.damping_max
	s.gravity = Vector3.UP * 1.6
	s.scale_amount_curve = _curve([0.5, 1.2, 1.6])
	s.angle_min = -180.0
	s.angle_max = 180.0
	p.add_child(s)
	s.emitting = true


static func _ramp(cols: Array, at: Array) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(at)
	g.colors = PackedColorArray(cols)
	return g


static func _curve(v: Array) -> Curve:
	var c := Curve.new()
	for i in v.size():
		c.add_point(Vector2(float(i) / maxf(v.size() - 1, 1), v[i]))
	return c


static func _quad(size: float, kind: String, glow: bool) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var key := "%s%s" % [kind, glow]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		if glow:
			m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			m.albedo_color = Color(1.6, 1.6, 1.6)
		m.vertex_color_use_as_albedo = true
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.albedo_texture = _texture(kind)
		_mats[key] = m
	q.material = _mats[key]
	return q


static func _chip(size: float, c: Color) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(size, size * 0.7, size * 0.85)
	b.material = Fx.solid(c.darkened(0.15))
	return b


## The particle shapes, drawn once: a flame tongue, a hard droplet with a
## glint, a four-pointed spark, a six-pointed flake, a thin streak, a puff.
static func _texture(kind: String) -> Texture2D:
	if _tex.has(kind):
		return _tex[kind]
	var n := 32
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var u := (x + 0.5) / n * 2.0 - 1.0
			var v := (y + 0.5) / n * 2.0 - 1.0
			var r := sqrt(u * u + v * v)
			var a := 0.0
			var lum := 1.0
			match kind:
				"flame":
					# Round at the bottom, drawn to a point at the top.
					var w := 0.55 * (1.0 - clampf((-v + 0.2) / 1.2, 0.0, 1.0)) + 0.15
					a = clampf(1.0 - absf(u) / w, 0.0, 1.0) * clampf(1.0 - v, 0.0, 1.0) * (1.0 - smoothstep(0.6, 1.0, r))
					a = pow(a, 0.8)
				"drop":
					a = (1.0 - smoothstep(0.7, 0.82, r))
					# A glint near the top-left, and a darker rim.
					var g := Vector2(u + 0.3, v + 0.3).length()
					lum = 0.75 + 0.25 * (1.0 - smoothstep(0.3, 0.75, r)) + 0.6 * (1.0 - smoothstep(0.05, 0.3, g))
				"spark":
					var cross := maxf(maxf(0.0, 1.0 - absf(u) * 9.0) * (1.0 - absf(v)), maxf(0.0, 1.0 - absf(v) * 9.0) * (1.0 - absf(u)))
					a = clampf(cross + (1.0 - smoothstep(0.0, 0.35, r)), 0.0, 1.0)
				"flake":
					var ang := atan2(v, u)
					var arm := absf(cos(ang * 3.0))
					a = clampf((1.0 - smoothstep(0.0, 0.08, r * (1.0 - arm)) ) * (1.0 - r) + (1.0 - smoothstep(0.0, 0.3, r)), 0.0, 1.0)
				"streak":
					a = maxf(0.0, 1.0 - absf(v) * 7.0) * pow(maxf(0.0, 1.0 - absf(u)), 1.5)
				"puff":
					a = pow((1.0 - smoothstep(0.0, 1.0, r)), 1.6)
			img.set_pixel(x, y, Color(lum, lum, lum, a))
	var t := ImageTexture.create_from_image(img)
	_tex[kind] = t
	return t

class_name BlastFx
extends Node3D
## A proper explosion, ported from Growing Guns' layered blast (violence.gd,
## by way of Bombing Bugs' explosion.gd): lumpy fire clouds that swell and
## cool from white through orange to soot, flame tongues licking out, sparks
## arcing back down, slow smoke rising after, a white flash then a warm
## fireball light, and a scorch mark left on the floor. Each layer is one
## MultiMesh driven by a single `anim` uniform; game time drives it, so a
## pause freezes the blast. Barrels and enchanted fire bolts use it.

const FIRE_LIFE := 0.72
const BILLOW_CODE := """shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform float anim = 0.0;
uniform float is_fire = 0.0;
uniform float edge_power = 2.1;
uniform float lump_amount = 0.32;
uniform float growth_min = 0.35;
uniform float tail_power = 1.5;
uniform vec3 smoke_tint : source_color = vec3(1.0);
varying float v_age;
varying float v_heat;
varying vec3 v_body;
varying float v_opk;
varying float v_shade;
void vertex() {
 float seed = INSTANCE_CUSTOM.x;
 float delay = INSTANCE_CUSTOM.y;
 v_heat = INSTANCE_CUSTOM.z;
 v_body = COLOR.rgb;
 v_opk = COLOR.a;
 v_age = clamp((anim-delay)*(1.0+INSTANCE_CUSTOM.w)/max(1.0-delay,0.001),0.0,1.0);
 float s = seed*100.0;
 float a = sin(VERTEX.x*6.3+s)*sin(VERTEX.y*5.1+s*1.7)*sin(VERTEX.z*7.2+s*.9);
 float b = sin(VERTEX.x*13.0+s*2.1)*sin(VERTEX.z*11.0+s*1.3);
 float c = sin(VERTEX.x*21.0+s*3.3)*sin(VERTEX.y*18.0+s*2.1)*sin(VERTEX.z*25.0+s*1.5);
 v_shade = (a*.7+b*.3)*.55+c*.45;
 VERTEX += NORMAL*(a*.7+b*.3)*lump_amount;
 VERTEX *= mix(growth_min,1.0,v_age);
}
void fragment() {
 float facing = abs(dot(normalize(NORMAL),normalize(VIEW)));
 float fres = pow(1.0-facing,edge_power);
 float fade_in = smoothstep(0.0,.12,v_age);
 float t = clamp((v_age-.12)/.88,0.0,1.0);
 float fade_out = pow(1.0-t,tail_power)*(1.0-smoothstep(.5,1.0,t));
 ALPHA = v_opk*fade_in*fade_out*smoothstep(0.0,.85,facing);
 vec2 px_cell = floor(UV*vec2(8.0,5.0));
 float cell_band = mod(px_cell.x+px_cell.y,3.0)-1.0;
 if (is_fire > .5) {
  float heat = clamp(v_heat+cell_band*.06,0.0,1.0);
  float age_cool = 1.0-smoothstep(0.0,.75,v_age);
  float fire_band = clamp(heat*.6+facing*.25+age_cool*.15,0.0,1.0);
  vec3 color = vec3(.03,.025,.02);
  color = mix(color,vec3(.30,.09,.025),smoothstep(.05,.34,fire_band));
  color = mix(color,vec3(1.0,.24,.04),smoothstep(.30,.54,fire_band));
  color = mix(color,vec3(1.0,.62,.12),smoothstep(.52,.74,fire_band));
  color = mix(color,vec3(1.0,.95,.72),smoothstep(.74,.94,fire_band));
  // Growing Guns pushes the core into HDR for its glow pass; with none here
  // a gentler lift keeps the bands readable.
  ALBEDO = color*mix(.6,1.9,fire_band*fire_band);
 } else {
  float shade = clamp(.45+.85*(v_shade*.5+.5)+cell_band*.05,0.0,1.0);
  vec3 body = v_body*shade;
  body = mix(body,body*.35,fres);
  ALBEDO = body*smoke_tint;
 }
}
"""
const SPARK_CODE := """shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, blend_add;
uniform float anim = 0.0;
uniform vec3 tint : source_color = vec3(1.0,.7,.3);
uniform float brightness = 2.0;
uniform float size_scale = 1.0;
uniform float elong_max = 8.0;
varying float v_b;
void vertex() {
 vec3 travel = INSTANCE_CUSTOM.xyz;
 float delay = INSTANCE_CUSTOM.w;
 float size = COLOR.r*size_scale;
 float elong = 1.0+COLOR.g*(elong_max-1.0);
 float age = clamp((anim-delay)/max(1.0-delay,.001),0.0,1.0);
 float prog = 1.0-pow(1.0-age,2.0);
 float dist = length(travel);
 vec3 dir = dist > .0001 ? travel/dist : vec3(0.0,1.0,0.0);
 vec3 upv = abs(dir.y) < .99 ? vec3(0.0,1.0,0.0) : vec3(1.0,0.0,0.0);
 vec3 ex = normalize(cross(upv,dir));
 vec3 ez = cross(dir,ex);
 vec3 v = VERTEX*size;
 v.y *= mix(1.0,elong,prog);
 // Sparks arc: fly out decelerating, then gravity pulls them back to the sand.
 VERTEX = ex*v.x+dir*v.y+ez*v.z+travel*prog-vec3(0.0,age*age*dist*.6,0.0);
 v_b = (1.0-smoothstep(.35,1.0,age))*COLOR.a;
}
void fragment() {
 ALBEDO = tint*brightness;
 ALPHA = v_b;
}
"""
const SCORCH_CODE := """shader_type spatial;
render_mode unshaded, depth_draw_never, shadows_disabled;
uniform float fade = 1.0;
uniform float seed = 0.0;
void fragment() {
 vec2 p = UV*2.0-1.0;
 float a = atan(p.y,p.x);
 float edge = .8+.07*sin(a*3.0+seed)+.04*sin(a*7.0+seed*2.3);
 float d = length(p)/edge;
 ALBEDO = vec3(.11,.075,.05);
 ALPHA = (1.0-smoothstep(.15,1.0,d))*.5*fade;
}
"""
static var billow_shader: Shader
static var spark_shader: Shader
static var scorch_shader: Shader
static var puff_mesh: SphereMesh
static var spark_mesh: SphereMesh

## [material, life, node, rise] per layer.
var layers: Array = []
## [light, peak, hold, decay] per light.
var lights: Array = []
var scorch: ShaderMaterial
var age := 0.0
## How big the blast is, in cells of about a metre: 1 a pop, 12 a barrel.
var size := 1.0
var _mark := true


## Blow up at [param at] with [param radius] metres of fire; [param mark]
## leaves a scorch behind (small, frequent pops go without).
static func boom(at: Vector3, radius: float, mark := true) -> BlastFx:
	var b := BlastFx.new()
	b._mark = mark
	b._build(radius, randi())
	Fx._spawn(b, Vector3(at.x, 0.0, at.z))
	return b


func _build(radius: float, seed_value: int) -> void:
	if billow_shader == null:
		billow_shader = Shader.new()
		billow_shader.code = BILLOW_CODE
		spark_shader = Shader.new()
		spark_shader.code = SPARK_CODE
		scorch_shader = Shader.new()
		scorch_shader.code = SCORCH_CODE
		puff_mesh = SphereMesh.new()
		puff_mesh.radius = 0.5
		puff_mesh.height = 1.0
		puff_mesh.radial_segments = 16
		puff_mesh.rings = 9
		spark_mesh = SphereMesh.new()
		spark_mesh.radius = 0.06
		spark_mesh.height = 0.12
		spark_mesh.radial_segments = 5
		spark_mesh.rings = 3
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	# The fire spreads over a disc of cells, the middle first.
	var cell := 0.8
	var reach := maxi(0, int(radius / cell))
	var cells: Array[Vector2i] = [Vector2i.ZERO]
	for x in range(-reach, reach + 1):
		for z in range(-reach, reach + 1):
			if (x != 0 or z != 0) and Vector2(x, z).length() <= radius / cell:
				cells.append(Vector2i(x, z))
	size = float(cells.size())
	var big := clampf((size - 5.0) / 30.0, 0.0, 1.0)
	var fire_puffs: Array = []
	var smoke_puffs: Array = []
	var tongues: Array = []
	for c in cells:
		var at := Vector3(c.x, 0, c.y) * cell + Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.2, 0.2))
		var middle := c == Vector2i.ZERO
		var stagger := (absi(c.x) + absi(c.y)) * 0.035
		for i in (9 if middle else 4):
			var off := Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(0.15, 0.6) + (i * 0.09 if middle else 0.0), rng.randf_range(-0.3, 0.3))
			var heat := (1.0 if middle else 0.8) * rng.randf_range(0.75, 1.0)
			fire_puffs.append([at + off, rng.randf_range(0.75, 1.2) * (1.3 if middle else 1.0), stagger + rng.randf_range(0, 0.12), heat, Vector3.ZERO, 1.0])
		if rng.randf() < (1.0 if middle else 0.45):
			smoke_puffs.append([at + Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(0.3, 0.7), rng.randf_range(-0.2, 0.2)), rng.randf_range(0.8, 1.4), stagger + 0.22 + rng.randf_range(0, 0.1)])
	# Flame tongues shoot up from the middle and out over the edge.
	for i in 5:
		var a := rng.randf() * TAU
		tongues.append([Vector3(0, 0.4, 0), 0.6, rng.randf_range(0, 0.06), 0.9, Vector3(cos(a) * 0.35, 1.0, sin(a) * 0.35).normalized(), 2.2])
	var rays := 0 if reach == 0 else 6 + reach * 2
	for i in rays:
		var a := TAU * i / rays + rng.randf_range(-0.2, 0.2)
		var dir := Vector3(cos(a), 0.35, sin(a)).normalized()
		tongues.append([Vector3(cos(a), 0, sin(a)) * radius * 0.8 + Vector3(0, 0.3, 0), 0.55, reach * 0.035 + 0.04, 0.8, dir, 2.4])
	_billow(fire_puffs, true, FIRE_LIFE + big * 0.25, 0.0, rng)
	_billow(tongues, true, 0.5 + big * 0.15, 0.0, rng)
	_billow(smoke_puffs, false, 1.6 + big * 1.2, 0.9 + big * 0.6, rng)
	_sparks(cells, cell, rng)
	# A short white pop, then the warm glow of the fireball.
	var glow := clampf(2.4 + size * 0.12, 2.6, 7.0) * 1.4
	_light(Vector3(0, 1.0, 0), glow, 4.0 + big * 3.0, 0.03, 0.12, Color("fff2d6"))
	_light(Vector3(0, 0.7, 0), glow * 1.3, 2.6 + big * 2.0, 0.08, 0.5 + big * 0.3, Color("ff9a3c"))
	var mark := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * (radius * 2.2 + 0.8)
	mark.mesh = quad
	mark.rotation.x = -PI / 2
	mark.position.y = 0.03
	scorch = ShaderMaterial.new()
	scorch.shader = scorch_shader
	scorch.set_shader_parameter("seed", rng.randf() * 10)
	mark.material_override = scorch
	mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mark.visible = _mark
	add_child(mark)


func _billow(puffs: Array, fire: bool, life: float, rise: float, rng: RandomNumberGenerator) -> void:
	if puffs.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = puff_mesh
	mm.instance_count = puffs.size()
	for i in puffs.size():
		var p: Array = puffs[i]
		var s: float = p[1]
		var basis := Basis.IDENTITY.scaled(Vector3.ONE * s)
		if fire and p.size() > 4 and p[5] > 1.01:
			# Stretched along the tongue's direction.
			var dir: Vector3 = p[4]
			var up := Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT
			var ex := up.cross(dir).normalized()
			var ez := dir.cross(ex)
			basis = Basis(ex * s, dir * s * p[5], ez * s)
			p[0] += dir * s * 0.5
		mm.set_instance_transform(i, Transform3D(basis, p[0]))
		if fire:
			mm.set_instance_color(i, Color(1, 1, 1, rng.randf_range(0.8, 0.95)))
			mm.set_instance_custom_data(i, Color(rng.randf(), p[2] / life, p[3], rng.randf_range(0, 0.6)))
		else:
			# Dark chapel smoke, a little warm.
			var g := rng.randf_range(0.22, 0.34)
			mm.set_instance_color(i, Color(g * 1.08, g, g * 0.95, rng.randf_range(0.55, 0.75)))
			mm.set_instance_custom_data(i, Color(rng.randf(), p[2] / life, 0, rng.randf_range(0, 0.5)))
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.custom_aabb = AABB(Vector3(-14, -1, -14), Vector3(28, 8, 28))
	var mat := ShaderMaterial.new()
	mat.shader = billow_shader
	mat.set_shader_parameter("is_fire", 1.0 if fire else 0.0)
	mat.set_shader_parameter("tail_power", 2.2 if fire else 0.5)
	mat.set_shader_parameter("lump_amount", 0.32 if fire else 0.26)
	node.material_override = mat
	add_child(node)
	layers.append([mat, life, node, rise])


func _sparks(cells: Array[Vector2i], cell: float, rng: RandomNumberGenerator) -> void:
	var count := clampi(int(size * 2.0), 12, 50)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = spark_mesh
	mm.instance_count = count
	for i in count:
		var c: Vector2i = cells[rng.randi() % cells.size()]
		var from := Vector3(c.x, 0, c.y) * cell + Vector3(0, 0.3, 0)
		var a := rng.randf() * TAU
		var elev := rng.randf_range(0.2, 1.3)
		var dir := Vector3(cos(a) * cos(elev), sin(elev), sin(a) * cos(elev))
		var travel := dir * rng.randf_range(0.8, 2.4)
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, from))
		mm.set_instance_color(i, Color(rng.randf_range(0.5, 1.2), rng.randf_range(0.2, 0.7), 1, rng.randf_range(0.6, 1.0)))
		mm.set_instance_custom_data(i, Color(travel.x, travel.y, travel.z, rng.randf_range(0, 0.15)))
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.custom_aabb = AABB(Vector3(-14, -1, -14), Vector3(28, 8, 28))
	var mat := ShaderMaterial.new()
	mat.shader = spark_shader
	mat.set_shader_parameter("tint", Color("ff9a3a"))
	mat.set_shader_parameter("brightness", 2.0)
	mat.set_shader_parameter("elong_max", 3.0)
	node.material_override = mat
	add_child(node)
	layers.append([mat, 0.55 + clampf(size / 60.0, 0, 0.35), node, 0.0])


func _light(at: Vector3, reach: float, peak: float, hold: float, decay: float, color: Color) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.omni_range = reach
	light.omni_attenuation = 1.1
	light.shadow_enabled = false
	light.light_color = color
	light.light_energy = peak
	add_child(light)
	lights.append([light, peak, hold, decay])


func _process(dt: float) -> void:
	age += dt
	for layer in layers:
		var t := clampf(age / float(layer[1]), 0, 1)
		layer[0].set_shader_parameter("anim", t)
		if layer[3] > 0:
			layer[2].position.y = layer[3] * t
		layer[2].visible = t < 1
	for l in lights:
		var light: OmniLight3D = l[0]
		var k := 1.0 if age < l[2] else maxf(0.0, 1.0 - (age - l[2]) / l[3])
		light.light_energy = l[1] * k * k
		light.visible = k > 0
	# The scorch mark outlives the fire and slowly fades.
	scorch.set_shader_parameter("fade", clampf(1.0 - (age - 3.0) / 4.0, 0, 1))
	if age > (7.0 if _mark else 2.5):
		queue_free()

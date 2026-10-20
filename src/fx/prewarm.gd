class_name Prewarm
extends Node3D
## Compiles every shader the game uses before anyone needs it, so the first
## fireball, the first frozen wizard or the first sentry never stutters.
##
## The GL renderer only compiles a shader (and each variant of it: lit or
## unshaded, transparent, instanced for particles) the first time something
## is drawn with it. So for a few frames at start-up, behind the title menu,
## this draws a tiny speck of every material in front of the camera, then
## goes away. Godot keeps the compiled programs in its shader cache on disk
## (rendering/shader_compiler/shader_cache, on in project.godot), so after
## the first launch on a machine even this step is nearly free.

const FRAMES := 6
## Every 3D shader file in these folders is compiled; each one compiles
## once whatever its uniforms, so one material each is enough.
const SHADER_DIRS := ["res://src/fx", "res://src/world"]

var _frames := FRAMES


static func run(camera: Camera3D) -> void:
	if camera == null or DisplayServer.get_name() == "headless":
		return
	var p := Prewarm.new()
	# The title menu pauses the tree; this has to run behind it.
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	camera.add_child(p)
	p.position = Vector3(0, 0, -2.0)


func _ready() -> void:
	var mats: Array[Material] = []
	for sh in _shaders():
		var sm := ShaderMaterial.new()
		sm.shader = sh
		mats.append(sm)
	# The standard material variants the effects build.
	mats.append(Fx.glow(Color.WHITE, 2.0))
	mats.append(Fx.additive(Color.WHITE, 1.0))
	mats.append(Fx.solid(Color.GRAY, 0.8))
	var field := StandardMaterial3D.new()
	field.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	field.albedo_texture = Fx.particle_mesh(0.2, Color.WHITE).material.albedo_texture
	mats.append(field)
	var lit_field := field.duplicate() as StandardMaterial3D
	lit_field.emission_enabled = true
	mats.append(lit_field)
	# Tiny in its own vertices, not by scale: billboards (hp bars, halos)
	# drop the node's scale and would fill the screen.
	var mesh := Art.sphere(0.002, 8)
	var i := 0
	for m in mats:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3((i % 6 - 2.5) * 0.004, (i / 6) * 0.004, 0)
		add_child(mi)
		i += 1
	# Every monster once: its materials compile and its meshes are built
	# and cached now, not when the first one walks in mid-fight.
	var at := 0
	for k: String in Enemy.KINDS:
		var e := Enemy.new()
		e.kind = k
		e.cfg = Enemy.KINDS[k]
		e._model = Node3D.new()
		e._build(e.cfg.get("model", k))
		var m := e._model
		e.free()
		m.scale = Vector3.ONE * 0.001
		m.position = Vector3((at % 8 - 3.5) * 0.004, -0.02 - (at / 8) * 0.004, 0)
		add_child(m)
		at += 1
	# Particles draw through a MultiMesh, which is its own variant.
	var sparks := Fx.particles(Color.WHITE, 4, 0.5, 0.01)
	sparks.local_coords = true
	add_child(sparks)
	sparks.emitting = true


static func _shaders() -> Array[Shader]:
	var out: Array[Shader] = []
	out.append_array(BlastFx.shaders())
	for dir: String in SHADER_DIRS:
		for f in ResourceLoader.list_directory(dir):
			if not f.ends_with(".gdshader"):
				continue
			var sh := load(dir + "/" + f) as Shader
			if sh and sh.get_mode() == Shader.MODE_SPATIAL:
				out.append(sh)
	return out


func _process(_dt: float) -> void:
	_frames -= 1
	if _frames <= 0:
		queue_free()

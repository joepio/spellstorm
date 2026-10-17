class_name ElementBall
extends Control
## An element in the HUD: a little ball with the element's own material
## (src/fx/element_ui.gdshader) and its icon on top. Place it with
## show_at(); hide() when the slot is empty.

var el := -1
var _ball: ColorRect
var _mat: ShaderMaterial
var _icon: Control


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://src/fx/element_ui.gdshader")
	_ball = ColorRect.new()
	_ball.material = _mat
	_ball.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ball.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_ball)
	_icon = Control.new()
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_icon.draw.connect(_draw_icon)
	add_child(_icon)


## Show element [param e] centred on [param c] with radius [param r].
func show_at(e: int, c: Vector2, r: float, dim := 1.0) -> void:
	visible = true
	position = c - Vector2(r, r)
	size = Vector2(r, r) * 2.0
	if e != el:
		el = e
		_mat.set_shader_parameter("element", e)
		_mat.set_shader_parameter("base", El.COLOR[e])
	_icon.queue_redraw()
	_mat.set_shader_parameter("dim", dim)


func _draw_icon() -> void:
	if el < 0:
		return
	var r := size.x * 0.5
	Icons.draw(_icon, el, Vector2(r, r), r * 0.6, Color(0.05, 0.03, 0.03, 0.85))

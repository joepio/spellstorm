class_name Pad
extends RefCounted
## One player's controller, read the same way whatever it is: a GameNight seat,
## a local joypad, the keyboard and mouse, or a bot writing into it.

enum { A, B, X, Y, LB, RB, BACK, START, LS, RS, UP, DOWN, LEFT, RIGHT, LT, RT }

enum Source { SEAT, JOYPAD, KEYBOARD, BOT }

var source := Source.BOT
var seat := 0
var device := 0
var move := Vector2.ZERO
var aim := Vector2.ZERO
var held := 0
var _before := 0
## Mouse aiming needs the wizard's position on screen.
var mouse_origin := Vector2.ZERO


static func seat_pad(index: int) -> Pad:
	var p := Pad.new()
	p.source = Source.SEAT
	p.seat = index
	return p


static func joypad(id: int) -> Pad:
	var p := Pad.new()
	p.source = Source.JOYPAD
	p.device = id
	return p


static func keyboard() -> Pad:
	var p := Pad.new()
	p.source = Source.KEYBOARD
	return p


func poll() -> void:
	_before = held
	match source:
		Source.SEAT: _read_frame(GameNight.frame_for_seat(seat))
		Source.JOYPAD: _read_joypad()
		Source.KEYBOARD: _read_keyboard()
		Source.BOT: pass


func down(b: int) -> bool:
	return held & (1 << b) != 0


func pressed(b: int) -> bool:
	return held & (1 << b) != 0 and _before & (1 << b) == 0


func released(b: int) -> bool:
	return held & (1 << b) == 0 and _before & (1 << b) != 0


## Bots and tests press buttons through this.
func set_button(b: int, on: bool) -> void:
	if on:
		held |= 1 << b
	else:
		held &= ~(1 << b)


func _read_frame(f: Dictionary) -> void:
	move = _dead(Vector2(GameNight.axis(f, 0), GameNight.axis(f, 1)))
	aim = _dead(Vector2(GameNight.axis(f, 2), GameNight.axis(f, 3)))
	var bits := int(f.get("buttons", 0)) & 0x3FFF
	if GameNight.axis(f, 4) > 0.4:
		bits |= 1 << LT
	if GameNight.axis(f, 5) > 0.4:
		bits |= 1 << RT
	held = bits


const JOY := [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_LEFT_SHOULDER,
	JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_BACK, JOY_BUTTON_START, JOY_BUTTON_LEFT_STICK,
	JOY_BUTTON_RIGHT_STICK, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT,
	JOY_BUTTON_DPAD_RIGHT]


func _read_joypad() -> void:
	move = _dead(Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)))
	aim = _dead(Vector2(Input.get_joy_axis(device, JOY_AXIS_RIGHT_X), Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y)))
	var bits := 0
	for i in JOY.size():
		if Input.is_joy_button_pressed(device, JOY[i]):
			bits |= 1 << i
	if Input.get_joy_axis(device, JOY_AXIS_TRIGGER_LEFT) > 0.4:
		bits |= 1 << LT
	if Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT) > 0.4:
		bits |= 1 << RT
	held = bits


## WASD moves, the mouse aims. 1 2 3 4 (or J K L I) are the four element
## pairs, Shift flips to the opposite. Left click casts, right click bursts,
## Space plants, F wards, Q dashes, R recasts.
func _read_keyboard() -> void:
	var m := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)))
	move = m.normalized()
	var vp := Engine.get_main_loop() as SceneTree
	if vp and vp.root:
		var mp := vp.root.get_mouse_position()
		var d := mp - mouse_origin
		aim = d.normalized() if d.length() > 20.0 else Vector2.ZERO
	var keys := {
		A: [KEY_1, KEY_J], B: [KEY_2, KEY_K], X: [KEY_3, KEY_L], Y: [KEY_4, KEY_I],
		LB: [KEY_SHIFT], RB: [KEY_SPACE], RS: [KEY_F], LS: [KEY_Q], UP: [KEY_R],
		LEFT: [KEY_Z], RIGHT: [KEY_C], DOWN: [KEY_V],
	}
	var bits := 0
	for b in keys:
		for k in keys[b]:
			if Input.is_key_pressed(k):
				bits |= 1 << b
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		bits |= 1 << RT
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		bits |= 1 << LT
	held = bits


static func _dead(v: Vector2) -> Vector2:
	var l := v.length()
	if l < 0.22:
		return Vector2.ZERO
	return v / l * clampf((l - 0.22) / 0.7, 0.0, 1.0)

class_name Icons
## Element icons drawn from simple shapes, so the HUD needs no text or image
## files: a flame, a snowflake, a drop, a bolt, a rock, a gust, a skull and an
## eye, plus the five fusions. Each fits a circle of radius [code]r[/code].


static func draw(ci: CanvasItem, e: int, c: Vector2, r: float, col: Color) -> void:
	var w := maxf(1.5, r * 0.16)
	match e:
		El.FIRE:
			_flame(ci, c, r, col)
		El.FROST:
			_snowflake(ci, c, r, col, w)
		El.WATER:
			_drop(ci, c, r, col)
		El.LIGHTNING:
			_bolt(ci, c, r, col)
		El.EARTH:
			_rock(ci, c, r, col)
		El.AIR:
			_gust(ci, c, r, col, w)
		El.POISON:
			_skull(ci, c, r, col)
		El.VOID:
			_eye(ci, c, r, col, w)
		El.STEAM:
			for i in 3:
				var x := c.x + (i - 1) * r * 0.55
				var pts := PackedVector2Array()
				for k in 9:
					var t := float(k) / 8.0
					pts.append(Vector2(x + sin(t * TAU) * r * 0.16, c.y + r * 0.8 - t * r * 1.6))
				ci.draw_polyline(pts, col, w, true)
		El.ICE:
			var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.6, 0), c + Vector2(0, r), c + Vector2(-r * 0.6, 0)])
			ci.draw_colored_polygon(pts, col)
			ci.draw_line(c + Vector2(0, -r * 0.7), c + Vector2(0, r * 0.7), col.darkened(0.5), w * 0.6)
		El.MUD:
			ci.draw_circle(c + Vector2(0, r * 0.15), r * 0.62, col)
			ci.draw_circle(c + Vector2(-r * 0.55, r * 0.55), r * 0.22, col)
			ci.draw_circle(c + Vector2(r * 0.6, r * 0.6), r * 0.16, col)
		El.MAGMA:
			_rock(ci, c, r, col)
			ci.draw_line(c + Vector2(-r * 0.3, -r * 0.4), c + Vector2(r * 0.05, r * 0.05), Color(1, 0.55, 0.1), w)
			ci.draw_line(c + Vector2(r * 0.05, r * 0.05), c + Vector2(r * 0.35, r * 0.45), Color(1, 0.55, 0.1), w)
		El.STORM:
			ci.draw_circle(c + Vector2(-r * 0.35, -r * 0.25), r * 0.38, col)
			ci.draw_circle(c + Vector2(r * 0.25, -r * 0.35), r * 0.45, col)
			ci.draw_rect(Rect2(c.x - r * 0.7, c.y - r * 0.3, r * 1.4, r * 0.35), col)
			_bolt(ci, c + Vector2(0, r * 0.45), r * 0.55, col)


static func _flame(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in 24:
		var t := float(i) / 24.0 * TAU
		# A teardrop pointing up, with a slight lick to one side.
		var x := sin(t)
		var y := cos(t)
		var pinch := 1.0 - 0.55 * maxf(0.0, -y)
		outer.append(c + Vector2(x * r * 0.62 * pinch + maxf(0.0, -y) * r * 0.12, -y * r * 0.95 + r * 0.1))
		inner.append(c + Vector2(x * r * 0.3 * pinch, -y * r * 0.5 + r * 0.38))
	ci.draw_colored_polygon(outer, col)
	ci.draw_colored_polygon(inner, col.lightened(0.55))


static func _snowflake(ci: CanvasItem, c: Vector2, r: float, col: Color, w: float) -> void:
	for i in 6:
		var a := i * TAU / 6.0
		var d := Vector2(sin(a), -cos(a))
		var tip := c + d * r
		ci.draw_line(c, tip, col, w, true)
		var mid := c + d * r * 0.55
		for s in [-1.0, 1.0]:
			ci.draw_line(mid, mid + d.rotated(s * 0.8) * r * 0.32, col, w * 0.8, true)


static func _drop(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var t := float(i) / 19.0 * PI
		pts.append(c + Vector2(cos(t + PI) * r * 0.62, r * 0.3 + sin(t) * r * 0.62))
	pts.append(c + Vector2(0, -r))
	ci.draw_colored_polygon(pts, col)
	ci.draw_circle(c + Vector2(-r * 0.22, r * 0.25), r * 0.13, col.lightened(0.6))


static func _bolt(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array([
		c + Vector2(r * 0.25, -r), c + Vector2(-r * 0.5, r * 0.12), c + Vector2(-r * 0.02, r * 0.12),
		c + Vector2(-r * 0.3, r), c + Vector2(r * 0.52, -r * 0.2), c + Vector2(r * 0.05, -r * 0.2)])
	ci.draw_colored_polygon(pts, col)


static func _rock(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array([
		c + Vector2(-r * 0.85, r * 0.55), c + Vector2(-r * 0.7, -r * 0.2), c + Vector2(-r * 0.2, -r * 0.75),
		c + Vector2(r * 0.45, -r * 0.6), c + Vector2(r * 0.85, -r * 0.05), c + Vector2(r * 0.75, r * 0.55)])
	ci.draw_colored_polygon(pts, col)
	ci.draw_line(c + Vector2(-r * 0.2, -r * 0.75), c + Vector2(-r * 0.05, r * 0.1), col.darkened(0.45), maxf(1.0, r * 0.1))
	ci.draw_line(c + Vector2(-r * 0.05, r * 0.1), c + Vector2(r * 0.4, r * 0.3), col.darkened(0.45), maxf(1.0, r * 0.1))


static func _gust(ci: CanvasItem, c: Vector2, r: float, col: Color, w: float) -> void:
	for i in 3:
		var y := c.y + (i - 1) * r * 0.55
		var len_k: float = [0.9, 1.2, 0.7][i]
		var x0 := c.x - r * 0.85
		var x1 := x0 + r * 1.3 * len_k
		ci.draw_line(Vector2(x0, y), Vector2(x1, y), col, w, true)
		ci.draw_arc(Vector2(x1, y - r * 0.18), r * 0.18, PI * 0.5, PI * 2.0, 10, col, w, true)


static func _skull(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_circle(c + Vector2(0, -r * 0.12), r * 0.62, col)
	ci.draw_rect(Rect2(c + Vector2(-r * 0.36, r * 0.2), Vector2(r * 0.72, r * 0.5)), col)
	var hole := col.darkened(0.8)
	ci.draw_circle(c + Vector2(-r * 0.24, -r * 0.1), r * 0.17, hole)
	ci.draw_circle(c + Vector2(r * 0.24, -r * 0.1), r * 0.17, hole)
	for i in 3:
		ci.draw_line(c + Vector2((i - 1) * r * 0.2, r * 0.42), c + Vector2((i - 1) * r * 0.2, r * 0.7), hole, maxf(1.0, r * 0.07))


static func _eye(ci: CanvasItem, c: Vector2, r: float, col: Color, w: float) -> void:
	var top := PackedVector2Array()
	for i in 17:
		var t := float(i) / 16.0
		top.append(c + Vector2((t - 0.5) * r * 1.9, -sin(t * PI) * r * 0.62))
	for i in 17:
		var t := 1.0 - float(i) / 16.0
		top.append(c + Vector2((t - 0.5) * r * 1.9, sin(t * PI) * r * 0.62))
	ci.draw_colored_polygon(top, col)
	ci.draw_circle(c, r * 0.36, col.darkened(0.8))
	ci.draw_circle(c, r * 0.14, col.lightened(0.5))

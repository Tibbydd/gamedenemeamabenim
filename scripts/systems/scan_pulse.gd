extends Node2D

const DURATION: float = 0.55

var elapsed: float = 0.0
var max_radius: float = 360.0

func _ready() -> void:
	z_index = 50

func setup(radius: float) -> void:
	max_radius = radius

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= DURATION:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t: float = elapsed / DURATION
	var r: float = lerpf(8.0, max_radius, t)
	var a: float = lerpf(0.85, 0.0, t)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(0.35, 1.0, 1.0, a), 3.0, true)
	draw_arc(Vector2.ZERO, maxf(0.0, r - 6.0), 0.0, TAU, 64, Color(0.75, 1.0, 1.0, a * 0.5), 1.5, true)

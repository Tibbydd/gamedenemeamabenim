extends Node2D

const SCAN_PULSE_SCENE: PackedScene = preload("res://scenes/ScanPulse.tscn")

const ROOM_SIZE: Vector2 = Vector2(600, 900)
const FLOOR_COLOR: Color = Color(0.04, 0.05, 0.08)
const WALL_FILL: Color = Color(0.12, 0.14, 0.20)
const WALL_EDGE: Color = Color(0.35, 0.55, 0.75, 0.55)

@onready var floor_layer: Node2D = $Floor
@onready var walls_layer: Node2D = $Walls

func _ready() -> void:
	GameEvents.scan_emitted.connect(_on_scan_emitted)
	_build_room()

func _build_room() -> void:
	_paint_floor()
	# Outer walls (16 px thick, overhanging corners)
	var t: float = 16.0
	var w: float = ROOM_SIZE.x
	var h: float = ROOM_SIZE.y
	_spawn_wall(Vector2(w * 0.5, -t * 0.5), Vector2(w + t * 2.0, t))
	_spawn_wall(Vector2(w * 0.5, h + t * 0.5), Vector2(w + t * 2.0, t))
	_spawn_wall(Vector2(-t * 0.5, h * 0.5), Vector2(t, h + t * 2.0))
	_spawn_wall(Vector2(w + t * 0.5, h * 0.5), Vector2(t, h + t * 2.0))
	# Interior cover so Memory Scan has something to "see around"
	_spawn_wall(Vector2(170, 300), Vector2(120, 40))
	_spawn_wall(Vector2(420, 500), Vector2(80, 200))
	_spawn_wall(Vector2(220, 680), Vector2(40, 120))

func _paint_floor() -> void:
	var rect := Polygon2D.new()
	rect.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(ROOM_SIZE.x, 0),
		ROOM_SIZE,
		Vector2(0, ROOM_SIZE.y),
	])
	rect.color = FLOOR_COLOR
	rect.z_index = -10
	floor_layer.add_child(rect)
	# Grid hint lines for orientation
	var grid := Line2D.new()
	grid.default_color = Color(0.10, 0.18, 0.28, 0.35)
	grid.width = 1.0
	grid.z_index = -9
	floor_layer.add_child(grid)
	var step := 48.0
	var pts: Array[Vector2] = []
	var x: float = step
	while x < ROOM_SIZE.x:
		pts.append(Vector2(x, 0))
		pts.append(Vector2(x, ROOM_SIZE.y))
		pts.append(Vector2(x, 0))
		x += step
	var y: float = step
	while y < ROOM_SIZE.y:
		pts.append(Vector2(0, y))
		pts.append(Vector2(ROOM_SIZE.x, y))
		pts.append(Vector2(0, y))
		y += step
	grid.points = PackedVector2Array(pts)

func _spawn_wall(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = center
	body.collision_layer = 4
	body.collision_mask = 0
	var shape_node := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape_node.shape = rect
	body.add_child(shape_node)
	var hw: float = size.x * 0.5
	var hh: float = size.y * 0.5
	var fill := Polygon2D.new()
	fill.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw, hh), Vector2(-hw, hh),
	])
	fill.color = WALL_FILL
	body.add_child(fill)
	var edge := Line2D.new()
	edge.points = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw, hh), Vector2(-hw, hh),
		Vector2(-hw, -hh),
	])
	edge.width = 1.5
	edge.default_color = WALL_EDGE
	body.add_child(edge)
	walls_layer.add_child(body)

func _on_scan_emitted(world_position: Vector2, radius: float) -> void:
	var pulse := SCAN_PULSE_SCENE.instantiate()
	add_child(pulse)
	pulse.global_position = world_position
	if pulse.has_method("setup"):
		pulse.setup(radius)

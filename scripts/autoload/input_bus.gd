extends Node

# Unified input layer. Routes keyboard, mouse, and touch into one interface
# the gameplay code can consume without caring about the platform.

signal scan_pressed

var keyboard_vector: Vector2 = Vector2.ZERO
var pointer_held: bool = false

func _process(_delta: float) -> void:
	var v := Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		v.x += 1.0
	if Input.is_action_pressed("move_left"):
		v.x -= 1.0
	if Input.is_action_pressed("move_down"):
		v.y += 1.0
	if Input.is_action_pressed("move_up"):
		v.y -= 1.0
	keyboard_vector = v.normalized() if v.length_squared() > 0.0 else Vector2.ZERO
	# Safety net: GUI elements can consume the mouse-release event, leaving
	# pointer_held stuck true. Poll the actual state to downgrade — we never
	# upgrade here, so presses on GUI still won't trigger movement.
	if pointer_held and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		pointer_held = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pointer_held = event.pressed
	elif event.is_action_pressed("hack_scan"):
		scan_pressed.emit()

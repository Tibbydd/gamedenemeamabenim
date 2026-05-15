extends Node

var mouse_sensitivity: float = 0.0022
var invert_y: bool = false

func get_move_vector() -> Vector2:
	var move := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		move.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		move.x += 1.0
	if Input.is_key_pressed(KEY_W):
		move.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		move.y += 1.0
	return move.normalized()

func wants_sprint() -> bool:
	return Input.is_key_pressed(KEY_SHIFT)

func wants_crouch() -> bool:
	return Input.is_key_pressed(KEY_CTRL)

func wants_fire() -> bool:
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

func wants_aim() -> bool:
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

func wants_stealth_walk() -> bool:
	return Input.is_key_pressed(KEY_ALT)

func wants_reload(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R

func wants_weapon_check(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_H

func wants_weapon_inspect(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_I

func wants_interact(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E

func wants_build_next(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C

func wants_build_place(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_G

func wants_quick_bandage(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_B

func wants_trauma_kit(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_T

func wants_neural_stabilizer(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_X

func is_neural_stabilizer_held() -> bool:
	return Input.is_key_pressed(KEY_X)

func wants_injector(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V

func wants_shove(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F

func wants_restart(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R

func wants_debug_overlay(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3

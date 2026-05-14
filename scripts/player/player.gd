extends CharacterBody2D

const SPEED: float = 220.0
const MAX_HP: float = 100.0
const MAX_ENERGY: float = 100.0
const ENERGY_REGEN: float = 14.0
const SCAN_COST: float = 30.0
const SCAN_RADIUS: float = 360.0
const SCAN_COOLDOWN: float = 2.5
const I_FRAMES: float = 0.8
const POINTER_DEADZONE: float = 12.0

var hp: float = MAX_HP
var energy: float = MAX_ENERGY
var scan_ready_at: float = 0.0
var invuln_until: float = 0.0
var dead: bool = false

@onready var sprite: Sprite2D = $Sprite
@onready var camera: Camera2D = $Camera

func _ready() -> void:
	add_to_group("player")
	sprite.texture = SpriteFactory.get_texture("player")
	InputBus.scan_pressed.connect(_on_scan_pressed)
	camera.make_current()

func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
		return
	velocity = _resolve_direction() * SPEED
	move_and_slide()
	energy = minf(MAX_ENERGY, energy + ENERGY_REGEN * delta)

func _resolve_direction() -> Vector2:
	if InputBus.keyboard_vector != Vector2.ZERO:
		return InputBus.keyboard_vector
	if InputBus.pointer_held:
		var to_pointer := get_global_mouse_position() - global_position
		if to_pointer.length() > POINTER_DEADZONE:
			return to_pointer.normalized()
	return Vector2.ZERO

func _on_scan_pressed() -> void:
	if dead:
		return
	var now := _now()
	if now < scan_ready_at or energy < SCAN_COST:
		return
	energy -= SCAN_COST
	scan_ready_at = now + SCAN_COOLDOWN
	GameEvents.scan_emitted.emit(global_position, SCAN_RADIUS)

func take_damage(amount: float) -> void:
	if dead:
		return
	var now := _now()
	if now < invuln_until:
		return
	hp = maxf(0.0, hp - amount)
	invuln_until = now + I_FRAMES
	_flash_hit()
	if hp <= 0.0:
		dead = true
		modulate = Color(0.4, 0.4, 0.4)
		GameEvents.player_died.emit()

func can_scan() -> bool:
	return not dead and energy >= SCAN_COST and _now() >= scan_ready_at

func _flash_hit() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.4, 0.4, 0.4), 0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.20)

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0

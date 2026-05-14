extends CharacterBody2D

const SPEED: float = 95.0
const CONTACT_DAMAGE: float = 20.0

@onready var sprite: Sprite2D = $Sprite
@onready var damage_zone: Area2D = $DamageZone

var player: Node2D

func _ready() -> void:
	add_to_group("enemy")
	sprite.texture = SpriteFactory.get_texture("corruptor")
	damage_zone.body_entered.connect(_on_damage_zone_body_entered)
	GameEvents.scan_emitted.connect(_on_scan_emitted)
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(_delta: float) -> void:
	if player == null:
		return
	var to_player := player.global_position - global_position
	if to_player.length() < 1.0:
		velocity = Vector2.ZERO
	else:
		velocity = to_player.normalized() * SPEED
	move_and_slide()

func _on_damage_zone_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(CONTACT_DAMAGE)

func _on_scan_emitted(world_position: Vector2, radius: float) -> void:
	if global_position.distance_to(world_position) > radius:
		return
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(2.0, 1.4, 1.4), 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.4)

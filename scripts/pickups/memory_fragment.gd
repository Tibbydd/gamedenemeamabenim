extends Area2D

const HIDDEN_ALPHA: float = 0.18
const REVEAL_FADE: float = 0.4

var revealed: bool = false

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	add_to_group("fragment")
	sprite.texture = SpriteFactory.get_texture("fragment")
	sprite.modulate.a = HIDDEN_ALPHA
	body_entered.connect(_on_body_entered)
	GameEvents.scan_emitted.connect(_on_scan_emitted)

func _on_scan_emitted(world_position: Vector2, radius: float) -> void:
	if global_position.distance_to(world_position) <= radius:
		reveal()

func reveal() -> void:
	if revealed:
		return
	revealed = true
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, REVEAL_FADE)
	var bob := create_tween().set_loops()
	bob.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.6).set_trans(Tween.TRANS_SINE)
	bob.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.6).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		GameEvents.fragment_collected.emit()
		queue_free()

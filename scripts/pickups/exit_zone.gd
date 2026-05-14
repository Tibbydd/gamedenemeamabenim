extends Area2D

var armed: bool = false

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	sprite.texture = SpriteFactory.get_texture("exit")
	sprite.modulate.a = 0.25
	body_entered.connect(_on_body_entered)
	GameEvents.fragment_collected.connect(_arm)

func _arm() -> void:
	if armed:
		return
	armed = true
	sprite.modulate.a = 1.0
	var pulse := create_tween().set_loops()
	pulse.tween_property(sprite, "modulate:a", 0.55, 0.6)
	pulse.tween_property(sprite, "modulate:a", 1.0, 0.6)

func _on_body_entered(body: Node) -> void:
	if armed and body.is_in_group("player"):
		GameEvents.player_won.emit()

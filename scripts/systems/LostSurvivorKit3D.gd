extends DynamicObject3D
class_name LostSurvivorKit3D

var contains_headset: bool = false
var recovered: bool = false
var survivor_index: int = 0
var stored_loadout: Dictionary = {}

func configure_lost_kit(index: int, loadout: Dictionary, had_headset: bool) -> void:
	survivor_index = index
	stored_loadout = loadout.duplicate(true)
	contains_headset = had_headset
	configure("Lost Survivor Kit %d" % survivor_index, Vector3(0.75, 0.32, 0.52), Color(0.18, 0.32, 0.3), 9.0)

func use(actor: Node) -> void:
	if recovered:
		return
	recovered = true
	if actor and actor.has_method("recover_lost_kit"):
		actor.recover_lost_kit(stored_loadout, contains_headset)
	GameEvents.emit_environment_impulse(global_position, 0.9, 1.0, self, "kit_recovered")
	queue_free()

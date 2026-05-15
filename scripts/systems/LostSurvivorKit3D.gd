extends DynamicObject3D
class_name LostSurvivorKit3D

var contains_headset: bool = false
var recovered: bool = false
var survivor_index: int = 0
var stored_loadout: Dictionary = {}
var blood_beacon_time: float = 0.0
var beacon_pulse_timer: float = 0.0
var decay_count: int = 0

func configure_lost_kit(index: int, loadout: Dictionary, had_headset: bool, bleeding_death: bool = false) -> void:
	survivor_index = index
	stored_loadout = loadout.duplicate(true)
	contains_headset = had_headset
	blood_beacon_time = 60.0 if bleeding_death else 0.0
	configure("Lost Survivor Kit %d" % survivor_index, Vector3(0.75, 0.32, 0.52), Color(0.18, 0.32, 0.3), 9.0)
	add_to_group("lost_survivor_kits")

func _process(delta: float) -> void:
	if blood_beacon_time <= 0.0 or recovered:
		return
	blood_beacon_time = max(0.0, blood_beacon_time - delta)
	beacon_pulse_timer -= delta
	if beacon_pulse_timer <= 0.0:
		beacon_pulse_timer = 5.0
		GameEvents.emit_player_noise(global_position, 8.0)
		GameEvents.request_sound("enemy_grunt", global_position, 0.16)

func use(actor: Node) -> void:
	if recovered:
		return
	recovered = true
	if actor and actor.has_method("recover_lost_kit"):
		actor.recover_lost_kit(stored_loadout, contains_headset)
	GameEvents.emit_environment_impulse(global_position, 0.9, 1.0, self, "kit_recovered")
	queue_free()

func erode_contents(reason: String = "time") -> void:
	if recovered:
		return
	decay_count += 1
	var recoverable := int(stored_loadout.get("recoverable_ammo", 0))
	if recoverable > 0:
		stored_loadout["recoverable_ammo"] = max(0, recoverable - randi_range(1, 4))
		return
	var resources: Dictionary = stored_loadout.get("resources", {})
	for key in resources.keys():
		if int(resources[key]) > 0:
			resources[key] = max(0, int(resources[key]) - 1)
			stored_loadout["resources"] = resources
			return
	if reason == "surgeon":
		contains_headset = false

func consume_by_enemy(enemy: Node) -> void:
	erode_contents("surgeon")
	GameEvents.request_sound("enemy_attack", global_position, 0.45)

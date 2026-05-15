extends SceneTree

func _initialize() -> void:
	var arena := load("res://scenes/PrototypeArena.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	await process_frame
	var player := arena.get("player") as PlayerControllerFPS
	assert(player != null, "PrototypeArena should spawn a player.")
	var first_survivor := int(arena.get("survivor_count"))
	player.health.kill("smoke test")
	await create_timer(2.6).timeout
	var next_player := arena.get("player") as PlayerControllerFPS
	assert(next_player != null, "Successor should spawn after death.")
	assert(int(arena.get("survivor_count")) > first_survivor, "Survivor count should advance after handoff.")
	quit(0)

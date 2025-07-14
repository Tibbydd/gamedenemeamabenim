extends Node
class_name EnemySpawner

# Enemy spawning system for CURSOR: Fragments of the Forgotten

var enemy_scenes: Dictionary = {}
var spawned_enemies: Array[Enemy] = []

func _ready() -> void:
	# Load enemy scenes
	load_enemy_scenes()

func load_enemy_scenes() -> void:
	# For now, we'll create enemies via script
	# In a full implementation, these would be PackedScenes
	pass

func spawn_enemies_for_room(room: DungeonGenerator.Room, parent_node: Node2D) -> void:
	var emotion = DungeonGenerator.current_dungeon.mind_profile.primary_emotion
	
	# Spawn enemies based on room type and enemy spawn points
	for spawn_pos in room.enemy_spawns:
		var enemy_type = determine_enemy_type(room.type, emotion)
		var enemy = create_enemy(enemy_type, emotion)
		
		if enemy:
			# Position enemy in world coordinates
			var world_pos = Vector2(
				(room.position.x + spawn_pos.x) * 32 + 16,
				(room.position.y + spawn_pos.y) * 32 + 16
			)
			enemy.global_position = world_pos
			
			parent_node.add_child(enemy)
			spawned_enemies.append(enemy)
			
			# Connect enemy death signal for cleanup
			enemy.died.connect(_on_enemy_died.bind(enemy))

func determine_enemy_type(room_type: DungeonGenerator.RoomType, emotion: String) -> Enemy.EnemyType:
	# Determine enemy type based on room and emotion
	match room_type:
		DungeonGenerator.RoomType.COMBAT_ARENA:
			# Combat rooms favor aggressive enemies
			if emotion in ["anger", "trauma"]:
				return Enemy.EnemyType.CORRUPTOR
			else:
				return [Enemy.EnemyType.CORRUPTOR, Enemy.EnemyType.LOOPER][randi() % 2]
		
		DungeonGenerator.RoomType.PUZZLE_ROOM:
			# Puzzle rooms favor mind-based enemies
			return Enemy.EnemyType.PHANTOM_MEMORY
		
		DungeonGenerator.RoomType.BOSS_CHAMBER:
			# Boss rooms get stronger enemy types
			match emotion:
				"anger", "trauma":
					return Enemy.EnemyType.CORRUPTOR
				"regret", "melancholy":
					return Enemy.EnemyType.PHANTOM_MEMORY
				_:
					return Enemy.EnemyType.LOOPER
		
		DungeonGenerator.RoomType.EMOTION_CORE:
			# Core rooms get enemies matching the emotion
			match emotion:
				"anger", "trauma":
					return Enemy.EnemyType.CORRUPTOR
				"regret", "melancholy", "fear":
					return Enemy.EnemyType.PHANTOM_MEMORY
				_:
					return Enemy.EnemyType.LOOPER
		
		_:
			# Default random selection
			return [Enemy.EnemyType.CORRUPTOR, Enemy.EnemyType.LOOPER, Enemy.EnemyType.PHANTOM_MEMORY][randi() % 3]

func create_enemy(enemy_type: Enemy.EnemyType, emotion: String) -> Enemy:
	var enemy: Enemy = null
	
	match enemy_type:
		Enemy.EnemyType.CORRUPTOR:
			enemy = Corruptor.new()
		Enemy.EnemyType.LOOPER:
			enemy = Looper.new()
		Enemy.EnemyType.PHANTOM_MEMORY:
			enemy = PhantomMemory.new()
	
	if enemy:
		enemy.set_emotion_type(emotion)
		print("Spawned ", enemy.get_enemy_type_string(), " with emotion: ", emotion)
	
	return enemy

func spawn_boss_enemy(room: DungeonGenerator.Room, parent_node: Node2D) -> Enemy:
	var emotion = DungeonGenerator.current_dungeon.mind_profile.primary_emotion
	var corruption_level = DungeonGenerator.current_dungeon.mind_profile.corruption_level
	
	# Create enhanced boss version
	var boss_type = determine_enemy_type(room.type, emotion)
	var boss = create_enemy(boss_type, emotion)
	
	if boss:
		# Enhance boss stats
		boss.max_health *= 2.0
		boss.health = boss.max_health
		boss.attack_damage *= 1.5
		boss.move_speed *= 1.2
		boss.detection_range *= 1.3
		
		# Position boss at center of room
		var center_pos = Vector2(
			(room.position.x + room.size.x / 2) * 32,
			(room.position.y + room.size.y / 2) * 32
		)
		boss.global_position = center_pos
		
		parent_node.add_child(boss)
		spawned_enemies.append(boss)
		boss.died.connect(_on_enemy_died.bind(boss))
		
		# Visual boss effect
		create_boss_spawn_effect(boss)
	
	return boss

func create_boss_spawn_effect(boss: Enemy) -> void:
	# Create dramatic boss spawn effect
	var effect_node = Node2D.new()
	boss.get_parent().add_child(effect_node)
	effect_node.global_position = boss.global_position
	
	# Create expanding rings
	for i in range(5):
		var ring = ColorRect.new()
		ring.size = Vector2(20, 20)
		ring.position = Vector2(-10, -10)
		ring.color = boss.sprite_node.modulate
		ring.color.a = 0.7
		effect_node.add_child(ring)
		
		var delay = i * 0.2
		var tween = boss.create_tween()
		tween.tween_delay(delay)
		tween.parallel().tween_property(ring, "scale", Vector2(8, 8), 1.0)
		tween.parallel().tween_property(ring, "modulate:a", 0.0, 1.0)
	
	# Clean up effect
	var cleanup_tween = boss.create_tween()
	cleanup_tween.tween_delay(2.0)
	cleanup_tween.tween_callback(effect_node.queue_free)

func spawn_emotion_specific_enemies(emotion: String, count: int, area_center: Vector2, radius: float, parent_node: Node2D) -> void:
	# Spawn enemies that match the current emotion theme
	for i in range(count):
		var enemy_type = get_emotion_enemy_type(emotion)
		var enemy = create_enemy(enemy_type, emotion)
		
		if enemy:
			# Position randomly in area
			var angle = randf() * TAU
			var distance = randf() * radius
			var spawn_pos = area_center + Vector2(cos(angle), sin(angle)) * distance
			
			enemy.global_position = spawn_pos
			parent_node.add_child(enemy)
			spawned_enemies.append(enemy)
			enemy.died.connect(_on_enemy_died.bind(enemy))

func get_emotion_enemy_type(emotion: String) -> Enemy.EnemyType:
	match emotion:
		"anger", "trauma":
			return Enemy.EnemyType.CORRUPTOR
		"regret", "melancholy":
			return Enemy.EnemyType.PHANTOM_MEMORY
		"fear":
			return [Enemy.EnemyType.PHANTOM_MEMORY, Enemy.EnemyType.LOOPER][randi() % 2]
		"joy":
			return Enemy.EnemyType.LOOPER
		_:
			return [Enemy.EnemyType.CORRUPTOR, Enemy.EnemyType.LOOPER, Enemy.EnemyType.PHANTOM_MEMORY][randi() % 3]

func apply_global_enemy_effects(effect_type: String, duration: float = 0.0) -> void:
	# Apply effects to all spawned enemies
	for enemy in spawned_enemies:
		if not enemy or not is_instance_valid(enemy):
			continue
		
		match effect_type:
			"stun":
				enemy.apply_stun(duration)
			"confusion":
				enemy.apply_code_injection("confused")
			"friendly":
				enemy.apply_code_injection("friendly")
			"aggressive":
				enemy.apply_code_injection("aggressive")

func get_enemies_in_range(center: Vector2, radius: float) -> Array[Enemy]:
	var enemies_in_range: Array[Enemy] = []
	
	for enemy in spawned_enemies:
		if not enemy or not is_instance_valid(enemy):
			continue
		
		if enemy.global_position.distance_to(center) <= radius:
			enemies_in_range.append(enemy)
	
	return enemies_in_range

func get_enemy_count() -> int:
	# Return count of valid, alive enemies
	var count = 0
	for enemy in spawned_enemies:
		if enemy and is_instance_valid(enemy):
			count += 1
	return count

func clear_all_enemies() -> void:
	# Remove all enemies (for level transitions)
	for enemy in spawned_enemies:
		if enemy and is_instance_valid(enemy):
			enemy.queue_free()
	spawned_enemies.clear()

func _on_enemy_died(enemy: Enemy) -> void:
	# Remove enemy from tracking
	if enemy in spawned_enemies:
		spawned_enemies.erase(enemy)
	
	print("Enemy died, remaining: ", get_enemy_count())
	
	# Check if all enemies in room are defeated
	check_room_clear_condition()

func check_room_clear_condition() -> void:
	# Could trigger room completion events, unlock doors, etc.
	var remaining_count = get_enemy_count()
	if remaining_count == 0:
		print("All enemies defeated!")
		# Could trigger rewards, unlock areas, etc.

func spawn_reinforcements(trigger_position: Vector2, count: int, parent_node: Node2D) -> void:
	# Spawn emergency reinforcement enemies
	var emotion = DungeonGenerator.current_dungeon.mind_profile.primary_emotion if DungeonGenerator.current_dungeon else "neutral"
	
	spawn_emotion_specific_enemies(emotion, count, trigger_position, 100.0, parent_node)
	
	print("Spawned ", count, " reinforcement enemies")

func create_enemy_wave(wave_size: int, spawn_center: Vector2, parent_node: Node2D) -> void:
	# Create a wave of enemies with dramatic effect
	var emotion = DungeonGenerator.current_dungeon.mind_profile.primary_emotion if DungeonGenerator.current_dungeon else "neutral"
	
	for i in range(wave_size):
		# Stagger spawning for dramatic effect
		var spawn_timer = parent_node.create_tween()
		spawn_timer.tween_delay(i * 0.5)
		spawn_timer.tween_callback(func():
			var enemy_type = get_emotion_enemy_type(emotion)
			var enemy = create_enemy(enemy_type, emotion)
			
			if enemy:
				var angle = (i / float(wave_size)) * TAU
				var radius = 80.0
				var spawn_pos = spawn_center + Vector2(cos(angle), sin(angle)) * radius
				
				enemy.global_position = spawn_pos
				parent_node.add_child(enemy)
				spawned_enemies.append(enemy)
				enemy.died.connect(_on_enemy_died.bind(enemy))
				
				# Spawn effect
				create_enemy_spawn_effect(enemy)
		)

func create_enemy_spawn_effect(enemy: Enemy) -> void:
	# Visual effect for enemy spawning
	var effect = ColorRect.new()
	effect.size = Vector2(40, 40)
	effect.position = Vector2(-20, -20)
	effect.color = enemy.sprite_node.modulate
	effect.color.a = 0.8
	enemy.add_child(effect)
	
	var tween = enemy.create_tween()
	tween.parallel().tween_property(effect, "scale", Vector2(2, 2), 0.5)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.5)
	tween.tween_callback(effect.queue_free)
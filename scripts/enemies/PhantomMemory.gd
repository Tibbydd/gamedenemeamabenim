extends Enemy
class_name PhantomMemory

# PhantomMemory - Ethereal memory-based enemy
# Behavior: Phases through walls, steals memories, creates illusions

var phase_duration: float = 3.0
var phase_cooldown: float = 8.0
var phase_timer: float = 0.0
var is_phasing: bool = false
var memory_steal_range: float = 80.0
var memory_steal_timer: float = 0.0
var memory_steal_interval: float = 6.0
var illusion_timer: float = 0.0
var illusion_interval: float = 12.0
var stolen_memories: int = 0
var max_stolen_memories: int = 3

func _ready() -> void:
	enemy_type = EnemyType.PHANTOM_MEMORY
	
	# High mobility, moderate health, memory-based attacks
	max_health = 40.0
	health = max_health
	move_speed = 110.0
	base_move_speed = move_speed
	attack_damage = 12.0
	detection_range = 160.0
	attack_range = 50.0
	
	super._ready()
	
	# Start semi-transparent
	sprite_node.modulate.a = 0.8

func _process(delta: float) -> void:
	super._process(delta)
	
	# Phase management
	if phase_timer > 0:
		phase_timer -= delta
		if is_phasing and phase_timer <= 0:
			end_phase()
	elif phase_cooldown > 0:
		phase_cooldown -= delta
	
	# Memory stealing
	memory_steal_timer += delta
	if memory_steal_timer >= memory_steal_interval:
		attempt_memory_steal()
		memory_steal_timer = 0.0
	
	# Illusion creation
	illusion_timer += delta
	if illusion_timer >= illusion_interval:
		create_memory_illusion()
		illusion_timer = 0.0

func apply_chase_modifier(direction: Vector2, delta: float) -> void:
	# PhantomMemory phases through obstacles when chasing
	if not is_phasing and phase_cooldown <= 0:
		start_phase()
	
	# Moves in haunting, floating patterns
	var float_offset = sin(state_timer * 2.0) * 20.0
	var perpendicular = Vector2(-direction.y, direction.x)
	velocity += perpendicular * float_offset * delta

func start_phase() -> void:
	is_phasing = true
	phase_timer = phase_duration
	phase_cooldown = 8.0
	
	# Become ghostly and pass through walls
	sprite_node.modulate.a = 0.4
	collision_layer = 0  # Disable collision with walls
	collision_mask = 1   # Only collide with player
	
	print("PhantomMemory started phasing")
	
	# Visual phasing effect
	create_phase_effect()

func end_phase() -> void:
	is_phasing = false
	sprite_node.modulate.a = 0.8
	collision_layer = 2  # Re-enable normal collision
	collision_mask = 5   # Collide with player and environment
	
	print("PhantomMemory ended phasing")

func create_phase_effect() -> void:
	# Create swirling ghostly particles
	var effect_node = Node2D.new()
	add_child(effect_node)
	
	for i in range(12):
		var particle = ColorRect.new()
		particle.size = Vector2(3, 3)
		particle.color = Color.WHITE
		particle.color.a = 0.6
		effect_node.add_child(particle)
		
		var angle = (i / 12.0) * TAU
		var radius = 25.0
		var start_pos = Vector2(cos(angle), sin(angle)) * radius
		particle.position = start_pos
		
		var tween = create_tween()
		tween.set_loops(int(phase_duration))
		tween.tween_property(particle, "rotation", TAU, 1.0)
	
	# Clean up after phase ends
	var cleanup_tween = create_tween()
	cleanup_tween.tween_delay(phase_duration)
	cleanup_tween.tween_callback(effect_node.queue_free)

func apply_attack_effects() -> void:
	# Memory drain attack
	perform_memory_drain()
	
	# Create confusion effect
	create_confusion_field()

func perform_memory_drain() -> void:
	if not target_player:
		return
	
	print("PhantomMemory performing memory drain")
	
	# Visual memory drain effect
	var drain_effect = Line2D.new()
	drain_effect.width = 3.0
	drain_effect.default_color = Color.PURPLE
	drain_effect.add_point(Vector2.ZERO)
	drain_effect.add_point(to_local(target_player.global_position))
	add_child(drain_effect)
	
	# Animate the drain
	var tween = create_tween()
	tween.tween_method(animate_memory_drain, 0.0, 1.0, 1.0)
	tween.tween_callback(drain_effect.queue_free)
	
	# Apply memory effects to player
	if target_player.has_method("apply_memory_confusion"):
		target_player.apply_memory_confusion(3.0)

func animate_memory_drain(progress: float) -> void:
	# Animate particles flowing from player to phantom
	if not target_player:
		return
	
	for i in range(3):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = Color.PURPLE
		particle.color.a = 0.8
		
		var start_pos = target_player.global_position
		var end_pos = global_position
		var current_pos = start_pos.lerp(end_pos, progress)
		
		particle.global_position = current_pos
		get_parent().add_child(particle)
		
		# Fade out particle
		var fade_tween = create_tween()
		fade_tween.tween_property(particle, "modulate:a", 0.0, 0.3)
		fade_tween.tween_callback(particle.queue_free)

func create_confusion_field() -> void:
	# Create area that confuses player controls
	var confusion_area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 70.0
	collision.shape = shape
	confusion_area.add_child(collision)
	confusion_area.global_position = global_position
	
	get_parent().add_child(confusion_area)
	
	# Visual effect
	var effect_circle = ColorRect.new()
	effect_circle.size = Vector2(140, 140)
	effect_circle.position = Vector2(-70, -70)
	effect_circle.color = Color.PURPLE
	effect_circle.color.a = 0.2
	confusion_area.add_child(effect_circle)
	
	# Connect area signals
	confusion_area.body_entered.connect(_on_confusion_area_entered)
	confusion_area.body_exited.connect(_on_confusion_area_exited)
	
	# Remove after duration
	var cleanup_tween = create_tween()
	cleanup_tween.tween_delay(5.0)
	cleanup_tween.tween_callback(confusion_area.queue_free)

func _on_confusion_area_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Player entered confusion field")
		# Could reverse controls or add input lag

func _on_confusion_area_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Player exited confusion field")

func attempt_memory_steal() -> void:
	if not target_player or stolen_memories >= max_stolen_memories:
		return
	
	var distance = global_position.distance_to(target_player.global_position)
	if distance <= memory_steal_range:
		steal_memory()

func steal_memory() -> void:
	stolen_memories += 1
	print("PhantomMemory stole memory! Total: ", stolen_memories)
	
	# Create memory steal effect
	var steal_effect = ColorRect.new()
	steal_effect.size = Vector2(30, 30)
	steal_effect.position = Vector2(-15, -15)
	steal_effect.color = Color.CYAN
	steal_effect.color.a = 0.7
	target_player.add_child(steal_effect)
	
	var tween = create_tween()
	tween.tween_property(steal_effect, "scale", Vector2(2, 2), 0.5)
	tween.parallel().tween_property(steal_effect, "modulate:a", 0.0, 0.5)
	tween.tween_callback(steal_effect.queue_free)
	
	# Enhance phantom based on stolen memories
	enhance_from_memory()

func enhance_from_memory() -> void:
	# Get stronger with each stolen memory
	attack_damage += 3.0
	move_speed += 5.0
	detection_range += 10.0
	
	# Visual enhancement
	sprite_node.modulate = sprite_node.modulate.lerp(Color.CYAN, 0.2)
	
	print("PhantomMemory enhanced! Attack: ", attack_damage, " Speed: ", move_speed)

func create_memory_illusion() -> void:
	print("PhantomMemory creating illusion")
	
	# Create fake player illusions
	for i in range(2):
		create_player_illusion()
	
	# Create fake memory fragments
	create_fake_memory_fragments()

func create_player_illusion() -> void:
	if not target_player:
		return
	
	# Create fake player sprite
	var illusion = Sprite2D.new()
	# Use player sprite if available, otherwise create similar
	if target_player.has_method("get_node") and target_player.get_node("Sprite"):
		var player_sprite = target_player.get_node("Sprite")
		illusion.texture = player_sprite.texture
	else:
		illusion.texture = SpriteGenerator.create_player_sprite()
	
	illusion.modulate = Color.CYAN
	illusion.modulate.a = 0.6
	
	# Position randomly around player
	var angle = randf() * TAU
	var distance = randf_range(60, 120)
	illusion.global_position = target_player.global_position + Vector2(cos(angle), sin(angle)) * distance
	
	get_parent().add_child(illusion)
	
	# Move illusion to confuse player
	var target_pos = illusion.global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
	var tween = create_tween()
	tween.tween_property(illusion, "global_position", target_pos, 3.0)
	tween.parallel().tween_property(illusion, "modulate:a", 0.0, 3.0)
	tween.tween_callback(illusion.queue_free)

func create_fake_memory_fragments() -> void:
	# Create fake memory fragments that disappear when touched
	for i in range(3):
		var fake_fragment = Area2D.new()
		var sprite = Sprite2D.new()
		sprite.texture = SpriteGenerator.create_memory_fragment_sprite(emotion_type, false)
		sprite.modulate = Color.RED  # Different color to indicate fake
		fake_fragment.add_child(sprite)
		
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 10
		collision.shape = shape
		fake_fragment.add_child(collision)
		
		# Position around phantom
		var angle = (i / 3.0) * TAU
		var distance = randf_range(80, 150)
		fake_fragment.global_position = global_position + Vector2(cos(angle), sin(angle)) * distance
		
		get_parent().add_child(fake_fragment)
		
		# Connect touch signal
		fake_fragment.body_entered.connect(_on_fake_fragment_touched.bind(fake_fragment))
		
		# Auto-remove after time
		var cleanup_tween = create_tween()
		cleanup_tween.tween_delay(8.0)
		cleanup_tween.tween_callback(fake_fragment.queue_free)

func _on_fake_fragment_touched(fake_fragment: Area2D, body: Node2D) -> void:
	if body.is_in_group("player"):
		# Create "fake" effect and remove
		var fake_effect = ColorRect.new()
		fake_effect.size = Vector2(40, 40)
		fake_effect.position = Vector2(-20, -20)
		fake_effect.color = Color.RED
		fake_effect.global_position = fake_fragment.global_position
		
		get_parent().add_child(fake_effect)
		
		var tween = create_tween()
		tween.tween_property(fake_effect, "scale", Vector2.ZERO, 0.3)
		tween.tween_callback(fake_effect.queue_free)
		
		fake_fragment.queue_free()
		print("Player touched fake memory fragment!")

func execute_injected_behavior(delta: float) -> void:
	match injection_type:
		"friendly":
			# Reveals real memory fragments and removes fakes
			reveal_true_memories()
		"aggressive":
			# Constant phasing and memory stealing
			super.execute_injected_behavior(delta)
			memory_steal_interval = 3.0
			illusion_interval = 6.0
			if not is_phasing and phase_cooldown <= 0:
				start_phase()
		"static":
			# Becomes a memory beacon
			velocity = Vector2.ZERO
			if state_timer > 2.0:
				create_memory_beacon()
				state_timer = 0.0
		"confused":
			# Creates chaotic illusions everywhere
			super.execute_injected_behavior(delta)
			if randf() < 0.1:
				create_memory_illusion()

func reveal_true_memories() -> void:
	# Remove fake fragments and highlight real ones
	var fragments = get_tree().get_nodes_in_group("memory_fragments")
	
	for fragment in fragments:
		if fragment.has_method("highlight"):
			fragment.highlight(5.0)
		
		# Create revealing effect
		var reveal_effect = ColorRect.new()
		reveal_effect.size = Vector2(50, 50)
		reveal_effect.position = Vector2(-25, -25)
		reveal_effect.color = Color.GREEN
		reveal_effect.color.a = 0.5
		fragment.add_child(reveal_effect)
		
		var tween = create_tween()
		tween.tween_property(reveal_effect, "scale", Vector2(2, 2), 1.0)
		tween.parallel().tween_property(reveal_effect, "modulate:a", 0.0, 1.0)
		tween.tween_callback(reveal_effect.queue_free)

func create_memory_beacon() -> void:
	# Creates a beacon that shows memory locations
	var beacon = ColorRect.new()
	beacon.size = Vector2(20, 20)
	beacon.position = Vector2(-10, -10)
	beacon.color = Color.WHITE
	beacon.global_position = global_position
	
	get_parent().add_child(beacon)
	
	# Pulsing effect
	var tween = create_tween()
	tween.set_loops(5)
	tween.tween_property(beacon, "scale", Vector2(3, 3), 0.5)
	tween.tween_property(beacon, "scale", Vector2(1, 1), 0.5)
	tween.tween_callback(beacon.queue_free)

func take_damage(amount: float) -> void:
	super.take_damage(amount)
	
	# When damaged, becomes more ethereal
	if health < max_health * 0.6:
		sprite_node.modulate.a = 0.6
		# Faster phasing
		phase_cooldown = max(phase_cooldown * 0.7, 2.0)

func die() -> void:
	# Release all stolen memories
	release_stolen_memories()
	
	# Create memory explosion
	create_memory_explosion()
	
	super.die()

func release_stolen_memories() -> void:
	# Create memory fragments equal to stolen memories
	var fragments_container = get_tree().get_first_node_in_group("memory_fragments")
	if not fragments_container:
		return
	
	for i in range(stolen_memories):
		var memory_fragment = Area2D.new()
		var sprite = Sprite2D.new()
		sprite.texture = SpriteGenerator.create_memory_fragment_sprite(emotion_type, true)
		memory_fragment.add_child(sprite)
		
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 10
		collision.shape = shape
		memory_fragment.add_child(collision)
		
		# Position around death location
		var angle = (i / float(stolen_memories)) * TAU
		var distance = randf_range(30, 60)
		memory_fragment.global_position = global_position + Vector2(cos(angle), sin(angle)) * distance
		
		fragments_container.add_child(memory_fragment)
		memory_fragment.add_to_group("memory_fragments")

func create_memory_explosion() -> void:
	# Visual explosion of memories
	for i in range(20):
		var memory_particle = ColorRect.new()
		memory_particle.size = Vector2(6, 6)
		memory_particle.color = Color.PURPLE
		memory_particle.global_position = global_position
		
		get_parent().add_child(memory_particle)
		
		var angle = randf() * TAU
		var distance = randf_range(50, 150)
		var target = global_position + Vector2(cos(angle), sin(angle)) * distance
		
		var tween = create_tween()
		tween.tween_property(memory_particle, "global_position", target, 1.5)
		tween.parallel().tween_property(memory_particle, "modulate:a", 0.0, 1.5)
		tween.tween_callback(memory_particle.queue_free)
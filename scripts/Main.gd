extends Node2D

# Main scene controller for CURSOR: Fragments of the Forgotten

# Scene references
@onready var camera: Camera2D = $Camera2D
@onready var dungeon_renderer: Node2D = $WorldContainer/DungeonRenderer
@onready var player: Node2D = $WorldContainer/Player
@onready var enemies_container: Node2D = $WorldContainer/Enemies
@onready var fragments_container: Node2D = $WorldContainer/MemoryFragments
@onready var effects_container: Node2D = $WorldContainer/Effects

# UI references
@onready var health_bar: ProgressBar = $UILayer/GameUI/TopPanel/HealthBar
@onready var energy_bar: ProgressBar = $UILayer/GameUI/TopPanel/EnergyBar
@onready var fragment_counter: Label = $UILayer/GameUI/TopPanel/FragmentCounter
@onready var mind_info_panel: Panel = $UILayer/GameUI/MindInfoPanel
@onready var mind_details: RichTextLabel = $UILayer/GameUI/MindInfoPanel/MindDetails

# Hack tool buttons
@onready var time_rewind_btn: Button = $UILayer/GameUI/BottomPanel/HackToolPanel/TimeRewindBtn
@onready var data_leak_btn: Button = $UILayer/GameUI/BottomPanel/HackToolPanel/DataLeakBtn
@onready var memory_scan_btn: Button = $UILayer/GameUI/BottomPanel/HackToolPanel/MemoryScanBtn

# Dungeon rendering
var tile_size: int = 32
var wall_tiles: Array[Node2D] = []
var floor_tiles: Array[Node2D] = []
var memory_fragment_instances: Array[Node2D] = []

# Preloaded scenes
var wall_tile_scene: PackedScene
var floor_tile_scene: PackedScene
var memory_fragment_scene: PackedScene
var enemy_spawner: EnemySpawner

func _ready() -> void:
	print("Main scene initialized")
	
	# Initialize enemy spawner
	enemy_spawner = EnemySpawner.new()
	add_child(enemy_spawner)
	
	# Connect signals
	connect_signals()
	
	# Setup camera for isometric view
	setup_isometric_camera()
	
	# Load tile scenes (will create placeholder scenes for now)
	load_tile_scenes()
	
	# Connect UI buttons
	setup_ui_buttons()
	
	# Start the game
	start_game()

func connect_signals() -> void:
	# GameManager signals
	GameManager.game_started.connect(_on_game_started)
	GameManager.memory_fragment_collected.connect(_on_memory_fragment_collected)
	GameManager.level_completed.connect(_on_level_completed)
	
	# DungeonGenerator signals
	DungeonGenerator.dungeon_generated.connect(_on_dungeon_generated)
	
	# MemorySystem signals
	MemorySystem.memory_fragment_found.connect(_on_memory_fragment_found)
	MemorySystem.memory_reconstruction_complete.connect(_on_memory_reconstruction_complete)
	
	# HackingSystem signals
	HackingSystem.hack_tool_used.connect(_on_hack_tool_used)
	HackingSystem.time_rewind_activated.connect(_on_time_rewind_activated)

func setup_isometric_camera() -> void:
	# Configure camera for isometric feel
	camera.zoom = Vector2(1.5, 1.5)
	camera.rotation_degrees = 0  # Keep 2D but with isometric sprites later
	
	# Enable camera smoothing
	camera.enabled = true

func load_tile_scenes() -> void:
	# Generate sprite-based tiles using the SpriteGenerator
	# These will be created dynamically based on the current dungeon's emotion
	pass  # Will be generated per-dungeon in render_dungeon()

# Old tile creation functions removed - now using SpriteGenerator

func setup_ui_buttons() -> void:
	# Connect hack tool buttons
	time_rewind_btn.pressed.connect(_on_time_rewind_pressed)
	data_leak_btn.pressed.connect(_on_data_leak_pressed)
	memory_scan_btn.pressed.connect(_on_memory_scan_pressed)
	
	# Apply cyberpunk styling
	apply_cyberpunk_styling()

func apply_cyberpunk_styling() -> void:
	# Apply cyberpunk themes to all UI elements
	EffectsManager.apply_cyberpunk_button_style(time_rewind_btn)
	EffectsManager.apply_cyberpunk_button_style(data_leak_btn)
	EffectsManager.apply_cyberpunk_button_style(memory_scan_btn)
	
	EffectsManager.apply_cyberpunk_progressbar_style(health_bar)
	EffectsManager.apply_cyberpunk_progressbar_style(energy_bar)
	
	# Apply panel styling
	var top_panel = $UILayer/GameUI/TopPanel
	var bottom_panel = $UILayer/GameUI/BottomPanel
	var mind_panel = mind_info_panel
	
	EffectsManager.apply_cyberpunk_panel_style(top_panel)
	EffectsManager.apply_cyberpunk_panel_style(bottom_panel)
	EffectsManager.apply_cyberpunk_panel_style(mind_panel)
	
	# Style labels
	fragment_counter.add_theme_color_override("font_color", Color.CYAN)
	
	var health_label = $UILayer/GameUI/TopPanel/HealthLabel
	var energy_label = $UILayer/GameUI/TopPanel/EnergyLabel
	health_label.add_theme_color_override("font_color", Color.CYAN)
	energy_label.add_theme_color_override("font_color", Color.CYAN)

func start_game() -> void:
	print("Starting new game...")
	GameManager.start_new_game()

func _process(delta: float) -> void:
	update_ui()
	
	# Update camera to follow player
	if player:
		camera.global_position = player.global_position

func update_ui() -> void:
	# Update health bar
	health_bar.value = GameManager.player_health
	health_bar.max_value = GameManager.max_player_health
	
	# Update energy bar
	energy_bar.value = GameManager.cursor_energy
	energy_bar.max_value = GameManager.max_cursor_energy
	
	# Update fragment counter
	fragment_counter.text = "FRAGMENTS: %d/%d" % [
		GameManager.memory_fragments_collected,
		GameManager.total_fragments_in_level
	]
	
	# Update hack tool button states
	update_hack_tool_buttons()

func update_hack_tool_buttons() -> void:
	# Time Rewind button
	var time_rewind_ready = HackingSystem.is_tool_ready(HackingSystem.HackTool.TIME_REWIND)
	time_rewind_btn.disabled = not time_rewind_ready or GameManager.cursor_energy < 20
	
	# Data Leak button
	var data_leak_ready = HackingSystem.is_tool_ready(HackingSystem.HackTool.DATA_LEAK)
	data_leak_btn.disabled = not data_leak_ready or GameManager.cursor_energy < 25
	
	# Memory Scan button
	var memory_scan_ready = HackingSystem.is_tool_ready(HackingSystem.HackTool.MEMORY_SCAN)
	memory_scan_btn.disabled = not memory_scan_ready or GameManager.cursor_energy < 15

func _on_game_started() -> void:
	print("Game started signal received")
	
	# Generate and display mind information
	var mind_profile = GameManager.current_mind_profile
	if mind_profile:
		display_mind_info(mind_profile)

func _on_dungeon_generated() -> void:
	print("Dungeon generated signal received")
	render_dungeon()
	spawn_memory_fragments()
	spawn_enemies()
	
	# Generate mind memory from profile
	if GameManager.current_mind_profile:
		MemorySystem.generate_mind_memory(GameManager.current_mind_profile)

func render_dungeon() -> void:
	# Clear existing tiles
	clear_dungeon_render()
	
	var dungeon = DungeonGenerator.get_current_dungeon()
	if not dungeon:
		return
	
	print("Rendering dungeon with ", dungeon.rooms.size(), " rooms")
	
	# Generate emotion-based tile sprites
	var emotion = dungeon.mind_profile.primary_emotion
	var corruption = dungeon.mind_profile.corruption_level
	
	# Render rooms
	for room in dungeon.rooms:
		render_room(room, emotion, corruption)
	
	# Render corridors
	render_corridors(dungeon.corridors, emotion, corruption)
	
	# Position player at entrance
	if player and dungeon.entrance_position:
		var world_pos = Vector2(
			dungeon.entrance_position.x * tile_size + tile_size / 2,
			dungeon.entrance_position.y * tile_size + tile_size / 2
		)
		player.global_position = world_pos

func clear_dungeon_render() -> void:
	# Remove all existing tiles
	for tile in wall_tiles + floor_tiles:
		if tile:
			tile.queue_free()
	wall_tiles.clear()
	floor_tiles.clear()

func render_room(room: DungeonGenerator.Room, emotion: String, corruption: float) -> void:
	for x in range(room.size.x):
		for y in range(room.size.y):
			var world_x = (room.position.x + x) * tile_size
			var world_y = (room.position.y + y) * tile_size
			var tile_type = room.tiles[x][y]
			
			var tile_instance: Sprite2D
			
			match tile_type:
				DungeonGenerator.TileType.WALL:
					tile_instance = Sprite2D.new()
					tile_instance.texture = SpriteGenerator.create_wall_sprite(emotion, corruption)
				DungeonGenerator.TileType.FLOOR, DungeonGenerator.TileType.PLAYER_SPAWN:
					tile_instance = Sprite2D.new()
					tile_instance.texture = SpriteGenerator.create_floor_sprite(emotion, corruption)
				_:
					tile_instance = Sprite2D.new()
					tile_instance.texture = SpriteGenerator.create_floor_sprite(emotion, corruption)
			
			if tile_instance:
				tile_instance.position = Vector2(world_x, world_y)
				dungeon_renderer.add_child(tile_instance)
				
				if tile_type == DungeonGenerator.TileType.WALL:
					wall_tiles.append(tile_instance)
					tile_instance.add_to_group("walls")
					
					# Add collision for walls
					var static_body = StaticBody2D.new()
					var collision_shape = CollisionShape2D.new()
					var rect_shape = RectangleShape2D.new()
					rect_shape.size = Vector2(tile_size, tile_size)
					collision_shape.shape = rect_shape
					static_body.add_child(collision_shape)
					static_body.position = Vector2(world_x, world_y)
					static_body.add_to_group("walls")
					dungeon_renderer.add_child(static_body)
				else:
					floor_tiles.append(tile_instance)

func render_corridors(corridors: Array[Vector2i], emotion: String, corruption: float) -> void:
	for corridor_pos in corridors:
		var world_x = corridor_pos.x * tile_size
		var world_y = corridor_pos.y * tile_size
		
		var tile_instance = Sprite2D.new()
		tile_instance.texture = SpriteGenerator.create_floor_sprite(emotion, corruption)
		tile_instance.position = Vector2(world_x, world_y)
		dungeon_renderer.add_child(tile_instance)
		floor_tiles.append(tile_instance)

func spawn_memory_fragments() -> void:
	# Clear existing fragments
	for fragment in memory_fragment_instances:
		if fragment:
			fragment.queue_free()
	memory_fragment_instances.clear()
	
	var dungeon = DungeonGenerator.get_current_dungeon()
	if not dungeon:
		return
	
	# Spawn fragments from rooms
	for room in dungeon.rooms:
		for fragment_pos in room.memory_fragments:
			spawn_memory_fragment_at(room.position + fragment_pos)

func spawn_memory_fragment_at(dungeon_pos: Vector2i) -> void:
	var fragment_instance = create_dynamic_memory_fragment()
	var world_pos = Vector2(
		dungeon_pos.x * tile_size + tile_size / 2,
		dungeon_pos.y * tile_size + tile_size / 2
	)
	fragment_instance.position = world_pos
	
	# Connect fragment collection signal
	if fragment_instance.has_signal("body_entered"):
		fragment_instance.body_entered.connect(_on_memory_fragment_touched)
	
	fragments_container.add_child(fragment_instance)
	memory_fragment_instances.append(fragment_instance)

func create_dynamic_memory_fragment() -> Area2D:
	var dungeon = DungeonGenerator.get_current_dungeon()
	var emotion = dungeon.mind_profile.primary_emotion if dungeon else "neutral"
	
	var fragment = Area2D.new()
	
	# Create sprite using SpriteGenerator
	var sprite = Sprite2D.new()
	sprite.texture = SpriteGenerator.create_memory_fragment_sprite(emotion, false)
	fragment.add_child(sprite)
	
	# Add collision
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 12
	collision.shape = shape
	fragment.add_child(collision)
	
	# Add to group
	fragment.add_to_group("memory_fragments")
	
	# Add glow animation
	var tween = fragment.create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "modulate:a", 0.7, 1.0)
	tween.tween_property(sprite, "modulate:a", 1.0, 1.0)
	
	return fragment

func spawn_enemies() -> void:
	# Clear existing enemies
	enemy_spawner.clear_all_enemies()
	
	var dungeon = DungeonGenerator.get_current_dungeon()
	if not dungeon:
		return
	
	print("Spawning enemies for ", dungeon.rooms.size(), " rooms")
	
	# Spawn enemies for each room
	for room in dungeon.rooms:
		if room.enemy_spawns.size() > 0:
			enemy_spawner.spawn_enemies_for_room(room, enemies_container)
		
		# Spawn boss for boss chambers
		if room.type == DungeonGenerator.RoomType.BOSS_CHAMBER:
			enemy_spawner.spawn_boss_enemy(room, enemies_container)

func display_mind_info(mind_profile: Dictionary) -> void:
	var info_text = "[center][b]ACCESSING MIND...[/b][/center]\n\n"
	info_text += "[b]Primary Emotion:[/b] " + str(mind_profile.get("primary_emotion", "Unknown")).capitalize() + "\n"
	info_text += "[b]Corruption Level:[/b] " + str(int(mind_profile.get("corruption_level", 0.5) * 100)) + "%\n"
	info_text += "[b]Profession:[/b] " + str(mind_profile.get("profession", "Unknown")).capitalize() + "\n"
	info_text += "[b]Memory Fragments:[/b] " + str(mind_profile.get("memory_density", 0)) + "\n\n"
	info_text += "[i]Preparing neural interface...[/i]"
	
	mind_details.text = info_text
	mind_info_panel.visible = true
	
	# Auto-hide after 3 seconds
	await get_tree().create_timer(3.0).timeout
	mind_info_panel.visible = false

# Hack tool button handlers
func _on_time_rewind_pressed() -> void:
	HackingSystem.use_cursor_tool(HackingSystem.HackTool.TIME_REWIND)

func _on_data_leak_pressed() -> void:
	HackingSystem.use_cursor_tool(HackingSystem.HackTool.DATA_LEAK)

func _on_memory_scan_pressed() -> void:
	HackingSystem.use_cursor_tool(HackingSystem.HackTool.MEMORY_SCAN)

# Signal handlers
func _on_memory_fragment_touched(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Find which fragment was touched and collect it
		var fragment_id = "fragment_" + str(randi_range(1000, 9999))  # Simplified ID
		MemorySystem.collect_fragment(fragment_id)
		GameManager.collect_memory_fragment()

func _on_memory_fragment_collected() -> void:
	print("Memory fragment collected!")
	
	# Create collection effect
	if player:
		EffectsManager.create_pulse_effect(player, 1.3, 0.4)
		EffectsManager.create_digital_noise_particles(player.global_position, effects_container, 8, Color.PURPLE)
		EffectsManager.create_screen_flash(Color.PURPLE, 0.1)

func _on_memory_fragment_found() -> void:
	print("Memory fragment found!")

func _on_level_completed() -> void:
	print("Level completed!")
	# Transition to next level or show completion screen

func _on_memory_reconstruction_complete() -> void:
	print("Memory reconstruction complete!")
	# Show ethical choice dialog

func _on_hack_tool_used() -> void:
	print("Hack tool used!")
	
	# Create hack tool activation effect
	if player:
		EffectsManager.create_glitch_effect(player, 0.3)
		EffectsManager.create_digital_noise_particles(player.global_position, effects_container, 12, Color.CYAN)

func _on_time_rewind_activated() -> void:
	print("Time rewind activated!")
	
	# Create time rewind visual effect
	EffectsManager.create_screen_flash(Color.CYAN, 0.3)
	if player:
		EffectsManager.create_data_stream_effect(
			player.global_position + Vector2(0, -50),
			player.global_position,
			effects_container,
			Color.CYAN
		)

func _input(event: InputEvent) -> void:
	# Handle keyboard shortcuts for hack tools
	if event.is_action_pressed("hack_time_rewind"):
		_on_time_rewind_pressed()
	elif event.is_action_pressed("hack_data_leak"):
		_on_data_leak_pressed()
	elif event.is_action_pressed("hack_memory_scan"):
		_on_memory_scan_pressed()

# Input map actions (these would be defined in the project settings)
# hack_time_rewind: Z key
# hack_data_leak: X key  
# hack_memory_scan: C key
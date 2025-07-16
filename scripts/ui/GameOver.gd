extends Control

# Game Over screen for CURSOR: Fragments of the Forgotten

@onready var status_label: Label = $MainContainer/StatusLabel
@onready var level_label: Label = $MainContainer/ResultsContainer/LevelLabel
@onready var fragments_label: Label = $MainContainer/ResultsContainer/FragmentsLabel
@onready var time_label: Label = $MainContainer/ResultsContainer/TimeLabel
@onready var enemies_label: Label = $MainContainer/ResultsContainer/EnemiesLabel
@onready var message_label: RichTextLabel = $MainContainer/MessageLabel
@onready var restart_button: Button = $MainContainer/ButtonContainer/RestartButton
@onready var menu_button: Button = $MainContainer/ButtonContainer/MenuButton
@onready var background_effects: Node2D = $BackgroundEffects

@onready var ethical_panel: Panel = $EthicalChoicePanel
@onready var dilemma_label: RichTextLabel = $EthicalChoicePanel/EthicalContainer/DilemmaLabel
@onready var choice_a_button: Button = $EthicalChoicePanel/EthicalContainer/ChoiceContainer/ChoiceAButton
@onready var choice_b_button: Button = $EthicalChoicePanel/EthicalContainer/ChoiceContainer/ChoiceBButton

var game_stats: Dictionary = {}
var is_victory: bool = false
var has_ethical_choice: bool = false

func _ready() -> void:
	print("Game Over screen initialized")
	
	# Connect button signals
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	choice_a_button.pressed.connect(_on_choice_a_pressed)
	choice_b_button.pressed.connect(_on_choice_b_pressed)
	
	# Apply cyberpunk styling
	apply_styling()
	
	# Setup background effects
	setup_background_effects()
	
	# Load and display game stats
	load_game_stats()
	display_stats()
	
	# Show ethical choice if applicable
	if has_ethical_choice:
		await get_tree().create_timer(2.0).timeout
		show_ethical_choice()

func apply_styling() -> void:
	# Apply cyberpunk styling to all elements
	EffectsManager.apply_cyberpunk_button_style(restart_button)
	EffectsManager.apply_cyberpunk_button_style(menu_button)
	EffectsManager.apply_cyberpunk_button_style(choice_a_button)
	EffectsManager.apply_cyberpunk_button_style(choice_b_button)
	EffectsManager.apply_cyberpunk_panel_style(ethical_panel)
	
	# Style labels with appropriate colors
	status_label.add_theme_color_override("font_color", Color.CYAN if is_victory else Color.RED)
	status_label.add_theme_font_size_override("font_size", 28)
	
	var stat_labels = [level_label, fragments_label, time_label, enemies_label]
	for label in stat_labels:
		label.add_theme_color_override("font_color", Color.WHITE)
	
	# Style ethical panel labels
	$EthicalChoicePanel/EthicalContainer/EthicalTitle.add_theme_color_override("font_color", Color.YELLOW)

func setup_background_effects() -> void:
	# Create digital corruption effect
	create_corruption_particles()
	create_data_streams()
	
	# Add scan lines
	create_scan_lines()

func create_corruption_particles() -> void:
	# Create floating corruption particles
	var viewport_size = get_viewport().get_visible_rect().size
	
	for i in range(20):
		var particle = ColorRect.new()
		particle.size = Vector2(randf_range(1, 4), randf_range(1, 4))
		particle.color = Color.RED if not is_victory else Color.CYAN
		particle.color.a = randf_range(0.1, 0.4)
		
		particle.position = Vector2(
			randf() * viewport_size.x,
			randf() * viewport_size.y
		)
		
		background_effects.add_child(particle)
		
		# Animate particles
		var tween = particle.create_tween()
		tween.set_loops()
		tween.tween_property(particle, "position", 
			particle.position + Vector2(randf_range(-100, 100), randf_range(-100, 100)), 
			randf_range(3.0, 8.0))
		tween.tween_property(particle, "position", 
			particle.position, 
			randf_range(3.0, 8.0))

func create_data_streams() -> void:
	# Create data stream effects
	for i in range(5):
		EffectsManager.create_data_stream_effect(background_effects, 
			Vector2(randf_range(0, get_viewport().get_visible_rect().size.x), 0),
			Vector2(randf_range(-50, 50), 200), 
			4.0)

func create_scan_lines() -> void:
	# Create scanning effects
	var viewport_size = get_viewport().get_visible_rect().size
	
	for i in range(4):
		var line = ColorRect.new()
		line.size = Vector2(viewport_size.x, 1)
		line.color = Color.GREEN if is_victory else Color.RED
		line.color.a = 0.1
		line.position = Vector2(0, i * viewport_size.y / 4)
		
		background_effects.add_child(line)
		
		# Animate scan lines
		var tween = line.create_tween()
		tween.set_loops()
		tween.tween_property(line, "modulate:a", 0.3, 1.5)
		tween.tween_property(line, "modulate:a", 0.1, 1.5)

func load_game_stats() -> void:
	# Load game statistics from GameManager
	game_stats = GameManager.get_current_session_stats()
	
	# Determine if this is a victory or defeat
	is_victory = game_stats.get("victory", false)
	has_ethical_choice = game_stats.get("has_memories", false) and is_victory

func display_stats() -> void:
	# Update status based on game outcome
	if is_victory:
		status_label.text = "NEURAL DIVE SUCCESSFUL"
		message_label.text = """[center][color=cyan]Mind successfully cleansed.[/color]
[color=gray]The digital fragments have been recovered
and the corrupted data purged.[/color][/center]"""
	else:
		status_label.text = "NEURAL CONNECTION SEVERED"
		message_label.text = """[center][color=red]Connection to mind lost.[/color]
[color=gray]Cursor integrity compromised.
Recommend immediate extraction.[/color][/center]"""
	
	# Display game statistics
	level_label.text = "MIND LEVEL: " + str(game_stats.get("level", 1))
	fragments_label.text = "FRAGMENTS COLLECTED: %d/%d" % [
		game_stats.get("fragments_collected", 0),
		game_stats.get("total_fragments", 10)
	]
	
	var play_time = game_stats.get("play_time", 0.0)
	var minutes = int(play_time) / 60
	var seconds = int(play_time) % 60
	time_label.text = "TIME IN MIND: %02d:%02d" % [minutes, seconds]
	
	enemies_label.text = "CORRUPTIONS PURGED: " + str(game_stats.get("enemies_defeated", 0))

func show_ethical_choice() -> void:
	print("Showing ethical choice")
	
	# Get memory information for the dilemma
	var memory_info = MemorySystem.get_reconstructed_memory_summary()
	
	dilemma_label.text = """[center][color=yellow]Memory Reconstruction Complete[/color]

[color=white]You have successfully recovered the memories of:
""" + memory_info.get("owner_name", "Unknown Person") + """

Age at death: """ + str(memory_info.get("age", "Unknown")) + """
Profession: """ + memory_info.get("profession", "Unknown") + """

These memories contain both joyful and painful experiences.
What should be done with them?[/color][/center]"""
	
	# Show the ethical choice panel with animation
	ethical_panel.visible = true
	ethical_panel.modulate.a = 0.0
	ethical_panel.scale = Vector2(0.8, 0.8)
	
	var tween = create_tween()
	tween.parallel().tween_property(ethical_panel, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(ethical_panel, "scale", Vector2.ONE, 0.5)
	
	# Add dramatic effect
	EffectsManager.create_screen_flash(Color.YELLOW, 0.3)

func _on_restart_pressed() -> void:
	print("Restarting game...")
	
	# Reset game state
	GameManager.reset_current_session()
	
	# Create transition effect
	EffectsManager.create_screen_flash(Color.CYAN, 0.5)
	
	await get_tree().create_timer(0.3).timeout
	
	# Return to main game
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_menu_pressed() -> void:
	print("Returning to menu...")
	
	# Create transition effect
	EffectsManager.create_screen_flash(Color.BLUE, 0.5)
	
	await get_tree().create_timer(0.3).timeout
	
	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")

func _on_choice_a_pressed() -> void:
	print("Player chose to preserve memories")
	
	# Record ethical choice
	GameManager.record_ethical_choice("preserve")
	
	# Update message
	message_label.text = """[center][color=cyan]Memories Preserved[/color]
[color=gray]The memories have been archived and will be
shared with the world to help others learn
from this person's experiences.[/color][/center]"""
	
	# Hide ethical panel
	hide_ethical_choice()
	
	# Add positive effect
	EffectsManager.create_screen_flash(Color.GREEN, 0.3)

func _on_choice_b_pressed() -> void:
	print("Player chose to purge memories")
	
	# Record ethical choice
	GameManager.record_ethical_choice("purge")
	
	# Update message
	message_label.text = """[center][color=purple]Memories Purged[/color]
[color=gray]The memories have been permanently deleted,
granting eternal peace to the departed soul.
Their suffering ends here.[/color][/center]"""
	
	# Hide ethical panel
	hide_ethical_choice()
	
	# Add solemn effect
	EffectsManager.create_screen_flash(Color.PURPLE, 0.3)

func hide_ethical_choice() -> void:
	# Hide the ethical choice panel with animation
	var tween = create_tween()
	tween.parallel().tween_property(ethical_panel, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(ethical_panel, "scale", Vector2(0.8, 0.8), 0.3)
	tween.tween_callback(func(): ethical_panel.visible = false)

func _input(event: InputEvent) -> void:
	# Handle escape key to return to menu
	if event.is_action_pressed("ui_cancel") and not ethical_panel.visible:
		_on_menu_pressed()
	elif event.is_action_pressed("ui_accept") and not ethical_panel.visible:
		_on_restart_pressed()
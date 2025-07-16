extends Control

# Main menu for CURSOR: Fragments of the Forgotten

@onready var start_button: Button = $MainContainer/ButtonContainer/StartButton
@onready var settings_button: Button = $MainContainer/ButtonContainer/SettingsButton
@onready var exit_button: Button = $MainContainer/ButtonContainer/ExitButton
@onready var title_label: Label = $MainContainer/TitleLabel
@onready var info_label: RichTextLabel = $MainContainer/InfoLabel
@onready var background_effect: Node2D = $BackgroundEffect

@onready var settings_panel: Panel = $SettingsPanel
@onready var back_button: Button = $SettingsPanel/SettingsContainer/BackButton
@onready var master_volume_slider: HSlider = $SettingsPanel/SettingsContainer/VolumeContainer/MasterVolumeSlider
@onready var sfx_volume_slider: HSlider = $SettingsPanel/SettingsContainer/VolumeContainer/SFXVolumeSlider

var matrix_rain_timer: float = 0.0
var matrix_rain_interval: float = 2.0

func _ready() -> void:
	print("Menu initialized")
	
	# Connect button signals
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Connect volume sliders
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# Apply cyberpunk styling
	apply_cyberpunk_styling()
	
	# Setup background effects
	setup_background_effects()
	
	# Load saved settings
	load_settings()

func _process(delta: float) -> void:
	# Update background effects
	matrix_rain_timer += delta
	if matrix_rain_timer >= matrix_rain_interval:
		create_matrix_rain()
		matrix_rain_timer = 0.0

func apply_cyberpunk_styling() -> void:
	# Apply cyberpunk theme to all UI elements
	EffectsManager.apply_cyberpunk_button_style(start_button)
	EffectsManager.apply_cyberpunk_button_style(settings_button)
	EffectsManager.apply_cyberpunk_button_style(exit_button)
	EffectsManager.apply_cyberpunk_button_style(back_button)
	
	EffectsManager.apply_cyberpunk_panel_style(settings_panel)
	
	# Style title
	title_label.add_theme_color_override("font_color", Color.CYAN)
	title_label.add_theme_font_size_override("font_size", 32)
	
	# Style labels
	var volume_labels = [
		$SettingsPanel/SettingsContainer/VolumeContainer/MasterVolumeLabel,
		$SettingsPanel/SettingsContainer/VolumeContainer/SFXVolumeLabel,
		$SettingsPanel/SettingsContainer/SettingsTitle
	]
	
	for label in volume_labels:
		label.add_theme_color_override("font_color", Color.CYAN)
	
	# Style sliders
	apply_slider_styling(master_volume_slider)
	apply_slider_styling(sfx_volume_slider)

func apply_slider_styling(slider: HSlider) -> void:
	# Create cyberpunk slider style
	var style_grabber = StyleBoxFlat.new()
	style_grabber.bg_color = Color.CYAN
	style_grabber.corner_radius_top_left = 4
	style_grabber.corner_radius_top_right = 4
	style_grabber.corner_radius_bottom_left = 4
	style_grabber.corner_radius_bottom_right = 4
	
	var style_slider = StyleBoxFlat.new()
	style_slider.bg_color = Color(0.2, 0.2, 0.3, 0.8)
	style_slider.border_width_left = 1
	style_slider.border_width_right = 1
	style_slider.border_width_top = 1
	style_slider.border_width_bottom = 1
	style_slider.border_color = Color.CYAN
	
	slider.add_theme_stylebox_override("grabber", style_grabber)
	slider.add_theme_stylebox_override("slider", style_slider)

func setup_background_effects() -> void:
	# Create initial digital effects
	create_floating_particles()
	create_scan_lines()

func create_floating_particles() -> void:
	# Create floating digital particles in background
	for i in range(15):
		var particle = ColorRect.new()
		particle.size = Vector2(2, 2)
		particle.color = Color.CYAN
		particle.color.a = 0.3
		
		var x = randf() * get_viewport().get_visible_rect().size.x
		var y = randf() * get_viewport().get_visible_rect().size.y
		particle.position = Vector2(x, y)
		
		background_effect.add_child(particle)
		
		# Create floating animation
		var tween = particle.create_tween()
		tween.set_loops()
		var target_y = y + randf_range(-50, 50)
		tween.tween_property(particle, "position:y", target_y, randf_range(3.0, 6.0))
		tween.tween_property(particle, "position:y", y, randf_range(3.0, 6.0))

func create_scan_lines() -> void:
	# Create scanning line effect across screen
	var viewport_size = get_viewport().get_visible_rect().size
	
	for i in range(3):
		var line = ColorRect.new()
		line.size = Vector2(viewport_size.x, 1)
		line.color = Color.CYAN
		line.color.a = 0.1
		line.position = Vector2(0, i * viewport_size.y / 3)
		
		background_effect.add_child(line)
		
		# Animate scan lines
		var tween = line.create_tween()
		tween.set_loops()
		tween.tween_property(line, "modulate:a", 0.3, 2.0)
		tween.tween_property(line, "modulate:a", 0.1, 2.0)

func create_matrix_rain() -> void:
	# Create occasional matrix rain effect
	if randf() < 0.3:  # 30% chance
		EffectsManager.create_matrix_rain_effect(background_effect, 3.0)

func _on_start_pressed() -> void:
	print("Starting game...")
	
	# Create transition effect
	EffectsManager.create_screen_flash(Color.CYAN, 0.5)
	
	# Wait for flash then transition
	await get_tree().create_timer(0.3).timeout
	
	# Change to main game scene
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_settings_pressed() -> void:
	print("Opening settings...")
	
	# Show settings panel with animation
	settings_panel.visible = true
	settings_panel.modulate.a = 0.0
	settings_panel.scale = Vector2(0.8, 0.8)
	
	var tween = create_tween()
	tween.parallel().tween_property(settings_panel, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(settings_panel, "scale", Vector2.ONE, 0.3)
	
	# Add glitch effect
	EffectsManager.create_glitch_effect(settings_panel, 0.2)

func _on_exit_pressed() -> void:
	print("Exiting game...")
	
	# Create exit effect
	EffectsManager.create_screen_flash(Color.RED, 0.5)
	
	await get_tree().create_timer(0.3).timeout
	
	# Quit the game
	get_tree().quit()

func _on_back_pressed() -> void:
	print("Closing settings...")
	
	# Save settings before closing
	save_settings()
	
	# Hide settings panel with animation
	var tween = create_tween()
	tween.parallel().tween_property(settings_panel, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(settings_panel, "scale", Vector2(0.8, 0.8), 0.2)
	tween.tween_callback(func(): settings_panel.visible = false)

func _on_master_volume_changed(value: float) -> void:
	# Update master volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
	print("Master volume set to: ", value)

func _on_sfx_volume_changed(value: float) -> void:
	# Update SFX volume (if we had an SFX bus)
	print("SFX volume set to: ", value)

func load_settings() -> void:
	# Load settings from GameManager
	master_volume_slider.value = GameManager.master_volume
	sfx_volume_slider.value = GameManager.sfx_volume
	
	# Apply the loaded values
	_on_master_volume_changed(GameManager.master_volume)
	_on_sfx_volume_changed(GameManager.sfx_volume)

func save_settings() -> void:
	# Save settings to GameManager
	GameManager.master_volume = master_volume_slider.value
	GameManager.sfx_volume = sfx_volume_slider.value
	GameManager.save_game_data()
	
	print("Settings saved")

func _input(event: InputEvent) -> void:
	# Handle escape key in settings
	if event.is_action_pressed("ui_cancel") and settings_panel.visible:
		_on_back_pressed()
	elif event.is_action_pressed("ui_accept") and not settings_panel.visible:
		_on_start_pressed()
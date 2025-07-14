extends Node

# Game state management for CURSOR: Fragments of the Forgotten
signal game_started
signal game_paused
signal game_resumed
signal level_completed
signal memory_fragment_collected
signal cursor_tool_activated

# Game States
enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	HACKING,
	MEMORY_RECONSTRUCTION,
	GAME_OVER
}

# Player progression
var current_state: GameState = GameState.MENU
var current_level: int = 1
var memory_fragments_collected: int = 0
var total_fragments_in_level: int = 0
var cursor_energy: float = 100.0
var max_cursor_energy: float = 100.0

# Level/Dungeon data
var current_dungeon_seed: String = ""
var current_mind_profile: Dictionary = {}
var time_in_current_level: float = 0.0
var enemies_defeated: int = 0

# Player stats
var player_health: float = 100.0
var max_player_health: float = 100.0
var hack_tools_unlocked: Array[String] = ["time_rewind"]

# Settings
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 1.0
var vibration_enabled: bool = true

# Save data
var save_file_path: String = "user://cursor_save.dat"

func _ready() -> void:
	print("GameManager initialized")
	load_game_data()

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		time_in_current_level += delta
		
		# Cursor energy regeneration
		if cursor_energy < max_cursor_energy:
			cursor_energy = min(cursor_energy + delta * 10.0, max_cursor_energy)

func start_new_game() -> void:
	current_state = GameState.PLAYING
	current_level = 1
	memory_fragments_collected = 0
	cursor_energy = max_cursor_energy
	player_health = max_player_health
	time_in_current_level = 0.0
	enemies_defeated = 0
	
	# Generate first dungeon
	generate_new_dungeon()
	game_started.emit()

func generate_new_dungeon() -> void:
	# Create a random seed for this dungeon
	current_dungeon_seed = str(randi_range(100000, 999999))
	
	# Generate mind profile for emotional theming
	current_mind_profile = create_random_mind_profile()
	
	# Notify DungeonGenerator
	DungeonGenerator.generate_dungeon(current_dungeon_seed, current_mind_profile)

func create_random_mind_profile() -> Dictionary:
	var emotions = ["regret", "anger", "melancholy", "fear", "joy", "confusion", "trauma", "peace"]
	var primary_emotion = emotions[randi() % emotions.size()]
	
	var profile = {
		"primary_emotion": primary_emotion,
		"corruption_level": randf_range(0.3, 0.9),
		"memory_density": randi_range(15, 35),
		"hostile_fragments": randi_range(3, 8),
		"age_of_death": randi_range(25, 85),
		"profession": get_random_profession(),
		"dominant_color": get_emotion_color(primary_emotion)
	}
	
	return profile

func get_random_profession() -> String:
	var professions = ["artist", "scientist", "teacher", "engineer", "musician", "writer", "doctor", "architect"]
	return professions[randi() % professions.size()]

func get_emotion_color(emotion: String) -> Color:
	match emotion:
		"regret": return Color(0.4, 0.2, 0.6)  # Purple
		"anger": return Color(0.8, 0.2, 0.2)   # Red
		"melancholy": return Color(0.2, 0.4, 0.7)  # Blue
		"fear": return Color(0.1, 0.1, 0.1)    # Dark
		"joy": return Color(0.9, 0.8, 0.3)     # Yellow
		"confusion": return Color(0.5, 0.5, 0.5)  # Gray
		"trauma": return Color(0.6, 0.1, 0.1)  # Dark Red
		"peace": return Color(0.3, 0.7, 0.4)   # Green
		_: return Color.WHITE

func collect_memory_fragment() -> void:
	memory_fragments_collected += 1
	memory_fragment_collected.emit()
	
	# Check if level is complete
	if memory_fragments_collected >= total_fragments_in_level:
		complete_level()

func complete_level() -> void:
	current_level += 1
	save_game_data()
	level_completed.emit()

func use_cursor_energy(amount: float) -> bool:
	if cursor_energy >= amount:
		cursor_energy -= amount
		return true
	return false

func activate_cursor_tool(tool_name: String) -> bool:
	if tool_name in hack_tools_unlocked:
		match tool_name:
			"time_rewind":
				if use_cursor_energy(20.0):
					cursor_tool_activated.emit()
					return true
			"code_injection":
				if use_cursor_energy(30.0):
					cursor_tool_activated.emit()
					return true
			"data_leak":
				if use_cursor_energy(25.0):
					cursor_tool_activated.emit()
					return true
	return false

func pause_game() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		get_tree().paused = true
		game_paused.emit()

func resume_game() -> void:
	if current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		get_tree().paused = false
		game_resumed.emit()

func save_game_data() -> void:
	var save_data = {
		"current_level": current_level,
		"hack_tools_unlocked": hack_tools_unlocked,
		"settings": {
			"master_volume": master_volume,
			"sfx_volume": sfx_volume,
			"music_volume": music_volume,
			"vibration_enabled": vibration_enabled
		}
	}
	
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

func get_current_session_stats() -> Dictionary:
	# Return current session statistics for game over screen
	return {
		"level": current_level,
		"fragments_collected": memory_fragments_collected,
		"total_fragments": total_fragments_in_level,
		"play_time": time_in_current_level,
		"enemies_defeated": enemies_defeated,
		"victory": memory_fragments_collected >= total_fragments_in_level,
		"has_memories": memory_fragments_collected > 0
	}

func reset_current_session() -> void:
	# Reset session statistics for new game
	time_in_current_level = 0.0
	enemies_defeated = 0
	memory_fragments_collected = 0
	cursor_energy = max_cursor_energy
	player_health = max_player_health
	current_state = GameState.PLAYING

func record_ethical_choice(choice: String) -> void:
	# Record an ethical choice made by the player
	print("Ethical choice recorded: ", choice)
	# This could be saved for long-term progression

func trigger_game_over(victory: bool = false) -> void:
	# Trigger game over state
	current_state = GameState.GAME_OVER
	print("Game over triggered. Victory: ", victory)

func load_game_data() -> void:
	if FileAccess.file_exists(save_file_path):
		var file = FileAccess.open(save_file_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_text)
			
			if parse_result == OK:
				var save_data = json.data
				current_level = save_data.get("current_level", 1)
				hack_tools_unlocked = save_data.get("hack_tools_unlocked", ["time_rewind"])
				
				var settings = save_data.get("settings", {})
				master_volume = settings.get("master_volume", 1.0)
				sfx_volume = settings.get("sfx_volume", 1.0)
				music_volume = settings.get("music_volume", 1.0)
				vibration_enabled = settings.get("vibration_enabled", true)
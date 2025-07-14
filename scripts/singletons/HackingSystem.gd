extends Node

# Hacking and cursor tool system for CURSOR: Fragments of the Forgotten
signal hack_tool_used
signal time_rewind_activated
signal code_injection_complete
signal data_leak_triggered
signal hacking_mini_game_started
signal hacking_mini_game_completed

# Hack tool types
enum HackTool {
	TIME_REWIND,
	CODE_INJECTION,
	DATA_LEAK,
	MEMORY_SCAN,
	DIGITAL_BREACH,
	EMOTION_FILTER
}

# Hacking states
enum HackState {
	INACTIVE,
	PREPARING,
	EXECUTING,
	COOLDOWN
}

# Tool data structure
class CursorTool:
	var type: HackTool
	var name: String
	var description: String
	var energy_cost: float
	var cooldown_time: float
	var current_cooldown: float = 0.0
	var is_unlocked: bool = false
	var usage_count: int = 0
	var max_uses_per_level: int = -1  # -1 means unlimited
	
	func _init(tool_type: HackTool, tool_name: String, tool_desc: String, cost: float, cooldown: float):
		type = tool_type
		name = tool_name
		description = tool_desc
		energy_cost = cost
		cooldown_time = cooldown

# Current hacking state
var current_hack_state: HackState = HackState.INACTIVE
var active_tool: CursorTool = null
var hack_target: Node = null

# Time rewind system
var time_rewind_buffer: Array[Dictionary] = []
var max_rewind_buffer_size: int = 300  # 5 seconds at 60 FPS
var rewind_duration: float = 3.0

# Available tools
var cursor_tools: Dictionary = {}

# Hacking mini-game data
var current_mini_game: Dictionary = {}
var mini_game_difficulty: float = 0.5

func _ready() -> void:
	initialize_cursor_tools()

func _process(delta: float) -> void:
	# Update tool cooldowns
	for tool in cursor_tools.values():
		if tool.current_cooldown > 0:
			tool.current_cooldown -= delta
	
	# Update time rewind buffer if not in rewind
	if current_hack_state != HackState.EXECUTING or (active_tool and active_tool.type != HackTool.TIME_REWIND):
		update_time_rewind_buffer()

func initialize_cursor_tools() -> void:
	# Define all available cursor tools
	cursor_tools[HackTool.TIME_REWIND] = CursorTool.new(
		HackTool.TIME_REWIND,
		"CTRL-Z",
		"Zamanı geriye sar - Ölümden birkaç saniye öncesine dön",
		20.0,
		10.0
	)
	
	cursor_tools[HackTool.CODE_INJECTION] = CursorTool.new(
		HackTool.CODE_INJECTION,
		"Code Inject",
		"Düşman davranışlarını değiştir - Dostça, saldırgan veya sabit mod",
		30.0,
		15.0
	)
	
	cursor_tools[HackTool.DATA_LEAK] = CursorTool.new(
		HackTool.DATA_LEAK,
		"Data Leak",
		"Gizli yollar ve anıları açığa çıkar",
		25.0,
		8.0
	)
	
	cursor_tools[HackTool.MEMORY_SCAN] = CursorTool.new(
		HackTool.MEMORY_SCAN,
		"Memory Scan",
		"Yakındaki hafıza parçalarını tespit et",
		15.0,
		5.0
	)
	
	cursor_tools[HackTool.DIGITAL_BREACH] = CursorTool.new(
		HackTool.DIGITAL_BREACH,
		"Digital Breach",
		"Dijital duvarları geçici olarak kır",
		40.0,
		20.0
	)
	
	cursor_tools[HackTool.EMOTION_FILTER] = CursorTool.new(
		HackTool.EMOTION_FILTER,
		"Emotion Filter",
		"Belirli duygu türündeki tehditleri filtrele",
		35.0,
		12.0
	)
	
	# Unlock starting tool
	cursor_tools[HackTool.TIME_REWIND].is_unlocked = true

func use_cursor_tool(tool_type: HackTool, target: Node = null) -> bool:
	var tool = cursor_tools.get(tool_type)
	
	if not tool or not tool.is_unlocked:
		print("Tool not available: ", tool_type)
		return false
	
	if tool.current_cooldown > 0:
		print("Tool on cooldown: ", tool.current_cooldown)
		return false
	
	if tool.max_uses_per_level > 0 and tool.usage_count >= tool.max_uses_per_level:
		print("Tool usage limit reached")
		return false
	
	if not GameManager.use_cursor_energy(tool.energy_cost):
		print("Insufficient energy")
		return false
	
	# Execute the tool
	execute_tool(tool, target)
	return true

func execute_tool(tool: CursorTool, target: Node = null) -> void:
	current_hack_state = HackState.EXECUTING
	active_tool = tool
	hack_target = target
	
	tool.current_cooldown = tool.cooldown_time
	tool.usage_count += 1
	
	match tool.type:
		HackTool.TIME_REWIND:
			execute_time_rewind()
		HackTool.CODE_INJECTION:
			execute_code_injection(target)
		HackTool.DATA_LEAK:
			execute_data_leak()
		HackTool.MEMORY_SCAN:
			execute_memory_scan()
		HackTool.DIGITAL_BREACH:
			execute_digital_breach()
		HackTool.EMOTION_FILTER:
			execute_emotion_filter()
	
	hack_tool_used.emit()

func execute_time_rewind() -> void:
	print("Executing time rewind...")
	
	if time_rewind_buffer.size() == 0:
		complete_hack_execution()
		return
	
	# Get player reference
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		complete_hack_execution()
		return
	
	# Calculate how many frames to rewind (3 seconds)
	var rewind_frames = min(int(rewind_duration * 60), time_rewind_buffer.size())
	
	if rewind_frames > 0:
		var rewind_state = time_rewind_buffer[-(rewind_frames)]
		
		# Restore player state
		if player.has_method("restore_state"):
			player.restore_state(rewind_state)
		
		# Clear recent buffer entries
		for i in range(rewind_frames):
			time_rewind_buffer.pop_back()
		
		time_rewind_activated.emit()
	
	complete_hack_execution()

func execute_code_injection(target: Node) -> void:
	print("Executing code injection on: ", target)
	
	if not target or not target.has_method("apply_code_injection"):
		# Start mini-game if no specific target
		start_code_injection_mini_game()
		return
	
	# Apply injection directly to target
	var injection_type = get_random_injection_type()
	target.apply_code_injection(injection_type)
	
	code_injection_complete.emit()
	complete_hack_execution()

func execute_data_leak() -> void:
	print("Executing data leak...")
	
	# Reveal hidden elements in current room
	var hidden_objects = get_tree().get_nodes_in_group("hidden")
	for obj in hidden_objects:
		if obj.has_method("reveal"):
			obj.reveal()
	
	# Spawn additional memory fragments
	var fragment_spawner = get_tree().get_first_node_in_group("fragment_spawner")
	if fragment_spawner and fragment_spawner.has_method("spawn_leaked_fragments"):
		fragment_spawner.spawn_leaked_fragments(2)
	
	data_leak_triggered.emit()
	complete_hack_execution()

func execute_memory_scan() -> void:
	print("Executing memory scan...")
	
	# Highlight nearby memory fragments
	var fragments = get_tree().get_nodes_in_group("memory_fragments")
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		for fragment in fragments:
			var distance = player.global_position.distance_to(fragment.global_position)
			if distance < 200:  # Scan radius
				fragment.call("highlight", 3.0)  # Highlight for 3 seconds
	
	complete_hack_execution()

func execute_digital_breach() -> void:
	print("Executing digital breach...")
	
	# Temporarily remove wall collisions
	var walls = get_tree().get_nodes_in_group("walls")
	for wall in walls:
		if wall.has_method("make_permeable"):
			wall.make_permeable(5.0)  # 5 seconds
	
	complete_hack_execution()

func execute_emotion_filter() -> void:
	print("Executing emotion filter...")
	
	# Get current emotion from dungeon
	var current_emotion = DungeonGenerator.current_dungeon.mind_profile.primary_emotion if DungeonGenerator.current_dungeon else "neutral"
	
	# Temporarily disable enemies of current emotion type
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_method("get_emotion_type") and enemy.has_method("apply_filter"):
			if enemy.get_emotion_type() == current_emotion:
				enemy.apply_filter(8.0)  # 8 seconds
	
	complete_hack_execution()

func start_code_injection_mini_game() -> void:
	current_mini_game = {
		"type": "code_injection",
		"target_sequence": generate_code_sequence(),
		"player_input": "",
		"time_limit": 5.0,
		"current_time": 0.0,
		"difficulty": mini_game_difficulty
	}
	
	hacking_mini_game_started.emit()

func start_memory_puzzle_mini_game() -> void:
	current_mini_game = {
		"type": "memory_puzzle",
		"pattern": generate_memory_pattern(),
		"player_sequence": [],
		"time_limit": 8.0,
		"current_time": 0.0,
		"difficulty": mini_game_difficulty
	}
	
	hacking_mini_game_started.emit()

func generate_code_sequence() -> Array[String]:
	var code_elements = ["IF", "THEN", "ELSE", "FOR", "WHILE", "RETURN", "VAR", "FUNC"]
	var sequence: Array[String] = []
	
	var length = int(3 + mini_game_difficulty * 3)  # 3-6 elements
	for i in range(length):
		sequence.append(code_elements[randi() % code_elements.size()])
	
	return sequence

func generate_memory_pattern() -> Array[Color]:
	var colors = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.PURPLE, Color.ORANGE]
	var pattern: Array[Color] = []
	
	var length = int(3 + mini_game_difficulty * 4)  # 3-7 colors
	for i in range(length):
		pattern.append(colors[randi() % colors.size()])
	
	return pattern

func update_mini_game(input: String) -> void:
	if current_mini_game.is_empty():
		return
	
	match current_mini_game.type:
		"code_injection":
			current_mini_game.player_input += input
			check_code_injection_completion()
		"memory_puzzle":
			# Handle color input for memory puzzle
			pass

func check_code_injection_completion() -> bool:
	var target = current_mini_game.target_sequence
	var input = current_mini_game.player_input.split(" ")
	
	if input.size() >= target.size():
		var success = true
		for i in range(target.size()):
			if i >= input.size() or input[i] != target[i]:
				success = false
				break
		
		if success:
			complete_mini_game(true)
			return true
		else:
			complete_mini_game(false)
			return false
	
	return false

func complete_mini_game(success: bool) -> void:
	if success:
		match current_mini_game.type:
			"code_injection":
				# Apply successful code injection effects
				var enemies = get_tree().get_nodes_in_group("enemies")
				for enemy in enemies:
					if enemy.has_method("apply_code_injection"):
						enemy.apply_code_injection("friendly")
				code_injection_complete.emit()
	
	current_mini_game.clear()
	hacking_mini_game_completed.emit()
	complete_hack_execution()

func get_random_injection_type() -> String:
	var types = ["friendly", "aggressive", "static", "confused"]
	return types[randi() % types.size()]

func update_time_rewind_buffer() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Store current game state
	var state = {
		"position": player.global_position,
		"health": player.get("health", 100.0),
		"timestamp": Time.get_ticks_msec()
	}
	
	time_rewind_buffer.append(state)
	
	# Limit buffer size
	if time_rewind_buffer.size() > max_rewind_buffer_size:
		time_rewind_buffer.pop_front()

func complete_hack_execution() -> void:
	current_hack_state = HackState.INACTIVE
	active_tool = null
	hack_target = null

func unlock_tool(tool_type: HackTool) -> void:
	var tool = cursor_tools.get(tool_type)
	if tool:
		tool.is_unlocked = true
		print("Tool unlocked: ", tool.name)

func get_available_tools() -> Array[CursorTool]:
	var available: Array[CursorTool] = []
	for tool in cursor_tools.values():
		if tool.is_unlocked:
			available.append(tool)
	return available

func get_tool_cooldown(tool_type: HackTool) -> float:
	var tool = cursor_tools.get(tool_type)
	return tool.current_cooldown if tool else 0.0

func is_tool_ready(tool_type: HackTool) -> bool:
	var tool = cursor_tools.get(tool_type)
	return tool and tool.is_unlocked and tool.current_cooldown <= 0.0

func reset_tool_usage() -> void:
	# Reset usage counts for new level
	for tool in cursor_tools.values():
		tool.usage_count = 0

func increase_mini_game_difficulty() -> void:
	mini_game_difficulty = min(mini_game_difficulty + 0.1, 1.0)

func get_current_mini_game() -> Dictionary:
	return current_mini_game
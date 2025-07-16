extends Node

# Procedural dungeon generation for CURSOR: Fragments of the Forgotten
signal dungeon_generated
signal room_generated

# Dungeon structure
enum RoomType {
	ENTRANCE,
	MEMORY_CHAMBER,
	COMBAT_ARENA,
	PUZZLE_ROOM,
	EMOTION_CORE,
	BOSS_CHAMBER,
	SAFE_ROOM
}

enum TileType {
	EMPTY,
	WALL,
	FLOOR,
	DOOR,
	MEMORY_FRAGMENT,
	CORRUPTED_DATA,
	HACK_TERMINAL,
	ENEMY_SPAWN,
	PLAYER_SPAWN
}

# Dungeon data structures
class Room:
	var type: RoomType
	var position: Vector2i
	var size: Vector2i
	var tiles: Array[Array] = []
	var emotion_intensity: float
	var corruption_level: float
	var memory_fragments: Array[Vector2i] = []
	var enemy_spawns: Array[Vector2i] = []
	var connected_rooms: Array[Room] = []
	
	func _init(room_type: RoomType, pos: Vector2i, room_size: Vector2i):
		type = room_type
		position = pos
		size = room_size
		tiles = []
		for x in range(size.x):
			tiles.append([])
			for y in range(size.y):
				tiles[x].append(TileType.FLOOR)

class Dungeon:
	var seed_value: String
	var mind_profile: Dictionary
	var rooms: Array[Room] = []
	var corridors: Array[Vector2i] = []
	var total_size: Vector2i
	var entrance_position: Vector2i
	
# Current dungeon
var current_dungeon: Dungeon

# Generation parameters
var min_rooms: int = 8
var max_rooms: int = 15
var min_room_size: Vector2i = Vector2i(6, 6)
var max_room_size: Vector2i = Vector2i(12, 12)
var dungeon_size: Vector2i = Vector2i(64, 64)

func generate_dungeon(seed_string: String, mind_profile: Dictionary) -> void:
	print("Generating dungeon with seed: ", seed_string)
	
	# Validate input
	if seed_string.is_empty():
		seed_string = str(randi_range(100000, 999999))
		print("Empty seed provided, using random: ", seed_string)
	
	if mind_profile.is_empty():
		print("Empty mind profile provided, creating default")
		mind_profile = create_default_mind_profile()
	
	# Set random seed
	seed(hash(seed_string))
	
	# Create new dungeon
	current_dungeon = Dungeon.new()
	current_dungeon.seed_value = seed_string
	current_dungeon.mind_profile = mind_profile
	current_dungeon.total_size = dungeon_size
	
	# Generate rooms based on mind profile
	generate_rooms()
	
	# Connect rooms with corridors
	generate_corridors()
	
	# Place memory fragments and enemies based on emotional theming
	populate_dungeon()
	
	# Notify that generation is complete
	dungeon_generated.emit()

func create_default_mind_profile() -> Dictionary:
	# Create a safe default mind profile
	return {
		"primary_emotion": "neutral",
		"corruption_level": 0.5,
		"memory_density": 15,
		"hostile_fragments": 3,
		"age_of_death": 50,
		"profession": "unknown",
		"dominant_color": Color.GRAY
	}

func generate_rooms() -> void:
	var room_count = get_room_count_for_emotion(current_dungeon.mind_profile.primary_emotion)
	var rooms_generated = 0
	var max_attempts = 100
	var attempts = 0
	
	# Always start with entrance room
	var entrance_room = create_room(RoomType.ENTRANCE, Vector2i(5, 5))
	if entrance_room:
		current_dungeon.rooms.append(entrance_room)
		current_dungeon.entrance_position = entrance_room.position
		rooms_generated += 1
	
	# Generate other rooms
	while rooms_generated < room_count and attempts < max_attempts:
		attempts += 1
		
		# Determine room type based on progression
		var room_type = determine_room_type(rooms_generated, room_count)
		
		# Find valid position
		var room_pos = find_valid_room_position()
		if room_pos != Vector2i(-1, -1):
			var room = create_room(room_type, room_pos)
			if room and not rooms_overlap(room):
				current_dungeon.rooms.append(room)
				rooms_generated += 1
				room_generated.emit()

func get_room_count_for_emotion(emotion: String) -> int:
	match emotion:
		"regret", "trauma":
			return randi_range(10, 15)  # More complex layouts for heavy emotions
		"anger", "fear":
			return randi_range(8, 12)   # Medium complexity with focus on combat
		"melancholy", "confusion":
			return randi_range(12, 14)  # Many small interconnected rooms
		"joy", "peace":
			return randi_range(6, 9)    # Simpler, more open layouts
		_:
			return randi_range(8, 12)

func determine_room_type(current_count: int, total_count: int) -> RoomType:
	var progress = float(current_count) / float(total_count)
	
	# Always have an emotion core as the final room
	if current_count == total_count - 1:
		return RoomType.EMOTION_CORE
	
	# Distribution based on progress through dungeon
	if progress < 0.3:
		# Early rooms - mostly memory chambers and safe rooms
		return RoomType.MEMORY_CHAMBER if randf() < 0.7 else RoomType.SAFE_ROOM
	elif progress < 0.7:
		# Middle rooms - combat and puzzles
		var rand_val = randf()
		if rand_val < 0.4:
			return RoomType.COMBAT_ARENA
		elif rand_val < 0.7:
			return RoomType.PUZZLE_ROOM
		else:
			return RoomType.MEMORY_CHAMBER
	else:
		# Late rooms - more challenging content
		var rand_val = randf()
		if rand_val < 0.5:
			return RoomType.COMBAT_ARENA
		elif rand_val < 0.7:
			return RoomType.BOSS_CHAMBER
		else:
			return RoomType.PUZZLE_ROOM

func find_valid_room_position() -> Vector2i:
	for attempt in range(50):
		var x = randi_range(2, dungeon_size.x - max_room_size.x - 2)
		var y = randi_range(2, dungeon_size.y - max_room_size.y - 2)
		var pos = Vector2i(x, y)
		
		# Check if position is valid (no overlap with existing rooms)
		var valid = true
		for room in current_dungeon.rooms:
			if rooms_would_overlap(pos, room.position, room.size):
				valid = false
				break
		
		if valid:
			return pos
	
	return Vector2i(-1, -1)  # No valid position found

func create_room(room_type: RoomType, position: Vector2i) -> Room:
	var room_size = get_room_size_for_type(room_type)
	var room = Room.new(room_type, position, room_size)
	
	# Set room properties based on emotion and type
	configure_room_properties(room)
	
	# Generate room layout
	generate_room_layout(room)
	
	return room

func get_room_size_for_type(room_type: RoomType) -> Vector2i:
	match room_type:
		RoomType.ENTRANCE:
			return Vector2i(8, 8)
		RoomType.EMOTION_CORE:
			return Vector2i(12, 12)
		RoomType.BOSS_CHAMBER:
			return Vector2i(10, 10)
		RoomType.SAFE_ROOM:
			return Vector2i(6, 6)
		_:
			return Vector2i(
				randi_range(min_room_size.x, max_room_size.x),
				randi_range(min_room_size.y, max_room_size.y)
			)

func configure_room_properties(room: Room) -> void:
	var emotion = current_dungeon.mind_profile.primary_emotion
	var base_corruption = current_dungeon.mind_profile.corruption_level
	
	# Set emotion intensity based on room type and base profile
	match room.type:
		RoomType.EMOTION_CORE:
			room.emotion_intensity = 1.0
			room.corruption_level = base_corruption * 1.2
		RoomType.BOSS_CHAMBER:
			room.emotion_intensity = 0.8
			room.corruption_level = base_corruption * 1.1
		RoomType.COMBAT_ARENA:
			room.emotion_intensity = 0.6
			room.corruption_level = base_corruption
		RoomType.SAFE_ROOM:
			room.emotion_intensity = 0.2
			room.corruption_level = base_corruption * 0.5
		_:
			room.emotion_intensity = randf_range(0.3, 0.7)
			room.corruption_level = base_corruption * randf_range(0.8, 1.2)

func generate_room_layout(room: Room) -> void:
	# Fill with walls first
	for x in range(room.size.x):
		for y in range(room.size.y):
			if x == 0 or x == room.size.x - 1 or y == 0 or y == room.size.y - 1:
				room.tiles[x][y] = TileType.WALL
			else:
				room.tiles[x][y] = TileType.FLOOR
	
	# Add room-specific content
	match room.type:
		RoomType.ENTRANCE:
			# Player spawn point
			room.tiles[room.size.x / 2][room.size.y / 2] = TileType.PLAYER_SPAWN
		
		RoomType.MEMORY_CHAMBER:
			# Place memory fragments
			place_memory_fragments(room)
		
		RoomType.COMBAT_ARENA:
			# Place enemy spawns
			place_enemy_spawns(room)
		
		RoomType.PUZZLE_ROOM:
			# Place hack terminals
			place_hack_terminals(room)
		
		RoomType.EMOTION_CORE:
			# Central emotional core with surrounding fragments
			var center_x = room.size.x / 2
			var center_y = room.size.y / 2
			room.tiles[center_x][center_y] = TileType.MEMORY_FRAGMENT
			room.memory_fragments.append(Vector2i(center_x, center_y))

func place_memory_fragments(room: Room) -> void:
	var fragment_count = randi_range(1, 3)
	
	for i in range(fragment_count):
		var x = randi_range(2, room.size.x - 3)
		var y = randi_range(2, room.size.y - 3)
		
		if room.tiles[x][y] == TileType.FLOOR:
			room.tiles[x][y] = TileType.MEMORY_FRAGMENT
			room.memory_fragments.append(Vector2i(x, y))

func place_enemy_spawns(room: Room) -> void:
	var enemy_count = int(room.corruption_level * 5)
	
	for i in range(enemy_count):
		var x = randi_range(2, room.size.x - 3)
		var y = randi_range(2, room.size.y - 3)
		
		if room.tiles[x][y] == TileType.FLOOR:
			room.tiles[x][y] = TileType.ENEMY_SPAWN
			room.enemy_spawns.append(Vector2i(x, y))

func place_hack_terminals(room: Room) -> void:
	var terminal_count = randi_range(1, 2)
	
	for i in range(terminal_count):
		var x = randi_range(2, room.size.x - 3)
		var y = randi_range(2, room.size.y - 3)
		
		if room.tiles[x][y] == TileType.FLOOR:
			room.tiles[x][y] = TileType.HACK_TERMINAL

func generate_corridors() -> void:
	# Simple corridor generation - connect each room to at least one other
	for i in range(current_dungeon.rooms.size()):
		var room_a = current_dungeon.rooms[i]
		
		# Connect to next room (or first room if last)
		var room_b = current_dungeon.rooms[(i + 1) % current_dungeon.rooms.size()]
		
		connect_rooms(room_a, room_b)

func connect_rooms(room_a: Room, room_b: Room) -> void:
	# Simple L-shaped corridor
	var start_pos = room_a.position + Vector2i(room_a.size.x / 2, room_a.size.y / 2)
	var end_pos = room_b.position + Vector2i(room_b.size.x / 2, room_b.size.y / 2)
	
	# Create corridor path
	var current_pos = start_pos
	
	# Move horizontally first
	while current_pos.x != end_pos.x:
		current_pos.x += 1 if current_pos.x < end_pos.x else -1
		current_dungeon.corridors.append(current_pos)
	
	# Then move vertically
	while current_pos.y != end_pos.y:
		current_pos.y += 1 if current_pos.y < end_pos.y else -1
		current_dungeon.corridors.append(current_pos)
	
	# Connect rooms in graph
	room_a.connected_rooms.append(room_b)
	room_b.connected_rooms.append(room_a)

func populate_dungeon() -> void:
	# Set total fragment count for GameManager
	var total_fragments = 0
	for room in current_dungeon.rooms:
		total_fragments += room.memory_fragments.size()
	
	GameManager.total_fragments_in_level = total_fragments

func rooms_overlap(room: Room) -> bool:
	for existing_room in current_dungeon.rooms:
		if rooms_would_overlap(room.position, existing_room.position, existing_room.size):
			return true
	return false

func rooms_would_overlap(pos_a: Vector2i, pos_b: Vector2i, size_b: Vector2i) -> bool:
	var room_size = Vector2i(8, 8)  # Default size for checking
	
	return not (pos_a.x + room_size.x < pos_b.x or 
				pos_a.x > pos_b.x + size_b.x or
				pos_a.y + room_size.y < pos_b.y or
				pos_a.y > pos_b.y + size_b.y)

func get_current_dungeon() -> Dungeon:
	return current_dungeon

func get_tile_at_world_position(world_pos: Vector2) -> TileType:
	# Convert world position to dungeon coordinates
	var dungeon_pos = Vector2i(int(world_pos.x / 32), int(world_pos.y / 32))
	
	# Check if position is in a room
	for room in current_dungeon.rooms:
		if (dungeon_pos.x >= room.position.x and dungeon_pos.x < room.position.x + room.size.x and
			dungeon_pos.y >= room.position.y and dungeon_pos.y < room.position.y + room.size.y):
			var local_x = dungeon_pos.x - room.position.x
			var local_y = dungeon_pos.y - room.position.y
			return room.tiles[local_x][local_y]
	
	# Check if position is in a corridor
	if dungeon_pos in current_dungeon.corridors:
		return TileType.FLOOR
	
	return TileType.WALL
extends Node
class_name EnemyDecisionStateMachine

enum State {
	IDLE,
	SEARCH,
	CHASE,
	FLANK,
	ATTACK,
	REPOSITION
}

var state: State = State.IDLE
var desired_position: Vector3 = Vector3.ZERO
var state_time: float = 0.0
var flank_cooldown: float = 0.0
var flank_commit_timer: float = 0.0
var search_offset: Vector3 = Vector3.ZERO
var chase_bias: Vector3 = Vector3.ZERO
var chase_bias_timer: float = 0.0
var flank_side_sign: float = 1.0
var flank_distance: float = 6.0
var flank_miss_read: float = 0.0
var flank_anchor_valid: bool = false

func update(enemy: EnemyBase3D, senses: EnemySenses3D, player: PlayerControllerFPS, delta: float) -> void:
	state_time += delta
	flank_cooldown = max(0.0, flank_cooldown - delta)
	flank_commit_timer = max(0.0, flank_commit_timer - delta)
	chase_bias_timer = max(0.0, chase_bias_timer - delta)
	if not enemy or not player:
		return
	var distance: float = enemy.global_position.distance_to(player.global_position)
	if state == State.FLANK and flank_commit_timer > 0.0:
		pass
	elif senses.has_recent_triangulation() and distance < 18.0 and flank_cooldown <= 0.0:
		_change_state(State.FLANK)
		flank_commit_timer = randf_range(2.5, 4.5)
		flank_cooldown = randf_range(5.0, 8.0)
	elif senses.can_see_player:
		if distance <= enemy.attack_range:
			_change_state(State.ATTACK)
		elif distance < 13.0 and flank_cooldown <= 0.0 and randf() < 0.45:
			_change_state(State.FLANK)
			flank_commit_timer = randf_range(2.0, 3.6)
			flank_cooldown = randf_range(4.0, 7.0)
		else:
			_change_state(State.CHASE)
	elif senses.knows_any_position():
		_change_state(State.SEARCH)
	else:
		_change_state(State.IDLE)
	match state:
		State.IDLE:
			desired_position = enemy.global_position
		State.SEARCH:
			if state_time < 0.1:
				search_offset = Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))
			desired_position = senses.get_best_known_position(player) + search_offset
		State.CHASE:
			desired_position = _predicted_player_position(enemy, player)
		State.FLANK:
			desired_position = _flank_position(enemy, player)
		State.ATTACK:
			desired_position = enemy.global_position
		State.REPOSITION:
			desired_position = enemy.global_position

func _predicted_player_position(enemy: EnemyBase3D, player: PlayerControllerFPS) -> Vector3:
	var distance: float = enemy.global_position.distance_to(player.global_position)
	var lead_time: float = clamp(distance / 12.0, 0.1, 1.1)
	if chase_bias_timer <= 0.0:
		chase_bias = Vector3(randf_range(-0.45, 0.45), 0.0, randf_range(-0.45, 0.45))
		if randf() < 0.12:
			chase_bias *= randf_range(1.2, 2.2)
		chase_bias_timer = randf_range(0.45, 0.85)
	return player.global_position + player.velocity * lead_time + chase_bias

func _flank_position(enemy: EnemyBase3D, player: PlayerControllerFPS) -> Vector3:
	var to_enemy: Vector3 = enemy.global_position - player.global_position
	to_enemy.y = 0.0
	if to_enemy.length() < 0.1:
		to_enemy = Vector3.FORWARD
	to_enemy = to_enemy.normalized()
	if state_time < 0.12 or not flank_anchor_valid:
		flank_side_sign = -1.0 if randf() < 0.5 else 1.0
		flank_distance = randf_range(5.0, 8.0)
		flank_miss_read = randf_range(-1.5, 1.5)
		flank_anchor_valid = true
	var side: Vector3 = Vector3(-to_enemy.z, 0.0, to_enemy.x) * flank_side_sign
	return player.global_position + side * flank_distance + to_enemy * flank_miss_read

func _change_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state
	state_time = 0.0
	if new_state == State.CHASE:
		chase_bias_timer = 0.0
	if new_state == State.FLANK:
		flank_anchor_valid = false

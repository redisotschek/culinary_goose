extends CharacterBody2D

var speed = 50  # speed in pixels/sec
var damage = 50
var hp = 200
var last_movement_direction = "down"
var is_attacking = false
var can_attack = true
var mov_y = 0
var mov_x = 0
var curr_attack_col_shape
var is_dead = false
var leader: CharacterBody2D
var is_leader: bool = false
var last_leader_position: Vector2
var pack_position: Vector2
var pack_radius: float = 50.0
var is_following = false
var character_state = IDLE

var READY = "ready_"
var IDLE = "idle_"
var MOVING = "moving_"
var HIT = "hit_"
var DEATH = "death_"

@onready var SPRITE = $AnimatedSprite2D
@onready var NAVIGATOR = $NavigationAgent2D
@onready var FOLLOW_TIMER = $FollowTimer
@onready var ATTACK_TIMER = $AttackTimer
@onready var LEFT_ATTACK_AREA = $AttackArea_left/CollisionShape2D
@onready var RIGHT_ATTACK_AREA = $AttackArea_right/CollisionShape2D
@onready var UP_ATTACK_AREA = $AttackArea_up/CollisionShape2D
@onready var DOWN_ATTACK_AREA = $AttackArea_down/CollisionShape2D
@onready var ATTACK_SHAPES = []
var attack_mode = HIT

func _ready():
	ATTACK_SHAPES = [LEFT_ATTACK_AREA, RIGHT_ATTACK_AREA, UP_ATTACK_AREA, DOWN_ATTACK_AREA]
	if not is_leader:
		deactivate()

func _physics_process(delta):
	if is_dead: return
	if is_leader:
		movement_controls()
	elif is_following:
		follow()

func set_leader(survivor):
	leader = survivor
	compute_pack_position()
	
func compute_pack_position():
	pack_position = Vector2(randf_range(-pack_radius, pack_radius), randf_range(-pack_radius, pack_radius))
	
func compute_pack_position_with_error():
	var position_error = Vector2.ZERO
	position_error.x = pack_position.x + randf_range(0, 20)
	position_error.y = pack_position.y + randf_range(0, 20)
	
	return pack_position + position_error
	
func follow():
	if not is_following: return
	NAVIGATOR.set_target_position(leader.global_position + compute_pack_position_with_error())
	NAVIGATOR.set_max_speed(2)
	NAVIGATOR.set_target_desired_distance(30)
	NAVIGATOR.set_path_max_distance(50)
	var current_agent_position = global_position
	var next_path_position = NAVIGATOR.get_target_position()
	var direction = current_agent_position.direction_to(next_path_position).normalized()
	sprite_controls(direction)
	move(direction)
	
func restart_follower():
	if not leader: return
	FOLLOW_TIMER.stop()
	is_following = false
	last_leader_position = leader.global_position
	sprite_controls(Vector2.ZERO)
	FOLLOW_TIMER.start()
	
func activate_attack_shapes():
	for shape in ATTACK_SHAPES:
		shape.disabled = false

func deactivate_attack_shapes():
	for shape in ATTACK_SHAPES:
		shape.disabled = true

func get_direction(vector):
	if (vector.x == 0 and vector.y == 0):
		return last_movement_direction
		
	if (vector.x > 0):
		return 'right'
	elif (vector.x < 0): return 'left'
	
	if (vector.y < 0):
		return 'up'
	elif (vector.y > 0): return 'down'
	
func movement_controls():
	controls_loop()
	var direction = Vector2(mov_x, mov_y).normalized()
	sprite_controls(direction)
	move(direction)
	if (Input.is_action_just_pressed("Attack")):
		if (!is_leader): return
		attack()

func attack():
	if not can_attack: return
	is_attacking = true
	match last_movement_direction:
		"left":
			curr_attack_col_shape = LEFT_ATTACK_AREA
		"right":
			curr_attack_col_shape = RIGHT_ATTACK_AREA
		"down":
			curr_attack_col_shape = DOWN_ATTACK_AREA
		"up":
			curr_attack_col_shape = UP_ATTACK_AREA
	
	if is_leader:
		curr_attack_col_shape.disabled = false
	SPRITE.play(attack_mode + last_movement_direction)
	can_attack = false
	ATTACK_TIMER.start()

func move(direction):
	if is_attacking: return
	velocity = direction * speed
	move_and_slide()

func sprite_controls(direction):
	if (direction.x == 0 and direction.y == 0):
		if not is_leader and not is_following:
			character_state = READY
		else: character_state = IDLE
	else: character_state = MOVING
	last_movement_direction = get_direction(direction)
	if (!is_attacking && !is_dead): SPRITE.play(character_state + last_movement_direction)

func controls_loop():
	if (Input.is_action_pressed("Left")):
		mov_x = -1
	elif (Input.is_action_pressed("Right")):
		mov_x = 1
	else: mov_x = 0
	
	if (Input.is_action_pressed("Up")):
		mov_y = -1
	elif (Input.is_action_pressed("Down")):
		mov_y = 1
	else: mov_y = 0

	
func activate():
	is_leader = true
	$Camera2D.enabled = true
	$PointLight2D.enabled = true
	deactivate_attack_shapes()
	FOLLOW_TIMER.stop()
	
func deactivate():
	is_leader = false
	sprite_controls(Vector2.ZERO)
	activate_attack_shapes()
	$Camera2D.enabled = false
	$PointLight2D.enabled = false
	activate_attack_shapes()
	FOLLOW_TIMER.start()

func take_damage(damage):
	if (is_dead): return
	hp -= damage
	if (hp <= 0):
		die()

func die():
	is_dead = true
	SPRITE.play(DEATH+last_movement_direction)
	deactivate_attack_shapes()

func _on_animated_sprite_2d_animation_finished():
	if DEATH in SPRITE.animation:
		print(self.name + " died")
	if (attack_mode in SPRITE.animation):
		is_attacking = false
		if is_leader:
			curr_attack_col_shape.disabled = true


func _on_attack_area_body_entered(body):
	if is_dead: return
	if body.is_in_group("enemy"):
		if is_leader and is_attacking:
			body.take_damage(damage)
		elif not is_leader:
			attack()
			body.take_damage(damage)

func _on_follow_timer_timeout():
	if not leader: return
	if leader and leader.global_position != last_leader_position:
		is_following = true


func _on_navigation_agent_2d_target_reached():
	restart_follower()


func _on_attack_timer_timeout():
	can_attack = true

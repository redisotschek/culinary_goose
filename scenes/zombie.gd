extends CharacterBody2D

var last_movement_direction = "down"
var hp = 50
var speed = 20
var damage = 100
var pref = "idle_"
var target
#var target_position
var dying = false
var is_attacking = false
var is_roaming = false
var roaming_speed = 5
var current_agent_position
var next_path_position
var PADDINGS_SUM = 20
var random_position_to_roam = Vector2.ZERO

@onready var SPRITE = $AnimatedSprite2D
@onready var NAVIGATOR = $NavigationAgent2D
@onready var DETECTION_AREA = $DetectionArea/CollisionShape2D
@onready var ROAMING_TIMER = $RoamingTimer

# Called when the node enters the scene tree for the first time.
func _ready():
	reset()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (global_rotation != 0):
		global_rotation = 0
#	print(target, is_roaming, ROAMING_TIMER.is_stopped())
	if not target and not ROAMING_TIMER.is_stopped():
		free_roam()
	elif target:
		is_roaming = false
		ROAMING_TIMER.stop()
		navigate()
	
func navigate():
	if not NAVIGATOR or not target or dying : return
	
	pref = "idle_"
	if target and not (int(NAVIGATOR.distance_to_target()) < PADDINGS_SUM):
		NAVIGATOR.set_target_position(target.global_position)
		current_agent_position = global_position
		next_path_position = NAVIGATOR.get_target_position()
		var direction = current_agent_position.direction_to(next_path_position).normalized()
		last_movement_direction = get_direction(direction)
		velocity = direction * speed
		move_and_slide()
		pref = "moving_"
		
	if (!is_attacking): SPRITE.play(pref+last_movement_direction)
	else: SPRITE.play("hit_"+last_movement_direction)
#
func reset():
	is_attacking = false
	is_roaming = false
	target = null
	var radius = 40
	random_position_to_roam = Vector2(randf_range(-radius, radius), randf_range(-radius, radius)).normalized()
	SPRITE.play("idle_"+last_movement_direction)
	ROAMING_TIMER.start()
#
func free_roam():
	is_roaming = true
	last_movement_direction = get_direction(random_position_to_roam)
	SPRITE.play("moving_"+last_movement_direction, .5)
	velocity = random_position_to_roam * roaming_speed
	move_and_slide()

func get_direction(vector):
	var hor
	var ver
	if (vector.x == 0 and vector.y == 0):
		return last_movement_direction
	if (vector.y < 0):
		ver = 'up'
	elif (vector.y > 0): ver = 'down'
	
	if (vector.x > 0):
		hor = 'right'
	elif (vector.x < 0): hor = 'left'
	
	if (abs(vector.x) > abs(vector.y)):
		return hor
	else: return ver


func take_damage(damage):
	if dying: return
	hp -= damage
	if (hp <= 0):
		dying = true
		SPRITE.stop()
		SPRITE.play("death_"+last_movement_direction)


func _on_animated_sprite_2d_animation_finished():
	if ("hit_" in SPRITE.animation && target):
		target.take_damage(damage)
		if target and target.is_in_group("survivors") and target.is_dead:
			reset()
	if ("death_" in SPRITE.animation):
		queue_free()


func _on_detection_area_body_entered(body):
	if (body.is_in_group("survivors")):
		if not target:
			target = body

func _on_attack_area_body_entered(body):
	if (body.is_in_group("survivors")):
		is_attacking = true


func _on_detection_area_body_exited(body):
	if (body.is_in_group("survivors")):
		is_attacking = false


func _on_roaming_timer_timeout():
	if is_roaming and not target:
		reset()


func _on_attack_area_area_entered(area):
	if area.is_in_group("borders") and not target:
		print("boop")
		reset()

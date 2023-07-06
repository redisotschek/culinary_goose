extends Node2D

@onready var survivors = get_tree().get_nodes_in_group("survivors")
var curr_hero_index = 0
var curr_hero = null
var is_game_over = false

# Called when the node enters the scene tree for the first time.
func _ready():
	curr_hero = survivors[curr_hero_index]
	curr_hero.activate()
	if survivors.size() > 1:
		set_leader()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_game_over: return
	if (Input.is_action_just_pressed("SwitchHero")):
		switch_hero()
	if curr_hero and curr_hero.is_dead:
		get_survivors()
		switch_hero()
		
func get_survivors():
	survivors = get_tree().get_nodes_in_group("survivors").filter(filter_survivors)
	
func filter_survivors(s):
	return !s.is_dead
		
func set_leader():
	for s in survivors:
		if s.name != curr_hero.name:
			s.set_leader(curr_hero)
	
func switch_hero():
	if survivors.size() == 0:
		print("GAME OVER")
		is_game_over = true
		return
	if survivors.size() == 1:
		curr_hero_index = 0
	else: 
		if (curr_hero_index + 1 >= survivors.size()):
			curr_hero_index = 0
	curr_hero.deactivate()
	var new_hero = survivors[curr_hero_index]
	if new_hero.is_dead: return
	curr_hero = new_hero
	curr_hero.activate()
	set_leader()

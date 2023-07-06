extends Node2D

@export var mob_scene: PackedScene
@export var is_active: bool
@export var sprite: CompressedTexture2D

@onready var sprite_node = $Sprite
var max_passengers = 4
var is_empty = false

# Called when the node enters the scene tree for the first time.
func _ready():
	sprite_node.texture = sprite


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	if (!is_active): return
	if (body.is_in_group("survivors") and !is_empty):
		spawn_zombies()

func spawn_zombies():
	var pass_num = randi_range(1, max_passengers)
	print(pass_num)
	for i in range(pass_num):
		var _child = mob_scene.instantiate()
		$SpawnArea.add_child(_child)
	is_empty = true

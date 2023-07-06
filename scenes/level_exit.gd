extends Area2D

@export var next_scene: Resource

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_level_exit_body_entered(body):
	if (body.is_in_group("survivors")):
		get_tree().change_scene_to_file(next_scene.resource_path)

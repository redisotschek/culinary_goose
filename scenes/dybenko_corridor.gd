extends Node2D

@onready var inv_light = $Apartment/InverseLight
# Called when the node enters the scene tree for the first time.
func _ready():
	inv_light.enabled = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_apartment_body_entered(body):
	if (body.is_in_group("survivors")):
		inv_light.enabled = false

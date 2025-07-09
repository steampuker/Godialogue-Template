extends Node

@export var sophia: CharacterController
@export var fall_gravity: float:
	set(val): 
		if(!sophia): return
		sophia.fall_gravity = val
	get(): 
		return sophia.fall_gravity if sophia else 0.0

func changeScene(scene_path: String):
	get_tree().change_scene_to_file(scene_path)

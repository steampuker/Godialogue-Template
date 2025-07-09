extends Area2D

@export var enter_animation: String
@export var press_animation: String
@export var animator: AnimationPlayer
@export var sophia: CharacterController

var complete: bool = false

func _ready():
	body_entered.connect(entered)

func _process(_d):
	if(!sophia): return
	if(press_animation != "" and Input.is_action_just_pressed("interact") and overlaps_body(sophia)):
		animator.play(press_animation)

func entered(who):
	if who is not CharacterController or complete or enter_animation == "": return
	complete = true
	if(animator.is_playing()): await animator.animation_finished
	animator.play(enter_animation)

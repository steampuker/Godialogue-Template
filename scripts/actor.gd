class_name Actor
extends AnimatedSprite2D

@export var message: DialogueMessage
@export_group("Interaction")
@export var repeat_yapping: int = 4
@export var talk_spot: float = 0.0
@export var shape: Shape2D:
	set(value):
		if(Engine.is_editor_hint() && shape_object != null):
			shape_object.shape = value
		shape = value
	get():
		return shape
@export var shape_offset: Vector2:
	set(value):
		if(Engine.is_editor_hint() && shape_object != null):
			shape_object.position = value
		shape_offset = value
	get():
		return shape_offset

@onready var area: Area2D = $Area
@onready var shape_object: CollisionShape2D = $Area/Shape
@onready var icon: Label = $Icon
@export var icon_position: Vector2

var icon_tween: Tween
var my_speech: bool = false

func _ready():
	if(Engine.is_editor_hint()): return
	icon.position = icon_position
	icon.visible = false
	shape_object.shape = shape
	shape_object.position = shape_offset
	area.body_entered.connect(onEnter)
	area.body_exited.connect(onExit)
	
	$"../../Interface/DialogueManager".message_started.connect(
	func(msg): my_speech = msg == message)
	
	$"../../Interface/DialogueManager".line_started.connect(
		func(): if(my_speech): messageInteracted()
	)
	
	$"../../Interface/DialogueManager".message_ended.connect(
	func(msg): if(my_speech): 
		icon.visible = true
		my_speech = false
		)

func showIcon():
	icon.visible = true
	icon_tween = create_tween()
	icon_tween.set_loops()
	icon_tween.tween_property(icon, "position:y", icon_position.y + 1.0, 1.0).from(icon_position.y - 1.0)
	icon_tween.tween_property(icon, "position:y", icon_position.y - 1.0, 1.0).from(icon_position.y + 1.0)

func onEnter(body):
	if(body is CharacterController):
		showIcon()
		body.setActor(self, "message")

func onExit(body):
	if(body is CharacterController):
		icon_tween.kill()
		icon.visible = false
		body.removeActor(self)

func getTalkSpot():
	return position.x + talk_spot

func messageInteracted():
	icon.visible = false
	play("yapping")
	
	for i in range(repeat_yapping):
		await animation_looped
	play("default")

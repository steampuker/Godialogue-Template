@tool
class_name Actor
extends Area2D

@export var message: DialogueMessage
@export var message_manager: DialogueManagerBase
@export_group("Interaction")
@export var repeat_yapping: int = 4
@export var talk_spot: float = 0.0

@export_group("Appearance")
@export var icon_symbol: String:
	set(value):
		if(icon): icon.text = value
		icon_symbol = value
@export var icon_position: Vector2 = Vector2(0, -50):
	set(value):
		if(icon): icon.position = value
		icon_position = value
@export var sprite_frames: SpriteFrames:
	set(value):
		if(sprite): sprite.sprite_frames = value
		sprite_frames = value
@export var flip: bool:
	set(value): 
		if(sprite): sprite.flip_h = value
		flip = value

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var icon: Label = $Icon
var icon_tween: Tween
var my_speech: bool = false

func _ready():
	sprite.flip_h = flip
	sprite.sprite_frames = sprite_frames
	icon.text = icon_symbol
	icon.position = icon_position
	
	if(Engine.is_editor_hint()): return
	icon.visible = false
	body_entered.connect(onEnter)
	body_exited.connect(onExit)
	
	message_manager.message_started.connect(
	func(msg): my_speech = msg == message)
	
	message_manager.line_started.connect(
		func(): if(my_speech): messageInteracted()
	)
	
	message_manager.message_ended.connect(
	func(_msg): if(my_speech): 
		icon.visible = true
		my_speech = false
		)

func showIcon():
	icon.visible = true
	icon_tween = create_tween()
	icon_tween.set_loops()
	icon_tween.tween_property(icon, "position:y", icon_position.y + 1.0, 1.0).from(icon_position.y - 1.0)
	icon_tween.tween_property(icon, "position:y", icon_position.y- 1.0, 1.0).from(icon_position.y + 1.0)

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
	sprite.play("yapping")
	
	for i in range(repeat_yapping):
		await sprite.animation_looped
	sprite.play("default")

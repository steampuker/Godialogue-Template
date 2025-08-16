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
var player: CharacterController

func _ready():
	sprite.flip_h = flip
	sprite.sprite_frames = sprite_frames
	icon.text = icon_symbol
	icon.position = icon_position
	
	if(Engine.is_editor_hint()): return
	
	initIcon()
	body_entered.connect(onEnter)
	body_exited.connect(onExit)
	
	message_manager.interacted.connect(interact)
	message_manager.message_started.connect(func(msg): my_speech = msg == message)
	message_manager.line_started.connect(func(): if(my_speech): lineChanged())
	message_manager.message_ended.connect(
		func(_msg): if(my_speech): 
			if has_overlapping_bodies(): icon.visible = true
			sprite.play("default")
			my_speech = false
	)

func initIcon():
	icon.visible = false
	icon_tween = create_tween()
	icon_tween.set_loops()
	icon_tween.tween_property(icon, "position:y", icon_position.y + 1.0, 1.0).from(icon_position.y - 1.0)
	icon_tween.tween_property(icon, "position:y", icon_position.y- 1.0, 1.0).from(icon_position.y + 1.0)

func onEnter(body):
	if body is CharacterController:
		player = body
		icon.visible = true

func onExit(body):
	if body is CharacterController:
		player = null
		icon.visible = false

func interact():
	if !player: return
	icon.visible = false
	await player.interactionReceived((position.x - player.position.x) < 0.0)
	message_manager.current_actor = self
	
	# Alternatively: message = await message_manager.processMessage(message)
	message_manager.processProperty(self, "message")

func getTalkSpot():
	return position.x + talk_spot

func lineChanged():
	if(sprite.animation == "yapping"): await sprite.animation_changed
	sprite.play("yapping")
	
	for i in range(repeat_yapping):
		await sprite.animation_looped
	sprite.play("default")

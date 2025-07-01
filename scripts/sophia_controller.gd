class_name CharacterController
extends CharacterBody2D

@export var xspeed: float = 1.0
@onready var animator: SophiaAnimator = $Sprite

@export var jump_height: float
@export var rise_time: float
@export var fall_time: float
@export var coyote_time: float
@export var jump_buffer_time: float

@onready var jump_velocity: float = -(2.0 * jump_height) / rise_time
@onready var jump_gravity: float = -(-2.0 * jump_height) / (rise_time * rise_time)
@onready var fall_gravity: float = -(-2.0 * jump_height) / (fall_time * fall_time)
var jump_timer: float = 0.0

var input_velocity: Vector2
var coyote_timer: float = 0.0

# Message interaction
var actor_object: Actor
var actor_property: StringName

var disable_movement: bool = false

var DialogueManager: DialogueManagerBase

func _ready():
	DialogueManager = $"../Interface/DialogueManager"
	DialogueManager.message_started.connect(func(_discard): animator.flip_v = true; disable_movement = true)
	DialogueManager.message_ended.connect(func(_discard): animator.flip_v = false; disable_movement = false)

func _process(_delta):
	processAnimation()
	processInteraction()
	
func processAnimation():
	if(velocity.x != 0):
		$Collider.position.x = 4.0 if velocity.x > 0 else -4.0
		animator.flip_h = velocity.x < 0
	
	if(is_on_floor()):
		if(velocity.x != 0): animator.walk()
		else: animator.blink()
	elif(!is_on_floor()):
		if velocity.y < 0: animator.jump()
		else: animator.fall()

func _physics_process(delta):
	if(!disable_movement):
		velocity.x = Input.get_axis("left", "right") * xspeed * 3.0
	handleJump(delta)
	move_and_slide()

func handleJump(delta):
	var gravity: float = jump_gravity if (velocity.y < 0.0) else fall_gravity
	velocity.y += gravity * delta
	coyote_timer = maxf(coyote_timer - 8.0 * delta, 0.0)
	jump_timer = maxf(jump_timer - 8.0 * delta, 0.0)
	
	if(is_on_floor()):
		coyote_timer = coyote_time
	
	if(!disable_movement && Input.is_action_just_pressed("jump")):
		jump_timer = jump_buffer_time
	
	if(coyote_timer > 0.0 && jump_timer > 0.0):
		jump_timer = 0
		velocity.y = jump_velocity
	
	if(is_on_ceiling() || (velocity.y > jump_velocity * 0.9 && !Input.is_action_pressed( "jump"))):
		velocity.y = maxf(0, velocity.y)

func processInteraction():
	if(!disable_movement && Input.is_action_just_released("interact") && actor_object != null):
		velocity.x = 0.0
		animator.flip_h = (actor_object.position.x - position.x) < 0.0
		DialogueManager.processProperty(actor_object, actor_property);

func setActor(actor: Actor, property: StringName):
	actor_object = actor
	actor_property = property

func removeActor(actor: Actor):
	if(actor == actor_object):
		actor_object = null

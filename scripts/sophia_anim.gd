class_name SophiaAnimator
extends AnimatedSprite2D

const jump_stretch: Vector2 = Vector2(0.8, 1.25)
const land_squash: Vector2 = Vector2(1.15, 0.85)

@export var fps: float = 5.0
@export var speed: float = 1.0

var tween: Tween
var scale_tween: Tween
var timer = 0.0
var status = false;

func _ready():
	animation = "default"
	blink()
	
func blink():
	if(animation == "idle" || animation == "wave"):
		return
	
	if(tween): tween.kill()
	handle_land()
	stop()
	animation = "idle"
	
	tween = create_tween()
	tween.set_loops()
	tween.tween_interval(randf_range(4.0, 8.0))
	tween.tween_property(self, "frame", 1, 1.0 / fps).from(0);
	tween.tween_property(self, "frame", 0, 1.0 / fps).from(1);

func walk():
	if(animation == "walk"):
		return
	
	handle_land()
	if(tween): tween.kill()
	
	play("walk")

func handle_land():
	if(animation != "fall"): return
	
	scale_tween = create_tween()
	scale_tween.tween_property(self, "scale", land_squash, 0.5 / fps).from(Vector2.ONE);
	scale_tween.tween_property(self, "scale", Vector2.ONE,  0.5 / fps);

func jump():
	if(animation == "jump"):
		return
	animation = "jump"
	if(scale_tween): 
		scale = Vector2.ONE
		scale_tween.kill()
	
	scale_tween = create_tween()
	scale_tween.tween_property(self, "scale", jump_stretch, 1.0 / fps).from(Vector2.ONE);
	scale_tween.tween_property(self, "scale", Vector2.ONE,  1.0 / fps);
	
func fall():
	if(animation == "fall"):
		return
	
	animation = "fall"
	if(scale_tween): 
		scale = Vector2.ONE
		scale_tween.kill()

func wave():
	animation = "wave"
	
	if(tween): tween.kill()
	for i in range(3):
		play("wave")
		await animation_finished
	animation = "default"
	blink()

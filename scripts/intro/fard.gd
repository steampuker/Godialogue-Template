extends Sprite2D

@export var interact: Node

var effect: Sprite2D
var tween: Tween

func _ready():
	interact.pressed.connect(fard)
	effect = Sprite2D.new()
	effect.texture = self.texture
	add_child(effect)
	effect.modulate.a = 0

func fard():
	if tween: return
	
	tween = create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.5).from(1.0)
	tween.tween_property(effect, "scale", Vector2.ONE * 3.0, 0.5).from(Vector2.ONE)

extends DialogueManagerBase

class DialogueLabel extends Node2D:
	var text: String:
		set(value): text = value; queue_redraw()
	var font: Font = SystemFont.new()
	var font_size: int = 16
	
	var background_color := Color.BLACK:
		set(value): background_color = value; queue_redraw()
	var background_visible := false
	var text_visible := false
	
	var visible_ratio: float = 1.0:
		set(value): 
			visible_ratio = maxf(value, 0.001);
			queue_redraw()
	
	var bg_margin = Vector2(4, 4)
	
	func setVisibility(text_visibilty: bool, background_visibility: bool):
		text_visible = text_visibilty
		background_visible = background_visibility
		queue_redraw()
	
	func getLinesRect(lines: PackedStringArray) -> Rect2:
		var rect = Rect2()
		
		for i in lines:
			var line_size := font.get_string_size(i)
			rect.position.x = min(rect.position.x, -line_size.x / 2.0)
			rect.position.y -= line_size.y
			rect.size.x = maxf(rect.size.x, line_size.x)
			rect.size.y += line_size.y
		rect.position -= bg_margin
		rect.size += bg_margin * 1.75
		return rect
	
	func getLinePosition(line: int, side := SIDE_LEFT) -> Vector2:
		var lines: PackedStringArray = text.split('\n')
		if(line > lines.size() - 1): return Vector2.ZERO
		var rect = getLinesRect(lines)
		if(side == SIDE_RIGHT): rect.position.x = rect.size.x
		
		var line_pos = Vector2(rect.position.x, -getLinesRect(lines.slice(line + 1)).size.y)
		
		return line_pos
	
	func _draw():
		var lines = text.split('\n')
		var rect = getLinesRect(lines)
		
		if(background_visible):
			draw_rect(rect, background_color)
		
		if !text_visible || text == "": return
		
		var v_offset = rect.position.y + font.get_string_size(lines[0], HORIZONTAL_ALIGNMENT_LEFT, -1, int(font_size * 0.75)).y + bg_margin.y
		var rem_ratio := visible_ratio
		var text_size = font.get_string_size(text)
		for line in lines:
			var line_size := font.get_string_size(line)
			var char_pos = Vector2(rect.position.x + bg_margin.x, v_offset)
			draw_string(font, char_pos, line, HORIZONTAL_ALIGNMENT_LEFT, text_size.x * rem_ratio)
			rem_ratio = maxf(rem_ratio - line_size.x / text_size.x, 0.001)
			v_offset += line_size.y

@export var player: CharacterController
@export var arrow: Node2D
@export var font: Font
@export var text_background: Color
@export var branch_background: Color

var current_actor: Actor = null

var label := DialogueLabel.new()
var branch_label := DialogueLabel.new()

var label_pos := Vector2.ZERO
var branching := false
var branch_index = 0
var max_branches = -1

func _ready():
	assert(player)
	label.font = font
	label.background_color = text_background
	branch_label.font = font
	branch_label.background_color = branch_background
	add_child(label)
	add_child(branch_label)
	arrow.reparent(branch_label)
	
	interact_config = InputConfig.fromAction("interact")
	input_configs["confirm"] = interact_config

func _process(_d):
	if(branching):
		if(Input.is_action_just_pressed("up")):
			branch_index = wrapi(branch_index - 1, 0, max_branches)
			arrow.position = branch_label.getLinePosition(branch_index)
		if(Input.is_action_just_pressed("down")):
			branch_index = wrapi(branch_index ++ 1, 0, max_branches)
			arrow.position = branch_label.getLinePosition(branch_index)

func messageStart(_line: String):
	label.text = _line
	if(current_actor):
		label_pos = current_actor.position + Vector2(0, 0.8) * current_actor.icon_position
	label.position = label_pos
	label.visible_ratio = 0.0
	label.setVisibility(false, true)
	
	var tween = create_tween().set_parallel()
	tween.tween_property(label, "modulate:a", 1.0, 0.15).from(0.0)
	tween.tween_property(label, "position:y", label_pos.y, 0.15).from(label_pos.y + 5)
	await tween.finished
	label.setVisibility(true, true)
	
func messageEnd():
	current_actor = null
	var tween = create_tween().set_parallel()
	tween.tween_property(label, "visible_ratio", 0.0, 0.15).from(1.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.3).from(1.0)
	tween.tween_property(label, "position:y", label_pos.y + 5, 0.3).from(label_pos.y)
	await tween.finished
	label.text = ""
	label.setVisibility(false, false)

func processLine(line: String, _data: Resource):
	label.text = line
	label.position = label_pos
	
	var tween = create_tween()
	tween.tween_property(label, "visible_ratio", 1.0, 0.15 + len(line) * 0.02).from(0.0)
	
	await tween.finished
	await input_configs["confirm"].pressed

func branchAppear():
	branch_label.z_index = 1
	branch_label.setVisibility(true, true)
	var tween = create_tween().set_parallel()
	tween.tween_property(label, "modulate:a", 0.1, 0.2).from(1.0)
	tween.tween_property(branch_label, "modulate:a", 1.0, 0.2).from(0.0)
	await tween.finished
	
	branching = true
	branch_index = 0
	arrow.position = branch_label.getLinePosition(0)
	arrow.visible = true

func branchDisppear():
	branch_label.z_index = -1
	var tween = create_tween().set_parallel()
	tween.tween_property(label, "modulate:a", 1.0, 0.2)
	tween.tween_property(branch_label, "modulate:a", 0.0, 0.2)
	await tween.finished
	branch_label.setVisibility(false, false)
	arrow.visible = false

func processBranches(branches: PackedStringArray) -> String:
	branch_label.position = player.position - Vector2(0, 20)
	branch_label.text = branches[0]
	max_branches = branches.size()
	for branch in branches.slice(1):
		branch_label.text += "\n" + branch
	
	await branchAppear()
	await input_configs["confirm"].pressed
	await branchDisppear()
	
	return branches[branch_index]

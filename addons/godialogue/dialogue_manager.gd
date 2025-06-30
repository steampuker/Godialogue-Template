extends Node

## The prototype class for handling dialogue messages.
##
## Provides the bare minimum, everything is printed to the terminal by default. [br]
## To change this behavior, override the following methods: [br]
##  -  [b]messageStart()[/b][br]
##  -  [b]processLine(line: String, data: Resource)[/b] [WARNING: Work in progress, the style might change in future][br]
##  -  [b]processBranches(branches: PackedStringArray) -> String[/b][br]
##  -  [b]messageEnd()[/b]

class_name DialogueManagerBase

class InputConfig:
	var from_keyboard: bool = false
	var from_joypad: bool = false
	var from_mouse: bool = false
	
	var oneshot: bool = true
	var on_release: bool = true
	
	var keycodes: Array[Key] = []
	var joy_buttons: Array[JoyButton] = []
	var mouse_buttons: Array[MouseButton] = []
	
	signal pressed

var processing: bool = false
var input_configs: Dictionary[StringName, InputConfig] = {}
var interaction_cooldown: float = 0.01

signal message_started(message: DialogueMessage)
signal message_ended(message: DialogueMessage)

signal line_started
signal line_ended

func _unhandled_input(event):
	for config: InputConfig in input_configs.values():
		if(event.is_released() == config.on_release) && (event.is_echo() == !config.oneshot):
			if config.from_keyboard && event is InputEventKey:
				if config.keycodes.has(event.get_keycode_with_modifiers()):
					config.pressed.emit()
			elif config.from_joypad && event is InputEventJoypadButton :
				if config.joy_buttons.has(event.get_keycode_with_modifiers()):
					config.pressed.emit()
			elif(config.from_mouse && event is InputEventMouseButton):
				if config.mouse_buttons.has(event.get_keycode_with_modifiers()):
					config.pressed.emit()

func _onMessageState(started: bool, message: DialogueMessage):
	if(started): message_started.emit(message)
	else: message_ended.emit(message)
	
	set_process_input(started)
	processing = started

func processProperty(object: Object, property: String):
	assert(object[property] is DialogueMessage)
	
	object[property] = await processMessage(object[property])

func processMessage(message: DialogueMessage) -> DialogueMessage:
	_onMessageState(true, message)
	await messageStart()
	
	var processed_message: DialogueMessage = message
	while(true):
		for i in processed_message.lines_text.size():
			line_started.emit()
			await processLine(processed_message.lines_text[i], processed_message.lines_data[i])
			line_ended.emit()
		
		var next: DialogueMessage
		if(!processed_message.is_branching):
			next = processed_message.branches["next"]
		else:
			var branch_key: String = await processBranches(processed_message.branch_labels)
			next = processed_message.branches.get(branch_key)
		
		if(!next): break;
		if(next.replacing): message = next
		if(!next.continuous): break;
		processed_message = next
		
	await messageEnd()
	await get_tree().create_timer(interaction_cooldown).timeout
	_onMessageState(false, message)
	
	return message

func processLine(line: String, data: Resource):
	if(OS.is_debug_build()): print("- ", line); await get_tree().create_timer(0.1).timeout

func processBranches(branches: PackedStringArray) -> String:
	if(OS.is_debug_build()): print("  -- ", branches); await get_tree().create_timer(0.1).timeout
	return ""

func messageStart(): pass

func messageEnd(): pass

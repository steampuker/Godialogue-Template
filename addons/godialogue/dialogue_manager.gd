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

var processing: bool = false
var input_configs: Dictionary[StringName, InputConfig] = {} 
var interact_config := InputConfig.new()

var interact_ready: bool = false
signal interacted

signal message_started(message: DialogueMessage)
signal message_ended(message: DialogueMessage)
signal line_started
signal line_ended

func _unhandled_input(event: InputEvent):
	if !processing && !event.is_echo() && interact_config.hasEvent(event):
		if interact_ready && event.is_released() == interact_config.on_release: interact_ready = false; return
		if !interact_ready && !event.is_released() != interact_config.on_release:
			interact_ready = true
			interacted.emit()
			return
	
	for config: InputConfig in input_configs.values():
		if event.is_released() == config.on_release && event.is_echo() == !config.oneshot && config.hasEvent(event):
			config.pressed.emit()
			return

func _onMessageState(started: bool, message: DialogueMessage):
	if(started): message_started.emit(message); interact_ready = false
	else: message_ended.emit.call_deferred(message)

func processProperty(object: Object, property: String):
	assert(object[property] is DialogueMessage)
	
	object[property] = await processMessage(object[property])

func processMessage(message: DialogueMessage):
	if(processing):
		printerr("Trying to process a message while another one is running! Aborted!")
		return message
	
	await messageStart(message.lines_text[0])
	processing = true
	_onMessageState(true, message)
	
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
	processing = false
	_onMessageState(false, message)
	return message

func processLine(line: String, data: Resource):
	if(OS.is_debug_build()): print("- ", line); await get_tree().create_timer(0.1).timeout

func processBranches(branches: PackedStringArray) -> String:
	if(OS.is_debug_build()): print("  -- ", branches); await get_tree().create_timer(0.1).timeout
	return ""

func messageStart(first_line: String): pass

func messageEnd(): pass

class InputConfig:
	var oneshot: bool = true
	var on_release: bool = false
	
	var keycodes: Array[Key] = []
	var joy_buttons: Array[JoyButton] = []
	var mouse_buttons: Array[MouseButton] = []
	
	signal pressed
	
	func _init(oneshot: bool = true, on_release: bool = false, keycodes: Array[Key] = [], joy_buttons: Array[JoyButton] = [], mouse_buttons: Array[MouseButton] = []):
		self.oneshot = oneshot
		self.on_release = on_release
		
		self.keycodes = keycodes
		self.joy_buttons = joy_buttons
		self.mouse_buttons = mouse_buttons
	
	func hasEvent(event: InputEvent) -> bool:
		if event is InputEventKey && keycodes.has(event.get_keycode_with_modifiers()): return true
		elif event is InputEventJoypadButton && joy_buttons.has(event.button_index): return true
		elif event is InputEventMouseButton && mouse_buttons.has(event.button_index): return true
		return false
	
	static func fromAction(action: StringName, oneshot: bool = true, on_release: bool = false) -> InputConfig:
		var input_config := InputConfig.new(oneshot, on_release)
		var events := InputMap.action_get_events(action)
		for event in events:
			if(event is InputEventKey): 
				if event.keycode: input_config.keycodes.append(event.keycode)
				if event.physical_keycode: input_config.keycodes.append(event.physical_keycode)
				if event.key_label: input_config.keycodes.append(event.key_label)
			elif(event is InputEventJoypadButton): input_config.joy_buttons.append(event.button_index)
			elif(event is InputEventMouseButton): input_config.mouse_buttons.append(event.button_index)
		return input_config

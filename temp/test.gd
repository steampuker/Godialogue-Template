extends Node

@export var message: DialogueMessage
@export var arr: Array = []
@export var res: Resource

#@export_tool_button("Print Message", "Callable") var action = printMessage

func printMessage():
	print(message)

func _ready():
	arr = message.lines
	print(arr)

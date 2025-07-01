@tool
@icon("res://addons/godialogue/icons/bubble.svg")
class_name DialogueMessage extends Resource

# Message Lines
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NO_EDITOR) 
var lines_text: PackedStringArray = [""]
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NO_EDITOR) 
var lines_data: Array[Resource] = [null]

@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NO_EDITOR)
var branch_labels: PackedStringArray = []
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NO_EDITOR)
var branches: Dictionary[String, DialogueMessage] = {"next" : null}
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NO_EDITOR) 
var is_branching: bool = false

@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NO_EDITOR) 
var replacing: bool = false
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NO_EDITOR) 
var continuous: bool = false

func _get_property_list():
	return [
		{
			name = "",
			type = TYPE_OBJECT,
			hint = PROPERTY_HINT_RESOURCE_TYPE,
			usage = PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_INTERNAL
		}
	]

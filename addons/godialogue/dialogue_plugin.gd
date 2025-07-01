@tool
extends EditorPlugin

class MessageInspector extends EditorInspectorPlugin:
	const property_editor = preload("res://addons/godialogue/message_container.gd")
	func _can_handle(object):
		return object is DialogueMessage
		
	static func print_prop(object, type, name, hint_type, hint_string, usage_flags, wide):
		print("object : ", object);
		print("type : ", type);
		print("name : ", name);
		print("hint_type : ", hint_type);
		print("hint_string : ", hint_string);
		print("usage_flags : ", usage_flags);
		print("wide : ", wide);
		print("")
	
	func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
		#print_prop(object, type, name, hint_type, hint_string, usage_flags, wide)
		if(usage_flags & PROPERTY_USAGE_INTERNAL):
			var editor = property_editor.new()
			add_property_editor("", editor)
			return true

var plugin := MessageInspector.new()

func _enter_tree():
	add_inspector_plugin(plugin)

func _exit_tree():
	remove_inspector_plugin(plugin)

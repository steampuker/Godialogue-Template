@tool
extends Object

static var _user_theme: Theme
static var _user_theme_type: StringName

static func getIcon(name: StringName):
	if(Engine.is_editor_hint()): return EditorInterface.get_editor_theme().get_icon(name, "EditorIcons")
	elif(_user_theme): return _user_theme.get_icon(name, _user_theme_type) 

static func getStyleColor(name: StringName):
	if(Engine.is_editor_hint()): return EditorInterface.get_editor_theme().get_color(name, "Editor")
	elif(_user_theme): return _user_theme.get_color(name, _user_theme_type)
	return Color.WHITE

static func setUserTheme(theme: Theme, type: StringName):
	_user_theme = theme
	_user_theme_type = type

class ContextButton extends Button:
	var popup: PopupMenu = PopupMenu.new()
	var context_button_mask: int = MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT
	
	signal double_click
	
	func add_item(label: String, icon: Texture = null, id := -1):
		if(icon):
			popup.add_icon_item(icon, label, id)
		else:
			popup.add_item(label, id)
	
	func add_separator(label: String = "", id := -1):
		popup.add_separator(label, id)
	
	func remove_item(index: int):
		popup.remove_item(index)
	
	func show_popup():
		popup.reparent(self)
		var rect: Rect2 = get_global_rect()
		rect.position.y += 2.0 * rect.size.y
		if(is_layout_rtl()):
			rect.position.x += rect.size.x - popup.get_size().x
		popup.position = rect.position
		popup.popup()
	
	func _init(label: String = ""):
		add_child(popup)
		gui_input.connect(_pressed_event)
		button_mask = 0
		text = label
	
	func _set(property: StringName, value: Variant):
		if(property == "button_mask"):
			context_button_mask = value
	
	func _pressed_event(event):
		if(!(event is InputEventMouseButton) || !event.pressed || disabled): return
		if(event.button_index == MOUSE_BUTTON_MASK_LEFT
		and context_button_mask & MOUSE_BUTTON_MASK_LEFT):
			if(event.double_click): double_click.emit()
			button_pressed = !button_pressed
			pressed.emit()
		if(event.button_index == MOUSE_BUTTON_MASK_RIGHT
		and context_button_mask & MOUSE_BUTTON_MASK_RIGHT):
			if(popup.visible):
				popup.hide()
				return
			show_popup()

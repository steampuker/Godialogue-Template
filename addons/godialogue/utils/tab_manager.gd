@tool
extends VBoxContainer

const InspectorUtils = preload("res://addons/godialogue/utils/common.gd")

var control_list: VBoxContainer = VBoxContainer.new()
var tab_bar := HBoxContainer.new()
var left_button := Button.new()
var right_button := Button.new()
var offset := 0
var tab_char_limits: Vector2 = Vector2(4, 16)

var selected := -1
var allow_deselect := false
var non_empty := false

var tab_bar_dest: float = 0.0
const scroll_time: float = 0.15

signal add_pressed
signal tab_removed(tab_id: int, control: Control)
signal tabs_rearranged(from: int, to: int)

func changeOffset(value: int, duration: float = scroll_time):
	var tween := create_tween()
	if(value != 0):
		var current = tab_bar.get_child(offset)
		tab_bar_dest = 2.0 - current.position.x - (current.size.x if(value - offset > 0) else -tab_bar.get_child(value).size.x)
		if(offset == 0): tab_bar.position.x -= left_button.size.x
	else:
		tab_bar.position.x += left_button.size.x
		tab_bar_dest = 2.0
	tween.tween_property(tab_bar, "position:x", tab_bar_dest, duration)
	offset = value

func _init(initial_controls: Array[Control] = [], allow_empty := true):
	for control in initial_controls:
		control_list.add_child(control)
	
	if(!allow_empty): 
		if(initial_controls.size() == 0): assert(0, "You declared it non-empty, yet provided a zero array?")
	non_empty = !allow_empty

func addTab(control: Control, name: String = "", should_select := true, draggable := true):
	if(non_empty && getTabCount() == 1):
		(tab_bar.get_child(0) as TabButton).setRemoveState(false)
	
	control_list.add_child(control)
	var button := TabButton.new(control, name, true, InspectorUtils.getStyleColor("accent_color"), draggable)
	
	tab_bar.add_child(button)
	tab_bar.move_child(button, -2)
	
	button.pressed.connect(func(): tabSelect(button.get_index()))
	button.remove.connect(
		func(type):
			match(type):
				TabButton.REMOVE_SELF: removeTab(button.get_index())
				TabButton.REMOVE_RIGHT: removeTabs(button.get_index() + 1, tab_bar.get_child_count() - 1)
				TabButton.REMOVE_LEFT: removeTabs(0, button.get_index(), true)
			)
	button.data_dropped.connect(_tabsRearranged)
	
	if(non_empty && getTabCount() == 1):
		button.setRemoveState(true)
	#tab_bar.size.x += button.size.x
	if(should_select):
		tabSelect(button.get_index())
		await tab_bar.resized
		if(tab_bar.size.x + tab_bar_dest > tab_bar.get_parent_control().size.x): 
			changeOffset(offset + 1)
	else:
		await tab_bar.resized
	_offsetModified()

func removeTab(tab_id: int):
	var tab: TabButton = tab_bar.get_child(tab_id)
	var total_tabs: int = tab_bar.get_child_count() - 2
	
	if(tab_id == selected):
		var new_select := maxi(selected - 1, 0)
		selected = -1
		call_deferred("tabSelect", new_select)
	elif(tab_id < selected):
		selected -= 1
	
	if(offset > 0 && tab_id == offset && tab_id == total_tabs):
		changeOffset(maxi(offset - 1, 0))
		
	control_list.remove_child(tab.tab_content)
	tab_bar.remove_child(tab)
	tab_removed.emit(tab_id, tab.tab_content)
	
	await tab_bar.resized
	if(non_empty && total_tabs == 1):
		tab_bar.get_child(0).setRemoveState()
	_offsetModified()

func removeTabs(from: int, to: int, to_the_left: bool = false):
	if(from == to): return
	from = maxi(from, 0)
	to = mini(to, tab_bar.get_child_count())
		
	if(selected <= to && selected >= from):
		if(to_the_left):
			tabSelect(to)
			selected = from
		else:
			tabSelect(from - 1)
	elif(selected > to):
		selected -= to - from
	
	if(to_the_left && offset > 0):
		changeOffset(maxi(offset - to + from, 0), scroll_time * 0.1)
	
	for i in range(from, to):
		var tab = tab_bar.get_child(from)
		tab.visible = false
		tab_bar.remove_child(tab)
		control_list.remove_child(tab.tab_content)
		tab_removed.emit(from, tab.tab_content)
	
	await tab_bar.resized
	if(tab_bar.get_child_count() - 1 == 1 && non_empty):
		tab_bar.get_child(0).setRemoveState()
	_offsetModified()

func clearTabs():
	selected = -1
	changeOffset(0, 0.0)
	for i in range(0, getTabCount()):
		var tab: TabButton = tab_bar.get_child(0)
		tab_bar.remove_child(tab)
		control_list.remove_child(tab.tab_content)
	tab_bar.size.x = 0
	
	_offsetModified()

func setTabName(id: int, name: String) -> Error:
	var button = tab_bar.get_child(id)
	if(button is not TabButton): return Error.FAILED
	
	button.setName(name)
	await tab_bar.resized
	_offsetModified()
	return Error.OK

func setTabIcon(id: int, icon: Texture = null, color := Color.WHITE, icon_size := 12) -> Error:
	var button = tab_bar.get_child(id)
	if(button is not TabButton): return Error.FAILED
	button.icon = icon
	button.add_theme_constant_override("icon_max_width", icon_size)
	(button as TabButton).add_theme_color_override("icon_normal_color", color)
	await tab_bar.resized
	_offsetModified()
	return Error.OK

func setTabDraggable(id: int, state: bool) -> Error:
	var button = tab_bar.get_child(id)
	if(button is not TabButton): return Error.FAILED
	
	button.draggable = state
	await tab_bar.resized
	_offsetModified()
	return Error.OK

func setAddDisabled(state: bool):
	tab_bar.get_child(-1).disabled = state
	
func getTabCount():
	return control_list.get_child_count()
	
func getTabControl(id: int):
	return control_list.get_child(id)

func tabMove(index: int, to: int = -1, destroyed: bool = false):
	if(to == -1): to = getTabCount() - 1
	
	if(destroyed): tab_removed.emit(index, getTabControl(index))
	_tabsRearranged(tab_bar.get_child(index), to, false)

func tabSelect(index: int):
	if(selected >= 0):
		tab_bar.get_child(selected).deselect()
	
	if(allow_deselect && index == selected): selected = -1; return
	selected = index
	if(index < 0): return
	tab_bar.get_child(index).select()

func _offsetModified(margin: float = 0.0): 
	var header := tab_bar.get_parent_control()
	
	var base := left_button.size.x if offset > 0 else 0
	header.size.x = size.x - base - right_button.size.x
	header.position.x = base
	
	left_button.visible = offset > 0
	right_button.visible = tab_bar.size.x + tab_bar_dest + margin > header.size.x
	right_button.position.x = size.x - right_button.size.x

func barResized():
	var reduce_offset = 0
	var free_space: float = tab_bar.get_parent_control().size.x - (tab_bar.size.x + tab_bar_dest)
	var child_size: float = tab_bar.get_child(offset).size.x
	
	while(reduce_offset < offset && child_size <= free_space):
		free_space -= child_size
		reduce_offset += 1
		child_size = tab_bar.get_child(offset - reduce_offset).size.x
	
	if(reduce_offset > 0):
		changeOffset(maxi(offset - reduce_offset, 0))
	
	_offsetModified()

func setTabSeparation(amount: int):
	tab_bar.add_theme_constant_override("separation", amount)
	await tab_bar.resized
	_offsetModified()

func panelInit():
	var panel := Control.new()
	panel.draw.connect(func(): panel.draw_style_box(get_theme_stylebox("tab_unselected", "TabContainer"), panel.get_rect()))
	panel.custom_minimum_size.y = get_theme_default_font_size() * 2 + 4
	add_child(panel)
	
	control_list.name = "Control List"
	add_child(control_list)
	
	left_button.icon = InspectorUtils.getIcon("ArrowLeft")
	left_button.gui_input.connect(
		func(event): 
			if(!(event is InputEventMouseButton) || event.pressed): return
			if(event.button_index == MOUSE_BUTTON_MASK_LEFT): changeOffset(maxi(offset - 1, 0))
			elif(event.button_index == MOUSE_BUTTON_MASK_RIGHT): 
				changeOffset(0, scroll_time + offset * 0.08 - 0.08)
			_offsetModified()
			)
	left_button.size.y = panel.size.y
	
	right_button.icon = InspectorUtils.getIcon("ArrowRight")
	right_button.pressed.connect(
		func(): changeOffset(mini(offset + 1, getTabCount() - 1)); _offsetModified())
	
	right_button.size.y = panel.size.y
	
	var add_button := Button.new()
	add_button.icon = InspectorUtils.getIcon("Add")
	add_button.add_theme_constant_override("icon_max_width", 7)
	add_button.focus_mode = Control.FOCUS_NONE
	add_button.pressed.connect(func(): add_pressed.emit())
	
	tab_bar.add_child(add_button)
	tab_bar.position.x = 2.0 
	tab_bar.custom_minimum_size.y = panel.size.y
	setTabSeparation(0)
	
	var header = Control.new()
	header.name = "Header"
	header.clip_contents = true
	header.size.y = panel.size.y
	header.add_child(tab_bar)
	
	panel.add_child(left_button)
	panel.add_child(header)
	panel.add_child(right_button)

func setControlsIconSize(size: int):
	tab_bar.get_child(-1).add_theme_constant_override("icon_max_width", size)
	left_button.add_theme_constant_override("icon_max_width", size)
	right_button.add_theme_constant_override("icon_max_width", size)

func tabInit():
	for child in control_list.get_children():
		control_list.remove_child(child)
		addTab(child, child.name, false)
	
	var total_tabs = tab_bar.get_child_count() - 1
	if(total_tabs > 0):
		if(total_tabs == 1): tab_bar.get_child(0).setRemoveState()
		tabSelect(0)
		
	
func _tabsRearranged(tab: TabButton, pos: int, emit: bool = true):
	if(tab.get_index() == pos): return
	var current_tab: int = tab.get_index()
	tab_bar.move_child(tab, pos)
	control_list.move_child(control_list.get_child(current_tab), pos)
	
	selected = pos
	
	if(emit): tabs_rearranged.emit(current_tab, pos)

func _ready():
	resized.connect(barResized)
	panelInit()
	tabInit()

class TabButton extends InspectorUtils.ContextButton:
	enum { REMOVE_SELF, REMOVE_LEFT, REMOVE_RIGHT }
	static var tab_size_limits: Vector2 = Vector2(4, 16)
	var tab_content: Control
	var button_style := StyleBoxLine.new()
	var separator := ColorRect.new()
	
	var draggable
	
	signal data_dropped(what, index)
	signal remove(type)
	signal copied
	
	func _init(content: Control = null, title: String = "", toggle = true, style_color: Color = Color.WHITE, drag_possible = true):
		super()
		focus_mode = Control.FOCUS_NONE
		_init_style(style_color)
		toggle_mode = toggle
		
		draggable = drag_possible
		
		if(!content): return
		tab_content = content
		content.visible = false
		setName(content.name if(title == "") else title)
		mouse_exited.connect(func(): separator.visible = false)
		
		add_item("Remove", InspectorUtils.getIcon("Remove"))
		add_item("Remove to the right", InspectorUtils.getIcon("ArrowRight"))
		add_item("Remove to the left", InspectorUtils.getIcon("ArrowLeft"))
		add_separator()
		add_item("Copy", InspectorUtils.getIcon("ActionCopy"))
		popup.index_pressed.connect(
			func(id): 
				match(id):
					0: remove.emit(REMOVE_SELF)
					1: remove.emit(REMOVE_RIGHT)
					2: remove.emit(REMOVE_LEFT)
					4: copied.emit()
				)
	
	func _init_style(style_color: Color):
		button_style.color = style_color
		button_style.grow_begin = -5
		button_style.grow_end = -5
		add_theme_stylebox_override("pressed", button_style)
	
	func setName(new_name: String):
		if(new_name.length() < tab_size_limits.x): 
			custom_minimum_size.x = 25
	
		if(new_name.length() > tab_size_limits.y): 
			new_name = new_name.left(tab_size_limits.y) + "..."
		
		text = new_name
		size.x = 0
	
	func deselect():
		button_pressed = false
		tab_content.visible = false
		
	func select():
		button_pressed = true
		tab_content.visible = true
	
	func setRemoveState(disabled: bool = true):
		popup.set_item_disabled(REMOVE_SELF, disabled)
		popup.set_item_disabled(REMOVE_RIGHT, disabled)
		popup.set_item_disabled(REMOVE_LEFT, disabled)
	
	func separatorRearrange(left_side: bool):
		if(left_side):
			separator.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
		else:
			separator.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
		separator.position.y -= separator.size.y / 2
		separator.position.x -= separator.custom_minimum_size.x
	
	func _enter_tree():
		separator.size_flags_vertical = SIZE_SHRINK_CENTER
		separator.size_flags_horizontal = SIZE_SHRINK_CENTER
		
		separator.color = button_style.color
		separator.custom_minimum_size.x = 3
		separator.custom_minimum_size.y = floor(size.y * 0.65)
		separator.z_index = self.z_index + 1
		
		add_child(separator)
		separatorRearrange(false)
		separator.visible = false
	
	func _exit_tree():
		remove_child(separator)
	
	func _get_drag_data(_pos):
		if(!draggable): return
		
		var dup = self.duplicate()
		for child in dup.get_children():
			child.visible = false
		
		set_drag_preview(dup)
		return self

	func _can_drop_data(at_position, data) -> bool:
		if(draggable and data is TabButton and data != self):
			var center_x: float = get_rect().size.x * 0.5
			separator.visible = true
			separatorRearrange(at_position.x < center_x)
			return true
		return false

	func _drop_data(at_position: Vector2, data):
		if(data is not TabButton or !draggable): return
		
		var center_x: float = get_rect().size.x * 0.5
		var id_diff = data.get_index() - get_index()
		if(at_position.x < center_x): data_dropped.emit(data, maxi(get_index() - int(id_diff < 0), 0))
		else: data_dropped.emit(data, get_index() + int(id_diff > 0))
		
		separator.visible = false

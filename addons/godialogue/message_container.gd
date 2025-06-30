@tool
extends EditorProperty

const InspectorUtils = preload("res://addons/dialogue/utils/common.gd")
const branch_icon = preload("res://addons/dialogue/icons/branch.svg")
const bubble_icon = preload("res://addons/dialogue/icons/bubble.svg")

var line_list := preload("res://addons/dialogue/utils/line_list.gd").new()
var tab_manager := preload("res://addons/dialogue/utils/tab_manager.gd").new()
var next_message: BranchControl = BranchControl.new(true)
var branching: bool

var null_tabs: int = 0

static func getBehaviorBit(behavior: int, flag: int, state: bool) -> int:
	return (behavior & ~(1 << flag)) | (int(state) << flag)

func initLines():
	var message: DialogueMessage = get_edited_object()
	for line in message.lines_text:
		line_list.addLine(line)
	
	line_list.line_text_changed.connect(
		func(index: int, text: String): 
			message.lines_text[index] = text
			emit_changed("lines", message.lines_text))
	line_list.line_added.connect(
		func(text: String): 
			message.lines_text.append(text)
			message.lines_data.append(null)
			emit_changed("lines", message.lines_text))
	line_list.line_removed.connect(
		func(index: int): 
			message.lines_text.remove_at(index)
			message.lines_data.remove_at(index)
			emit_changed("lines", message.lines_text))

func _ready():
	label = ""
	draw_label = false
	draw_background = false
	var container := VBoxContainer.new()
	add_child(container)
	container.add_child(line_list)
	
	_instantiateBranchManager(container)
	initLines()

func _instantiateBranchManager(container: VBoxContainer):
	var header = Button.new()
	var check: CheckButton = CheckButton.new()
	var message: DialogueMessage = get_edited_object()
	
	container.add_child(header)
	container.add_child(check)
	container.add_child(tab_manager)
	container.add_child(next_message)
	
	line_list.initFoldableButton(header, "Message Continuation")
	header.pressed.connect(func(): 
		check.visible = header.button_pressed
		tab_manager.visible = header.button_pressed && message.is_branching
		next_message.visible = header.button_pressed && !message.is_branching
	)
	header.pressed.emit()
	header.add_theme_stylebox_override("pressed",  get_theme_stylebox("normal", "Button"))
	
	tab_manager.non_empty = true
	
	check.text = "Is Branching"
	check.tooltip_text = "Lalala"
	check.button_pressed = message.is_branching
	check.toggled.connect(
	func(toggle): 
		message.is_branching = toggle
		tab_manager.visible = toggle
		next_message.visible = !toggle
		
		message.branches.clear()
		message.branch_labels.clear()
		
		if(toggle):
			tab_manager.clearTabs()
			null_tabs = 0
			
			var new_branch := createBranch()
			tab_manager.addTab(new_branch, "")
			makeBranchNull(new_branch)
		else:
			next_message.setPropertyPreview(null)
		
		emit_changed("is_branching", toggle))
	
	for key in message.branch_labels:
		tab_manager.addTab(createBranch(key), key, false)
		tab_manager.setTabIcon(tab_manager.getTabCount() - 1, branch_icon, Color.DIM_GRAY)
	
	if(tab_manager.getTabCount() == 0):
		var new_branch := createBranch()
		tab_manager.addTab(new_branch, "", false)
		tab_manager.setTabIcon(tab_manager.getTabCount() - 1, branch_icon, Color.DIM_GRAY)
		makeBranchNull(new_branch)
	
	tab_manager.tabSelect(0)
	
	tab_manager.add_pressed.connect(
		func():
			if(null_tabs > 0): printerr("Incomplete branch detected, can not add more!"); return
			var new_branch := createBranch()
			tab_manager.addTab(new_branch, "")
			makeBranchNull(new_branch))
	tab_manager.tab_removed.connect(
		func(id, control: BranchControl): 
			if(control.is_null): null_tabs -= 1; tab_manager.setAddDisabled(null_tabs > 0)
			else: 
				message.branches.erase(control.key)
				message.branch_labels.remove_at(id)
				)
	
	tab_manager.tabs_rearranged.connect(func(prev: int, new: int):
		var prev_key := message.branch_labels[prev]
		message.branch_labels.remove_at(prev)
		message.branch_labels.insert(new, prev_key)
		
		emit_changed("branches", message.branches)
	)
	
	next_message.setPropertyPreview(message.branches.get("next"))
	next_message.button.popup.id_pressed.connect(func(id):
		if(next_message.empty):
			if(id == 0):
				var new_message := DialogueMessage.new()
				message.branches["next"] = new_message
				
				next_message.setPropertyPreview(new_message)
		else:
			if(id == 0):
				next_message.setPropertyPreview(null)
				message.branches["next"] = null
	)
	
	next_message.button.double_click.connect(func(): if(!next_message.empty): EditorInterface.get_inspector().call_deferred("edit", message.branches["next"]))
	next_message.continuous_check.toggled.connect(func(state): message.branches["next"].continuous = state)
	next_message.replacing_check.toggled.connect(func(state): message.branches["next"].replacing = state)

func makeBranchNull(branch: BranchControl, state: bool = true):
	var branch_index := branch.get_index()
	null_tabs += 1 if state else -1
	branch.is_null = state
	branch.button.disabled = state
	tab_manager.setTabDraggable(branch_index, !state)
	tab_manager.setTabName(branch_index, "<null>")
	tab_manager.setTabIcon(branch_index, branch_icon if !state else null, Color.DIM_GRAY)
	
	tab_manager.setAddDisabled(null_tabs > 0)

func createBranch(key: String = "") -> BranchControl:
	var message: DialogueMessage = get_edited_object()
	var branch: BranchControl = BranchControl.new(false, message.branches.get(key), key)
	branch.text_changed.connect(
	func(old: String, new: String):
		var branch_index := branch.get_index()
		if(message.branch_labels.has(new)): 
			printerr("Branch already exists! Pick something else!")
			branch.line_edit.text = old
			return
		var prev_message: DialogueMessage
		if(branch.is_null):
			makeBranchNull(branch, false)
		else:
			prev_message = message.branches.get(old)
			message.branches.erase(old)
			var index: int = message.branch_labels.find(old)
			if(index >= 0):
				message.branch_labels.remove_at(index)
		
		if(new != ""):
			branch.key = new
			message.branches[new] = prev_message
			
			if(!message.branch_labels.has(new)):
				message.branch_labels.append(new)
			else:
				message.branch_labels[branch_index] = new
				
			tab_manager.setTabName(branch_index, new)
		else:
			makeBranchNull(branch, true)
			tab_manager.tabMove(branch_index)
		emit_changed("branches", message.branches))
	
	branch.button.popup.id_pressed.connect(
		func(id: int):
			if(branch.empty):
				if(id == 0):
					var new_message := DialogueMessage.new()
					message.branches[branch.key] = new_message
					branch.setPropertyPreview(new_message)
			else:
				if(id == 0):
					branch.setPropertyPreview(null)
					message.branches[branch.key] = null
	)
	
	branch.button.double_click.connect(func():
		if(!branch.empty): 
			EditorInterface.get_inspector().call_deferred("edit", message.branches[branch.key]))
	branch.continuous_check.toggled.connect( func(state): message.branches[branch.key].continuous = state)
	branch.replacing_check.toggled.connect( func(state): message.branches[branch.key].replacing = state)
	return branch

class BranchControl extends VBoxContainer:
	var line_edit: Variant
	var button: InspectorUtils.ContextButton = InspectorUtils.ContextButton.new()
	var continuous_check: CheckBox = CheckBox.new()
	var replacing_check: CheckBox = CheckBox.new()
	
	var key: String = ""
	var is_null: bool = false
	var empty: bool = true
	var _prev_text: String
	signal text_changed
	
	func _init(unique: bool = false, message: DialogueMessage = null, new_key: String = ""):
		if(unique): 
			line_edit = Label.new()
			line_edit.text = "Next"
			line_edit.size_flags_horizontal = Control.SIZE_FILL
		else:
			key = new_key
			line_edit = TextEdit.new()
			line_edit.text = new_key
			line_edit.placeholder_text = "Branch message"
			line_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
			line_edit.scroll_smooth = true
			line_edit.scroll_fit_content_height = true
			line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line_edit.focus_entered.connect(func(): _prev_text = line_edit.text)
			line_edit.focus_exited.connect(func(): if(_prev_text != line_edit.text): text_changed.emit(_prev_text, line_edit.text))
		
		var arrow := TextureRect.new()
		arrow.texture = InspectorUtils.getIcon("GuiTreeArrowDown")
		arrow.set_anchor(SIDE_LEFT, 0.9)
		arrow.set_anchor(SIDE_TOP, 0.3)
		button.add_child(arrow)
		button.text = "<null>"
		
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.add_theme_constant_override("icon_max_width", 16)
		setPropertyPreview(message)
		
		continuous_check.text = "Continuous"
		replacing_check.text = "Replacing"
			
	
	func setPropertyPreview(property: DialogueMessage):
		var color = Color.WHITE if property else Color.DIM_GRAY
		var name = property.lines_text[0].left(16) + "..." if property else "<null>"
		if(name == "..."): name = "New Message"
		button.icon = bubble_icon if property else null
		button.text = name
		
		button.add_theme_color_override("font_color", color)
		button.add_theme_color_override("font_hover_color", color)
		button.add_theme_color_override("font_focus_color", color)
		
		empty = property == null
		button.popup.clear()
		
		continuous_check.disabled = !property
		replacing_check.disabled = !property
		
		if(!property):
			continuous_check.button_pressed = false
			replacing_check.button_pressed = false
			
			button.add_item("New")
		else:
			continuous_check.button_pressed = property.continuous
			replacing_check.button_pressed = property.replacing
			button.add_item("Remove")
	
	func connectTextChange(callback: Callable):
		if(line_edit is TextEdit):
			line_edit.focus_exited.connect(callback)
	
	func _ready():
		var hbox1 = HBoxContainer.new()
		hbox1.add_child(line_edit)
		hbox1.add_child(button)
		
		var hbox2 = HBoxContainer.new()
		hbox2.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		hbox2.add_child(continuous_check)
		hbox2.add_child(replacing_check)
		
		add_child(hbox1)
		add_child(hbox2)

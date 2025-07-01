@tool
extends VBoxContainer
const InspectorUtils = preload("res://addons/godialogue/utils/common.gd")

var foldable: VBoxContainer = VBoxContainer.new()
var add_button = Button.new()

var popup_button: InspectorUtils.ContextButton = InspectorUtils.ContextButton.new("Lines")
var return_button: Button = Button.new()

signal line_text_changed(index: int, new_text: String)
signal lines_updated
signal line_added(text: String)
signal line_removed(index: int)

func _ready():
	var header = HBoxContainer.new()
	add_child(header)
	add_child(foldable)
	foldable.visible = true
	_init_header(header)
	
	add_button.text = "Add Line"
	add_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_button.icon = InspectorUtils.getIcon("Add")
	add_button.pressed.connect(addLine)
	add_child(add_button)

func _init_header(header: HBoxContainer):
	initFoldableButton(popup_button)
	popup_button.pressed.connect(func(): 
		foldable.visible = popup_button.button_pressed
		add_button.visible = popup_button.button_pressed
	)
	popup_button.add_theme_stylebox_override("pressed",  get_theme_stylebox("normal", "Button"))
	popup_button.button_pressed = true
	
	return_button.disabled = true
	return_button.icon = InspectorUtils.getIcon("ArrowUp")
	header.add_child(popup_button)
	header.add_child(return_button)

func initFoldableButton(button: Button, title: String = ""):
	var ico_button_default = InspectorUtils.getIcon("GuiTreeArrowRight")
	var ico_button_press = InspectorUtils.getIcon("GuiTreeArrowDown")
	
	if(title != ""): button.text = title
	
	button.focus_mode = Control.FOCUS_NONE
	button.toggle_mode = true
	button.icon = ico_button_press if foldable.visible else ico_button_default
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(func(): 
		button.icon = ico_button_press if button.button_pressed else ico_button_default)

func addLine(line: String = ""):
	if(foldable.get_child_count() > 0): foldable.get_child(-1).setRemoveState(1, true)
	
	var control := LineControl.new()
	control.line_edit.text = line
	foldable.add_child(control)
	
	lines_updated.emit()
	lines_updated.connect(control.updateIndex)
	
	line_added.emit(line)
	control.options.get_popup().index_pressed.connect(
		func(id): 
		match(id): 
			0: removeLine(control.get_index())
			1: removeLines(control.get_index() + 1, foldable.get_child_count())
		)
	control.text_changed.connect(func(): line_text_changed.emit(control.get_index(), control.line_edit.text))
	
	foldable.get_child(0).setRemoveState(0, foldable.get_child_count() != 1)
	foldable.get_child(-1).setRemoveState(1, false)

func getLines() -> PackedStringArray:
	var arr: PackedStringArray = []
	for child: LineControl in foldable:
		arr.append(child.line_edit.text)
	
	return arr

func removeLine(index: int):
	var control = foldable.get_child(index)
	foldable.remove_child(control)
	control.queue_free()
	
	lines_updated.emit()
	line_removed.emit(index)
	foldable.get_child(-1).setRemoveState(1, false)
	if(foldable.get_child_count() == 1):
		foldable.get_child(0).setRemoveState(0, false)

func removeLines(from: int, to: int):
	from = maxi(from, 0)
	to = mini(to, foldable.get_child_count())
	
	for i in range(from, to):
		foldable.remove_child(foldable.get_child(from))
		line_removed.emit(from)
	
	lines_updated.emit()
	foldable.get_child(-1).setRemoveState(1, false)
	if(foldable.get_child_count() == 1):
		foldable.get_child(0).setRemoveState(0, false)

class LineControl extends HBoxContainer:
	var index_button: Button = Button.new()
	var line_edit: TextEdit = TextEdit.new()
	var options: MenuButton = MenuButton.new()
	
	var _prev_text: String = ""
	signal text_changed
	
	func _ready():
		index_button.text = str(get_index() + 1)
		index_button.flat = true
		line_edit.placeholder_text = "Line here"
		options.icon = InspectorUtils.getIcon("GuiTabMenuHl")
		options.add_theme_stylebox_override("normal", get_theme_stylebox("normal", "Button"))
		options.add_theme_stylebox_override("pressed", get_theme_stylebox("pressed", "Button"))
		options.flat = false
		options.button_mask = MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT
		options.get_popup().add_icon_item(InspectorUtils.getIcon("Remove"), "Remove")
		options.get_popup().add_icon_item(InspectorUtils.getIcon("ArrowDown"), "Remove Below")
		
		var stylebox := StyleBoxFlat.new()
		stylebox.bg_color = Color8(0, 0, 0, 100)
		line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line_edit.scroll_fit_content_height = true
		line_edit.focus_entered.connect(func(): _prev_text = line_edit.text)
		line_edit.focus_exited.connect(func(): if(_prev_text != line_edit.text): text_changed.emit())
		
		add_child(index_button)
		add_child(line_edit)
		add_child(options)
	
	func updateIndex():
		index_button.text = str(get_index() + 1)
	
	func setRemoveState(index: int, state: bool):
		options.get_popup().set_item_disabled(index, !state)

extends DialogueManagerBase

var label = self

func _ready():
	var confirm := InputConfig.new()
	confirm.from_keyboard = true
	confirm.keycodes.append(KEY_UP)
	input_configs["confirm"] = confirm

func messageStart():
	label.visible = true
	
func messageEnd():
	label.visible = false

func processLine(line: String, _data: Resource):
	label.text = line
	await input_configs["confirm"].pressed

func processBranches(branches: PackedStringArray) -> String:
	$Branches.visible = true
	$Branches.text = ""
	for branch in branches:
		$Branches.text += branch + "    "
	
	await input_configs["confirm"].pressed
	$Branches.visible = false
	return branches[0]

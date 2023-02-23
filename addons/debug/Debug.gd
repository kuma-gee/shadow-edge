extends CanvasLayer

# Order used to check what should be printed
# More verbose the further below the level
enum Level {
	OFF,
	ERROR,
	INFO,
	WARN,
	DEBUG,
	TRACE,
}

const WINDOW_STRETCH = "display/window/stretch/mode"
const APPLICATION = "application/config/name"

@export var lines: Label
@export var input: LineEdit


var log_level = Level.DEBUG

var _original_zoom = null
var _commands = {
	"/help": {
		"action": func(x): _help_cmd(x)
	},
	"/version": {
		"desc": "Print game name with version",
		"action": func(x): _version_cmd(x)
	},
	"/logging": {
		"desc": "Print or change logging level " + str(Level.keys()),
		"action": func(x): _logging_cmd(x)
	},
	"/zoom": {
		"desc": "Toggle the window zoom mode",
		"action": func(x): _zoom_cmd(x)
	}
}

func _ready():
	hide()
	if Env.is_prod():
		log_level = Level.INFO

	_version_cmd()
	_logging_cmd()


func _unhandled_input(event):
	if event.is_action_pressed("dev"):
		visible = !visible
		if visible:
			input.grab_focus()


func print_line(str: String):
	lines.text += str + "\n"


func _on_text_edit_text_submitted(new_text):
	_on_command_input(new_text)
	input.clear()


func _on_command_input(input: String):
	if not input.begins_with("/"):
		print_line(input)
		return

	var args = input.split(" ")
	var cmd = args[0]

	if cmd in _commands:
		_commands[cmd]["action"].call(args.slice(1))
	else:
		print_line("Unknown command: %s" % cmd)


func _help_cmd(args: Array[String] = []):
	print_line("Available commands:")
	for cmd in _commands:
		var obj = _commands[cmd]
		if 'desc' in obj:
			print_line("%s: %s" % [cmd, obj["desc"]])


func _version_cmd(args: Array[String] = []):
	print_line("Playing %s in version %s" % [ProjectSettings.get(APPLICATION), Env.version])


func _logging_cmd(args: Array[String] = []):
	if args.size() < 1:
		print_line("Logging level: %s" % Level.keys()[log_level])
	else:
		var level = args[0]
		var new_level = Level[level]
		if new_level != null:
			log_level = new_level
			print_line("Changed logging level to %s" % level)
		else:
			print_line("Unknown logging level %s" % level)


func _zoom_cmd(args: Array[String] = []):
	if not _original_zoom:
		_original_zoom = ProjectSettings.get(WINDOW_STRETCH)
		ProjectSettings.set(WINDOW_STRETCH, "disabled")
		print_line("Disabled window zoom")
	else:
		ProjectSettings.set(WINDOW_STRETCH, _original_zoom)
		_original_zoom = null
		print_line("Restored window zoom")


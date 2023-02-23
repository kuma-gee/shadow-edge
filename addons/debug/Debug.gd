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

const WINDOW_STRETCH = "window/stretch/mode"
const APPLICATION = "config/name"

var log_level = Level.DEBUG

var _original_zoom = null
var _commands = {
    "/help": {
        "action": _help_cmd
    },
    "/version": {
        "desc": "Print game name with version",
        "action": _version_cmd
    },
    "/logging": {
        "desc": "Print or change logging level %s" % Level.keys(),
        "action": _logging_cmd
    },
    "/zoom": {
        "desc": "Toggle the window zoom mode",
        "action": _zoom_cmd
    }
}

func _ready():
    if Env.is_prod():
        log_level = Level.INFO

    _version_cmd()
    _logging_cmd()


func _unhandled_input(event):
	if event.is_action_pressed("dev"):
        visible = !visible


func print_line(str: String):
    pass # TODO: print + buffer?


func _on_command_input(input: String):
    if not input.begins_with("/"):
        return

    var args = input.split(" ")
    var cmd = args.shift()

    var obj = _commands[cmd]
    if obj:
        obj["action"].call(args)


func _help_cmd(args: Array[String] = []):
    print_line("Available commands:")
    for cmd in _commands:
        var obj = _commands[cmd]
        if 'desc' in obj:
            print_line("%s: %s" % [cmd, obj["desc"]])


func _version_cmd(args: Array[String] = []):
    print_line("Playing %s in version %s" % [ProjectSettings.get(APPLICATION), Env.version])


func _logging_cmd(args: Array[String] = []):
    var new_level = Level.get(args[0])
    if new_level:
        log_level = new_level
        print_line("Changed logging level to %s" % args[0])
    else:
        print_line("Logging level: %s" % Level.keys()[log_level])


func _zoom_cmd(args: Array[String] = []):
    if not _original_zoom:
        _original_zoom = ProjectSettings.get(WINDOW_STRETCH)
        ProjectSettings.set(WINDOW_STRETCH, "disabled")
        print_line("Disabled window zoom")
    else:
        ProjectSettings.set(WINDOW_STRETCH, _original_zoom)
        _original_zoom = null
        print_line("Restored window zoom")
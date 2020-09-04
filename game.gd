extends Node

var _file = "user://savegame.json"
var state = {}

func _ready():
    load_state()
    
func _initial_state():
    return {}
    
func save_state() -> bool:
    var savegame = File.new()
    
    savegame.open(_file, File.WRITE)
    savegame.store_line(to_json(state))
    savegame.close()
    return true
    
func load_state() -> bool:
    var savegame = File.new()
    if not savegame.file_exists(_file):
        return false
    
    savegame.open(_file, File.READ)
    
    state = _initial_state()
    var new_state = parse_json(savegame.get_line())
    for key in new_state:
        state[key] = new_state[key]
    savegame.close()
    return true

# Run a simple command given as a string, blocking, using execute.
func run(command):
    print("run: "+command)
    var output = []
    OS.execute(command, [], true, output, true)
    # Remove trailing newline.
    return output[0].substr(0,len(output[0])-1)

func sh(command, wd="/tmp/"):
    print("sh in "+wd+": "+command)
    var cwd = game.run("pwd")
    var output = []
    
    var hacky_command = command
    hacky_command = "cd '"+wd+"';"+hacky_command
    hacky_command = "export EDITOR=fake-editor;"+hacky_command
    hacky_command = "export PATH=\"$PATH\":"+cwd+"/scripts;"+hacky_command
    OS.execute("/bin/sh", ["-c",  hacky_command], true, output, true)
    return output[0]
    
func script(filename, wd="/tmp/"):
    print("sh script in "+wd+": "+filename)
    var cwd = game.run("pwd")
    var output = []
    
    var hacky_command = "/bin/sh " + filename
    hacky_command = "cd '"+wd+"';"+hacky_command
    OS.execute("/bin/sh", ["-c", hacky_command], true, output, true)
    return output[0]

func read_file(path):
    print("read "+path)
    var file = File.new()
    file.open(path, File.READ)
    var content = file.get_as_text()
    file.close()
    return content

func write_file(path, content):
    var file = File.new()
    file.open(path, File.WRITE)
    file.store_string(content)
    file.close()
    return true

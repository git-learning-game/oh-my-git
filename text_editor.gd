extends TextEdit

var path

var _server
var _client_connection

func _ready():
	# Initialize TCP server for fake editor.
	_server = TCP_Server.new()
	_server.listen(1234)
	
func _process(_delta):
	if _server.is_connection_available():
		_client_connection = _server.take_connection()
		var length = _client_connection.get_u8()
		var filename = _client_connection.get_string(length)
		var regex = RegEx.new()
		filename = filename.replace("/tmp/active/", "")
		open(filename)
	
func open(filename):
	path = filename
	
	var fixme_path = game.tmp_prefix+"/active/"
	var content = game.read_file(fixme_path+filename, "[ERROR_FAKE_EDITOR]")
	if content == "[ERROR_FAKE_EDITOR]":
		push_error("Specified file could not be read.")
		get_tree().quit()
	text = content
	
	show()
	grab_focus()

func save():
	var fixme_path = game.tmp_prefix+"/active/"
	game.write_file(fixme_path+path, text)
	_client_connection.disconnect_from_host()
	text = ""
	hide()

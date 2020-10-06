extends TextEdit

signal saved

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
		filename = filename.replace("%srepos/" % game.tmp_prefix_inside, "")
		open(filename)
	
func open(filename):
	path = filename
	
	var fixme_path = game.tmp_prefix_outside+"repos/"
	var content = helpers.read_file(fixme_path+filename)
	text = content
	
	show()
	grab_focus()

func save():
	var fixme_path = game.tmp_prefix_outside+"repos/"
	
	# Add a newline to the end of the file if there is none.
	if text.length() > 0 and text.substr(text.length()-1, 1) != "\n":
		text += "\n"
	
	helpers.write_file(fixme_path+path, text)
	emit_signal("saved")
	close()

func close():
	if _client_connection.is_connected_to_host():
		_client_connection.disconnect_from_host()
	text = ""
	hide()

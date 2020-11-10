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
		var length = _client_connection.get_u32()
		var _filename = _client_connection.get_string(length)
		
		length = _client_connection.get_u32()
		var content = _client_connection.get_string(length)
		
		open(content)
		
func _input(event):
	if event.is_action_pressed("save"):
		save()
	
func open(content):
	text = content
	show()
	grab_focus()

func save():
	if visible:
		# Add a newline to the end of the file if there is none.
		if text.length() > 0 and text.substr(text.length()-1, 1) != "\n":
			text += "\n"
		
		_client_connection.put_string(text)
		
		emit_signal("saved")
		close()

func close():
	if _client_connection and _client_connection.is_connected_to_host():
		_client_connection.disconnect_from_host()
	text = ""
	hide()

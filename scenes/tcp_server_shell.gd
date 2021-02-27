extends Node

signal data_received(string)
signal new_connection

export var port: int

var _s = TCP_Server.new()
var _c
var _connected = false

func _ready():
	start()

func start():
	_s.listen(port)
		
func _process(_delta):
	if _s.is_connection_available():
		if _connected:
			_c.disconnect_from_host()
			helpers.crash("Dropping active connection")
		_c = _s.take_connection()
		_connected = true
		emit_signal("new_connection")
		print("connected!")
	
	if _connected:
		if _c.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			_connected = false
			print("disconnected")
#		var available = _c.get_available_bytes()
#		while available > 0:
#			var data = _c.get_utf8_string(available)
#			emit_signal("data_received", data)
#			available = _c.get_available_bytes()

func send(text):
	if _connected:
		_c.put_utf8_string(text)
		var response = _c.get_utf8_string()
		var exit_code = _c.get_u32()
		
		var shell_command = ShellCommand.new()
		shell_command.command = text
		shell_command.output = response
		#print("response:")
		#print(response)
		shell_command.exit_code = exit_code
		return shell_command
	else:
		helpers.crash("Trying to send data on closed connection")

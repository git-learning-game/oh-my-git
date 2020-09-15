extends Node

func _ready():
	pass

func data(s):
	print(s)


func send(new_text):
	print("sending "+new_text)
	$TCPServer.send(new_text)

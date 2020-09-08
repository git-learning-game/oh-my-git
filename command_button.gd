extends Button

export var async = false

func _ready():
	pass

func pressed():
	if async:
		$"../..".send_command_async(text)
	else:
		$"../..".send_command(text)

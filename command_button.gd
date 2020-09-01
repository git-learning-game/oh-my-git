extends Button

func _ready():
	pass


func pressed():
	$"..".send_command(text)

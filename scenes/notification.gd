extends Node2D

var text setget _set_text
var button_texts = [
	tr("GOT_IT"),
	tr("INTERESTING"),
	tr("VERY_USEFULL"),
	tr("COOL"),
	tr("NICE"),
	tr("THANKS"),
	tr("WHATEVER"),
	tr("OKAY"),
	tr("YAY"),
	tr("AWESOME") ]

func _ready():
	button_texts.shuffle()
	$Panel/CenterContainer/OK.text = button_texts[0]

#func _gui_input(event):
#	if event is InputEventMouseButton:
#		queue_free()

func _set_text(new_text):
	text = new_text
	$Panel/Label.text = new_text


func confirm():
	queue_free()

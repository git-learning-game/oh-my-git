extends Node2D

var text setget _set_text
var button_texts = [
	tr("Got it!"),
	tr("Interesting!"),
	tr("Very useful!"),
	tr("Cool!"),
	tr("Nice!"),
	tr("Thanks!"),
	tr("Whatever..."),
	tr("Okay!"),
	tr("Yay!"),
	tr("Awesome!") ]

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

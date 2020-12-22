extends PopupPanel

var text setget _set_text

func _ready():
	popup()

func _gui_input(event):
	if event is InputEventMouseButton:
		queue_free()

func _set_text(new_text):
	text = new_text
	$Label.text = new_text

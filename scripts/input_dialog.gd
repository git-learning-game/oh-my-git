extends Window

signal entered(text)

func _text_entered(text):
	emit_signal("entered", text)
	queue_free()

func _notification(what):
	pass
	#ToDo 
	#if what == Popup.NOTIFICATION_POST_POPUP:
	#	$LineEdit.grab_focus()

extends WindowDialog

signal entered(text)

func _text_entered(text):
	emit_signal("entered", text)
	queue_free()

func _notification(what):
	if what == Popup.NOTIFICATION_POST_POPUP:
		$LineEdit.grab_focus()

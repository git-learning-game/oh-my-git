extends Node
class_name ShellCommand

signal done

var command
var output
var exit_code
var crash_on_fail = true
var thread

func _unused():
	# This is just to suppress a warning about the signal never being emitted.
	emit_signal("done")

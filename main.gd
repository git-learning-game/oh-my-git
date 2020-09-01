extends Node2D

var dragged = null

var viewport_size

var server
var client_connection

func _ready():
	viewport_size = get_viewport_rect().size
	
	server = TCP_Server.new()
	server.listen(1234)
	
func _process(delta):
	if server.is_connection_available():
		client_connection = server.take_connection()
		read_commit_message()
#	if true or get_global_mouse_position().x < get_viewport_rect().size.x*0.7:
#		if Input.is_action_just_pressed("click"):
#			var mindist = 9999999
#			for o in objects.values():
#				var d = o.position.distance_to(get_global_mouse_position())
#				if d < mindist:
#					mindist = d
#					dragged = o
#		if Input.is_action_just_released("click"):
#				dragged = null
#		if dragged:
#			dragged.position = get_global_mouse_position()
	
	
func read_commit_message():
	$CommitMessage.show()
	$Terminal/Input.editable = false
	var file_path = "/tmp/githydragit/.git/COMMIT_EDITMSG"
	var file = File.new()
	file.open(file_path, File.READ)
	var content = file.get_as_text()
	file.close()
	$CommitMessage.text = content

func save_commit_message():
	var file = File.new()
	var file_path = "/tmp/githydragit/.git/COMMIT_EDITMSG"
	file.open(file_path, File.WRITE)
	var content = $CommitMessage.text
	file.store_string(content)
	file.close()
	print("disconnect")
	client_connection.disconnect_from_host()
	$Terminal/Input.editable = true
	$CommitMessage.text = ""
	$CommitMessage.hide()
		

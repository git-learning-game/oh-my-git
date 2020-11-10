extends Node2D

var hovered = false
var highlighted = false setget _set_highlighted

func _ready():
	_set_highlighted(false)
	
func _mouse_entered(_area):
	hovered = true
	var tween = Tween.new()
	tween.interpolate_property($Highlight/Sprite.material, "shader_param/hovered", 0, 1, 0.1, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	add_child(tween)
	tween.start()

func _mouse_exited(_area):
	hovered = false
	var tween = Tween.new()
	tween.interpolate_property($Highlight/Sprite.material, "shader_param/hovered", 1, 0, 0.1, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	add_child(tween)
	tween.start()
	
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and !event.pressed and hovered:
			if highlighted and game.dragged_object:
				game.dragged_object.dropped_on(get_parent_with_type())

func _set_highlighted(new_highlighted):
	highlighted = new_highlighted
	$Highlight.visible = highlighted
	
func get_parent_with_type():
	var parent = get_parent()
	while(!parent.get("type")):
		parent = parent.get_parent()
	return parent

func highlight(type):
	if get_parent_with_type().type == type:
		_set_highlighted(true)

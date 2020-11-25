extends Node2D

var hovered = false
var highlighted = false setget _set_highlighted
var dragged = false

func _ready():
	_set_highlighted(false)
	
func _process(delta):
	if dragged:
		if get_parent().type == "file":
			var diff = get_viewport().get_mouse_position() - get_parent().global_position
			get_parent().move(diff)
	
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
		if event.button_index == BUTTON_LEFT and !event.pressed:
			if dragged:
				for area in get_tree().get_nodes_in_group("drop_areas"):
					if area.hovered:
						if area.highlighted:
							get_parent_with_type().dropped_on(area.get_parent_with_type())
				_turn_off_highlights()
				dragged = false
				game.dragged_object = null				
			elif game.dragged_object and game.dragged_object.has_method("try_play"):
				if hovered and highlighted:
					game.dragged_object.dropped_on(get_parent_with_type())
			
		if event.button_index == BUTTON_LEFT and event.pressed and hovered:
			if not game.dragged_object:
				if get_parent().type == "file" and get_parent().item_type == "wd":
					dragged = true
					game.dragged_object = self
					_turn_on_highlights()

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
		
func _turn_on_highlights():
	var parent_type = get_parent_with_type().file_browser.type 
	var highlight_type = "inventory"
	if parent_type == "inventory":
		highlight_type = "world"
		
	for area in get_tree().get_nodes_in_group("drop_areas"):
		area.highlight(highlight_type)
		
func _turn_off_highlights():
	for area in get_tree().get_nodes_in_group("drop_areas"):
		area.highlighted = false

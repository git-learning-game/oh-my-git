extends TextureRect

export var active = true setget _set_active
export var sparkling = true setget _set_sparkling
export var impossible = false setget _set_impossible


func _ready():
	_set_sparkling(sparkling)

func _set_active(new_active):
	active = new_active
	if active:
		self.self_modulate = Color(1, 1, 1)
	else:
		self.self_modulate = Color(0.2, 0.2, 0.2)
		sparkling = false

func _set_sparkling(new_sparkling):
	sparkling = new_sparkling
	if $Particles2D:
		$Particles2D.emitting = sparkling
		
func _set_impossible(new_impossible):
	impossible = new_impossible
	$Nope.visible = impossible

extends Node2D

var text setget _set_text
var button_texts = [
	"notif_btn_got_it",
	"notif_btn_interesting",
	"notif_btn_very_useful",
	"notif_btn_cool",
	"notif_btn_nice",
	"notif_btn_thanks",
	"notif_btn_whatever",
	"notif_btn_okay",
	"notif_btn_yay",
	"notif_btn_awesome"
]

func _ready():
	var translated_button_texts = []
	for key in button_texts:
		translated_button_texts.push_back(tr(key))
	
	translated_button_texts.shuffle()
	$Panel/CenterContainer/OK.text = translated_button_texts[0]


#func _gui_input(event):
#	if event is InputEventMouseButton:
#		queue_free()

func _set_text(new_text):
	text = new_text
	$Panel/Label.text = new_text


func confirm():
	queue_free()

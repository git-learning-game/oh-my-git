extends Control

func _ready():
	get_tree().set_auto_accept_quit(true)

func quit():
	get_tree().quit()

func levels():
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")


func on_survey_pressed():
	game.open_survey()

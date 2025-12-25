extends Control

func _ready():
	if !OS.has_feature("standalone") and !game.skipped_title:
		game.skipped_title = true
		get_tree().change_scene("res://scenes/level_select.tscn")

	$Label2.text = tr("by bleeptrack & blinry")
	$Label3.text = tr("Original score by winniehell")
	$VBoxContainer/Button.text = tr("Levels")
	$VBoxContainer/Button3.text = tr("Sandbox")
	$VBoxContainer/Button2.text = tr("Quit")


func quit():
	get_tree().quit()

func levels():
	get_tree().change_scene("res://scenes/level_select.tscn")


func on_survey_pressed():
	game.open_survey()


func sandbox():
	game.current_chapter = levels.chapters.size() - 1
	game.current_level = levels.chapters[game.current_chapter].levels.size() -1
	get_tree().change_scene("res://scenes/main.tscn")

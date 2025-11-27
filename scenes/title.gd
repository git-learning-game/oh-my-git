extends Control

func _ready():
	if !OS.has_feature("standalone") and !game.skipped_title:
		game.skipped_title = true
		get_tree().change_scene("res://scenes/level_select.tscn")
	
	$Label2.text = game.tr_custom("title_label2_007")
	$Label3.text = game.tr_custom("title_label3_008")
	$VBoxContainer/Button.text = game.tr_custom("title_button_009")   # Кнопка Levels
	$VBoxContainer/Button3.text = game.tr_custom("title_button3_010") # Кнопка Sandbox
	$VBoxContainer/Button2.text = game.tr_custom("title_button2_011") # Кнопка Quit


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

extends Control

onready var popup = $VBoxContainer/Language

func _ready():
	if !OS.has_feature("standalone") and !game.skipped_title:
		game.skipped_title = true
		get_tree().change_scene("res://scenes/level_select.tscn")
	
	make_popup_item()

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


func uncheck_all_item():
	# Set all item unchecked
	var num = popup.get_popup().get_item_count()
	for n in num:
		popup.get_popup().set_item_checked(n, false)
	pass


func make_popup_item():
	popup.get_popup().add_radio_check_item("en_EN", 0)
	popup.get_popup().add_radio_check_item(tr("it_IT"), 1)
	
	uncheck_all_item()
	
	if game.lang == "en_EN":
		popup.get_popup().set_item_checked(0, true)
	elif game.lang == "it_IT":
		popup.get_popup().set_item_checked(1, true)
	
	popup.get_popup().connect("id_pressed", self, "_on_item_pressed")


func _on_item_pressed(id):
	uncheck_all_item()
	
	popup.get_popup().set_item_checked(id, true)
	game.lang = popup.get_popup().get_item_text(id)

	
	TranslationServer.set_locale(game.lang)
	# DELETE ME
	print(popup.get_popup().get_item_text(id))
	print(game.lang)

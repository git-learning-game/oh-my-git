extends Control

onready var popup = $VBoxContainer/Language

func _ready():
	check_correct_lang_item()
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


# Check the apropriate locale
func check_correct_lang_item():
	for i in game.langs.keys():
		if game.lang == game.langs[i]:
			popup.get_popup().set_item_checked(i, true)

# Set all items to unchecked
func uncheck_all_item():
	for i in game.langs.keys():
		popup.get_popup().set_item_checked(i, false)


# Create popup items width allowed locales
func make_popup_item():
	for i in game.langs.keys():
		popup.get_popup().add_radio_check_item(game.langs[i], i)
	
	uncheck_all_item()
	
	check_correct_lang_item()
	
	popup.get_popup().connect("id_pressed", self, "_on_item_pressed")


# Change the translations and localizations of the cards and strings
func _on_item_pressed(id):
	uncheck_all_item()
	
	popup.get_popup().set_item_checked(id, true)
	game.lang = popup.get_popup().get_item_text(id)

	
	TranslationServer.set_locale(game.lang)
	

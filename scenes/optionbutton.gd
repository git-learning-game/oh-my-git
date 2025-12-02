extends OptionButton

	
func _ready():
	var languages = game.get_available_languages()
	
	for i in range(languages.size()):
		var locale = languages[i]
		add_item(_get_language_name(locale), i)
		set_item_metadata(i, locale)
	
	_select_current_language()
	
	connect("item_selected", self, "_on_language_selected")


func _select_current_language():
	var current = TranslationServer.get_locale()
	for i in range(get_item_count()):
		if get_item_metadata(i) == current:
			select(i)
			break

func _on_language_selected(index: int):
	var selected_language = get_item_metadata(index)
	game.change_language(selected_language)

func _get_language_name(locale: String) -> String:
	return tr(locale)


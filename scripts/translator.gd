extends Node

# Свойство, которое нужно перевести (например, "text" или "window_title")
export var property_to_translate : String = "text"

func _ready():
	var parent = get_parent()
	if not parent:
		return

	# Проверяем, существует ли у родителя такое свойство
	if parent.get(property_to_translate) != null:
		# Получаем ключ из свойства
		var key = parent.get(property_to_translate)
		
		# Переводим ключ с помощью нашей глобальной функции
		var translated_text = game.tr_custom(key)
		
		# Устанавливаем переведенный текст обратно в свойство
		parent.set(property_to_translate, translated_text)

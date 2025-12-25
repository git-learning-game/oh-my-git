extends HBoxContainer

signal back_pressed
signal reload_pressed
signal cards_toggle_pressed
signal new_tip_pressed
signal next_level_pressed
signal hide_cli
signal hide_next_level

export var show_next_level_button = true
export var show_cli_badge = true

func _ready():
	$NextLevelButton.visible = show_next_level_button
	$CLIBadge.visible = show_cli_badge

	$BackButton.text = tr("Back")
	$ReloadButton2.text = tr("Reload")
	$CardsButton.text = tr("Cards!")
	$"Tip!".text = tr("Tip!")
	$Button3.text = tr("Toggle music")
	$NextLevelButton.text = tr("Next level")

func _on_BackButton_pressed():
	emit_signal("back_pressed")

func _on_ReloadButton2_pressed():
	emit_signal("reload_pressed")

func _on_Tip_pressed():
	emit_signal("new_tip_pressed")

func _on_CardsButton_pressed():
	emit_signal("cards_toggle_pressed")

func _on_NextLevelButton_pressed():
	emit_signal("next_level_pressed")


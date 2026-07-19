extends Control

const MAIN_PATH: String = "res://UI/Menus/MainMenu/MainMenu.tscn"

func _ready() -> void:
	# Skip if running in debug or as headless
	if (DisplayServer.get_name() == "headless"):
		get_tree().change_scene_to_file.call_deferred(MAIN_PATH)
		return
	
	# Ask the Ezcha website to authenticate us
	var authenticated: bool = await Ezcha.client.authenticate()
	print("auth:", authenticated)
	# Check if authentication was successful
	if (authenticated || OS.is_debug_build()):
		get_tree().change_scene_to_file.call_deferred(MAIN_PATH)
	else:
		printerr("Authentication failed.")

extends Control

func _ready():
	MM.play_music.rpc(MM.Track.STUFF)
	
	var buttons:Array[Node] = $VBoxContainer.get_children()
	for i:int in range(buttons.size()):
		var button:Button = buttons[i]
		button.modulate = Color("#797979")

		#Button look behavior
		button.mouse_entered.connect(button.grab_focus)
		button.focus_entered.connect(func(): 
			button.get_node("RichTextLabel").add_theme_font_size_override("normal_font_size", 36)
			button.modulate = Color("#FFFFFF")
			$Icon.global_position = button.global_position + Vector2(-80,2)
			)
		button.focus_exited.connect(func(): 
			button.get_node("RichTextLabel").add_theme_font_size_override("normal_font_size", 30)
			button.modulate = Color("#797979")
			)
			
		match i:
			0:
				button.grab_focus()
				button.pressed.connect(func(): get_tree().change_scene_to_file("res://Main/Lobby/Lobby.tscn"))
				
			1:
				button.pressed.connect(func(): get_tree().change_scene_to_file("res://UI/Menus/Other/Controls.tscn"))
			2:
				button.pressed.connect(func(): get_tree().change_scene_to_file("res://UI/Menus/Other/Credits.tscn"))
			3:
				button.pressed.connect(func(): get_tree().quit())

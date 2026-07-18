extends Button

func _ready()->void:
	self.grab_focus()
	self.pressed.connect(func(): get_tree().change_scene_to_file("res://UI/Menus/MainMenu/MainMenu.tscn"))
	
	#Button look behavior
	self.mouse_entered.connect(self.grab_focus)
	self.focus_entered.connect(func(): 
		self.get_node("RichTextLabel").add_theme_font_size_override("normal_font_size", 36)
		self.modulate = Color("#FFFFFF")
		)
	self.focus_exited.connect(func(): 
		self.get_node("RichTextLabel").add_theme_font_size_override("normal_font_size", 30)
		self.modulate = Color("#797979")
		)
		

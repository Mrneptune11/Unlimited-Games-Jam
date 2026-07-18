extends Button

func _ready()->void:
		#Button look behavior
	self.focus_entered.connect(func(): 
		self.get_node("RichTextLabel").add_theme_font_size_override("normal_font_size", 36)
		self.modulate = Color("#FFFFFF")
		)
	self.focus_exited.connect(func(): 
		self.get_node("RichTextLabel").add_theme_font_size_override("normal_font_size", 30)
		self.modulate = Color("#797979")
		)
		

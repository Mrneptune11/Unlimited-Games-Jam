class_name EntryBox extends PanelContainer

#This class could be expanded for text entry events

@onready var my_button:Button = $HBox/Button ##Submit Button
@onready var my_entry:LineEdit = $HBox/Entry ##line entry

#Set up function gives entry box the necessary info to operate
func set_up(to_call:Callable, max_length:int = 9, prompt:String = "", start_text:String ="")->void:
	my_button.pressed.connect(to_call)
	$HBox/NameLabel.text = prompt
	my_entry.text = start_text
	my_entry.max_length = max_length
	
	var color:Color = Color(get_tree().current_scene.get_player(multiplayer.get_unique_id()).color_id)
	get_theme_stylebox("panel").bg_color = color
	my_button.add_theme_color_override("font_focus_color", color)
	my_button.focus_entered.connect(func():
		my_button.add_theme_font_size_override("font_size", 36))
	my_button.focus_exited.connect(func():
		my_button.add_theme_font_size_override("font_size", 30))
	
	
	
	

func _ready()->void:
	my_entry.grab_focus()

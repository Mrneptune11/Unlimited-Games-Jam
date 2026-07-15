class_name EntryBox extends PanelContainer

#This class could be expanded for text entry events

@onready var my_button:Button = $HBox/Button ##Submit Button
@onready var my_entry:LineEdit = $HBox/Entry ##line entry

func set_up(to_call:Callable, prompt:String = "", start_text:String ="")->void:
	my_button.pressed.connect(to_call)
	$HBox/NameLabel.text = prompt
	my_entry.text = start_text

func _ready()->void:
	my_entry.grab_focus()

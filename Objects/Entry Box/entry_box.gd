class_name EntryBox extends PanelContainer

#This class could be expanded for text entry events

@onready var my_button:Button = $HBox/Button ##Submit Button
@onready var my_entry:LineEdit = $HBox/Entry ##line entry

func _ready()->void:
	my_entry.grab_focus()
	my_button.pressed.connect(queue_free)

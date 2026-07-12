class_name EntryBox extends PanelContainer

@onready var my_button:Button = $HBox/Button
@onready var my_entry:LineEdit = $HBox/Entry

func _ready()->void:
	my_button.pressed.connect(queue_free)

## A timed, usually hazardous event.
## Extend this script with your specific event's functionality.
extends Node2D
class_name Event

## Emits when the event begins.
@warning_ignore("unused_signal")
signal started()

## Emits when this event fully finishes.
@warning_ignore("unused_signal")
signal finished()

## The text to display at the start of the event.
## This typically describes what will happen during the event.
@export_multiline var description: String

## The time (in seconds) that the event lasts for.
@export_range(0.0, 120.0, 1.0, "or_greater") var duration_sec: float

@onready var event_timer: Timer = %EventTimer

## Start the event.
## Sub-classed Events should append this function with their own logic.
func _ready() -> void:
	started.emit()
	
	# TODO: Ask EventManager to display description.
	
	event_timer.start(duration_sec)
	
	print("Event started!")

func _on_event_timer_timeout() -> void:
	finished.emit()
	
	print("Event finished!")
	
	queue_free()

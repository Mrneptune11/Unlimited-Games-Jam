extends Node

class Event:
	var id: StringName
	var weight:int = 1

const EVENT_LIST:Array[Event] = preload("res://Data/events.json").data
var event_weights:Array[int] = []

func _ready() -> void:
	event_weights = prep_weights(EVENT_LIST)

func prep_weights(events:Array[Event])->Array[int]:
	var return_arr:Array[int]

	for i:int in range(events.size()):
		return_arr.append(EVENT_LIST[i].weight)
	return return_arr

func choose_event(events:Array[Event],weights:Array[int])->Event:
	var rng:RandomNumberGenerator = RandomNumberGenerator.new()
	return(events[rng.rand_weighted(weights)])

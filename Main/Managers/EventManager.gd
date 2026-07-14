extends Node

class EventData:
	var id: StringName
	var weight:float = 1.0
	
	func _init(new_id:StringName, new_weight:int) -> void:
		id = new_id
		weight = new_weight

var EVENT_DICT:Array = preload("res://Data/events.json").data
var event_list:Array[EventData] = []
var event_weights:Array[float] = []

func _ready() -> void:
	prep_events(EVENT_DICT)
	
func prep_events(events:Array)->void:
	for i:int in range(events.size()):
		var event:Dictionary = events[i]
		event_list.append(EventData.new(event.id,event.weight))
		event_weights.append(events[i].weight)

func choose_event(events:Array[EventData],weights:Array[float])->EventData:
	var rng:RandomNumberGenerator = RandomNumberGenerator.new()
	return(events[rng.rand_weighted(weights)])

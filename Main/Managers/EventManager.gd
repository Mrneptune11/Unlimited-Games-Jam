extends Node

#-------------------------------------------------------------------------------

#Inner class for event data

class EventData:
	var id: StringName
	var weight:float = 1.0
	
	func _init(new_id:StringName, new_weight:int) -> void:
		id = new_id
		weight = new_weight

#-------------------------------------------------------------------------------

#Globals

var EVENT_DICT:Array = preload("res://Data/events.json").data
var event_list:Array[EventData] = []
var event_weights:Array[float] = []

#-------------------------------------------------------------------------------

#Lifecycle

func _ready() -> void:
	prep_events(EVENT_DICT)

#-------------------------------------------------------------------------------

#Event logic 

func prep_events(events:Array)->void:
	for i:int in range(events.size()):
		var event:Dictionary = events[i]
		event_list.append(EventData.new(event.id,event.weight))
		event_weights.append(events[i].weight)

func choose_event(events:Array[EventData] = event_list,weights:Array[float] = event_weights)->EventData:
	var rng:RandomNumberGenerator = RandomNumberGenerator.new()
	return(events[rng.rand_weighted(weights)])
	
	
func match_event(event_id:StringName, lobby:Lobby):
	var event_text:String = ""
	var event_call:Callable
	
	match event_id:
		"print_hi":
			event_call = func(): return "No event! Just wanted to say hi ╰(*°▽°*)╯"
		"print_buh":
			event_call = func(): return "No event! Just wanted to say I hate you all (ㆆ_ㆆ)"
		"name_change":
			event_call = name_change.bind(lobby)
		"someone_explode":
			event_call = someone_explode.bind(lobby)
		_:
			event_call = func(): return "ERROR: Event " + event_id + " not found."
	
	event_text = event_call.call()
	lobby.get_node("UI").update_event_terminal(event_text)
	
#-------------------------------------------------------------------------------

#Event calls

func name_change(lobby:Lobby)->String:
		var subject:Player = lobby.get_player(lobby.pick_rand_contestant())
		var return_str:String = lobby.get_player_color_string(subject, subject.player_name + "'s") + " name is now" + \
		lobby.get_player_color_string(subject," Joshy") +"."
		
		subject.set_player_name.rpc("Joshy")
		return return_str

func someone_explode(lobby:Lobby)->String:
	var contestant:int = lobby.pick_rand_contestant()
	var subject:Player = lobby.get_player(contestant)
	subject.explode.rpc_id(contestant)
	lobby.contestants.erase(contestant)
	return lobby.get_player_color_string(subject) + " has been smited by a higher being."
		

extends Node

signal event_complete #singal used to indicate an event is finished

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

const EVENT_DICT:Array = preload("res://Data/events.json").data
const NAME_DICT:Array = preload("res://Data/epic_names.json").data

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
			event_call = func(): 
				end_event_by_timer(3)
				return "No event! Just wanted to say hi ╰(*°▽°*)╯"
		"print_buh":
			event_call = func(): 
				end_event_by_timer(3)
				return "No event! Just wanted to say I hate you all (ㆆ_ㆆ)"
		"name_change":
			event_call = name_change.bind(lobby)
		"someone_explode":
			event_call = someone_explode.bind(lobby)
		"color_change":
			event_call = color_change.bind(lobby)
		"os_check":
			event_call = os_check.bind(lobby)
		_:
			event_call = func(): return "ERROR: Event " + event_id + " not found."
	
	event_text = event_call.call()
	lobby.get_node("UI").update_event_terminal(event_text)


func end_event_by_timer(time:float)->void:
	get_tree().create_timer(time).timeout.connect(event_complete.emit)
	
#-------------------------------------------------------------------------------

#Event calls

func name_change(lobby:Lobby)->String:
	var new_name:String = NAME_DICT.pick_random()
	
	var subject:Player = lobby.get_player(lobby.pick_rand_contestant())
	var return_str:String = lobby.get_player_color_string(subject, subject.player_name + "'s") + " name is now" + \
	lobby.get_player_color_string(subject," " + new_name) +"."
	
	end_event_by_timer(3)
	
	subject.set_player_name.rpc(new_name)
	return return_str

func someone_explode(lobby:Lobby)->String:
	var contestant:int = lobby.pick_rand_contestant()
	var subject:Player = lobby.get_player(contestant)
	subject.explode.rpc_id(contestant)
	
	end_event_by_timer(3)
	
	return lobby.get_player_color_string(subject) + " has been smited by a higher being."

func color_change(lobby:Lobby)->String:
	var subject:Player = lobby.get_player(lobby.pick_rand_contestant())
	var new_color:StringName = lobby.gen_id()
	subject.update_color.rpc(new_color)
	
	end_event_by_timer(3)
	
	return lobby.get_player_color_string(subject) + "'s color has been changed to " + "[color=" + str(new_color) + "]" + \
	new_color + "[/color]."


func os_check(lobby:Lobby)->String:
	var os_dict:Dictionary[String,String] ={
		"windows" : "Windows",
		"linux" : "Linux",
		"macos" : "macOS",
	}
	var os:String = os_dict.keys().pick_random()
	
	for contestant:int in lobby.contestants:
		check_banned_os.rpc_id(contestant, os, contestant)
			
	end_event_by_timer(3)
	
	return "Anyone running " + os_dict[os] + " explodes for being wrong."
	
#-------------------------------------------------------------------------------

#Event helpers

@rpc("authority", "call_local", "reliable")
func check_banned_os(os:String, contestant:int)->void:
	var subject:Player = get_tree().current_scene.get_player(contestant)
	if OS.has_feature(os):
		subject.explode.rpc_id.call_deferred(contestant)
		

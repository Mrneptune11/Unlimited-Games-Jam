extends Node

# Event-specific Parameters

# ---------- Fireballs ----------

## How long (in seconds) the Fireballs event lasts for.
const _FIREBALLS_EVENT_DURATION: float = 10.0

## Reference to the Fireball Spawner scene.
const _FIREBALLS_EVENT_SPAWNER_SCENE: PackedScene = preload("res://Events/Fireballs/FireballSpawner.tscn")

# ---------- Bouncy Balls ----------

## How long (in seconds) the Bouncy Balls event lasts for.
const _BOUNCY_BALLS_EVENT_DURATION: float = 20.0

## Reference to the Ball Spawner scene.
const _BOUNCY_BALLS_EVENT_SPAWNER_SCENE: PackedScene = preload("res://Events/BouncyBalls/BallSpawner.tscn")

# ---------- Lava ----------

## AFTER the lava has reached its max height, how long to wait before ending the event.
const _LAVA_EVENT_WAIT_DURATION: float = 7.0

## Reference to the Lava scene.
const _LAVA_EVENT_SCENE: PackedScene = preload("res://Events/Lava/Lava.tscn")

# ---------- Weapon Fights ----------

#Ref to gun scene
const GUN_SCN:String =  "res://Objects/Weapons/Gun/Gun.tscn"
const SWORD_SCN:String = "res://Objects/Weapons/Sword/sword.tscn"

# ---------- Kamikaze ----------

## Reference to the Bomb scene.
const _BOMB_WEAPON_SCENE: String = "res://Objects/Weapons/Bomb/Bomb.tscn"

#-------------------------------------------------------------------------------

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
const WORDS:Array[String] = preload("res://Data/words.json").data
const TRIVIA:Array[Dictionary] = preload("res://Data/questions.json").data

var event_list:Array[EventData] = []
var event_weights:Array[float] = []

var completed_goal:Dictionary[int,float] = {} #Tracks players that complete a given event goal
var goal_completed:bool = false #used to track goal state on a given event

#-------------------------------------------------------------------------------

#Lifecycle

func _ready() -> void:
	prep_events(EVENT_DICT)

#-------------------------------------------------------------------------------

#Event logic 

#Loads json data and creates the global banks for events and their weights
func prep_events(events:Array)->void:
	for i:int in range(events.size()):
		var event:Dictionary = events[i]
		event_list.append(EventData.new(event.id,event.weight))
		event_weights.append(events[i].weight)

#Chooses an event based on their weights
func choose_event(events:Array[EventData] = event_list,weights:Array[float] = event_weights)->EventData:
	var rng:RandomNumberGenerator = RandomNumberGenerator.new()
	return(events[rng.rand_weighted(weights)])
	
#Handles executing the logic tied to a given event
func match_event(event_id:StringName, lobby:Lobby):
	var event_text:String = ""
	var event_call:Callable
	
	#Given event ID is matched with a callable and updates the event terminal text accordingly
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
		"owe_money":
			event_call = owe_money.bind(lobby)
		"increase_size":
			event_call = change_size.bind(lobby, 1)
		"decrease_size":
			event_call = change_size.bind(lobby, -1)
		"fireballs":
			event_call = fireballs.bind(lobby)
		"bouncy_balls":
			event_call = bouncy_balls.bind(lobby)
		"lava":
			event_call = lava.bind(lobby)
		"gun_fight":
			event_call = weapon_fight.bind(lobby, GUN_SCN, "guns")
		"sword_fight":
			event_call = weapon_fight.bind(lobby, SWORD_SCN, "katanas")
		"kamikaze":
			event_call = kamikaze.bind(lobby)
		"spelling_bee": 
			event_call = spelling_bee.bind(lobby)
		"trivia_time": 
			event_call = trivia_time.bind(lobby)
		_:
			event_call = func(): return "ERROR: Event " + event_id + " not found." #Event id not recognized during match
	
	#After matching, the event is run and returns the terminal text
	event_text = event_call.call()
	lobby.get_node("UI").update_event_terminal(event_text)

#Helper func used to streamline ending events that are solely time based
func end_event_by_timer(time:float)->void:
	get_tree().create_timer(time).timeout.connect(event_complete.emit)
	
#-------------------------------------------------------------------------------

#Event calls

#A random players name is changed to a random name from a json file
func name_change(lobby:Lobby)->String:
	var new_name:String = NAME_DICT.pick_random()
	
	var subject:Player = lobby.get_player(lobby.pick_rand_contestant())
	var return_str:String = lobby.get_player_color_string(subject, subject.player_name + "'s") + " name is now" + \
	lobby.get_player_color_string(subject," " + new_name) +"."
	
	end_event_by_timer(3)
	
	subject.set_player_name.rpc(new_name)
	return return_str

# A random player is "smited" (explodes)
func someone_explode(lobby:Lobby)->String:
	var contestant:int = lobby.pick_rand_contestant()
	var subject:Player = lobby.get_player(contestant)
	subject.explode.rpc_id(contestant)
	
	end_event_by_timer(3)
	
	return lobby.get_player_color_string(subject) + " has been smited by a higher being."

#A random player is changed to a random color (Note there is no duplicate color validation as of now)
func color_change(lobby:Lobby)->String:
	var subject:Player = lobby.get_player(lobby.pick_rand_contestant())
	var new_color:StringName = lobby.gen_id()
	subject.update_color.rpc(new_color)
	
	end_event_by_timer(3)
	
	return lobby.get_player_color_string(subject, subject.player_name + "'s") + " color has been changed to " + \
	"[color=" + str(new_color) + "]" + new_color + "[/color]."


#OS checks are performed across all peers, and if players have a randomly drawn os they explode
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

#A random player is selected as the reason another player explodes and owes them money in real life for real legally binding
func owe_money(lobby:Lobby)->String:
	var dup_contestants:Array[int] = lobby.contestants.duplicate_deep()
	var owe_con:int = dup_contestants.pick_random()
	dup_contestants.erase(owe_con)
	var ded_con:int = dup_contestants.pick_random()
	
	var ded_subject:Player = lobby.get_player(ded_con)
	var owe_subject:Player = lobby.get_player(owe_con)
	ded_subject.explode.rpc_id(ded_con)
	
	end_event_by_timer(4)
	
	return lobby.get_player_color_string(owe_subject) + " owes " + lobby.get_player_color_string(ded_subject) + \
	 " $2 in real life for exploding them with their mind."

#Changes the size of a random contestant
func change_size(lobby:Lobby, change:int) -> String:
	var contestant:int = lobby.pick_rand_contestant()
	var subject:Player = lobby.get_player(contestant)
	subject.change_size.rpc_id(contestant, change)
	end_event_by_timer(3)
	
	if change > 0:
		return lobby.get_player_color_string(subject) + " has increased in size! Don't get too big now..."

	return lobby.get_player_color_string(subject) + " has decreased in size! Don't get too small now..."

func fireballs(lobby:Lobby)->String:
	# Setup Fireball Spawner node.
	# This will generate a constant flurry of fireballs until the node is deleted.
	fireballs_helper.rpc()
	
	# Then, set the event timer.
	end_event_by_timer(_FIREBALLS_EVENT_DURATION)
	
	# Get random contestant name for return String.
	var rand_contestant_id: int = lobby.contestants.pick_random()
	var rand_subject: Player = lobby.get_player(rand_contestant_id)
	var rand_subject_name: String = lobby.get_player_color_string(rand_subject, rand_subject.player_name + "'s")
	
	return "Fireballs are raining down from the sky. This is " + rand_subject_name + " fault somehow."

func bouncy_balls(_lobby:Lobby)->String:
	# Setup Ball Spawner node.
	# This will continuousely spawn bouncy balls until the node is deleted.
	bouncy_balls_helper.rpc()
	
	# Then, set the event timer.
	end_event_by_timer(_BOUNCY_BALLS_EVENT_DURATION)
	
	return "The circus is dropping bouncy balls everywhere!"

## Spawns lava, which slowly rises upward and kills any players who touch it.
## Uses the Lobby node's HazardSpawner to sync server & client.
func lava(lobby:Lobby)->String:
	var lava_scene: Lava = _LAVA_EVENT_SCENE.instantiate()
	lobby.add_child(lava_scene)
	
	# When the lava reaches its max height, wait for a moment before finishing the event.
	lava_scene.max_height_reached.connect(end_event_by_timer.bind(_LAVA_EVENT_WAIT_DURATION))
	
	# When the event timer expires, destroy the lava.
	event_complete.connect(lava_scene.queue_free)
	
	return "Corrupted data is is rising upward! Get to higher ground!"

#Begins a gun fight between two random players
func weapon_fight(lobby:Lobby, weapon_path:String, weapon_type:String)->String:
	for contestant in lobby.contestants:
		print(lobby.get_player(contestant))
	
	#Pick two different rand contestants
	var dup_contestants:Array[int] = lobby.contestants.duplicate_deep()
	var first_con:int = dup_contestants.pick_random()
	dup_contestants.erase(first_con)
	var second_con:int = dup_contestants.pick_random()
	
	var first_player:Player = lobby.get_player(first_con)
	var second_player:Player = lobby.get_player(second_con)
	
	#Equip their guns
	first_player.equip_weapon.rpc(weapon_path,second_con, first_con)
	second_player.equip_weapon.rpc(weapon_path,first_con, second_con)
	
	first_player.duel_complete.connect(grace_period, CONNECT_ONE_SHOT) #End event when the duel terminates
	
	return lobby.get_player_color_string(first_player) +" and " + lobby.get_player_color_string(second_player) + " must duel " +  \
	" to the death with " + weapon_type + "! Don't hurt any bystanders though..."

## Give a random player a bomb, which will explode after a couple seconds.
func kamikaze(lobby:Lobby)->String:
	# Pick a random contestant to become a kamikaze.
	var victim_con: int = lobby.contestants.pick_random()
	var victim_player: Player = lobby.get_player(victim_con)
	
	# Equip the player with a bomb.
	victim_player.equip_weapon.rpc(_BOMB_WEAPON_SCENE, victim_con, victim_con)
	
	# When the bomb explodes, the "duel" will complete & end the event shortly after.
	victim_player.duel_complete.connect(grace_period, CONNECT_ONE_SHOT) #End event when the duel terminates
	
	return lobby.get_player_color_string(victim_player) + " has been gifted a bomb. Take out as many other contestants with you as possible!"

#Prompt players to submit an answer as quick as they can 
func spelling_bee(lobby:Lobby)->String:
	completed_goal.clear() #clear old contestant data
	goal_completed = false # goal state not reached
	
	var word:String = WORDS.pick_random() #Random word to spell
	var lobby_path:NodePath = lobby.get_path()
	
	#All contestants have to spell the word
	for contestant:int in lobby.contestants:
		text_prompt.rpc_id(contestant,lobby_path, "spelling_bee", 40, word, "")
		
	#Tme limit for the spelling bee
	var timer:SceneTreeTimer = get_tree().create_timer(10) 
	lobby.get_node("UI").active_timer = timer
	timer.timeout.connect(eval_completion.bind(completed_goal,lobby_path))

	return "Time for a spelling bee! Last to answer explodes!"

func trivia_time(lobby:Lobby)->String:
	var trivia:Dictionary = TRIVIA.pick_random()
	var lobby_path:NodePath = lobby.get_path()
	
		#All contestants have to spell the word
	for contestant:int in lobby.contestants:
		text_prompt.rpc_id(contestant,lobby_path, "trivia_time", 1, trivia["answer"], "",trivia)
	
	return "Trivia time! Answer correctly or you explode."
#-------------------------------------------------------------------------------

#Event helpers

##--Ball Events--

## Helper function for the Fireballs event.
## Using RPC allows the event node to be instantiated on both the server & clients.
@rpc("authority", "call_local", "reliable")
func fireballs_helper()->void:
	var fireball_spawner: FireballSpawner = _FIREBALLS_EVENT_SPAWNER_SCENE.instantiate()
	get_tree().current_scene.add_child(fireball_spawner)
	
	# When the event timer expires, destroy the node to stop spawning fireballs.
	event_complete.connect(fireball_spawner.queue_free)

## Helper function for the Bouncy Balls event.
## Using RPC allows the event node to be instantiated on both the server & clients.
@rpc("authority", "call_local", "reliable")
func bouncy_balls_helper()->void:
	var ball_spawner: BallSpawner = _BOUNCY_BALLS_EVENT_SPAWNER_SCENE.instantiate()
	get_tree().current_scene.add_child(ball_spawner)
	
	# When the event timer expires, destroy the node to stop spawning balls.
	event_complete.connect(func(): 
		if ball_spawner:
			ball_spawner.spawning = false)

##--OS Events--

#RPC call used to check the operating systems of a give peer, and explode them if necessary
@rpc("authority", "call_local", "reliable")
func check_banned_os(os:String, contestant:int)->void:
	var subject:Player = get_tree().current_scene.get_player(contestant)
	if OS.has_feature(os):
		subject.explode.rpc_id.call_deferred(contestant)

##--Weapon Events--

#Grace period after a weapon fight ends helper, emits event complete cond
func grace_period()->void:
	await get_tree().create_timer(2).timeout
	event_complete.emit()

##--Text Prompt Events--

#Sends a text prompt to players
@rpc("authority", "call_local", "reliable")
func text_prompt(lobby_path:NodePath, to_call:String, max_length:int, word:String, start_text:String = "", 
		misc_data:Dictionary = {})->void:
	#Set up information
	var caller:Callable 
	var prompt:String = ""
	
	#Create the entry box
	var entry_box:EntryBox = preload("res://Objects/Entry Box/EntryBox.tscn").instantiate()
	get_node("/root/Lobby/UI").add_child(entry_box)
	var start_time = Time.get_ticks_usec() #Start tracking how long a peer takes to answer
	
	var lobby:Lobby = get_node(lobby_path)
	
	#Pause the player
	var player:Player = lobby.get_player(multiplayer.get_unique_id())
	player.mode = player.Mode.PAUSE
	
	#handle what completion function to call
	match to_call:
		"spelling_bee":
			prompt = "Type the word: " + word
			
			caller = (func(entry_path:NodePath, solution:String):
				var text_box:EntryBox = get_node(entry_path)
				if text_box.get_node("HBox").get_node("Entry").text.to_lower() !=  solution: return #Check correct solution
				
				EM.goal_complete.rpc_id(1,Time.get_ticks_usec() - start_time, lobby_path) #Client tells host they completed the goal
				player.mode = player.Mode.PLAY #Player can play again
				text_box.queue_free() #entry box is removed
				)
		"trivia_time":
			prompt = misc_data["question"] + "\n A: " + misc_data["A"] + "| B: " + misc_data["B"] + \
			"| C: " + misc_data["C"] + "| D: " + misc_data["D"]
			
			var timer:SceneTreeTimer = get_tree().create_timer(10) 
			timer.timeout.connect(player.explode)
		
			if multiplayer.is_server():
				lobby.get_node("UI").active_timer = timer
				timer.timeout.connect(grace_period)

			caller = (func(entry_path:NodePath, solution:String):
				var text_box:EntryBox = get_node(entry_path)
				if text_box.get_node("HBox").get_node("Entry").text.to_upper() !=  solution:  #Check correct solution
					player.explode()
				else:
					timer.timeout.disconnect(player.explode)
					player.mode = player.Mode.PLAY #Player can play again
					text_box.queue_free() #entry box is removed
				)
		_:
			printerr("valid text prompt callable not found")
	
	#Set up the entry box correctly
	entry_box.set_up(caller.bind(entry_box.get_path(),word), max_length, prompt, start_text)
	
@rpc("any_peer", "call_local", "reliable")
func goal_complete(time:float, lobby_path:NodePath)->void: 
	if !multiplayer.is_server(): return #Only the server handles goal complete logic
	
	#Which peer pinged the server
	var peer:int = multiplayer.get_remote_sender_id()
	completed_goal[peer] =  time
	 
	#Case where all peers complete a goal
	if completed_goal.size() >= get_node(lobby_path).contestants.size():
		print("All players reached goal complete")
		eval_completion(completed_goal,lobby_path)
		

#Evaluates all peers performance on a goal
func eval_completion(completed:Dictionary[int, float], lobby_path:NodePath)->void:
	var contest:Array[int] = get_node(lobby_path).contestants
	
	if !goal_completed: #Prevent running multiple times
		
		#Delete any peers who did not finish a goal in time
		if completed_goal.size() < contest.size():
			var unfinished:Array[int] = contest.duplicate_deep().filter( \
					func(item:int): 
						if !completed_goal.keys().has(item): 
							return item
			)
			
			for peer:int in unfinished:
				get_node(lobby_path).get_player(peer).explode.rpc_id(peer)
		
		#Delete the peer who finished the goal last
		else:
			var slowest_peer:int = -1
			var slowest_time:float = 0.0
			
			for peer:int in completed.keys():
				var test_time:float = completed[peer]
				if test_time >= slowest_time:
					slowest_time = test_time
					slowest_peer = peer
			
			var slowest_player:Player = get_node(lobby_path).get_player(slowest_peer)
			if slowest_peer == 1:
				slowest_player.explode()
			else:
				slowest_player.explode.rpc_id(slowest_peer)
	
	goal_completed = true #Goal complete lock
	
	await get_tree().create_timer(3).timeout #Grace period and event completion emitted
	event_complete.emit()
	

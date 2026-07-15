class_name Lobby extends Node2D

#-------------------------------------------------------------------------------

#enum used to prevent new server joins
enum State {
	MATCH = 0,
	LOBBY = 1,
	UNINIT = 2,
}

#Current status of the server
var server_status:State = State.UNINIT:
	set(value):
		match value:
			State.LOBBY:
				$UI.update_event_terminal("Waiting for host to begin match...")
			State.MATCH:
				$UI.update_event_terminal("The match is about to begin...")

#-------------------------------------------------------------------------------

const MAX_PLAYERS = 15 ##15 max players for now
const DEFAULT_PORT = 47218 ##Default port number

const PLAYER_SCN:PackedScene = preload("res://Objects/Player/Player.tscn")
var available_colors:Array[StringName] = [] ##Stores generated colors for a match
var player_idx:int = 0 ##Player number

var contestants:Array[int] = [] ##Array of players who are still in the running to win

#-------------------------------------------------------------------------------

var level:Level = null
var level_idx:int = 1
#-------------------------------------------------------------------------------

# Lifecycle

func _init()->void:
	#generate the colors for this session
	for i:int in range(MAX_PLAYERS):
		while true:
			var color:StringName = StringName(gen_id())
			if available_colors.has(color):
				continue
			else:
				available_colors.append(color)
				break
		

func _ready() -> void:
	# Listen to multiplayer signals
	# The following emit on both clients and servers
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	# The rest only emit for clients
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
#-------------------------------------------------------------------------------


##Creates a color / id for a given player 
func gen_id()->StringName:
	var rng:RandomNumberGenerator = RandomNumberGenerator.new()
	var id:String = "%06x" % rng.randi_range(0x000000,0xFFFFFF)
	return "#" + id

#-------------------------------------------------------------------------------

# Network

func _start_server_common() -> void:
	server_status = State.LOBBY #Changes to LOBBY once a session is hosted
	
	load_level(0) #start level scene
	spawn_player(1) # server is always first player
	$UI.init_start_btn()
	

func start_enet_server(port: int = DEFAULT_PORT) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_server(port, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer
	_start_server_common()

func start_enet_client(address: String, port: int = DEFAULT_PORT) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var err:Error = peer.create_client(address, port)
	
	#OS notification for incorrect host or port information
	if err != OK:
		OS.alert("Failed to connect using provided host information")
		get_tree().change_scene_to_file("res://Main/Lobby/Lobby.tscn")
		return
	
	multiplayer.multiplayer_peer = peer

func start_websocket_server(port: int = DEFAULT_PORT) -> void:
	var peer: WebSocketMultiplayerPeer = WebSocketMultiplayerPeer.new()
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	_start_server_common()

func start_websocket_client(url: String) -> void:
	var peer: WebSocketMultiplayerPeer = WebSocketMultiplayerPeer.new()
	peer.create_client(url)
	multiplayer.multiplayer_peer = peer

#Handles clean up for all connected peers when its time for the server to end
func handle_server_disconnect()->void:
	for child:Node in $Players.get_children():
		child.queue_free()
	
	for child:Node in $Level.get_children():
		child.queue_free()
	
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file("res://Main/Lobby/Lobby.tscn")

#Forces a peer to disconnect from the server
@rpc("authority", "reliable")
func force_peer_exit(message:String)->void:
	OS.alert(message)
	multiplayer.multiplayer_peer.close()
	get_tree().change_scene_to_file("res://Main/Lobby/Lobby.tscn")
#-------------------------------------------------------------------------------

# Network Events

func _on_peer_connected(peer_id: int) -> void:
	#Don't allow new joins after the game starts
	if !server_status: 
		force_peer_exit.rpc("Can't join server during an active match")
		return
		
	#handle spawn if host
	if (!multiplayer.is_server()): return
	spawn_player(peer_id)
	
func _on_peer_disconnected(peer_id: int) -> void:
	#handle removal if host
	if (!multiplayer.is_server()): return
	remove_player(peer_id)

func _on_connected_to_server() -> void:
	pass

func _on_connection_failed() -> void:
	#Fails to connect to a valid host
	OS.alert("Host connection failed")
	

func _on_server_disconnected() -> void:
	handle_server_disconnect() #If a peer disconnects, handle the clean up
#-------------------------------------------------------------------------------

# Level Management

func load_level(new_level_idx: int) -> void:
	# Get level path
	var level_spawner: MultiplayerSpawner = $LevelSpawner
	if (new_level_idx < 0 || new_level_idx >= level_spawner.get_spawnable_scene_count()):
		push_error("Level index out of bounds")
		return
	var level_path: String = level_spawner.get_spawnable_scene(new_level_idx)
	
	# Free previous level
	if (level != null): level.queue_free()
	
	# Load new level
	var level_scn: PackedScene = load(level_path)
	level = level_scn.instantiate()
	level_idx = new_level_idx
	$Level.add_child.call_deferred(level, true)
	
	#spawn players to 0,0
	teleport_players(Vector2.ZERO)

func unload_level() -> void:
	if (level != null): level.queue_free()
	level = null
	level_idx = -1

func next_level() -> void:
	load_level(level_idx + 1)

func is_final_level() -> bool:
	var level_spawner: MultiplayerSpawner = $LevelSpawner
	return (level_idx == level_spawner.get_spawnable_scene_count() - 1)

#-------------------------------------------------------------------------------

# Player Management

func get_player(peer_id: int) -> Player:
	for child: Node in $Players.get_children():
		if (child is Player && child.peer_id == peer_id):
			return child
	return null

func get_players() -> Array[Player]:
	var players: Array[Player] = []
	for child: Node in $Players.get_children():
		if (child is Player):
			players.append(child)
	return players

func get_player_count() -> int:
	var count: int = 0
	for child: Node in $Players.get_children():
		if (child is Player):
			count += 1
	return count

func spawn_player(peer_id: int) -> void:
	# Prepare new player
	var player: Player = PLAYER_SCN.instantiate()
	player.name = str(peer_id)
	
	#Set up player to start
	player.color_id = available_colors.pop_at(player_idx)
	player_idx += 1
	player.character = player_idx
	player.player_name = "Player " + str(player_idx)
	
	
	# Add player to level and teleport to spawn position
	$Players.add_child(player)
	player.teleport.rpc(Vector2.ZERO)
	
	#add player to contestant list
	contestants.append(peer_id)

func remove_player(peer_id: int) -> void:
	# Find player node
	var player: Player = get_player(peer_id)
	if (player == null): return
	
	contestants.erase(peer_id)
	
	# Return character back to available list
	available_colors.append(player.color_id)
	player_idx -= 1
	# Free player
	player.queue_free()

func teleport_players(new_pos: Vector2) -> void:
	for player: Player in get_players():
		player.teleport.rpc(new_pos)

#select a random peer id
func pick_rand_contestant()->int:
	return contestants.pick_random()

#RPC call to remove a contestant, can be called by any peer
@rpc("any_peer", "call_local", "reliable")
func remove_contestant(peer_id):
	contestants.erase(peer_id)
	

#Allows bbcode labeling of any word using a player's current color
func get_player_color_string(player:Player, color_word:String = "")->String:
	var color:String = player.color_id
	var p_name:String = player.player_name
	
	if color_word:
		return "[color=" + color + "]" + color_word + "[/color]"
	
	return "[color=" + color + "]" + p_name + "[/color]"
#-------------------------------------------------------------------------------

# Match Events

#Timer helper that is hooked up to the in game display
func create_game_timer(time:float = 5)->SceneTreeTimer: 
	var timer:SceneTreeTimer = get_tree().create_timer(time)
	$UI.active_timer = timer
	return timer

#Starts a match session
func start_match()->void:
	server_status = State.MATCH
	create_game_timer().timeout.connect(event_cycle)

#This is the primary game loop that runs until someone wins (or no one does)
func event_cycle()->void:
	#End cond checks
	if contestants.size() == 1:
		someone_wins(contestants[0])
		return
	elif contestants.size() == 0:
		no_one_wins()
		return
	
	#Prepare for the next event
	$UI.update_event_terminal("Next event in:")
	await create_game_timer(10).timeout
	
	#Safety check to account for async contestant removal beahvior
	if contestants.size() == 1:
		someone_wins(contestants[0])
		return
	elif contestants.size() == 0:
		no_one_wins()
		return
	
	#Event manager handles running an event
	var new_event:StringName = EM.choose_event().id
	$UI.update_event_terminal(new_event)
	EM.match_event(new_event, self)
	
	await EM.event_complete #Onve the event is complete, rerun the cycle
	
	event_cycle()

#Handle game end when someone wins
func someone_wins(peer:int)->void:
	var winner = get_player(peer)
	var win_message:String = "Congrations to the winner: " + get_player_color_string(winner)
	$UI.update_event_terminal(win_message)
	await create_game_timer(10).timeout
	
	handle_server_disconnect()

#Handle game end when nobody is left alive
func no_one_wins()->void:
	var end_message:String = "Nobody wins... Thats hilarious (●__●)"
	$UI.update_event_terminal(end_message)
	await create_game_timer(10).timeout
	
	handle_server_disconnect()

#-------------------------------------------------------------------------------

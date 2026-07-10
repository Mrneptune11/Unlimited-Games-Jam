class_name Lobby extends Node2D

const MAX_PLAYERS = 50
const DEFAULT_PORT = 47218

const PLAYER_SCN:PackedScene = preload("res://Objects/Player/Player.tscn")
var available_colors:Array[StringName] = []
var player_idx:int = 0

#-------------------------------------------------------------------------------

var level:Level = null
var level_idx:int = 1

#-------------------------------------------------------------------------------


# Lifecycle

func _init()->void:
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
	load_level(0) #start level scene
	spawn_player(1) # server is always first player

func start_enet_server(port: int = DEFAULT_PORT) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_server(port, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer
	_start_server_common()

func start_enet_client(address: String, port: int = DEFAULT_PORT) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
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
	
#-------------------------------------------------------------------------------

# Network Events

func _on_peer_connected(peer_id: int) -> void:
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
	pass

func _on_server_disconnected() -> void:
	pass
	
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

	# Listen to level events
	level.goal_reached.connect(_on_goal_reached, ConnectFlags.CONNECT_ONE_SHOT)
	
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

# Level Events

func _on_goal_reached(_player: Player) -> void:
	# Detect when a player reaches the goal and switch levels
	if (is_final_level()): return
	next_level()

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
	
	player.color_id = available_colors.pop_at(player_idx)
	player_idx += 1
	player.character = player_idx
	
	
	# Add player to level and teleport to spawn position
	$Players.add_child(player)
	player.teleport.rpc(level.get_spawn_position())

func remove_player(peer_id: int) -> void:
	# Find player node
	var player: Player = get_player(peer_id)
	if (player == null): return
	
	# Return character back to available list
	available_colors.append(player.color_id)
	player_idx -= 1
	# Free player
	player.queue_free()

func teleport_players(new_pos: Vector2) -> void:
	for player: Player in get_players():
		player.teleport.rpc(new_pos)
	

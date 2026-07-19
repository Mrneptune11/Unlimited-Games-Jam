extends CanvasLayer

@onready var lobby: Lobby = get_parent()
@onready var tick_sfx: AudioStreamPlayer = %TickSFX

var active_timer:SceneTreeTimer = null ##If there is an activetimer

var last_tick: int = 0	## The last timer tick number. When this changes, the tick SFX is played.

#-------------------------------------------------------------------------------

const START_BTN_SCN = preload("res://UI/StartButton/StartGameButton.tscn")

#-------------------------------------------------------------------------------

func _process(_delta: float) -> void:
	var timer_label:RichTextLabel = $EventTerminal/Timer
	
	#Keep the timer up to date when active, and blank when not needed
	if active_timer:
		var time_left:float = active_timer.time_left
		if time_left > 0.0:
			timer_label.text = str((roundi(time_left)))
			
			if (roundi(time_left) != last_tick):
				_play_tick_sfx.rpc()
		else:
			timer_label.text = ""


func _ready() -> void:
	$Start/ENet/Join/VBox/Start.pressed.connect(_on_enet_join_pressed)
	$Start/ENet/HostENet/VBox/Start.pressed.connect(_on_enet_host_pressed)
	$RelayStart/Relay/List/VBox/Actions/Join.pressed.connect(_on_relay_join_pressed)
	$RelayStart/Relay/List/VBox/Actions/Refresh.pressed.connect(_on_relay_refresh_pressed)
	$RelayStart/Relay/Split/Resolve/VBox/Resolve.pressed.connect(_on_relay_resolve_pressed)
	$RelayStart/Relay/Split/Host/VBox/Host.pressed.connect(_on_relay_host_pressed)
	
	# Prepare relay UI if visible
	if ($RelayStart/Relay.visible):
		_populate_relay_servers()
		_load_lobby_list()

# ENet

func _on_enet_join_pressed():
	var address: String = $Start/ENet/Join/VBox/Options/Address.text
	var port: int = $Start/ENet/Join/VBox/Options/Port.value
	lobby.start_enet_client(address, port)
	hide_starts()

func _on_enet_host_pressed():
	var port: int = $Start/ENet/HostENet/VBox/Options/Port.value
	lobby.start_enet_server(port)
	hide_starts()

# WebSocket

func _on_websocket_join_pressed():
	var url: String = $Start/WebSocket/Join/VBox/Options/Url.text
	lobby.start_websocket_client(url)
	hide_starts()

func _on_websocket_host_pressed():
	var port: int = $Start/ENet/Host/VBox/Options/Port.value
	lobby.start_websocket_server(port)
	hide_starts()

#-------------------------------------------------------------------------------

#Host gets a start button to begin the match
func init_start_btn()->void:
	var start_btn:Button = START_BTN_SCN.instantiate()
	add_child(start_btn)
	start_btn.pressed.connect(lobby.start_match)
	start_btn.pressed.connect(start_btn.hide)
	
	
#Update the event terminal current message
func update_event_terminal(string:String)->void:
	$EventTerminal.text = string

@rpc("authority", "call_local", "reliable")
func _play_tick_sfx() -> void:
	tick_sfx.play()
	
	if active_timer:
		last_tick = roundi(active_timer.time_left)

#-------------------------------------------------------------------------------

# Ezcha Relay

var server_list: Array[EzchaRelayServer] = []
var lobby_list: Array[EzchaRelayLobby] = []

func _load_lobby_list(page: int = 1) -> void:
	# Request the lobby list API
	var game_id: String = Ezcha.get_game_id()
	var request := Ezcha.relay.get_lobbies(game_id, page)
	
	# Wait for and check response
	await request.completed
	if (!request.is_successful()): return
	
	# Keep a reference
	lobby_list = request.lobbies
	
	# Populate item list
	var item_list: ItemList = $RelayStart/Relay/List/VBox/ItemList
	item_list.clear()
	for relay_lobby: EzchaRelayLobby in lobby_list:
		item_list.add_item(relay_lobby.name)

func _populate_relay_servers() -> void:
	var relay_servers: Array[EzchaRelayServer] = await Ezcha.client.order_relay_servers()
	if (relay_servers.is_empty()): return
	
	# Keep a reference
	server_list = relay_servers
	
	# Populate option button
	var option_button: OptionButton = $RelayStart/Relay/Split/Host/VBox/Parameters/Server
	option_button.clear()
	for server: EzchaRelayServer in server_list:
		option_button.add_item("(%s) %s" % [server.region, server.name])
	option_button.select(0)

func _on_relay_refresh_pressed() -> void:
	_load_lobby_list()

func _on_relay_join_pressed() -> void:
	# Determine the selected lobby
	var selected_items: PackedInt32Array = $RelayStart/Relay/List/VBox/ItemList.get_selected_items()
	if (selected_items.is_empty()): return
	var selected_lobby: EzchaRelayLobby = lobby_list[selected_items[0]]
	
	# Try to connect
	lobby.join_relay_lobby(selected_lobby)
	hide_starts()

func _on_relay_resolve_pressed() -> void:
	# Get the player input
	var join_code: String = $RelayStart/Relay/Split/Resolve/VBox/HBox/JoinCode.text
	if (join_code.is_empty()): return
	
	# Try to resolve and connect
	lobby.resolve_relay_lobby(join_code)
	hide_starts()

func _on_relay_host_pressed() -> void:
	# Get parameters
	var lobby_name: String = $RelayStart/Relay/Split/Host/VBox/Parameters/Name.text
	var server_idx: int = $RelayStart/Relay/Split/Host/VBox/Parameters/Server.get_selected_id()
	if (server_idx < 0): return
	var server: EzchaRelayServer = server_list[server_idx]
	var visibility_idx: int = $RelayStart/Relay/Split/Host/VBox/Parameters/Visibility.get_selected_id()
	
	# Start a new lobby
	lobby.start_relay_lobby(server, lobby_name, visibility_idx)
	hide_starts()

func hide_starts()->void:
	$RelayStart.hide()
	$Start.hide()
	$BG.hide()

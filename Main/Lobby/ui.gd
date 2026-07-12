extends CanvasLayer

@onready var lobby: Lobby = get_parent()

func _ready() -> void:
	$Start/ENet/Join/VBox/Start.pressed.connect(_on_enet_join_pressed)
	$Start/ENet/HostENet/VBox/Start.pressed.connect(_on_enet_host_pressed)

# ENet

func _on_enet_join_pressed():
	var address: String = $Start/ENet/Join/VBox/Options/Address.text
	var port: int = $Start/ENet/Join/VBox/Options/Port.value
	lobby.start_enet_client(address, port)
	$Start.hide()

func _on_enet_host_pressed():
	var port: int = $Start/ENet/HostENet/VBox/Options/Port.value
	lobby.start_enet_server(port)
	$Start.hide()

# WebSocket

func _on_websocket_join_pressed():
	var url: String = $Start/WebSocket/Join/VBox/Options/Url.text
	lobby.start_websocket_client(url)
	$Start.hide()

func _on_websocket_host_pressed():
	var port: int = $Start/ENet/Host/VBox/Options/Port.value
	lobby.start_websocket_server(port)
	$Start.hide()

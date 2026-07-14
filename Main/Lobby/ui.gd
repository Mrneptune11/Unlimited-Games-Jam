extends CanvasLayer

@onready var lobby: Lobby = get_parent()

var active_timer:SceneTreeTimer = null ##If there is an activetimer

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
		else:
			timer_label.text = ""


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

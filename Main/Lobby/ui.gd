extends CanvasLayer

@onready var lobby: Lobby = get_parent()
@onready var event_terminal: RichTextLabel = %EventTerminal
@onready var tick_sfx: AudioStreamPlayer = %TickSFX

var active_timer:SceneTreeTimer = null ##If there is an activetimer

var last_tick: int = 0	## The last timer tick number. When this changes, the tick SFX is played.

#-------------------------------------------------------------------------------

const START_BTN_SCN = preload("res://UI/StartButton/StartGameButton.tscn")

#-------------------------------------------------------------------------------

func _process(_delta: float) -> void:
	var timer_label:RichTextLabel = event_terminal.get_node("Timer")
	
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
	var btns:Array[Button] = []
	btns.append($Start/ENet/Join/VBox/Start)
	btns.append($Start/ENet/HostENet/VBox/Start)
	
	for i:int in range(btns.size()):
		var btn:Button = btns[i]
		btn.modulate = Color("#797979")
		if i == 0:
			btn.pressed.connect(_on_enet_join_pressed)
		if i == 1:
			btn.pressed.connect(_on_enet_host_pressed)
		
		btn.mouse_entered.connect(btn.grab_focus)
		btn.mouse_exited.connect(btn.release_focus)
		
		btn.focus_entered.connect(func(): 
			btn.add_theme_font_size_override("font_size", 36)
			btn.modulate = Color("#FFFFFF")
		)
		btn.focus_exited.connect(func(): 
			btn.add_theme_font_size_override("font_size", 30)
			btn.modulate = Color("#797979")
			)

# ENet

func _on_enet_join_pressed():
	var address: String = $Start/ENet/Join/VBox/Options/Address.text
	var port: int = $Start/ENet/Join/VBox/Options/Port.value
	lobby.start_enet_client(address, port)
	$Start.hide()
	$BG.hide()

func _on_enet_host_pressed():
	var port: int = $Start/ENet/HostENet/VBox/Options/Port.value
	lobby.start_enet_server(port)
	$Start.hide()
	$BG.hide()

# WebSocket

func _on_websocket_join_pressed():
	var url: String = $Start/WebSocket/Join/VBox/Options/Url.text
	lobby.start_websocket_client(url)
	$Start.hide()
	$BG.hide()

func _on_websocket_host_pressed():
	var port: int = $Start/ENet/Host/VBox/Options/Port.value
	lobby.start_websocket_server(port)
	$Start.hide()
	$BG.hide()

#-------------------------------------------------------------------------------

#Host gets a start button to begin the match
func init_start_btn()->void:
	var start_btn:Button = START_BTN_SCN.instantiate()
	add_child(start_btn)
	start_btn.pressed.connect(lobby.start_match)
	start_btn.pressed.connect(start_btn.hide)
	
	
#Update the event terminal current message
func update_event_terminal(string:String)->void:
	event_terminal.text = string

@rpc("authority", "call_local", "reliable")
func _play_tick_sfx() -> void:
	tick_sfx.play()
	
	if active_timer:
		last_tick = roundi(active_timer.time_left)

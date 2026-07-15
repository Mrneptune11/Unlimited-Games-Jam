class_name Projectile extends Area2D

var velocity:Vector2 
var life_time:float = 0
var time_alive:float = 0
var destroying:bool = false

var my_player:int 

signal hit_player(player:int)

func set_up(new_velocity:Vector2, new_life:float, my_peer:int, lobby:Lobby)->void:
	velocity = new_velocity
	life_time = new_life
	my_player = my_peer
	
	modulate = Color(lobby.get_player(my_peer).color_id)

func _ready()->void:
	body_entered.connect(handle_collision)
	
func handle_collision(body:Node2D)->void:
	if !is_multiplayer_authority(): return
	if body is Player:
		if body.mode == Player.Mode.SPECTATE || body.peer_id == my_player: return
		
		var peer:int = body.peer_id
		hit_player.emit(peer)
		body.explode.rpc_id(peer)
	
	destroy.rpc()

func _physics_process(delta: float) -> void:
	position += velocity * delta
	
	if !is_multiplayer_authority(): return
	time_alive += delta
	
	if time_alive >= life_time:
		try_destroy()
		
func try_destroy()->void:
	if destroying:
		return

	destroying = true
	destroy.rpc()

@rpc("call_local","reliable")
func destroy()->void:
	await get_tree().process_frame
	self.queue_free()

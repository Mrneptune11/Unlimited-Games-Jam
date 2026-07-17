class_name Projectile extends Area2D

#Core existance members
var velocity:Vector2 
var life_time:float = 0
var time_alive:float = 0
var destroying:bool = false

var my_player:int ##Owner peer id

signal hit_player(player:int) ##Emitted when this projectile hits a player

##Sets up the projectile basic members
func set_up(new_velocity:Vector2, new_life:float, my_peer:int, lobby:Lobby)->void:
	velocity = new_velocity
	life_time = new_life
	my_player = my_peer
	
	var player:Player = lobby.get_player(my_peer)
	
	$Sprite2D.modulate = Color(player.color_id)
	var anim:AnimatedSprite2D = $AnimatedSprite2D
	if anim:
			anim.modulate = Color(player.color_id)
	scale.x = player.direction

func _ready()->void:
	body_entered.connect(handle_collision) #Hitting a body triggers collision handling
	

##Handles collision cases
func handle_collision(body:Node2D)->void:
	if !is_multiplayer_authority(): return #Only Authority confirms collision results
	if body is Player:
		if body.mode == Player.Mode.SPECTATE || body.peer_id == my_player: return #Cant hit spectators or owner
		
		#A player was hit. so they explode and hit player emits
		var peer:int = body.peer_id
		hit_player.emit(peer)
		body.explode.rpc_id(peer)
	
	destroy.rpc() #Call the destroy rpc to remove projectile on all clients


func _physics_process(delta: float) -> void:
	position += velocity * delta #Simulates projectile velocity
	
	if !is_multiplayer_authority(): return #Only authority can handle projectile life span
	time_alive += delta
	
	if time_alive >= life_time: #Projectile dies from existing too long
		try_destroy()

#Destroy rpc wrapper that prevents a bullet from attempting to destroy itself more than once
func try_destroy()->void:
	if destroying:
		return

	destroying = true
	destroy.rpc()

#frees the bullet from all clients 
@rpc("call_local","reliable")
func destroy()->void:
	await get_tree().process_frame #with a frame delay to avoid sync issues
	self.queue_free()

class_name Projectile extends Area2D

var velocity:Vector2 
var life_time:float = 0
var time_alive:float = 0

signal hit_player(player:int)

func set_up(new_velocity:Vector2, new_life:float)->void:
	velocity = new_velocity
	life_time = new_life

func _ready()->void:
	body_entered.connect(handle_collision)
	
func handle_collision(body:Node2D)->void:
	if !is_multiplayer_authority(): return
	if body is Player:
		if body.mode == Player.Mode.SPECTATE: return
		
		var peer:int = body.peer_id
		hit_player.emit(peer)
		body.explode.rpc_id(peer)
	
	destroy.rpc()

func _physics_process(_delta: float) -> void:
	position += velocity

func _process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	time_alive += delta
	
	if time_alive >= life_time:
		destroy.rpc()

@rpc("call_local","reliable")
func destroy()->void:
	self.queue_free.call_deferred()

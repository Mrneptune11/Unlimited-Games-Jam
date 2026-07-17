class_name Sword extends Weapon

const SLASH_SCN:PackedScene = preload("res://Objects/Weapons/Sword/slash.tscn") #Bullet scene to instantiate from



func _ready() -> void:
	cool_down = .3 #Ready sets the gun weapon classs cool down
	super._ready()

#Overriden attack spawns a projectile owned by this gun's owner
func _attack()->void:
	spawn_projectile.rpc(my_owner)
	
	
#RPC call to spawn the projectile on all clients 
@rpc("any_peer", "call_local", "reliable")
func spawn_projectile(my_subject:int)->void:
	var slash:Projectile = SLASH_SCN.instantiate()
	var player:Player = get_tree().current_scene.get_player(my_subject)
	
	#Set up slash
	slash.set_up(Vector2.ZERO, 100, my_subject, lobby)
	slash.get_node("AnimatedSprite2D").animation_finished.connect(slash.queue_free)
	slash.global_position = self.global_position
	
	lobby.get_node("Projectiles").add_child(slash) #Bullet added to scene tree
	
	#Authority checks if the bullet hit the duel target
	if is_multiplayer_authority():
		slash.hit_player.connect(player.get_node("Socket").get_node("Weapon").validate_target)

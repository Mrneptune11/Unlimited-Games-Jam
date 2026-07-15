extends Node2D

const BULLET_SCN:PackedScene = preload("res://Objects/Weapons/Gun/Bullet.tscn")

const BULLET_SPEED:float = 7

@rpc("any_peer", "call_local", "reliable")
func spawn_projectile(my_owner:int)->void:
	var bullet:Projectile = BULLET_SCN.instantiate()
	
	var player:Player = get_tree().current_scene.get_player(my_owner)
	
	
	var dir:Vector2 = Vector2(player.direction,0)
	bullet.set_up(dir * BULLET_SPEED, 5)
	bullet.global_position = player.get_node("Socket").global_position
	
	add_child(bullet)
	
	if is_multiplayer_authority():
		bullet.hit_player.connect(player.get_node("Socket").get_node("Weapon").validate_target)

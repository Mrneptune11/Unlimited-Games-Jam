class_name Gun extends Weapon

const BULLET_SCN:PackedScene = preload("res://Objects/Weapons/Gun/Bullet.tscn")

const BULLET_SPEED:float = 7

func _attack()->void:
	#var bullet:Projectile = BULLET_SCN.instantiate()
	#
	#var dir:Vector2 = Vector2(lobby.get_player(my_owner).direction,0)
	#bullet.set_up(dir * BULLET_SPEED, 5)
	#bullet.global_position = self.global_position
	#
	#lobby.get_node("Projectiles").add_child(bullet)
	#bullet.hit_player.connect(validate_target)
	
	lobby.get_node("Projectiles").spawn_projectile.rpc(my_owner)
	

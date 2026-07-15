class_name Gun extends Weapon

const BULLET_SCN:PackedScene = preload("res://Objects/Weapons/Gun/Bullet.tscn")

const BULLET_SPEED:float = 200

func _ready() -> void:
	cool_down = .75

func _attack()->void:
	spawn_projectile.rpc(my_owner)
	
@rpc("any_peer", "call_local", "reliable")
func spawn_projectile(my_subject:int)->void:
	var bullet:Projectile = BULLET_SCN.instantiate()
	
	var player:Player = get_tree().current_scene.get_player(my_subject)
	
	var dir:Vector2 = Vector2(player.direction,0)
	bullet.set_up(dir * BULLET_SPEED, 5, my_subject, lobby)
	bullet.global_position = self.global_position
	
	lobby.get_node("Projectiles").add_child(bullet)
	
	if is_multiplayer_authority():
		bullet.hit_player.connect(player.get_node("Socket").get_node("Weapon").validate_target)

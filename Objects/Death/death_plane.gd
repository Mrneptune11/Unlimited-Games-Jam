extends Area2D

func _ready()->void:
	body_entered.connect(handle_collision)

func handle_collision(body:Node2D)->void:
	if body is Player:
		body.explode()
		return
	
	body.queue_free()

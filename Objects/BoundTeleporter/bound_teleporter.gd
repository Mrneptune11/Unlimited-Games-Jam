class_name BoundTeleporter extends Area2D


@export var change_y:float = 0.0
@export var change_x:float = 0.0

func _ready()->void:
	body_entered.connect(handle_collision)
	

func handle_collision(body:Node2D):
	if body is Player:
		if change_y:
			body.position.y = change_y
		if change_x:
			body.position.x = change_x

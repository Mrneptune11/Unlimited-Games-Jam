class_name Weapon extends Node2D

@onready var lobby:Lobby = get_tree().current_scene

var target:int = -1 #Peer id target
var my_owner:int = -1 #Peer owning this weapon

var cool_down:float = 0
var cool_timer:float
var can_attack:bool = true

func set_up(new_target:int, new_owner:int) ->void:
	target = new_target
	my_owner = new_owner

func _process(delta: float) -> void:
	if !can_attack:
		cool_timer += delta
		if cool_timer >= cool_down:
			cool_down = 0
			can_attack = true
	
func _input(_event: InputEvent) -> void:
	if (!lobby.get_player(my_owner).local): return 
	
	if Input.is_action_pressed("action") && can_attack:
		_attack()

func _attack()->void:
	pass

func validate_target(potential_target:int)->void:
	if potential_target != target:
		lobby.get_player(my_owner).explode.rpc_id(my_owner)

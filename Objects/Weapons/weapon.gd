class_name Weapon extends Node2D

@onready var lobby:Lobby = get_tree().current_scene #Easy access to the lobbby

var target:int = -1 #Peer id target, weapons always have a specific target
var my_owner:int = -1 #Peer owning this weapon

#Cool down members to prevent spam attacks
var cool_down:float = 0
var cool_timer:float
var can_attack:bool = true

#All weapons must call this to be set up correctly
func set_up(new_target:int, new_owner:int) ->void:
	target = new_target
	my_owner = new_owner

func _ready() -> void:
	$AnimatedSprite2D.modulate = Color(lobby.get_player(my_owner).color_id)

#Handles cooldown logic
func _process(delta: float) -> void:
	if !can_attack:
		cool_timer += delta
		if cool_timer >= cool_down:
			cool_timer = 0
			can_attack = true

func _input(_event: InputEvent) -> void:
	if (!lobby.get_player(my_owner).local): return #Local protection
	
	if Input.is_action_pressed("action") && can_attack:
		_attack()
		can_attack = false

#Overridable attack function
func _attack()->void:
	pass

#Validates whether the weapon was used to destroy the correct target
func validate_target(potential_target:int)->void:
	var my_player:Player = lobby.get_player(my_owner)
	var my_target:Player = lobby.get_player(target)
	
	#Player explodes if they killed the wrong target
	if potential_target != target:
		my_player.explode.rpc_id(my_owner)
	
	#Both members of a duel lose their weapons afterward on all clients
	my_player.unequip_weapon.rpc()
	my_target.unequip_weapon.rpc()
	

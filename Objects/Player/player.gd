class_name Player extends CharacterBody2D

# Physics/control parameters
const GRAVITY: float = 1024.0
const SPEED: float = 256.0
const JUMP_POWER: float = 256.0
const GROUND_ACCEL: float = 1024.0
const AIR_ACCEL: float = 512.0
const FRICTION: float = 1024.0
const SLIDE_FRICTION: float = 512.0
const AIR_DRAG: float = 512.0
const SPECTATE_SPEED:float = 10

@onready var jump_sfx: AudioStreamPlayer2D = %JumpSFX
@onready var land_sfx: AudioStreamPlayer2D = %LandSFX
@onready var _mutation_sfx: AudioStreamPlayer2D = %MutationSFX

#  player states
enum State {
	IDLE = 0,
	WALK = 1,
	JUMP = 2,
	FALL = 3,
}

#States of play the player can be in
enum Mode {
	PAUSE = 0,
	PLAY = 1,
	SPECTATE = 2,
}

#Size states
enum Size {
	REGULAR = 0,
	SMALL = -1,
	TINY = -2,
	BIG = 1,
	HUGE = 2,
}

var peer_id: int = 1 # The peer that controls this player
var local: bool = true # If this player belongs to the local peer

#Color id of the player
var color_id:String = "#FFFFFF"

##Label for the player
var my_label:Label = null
var label_offset:Vector2 = Vector2.ZERO

signal exploded(peer_id: int)	## Emits when the player explodes.
signal duel_complete ##Singal indicating a duel terminated

var character: int = 0 : # Determines which character to display as
	set(value):
		# Limit the value to the bounds of CHARACTERS
		character = clampi(value, 0, 50)
		# Update sprite to display as the new character
		$Sprite2D.modulate = Color(color_id)

var state: State = State.IDLE : # The current state the player is in
	set(value):
		var sprite: AnimatedSprite2D = $AnimatedSprite2D
		
		# Limit the value to the bounds of State
		state = clampi(value, 0, State.size() - 1) as State
		#TODO Change sprite animation based on state
		sprite.play("default")
		if state != State.WALK:
			sprite.frame = 0
			sprite.pause()
		
		if state == State.JUMP || state == State.FALL:
			$AnimatedSprite2D.play("jump")

var mode: Mode = Mode.PAUSE :
	set (value):
		if mode == Mode.SPECTATE: return #Lock mode to spectate
		
		mode = value

var direction: float = 1.0 : # Which direction the player is facing
	set(value):
		# Restrict to either exactly 1.0 or -1.0
		direction = 1.0 if (value > 0.0) else -1.0
		# Flip sprite
		$AnimatedSprite2D.flip_h = (direction < 0.0)
		
		#Socket updates with direction
		var socket:Marker2D = $Socket
		if socket:
			socket.scale.x = value
			socket.position.x = value * 12


var player_name:String = "" :
	set(value):
		player_name = value
		

var size_scale:Size = Size.REGULAR:
	set(value):
		size_scale = value
		
		if (abs(value) > 2):
			explode()
			
		var new_scale:float = pow(2.0, value / 2.0)
		scale = Vector2(new_scale,new_scale)
#-------------------------------------------------------------------------------

var death_scene:PackedScene = preload("res://Objects/Death/explosion.tscn") #Explosion scene

# Life cycle 

func _enter_tree() -> void:
	# Set node authority
	peer_id = int(name)
	$ClientSync.set_multiplayer_authority(peer_id)
	
	if multiplayer.multiplayer_peer: #confirm this player is still connected
		print(player_name)
		local = (peer_id == multiplayer.get_unique_id())

func _ready() -> void:
	if (local):
		# Activate the camera if local
		$Camera2D.make_current()
	
	#Create the player label and ask their name
	create_label() 
	ask_name()

#Teleports peers to a specific position
@rpc("authority", "call_local", "reliable")
func teleport(new_pos: Vector2, wait:bool = false) -> void:
	velocity = Vector2.ZERO
	global_position = new_pos
	state = State.IDLE
	 
	if wait:
		mode = Mode.PAUSE
		await get_tree().create_timer(1).timeout
		mode = Mode.PLAY

#-------------------------------------------------------------------------------

func _input(_event: InputEvent) -> void:
	if (!local || mode == Mode.PAUSE): return #Prevent input from others / during pause
	
	#if Input.is_key_label_pressed(KEY_0):
		#equip_weapon("res://Objects/Weapons/Sword/sword.tscn", 1,1)

func _physics_process(delta: float) -> void:
	# Only process physics if local
	if (!local || mode == Mode.PAUSE): return #Prevent input from others / during pause

	# Retrieve inputs as a convenient vector
	var input_v: Vector2 = Input.get_vector(
		&"move_left", &"move_right", &"move_up", &"move_down"
	)
	
	if mode == Mode.SPECTATE:
		self.global_position += input_v * SPECTATE_SPEED
		if (!is_zero_approx(input_v.x)): direction = roundf(input_v.x)
		return
	
	# Apply gravity
	velocity.y += GRAVITY * delta
	
	# Apply friction
	if (is_zero_approx(input_v.x) && !is_zero_approx(velocity.x)):
		var reduction: float = FRICTION if (is_on_floor()) else AIR_DRAG
		velocity.x = move_toward(velocity.x, 0.0, reduction * delta)
	
	# State machine
	match(state):
		State.IDLE: _state_idle(input_v, delta)
		State.WALK: _state_walk(input_v, delta)
		State.JUMP: _state_jump(input_v, delta)
		State.FALL: _state_fall(input_v, delta)
	
	# Apply physics
	move_and_slide()
	

func _process(_delta: float) -> void:
	update_label_offset()
	
	#Sync the ui labels with the player
	if my_label:
		my_label.position = (get_viewport().get_canvas_transform() * global_position) + label_offset
	
	#handle map borders
	handle_bounds()

func handle_bounds()->void:
	var camera:Camera2D = $Camera2D
	if global_position.x >= camera.limit_right:
		global_position.x = camera.limit_left + 16
	if global_position.x <= camera.limit_left:
		global_position.x = camera.limit_right -16
	if global_position.y >= camera.limit_bottom:
		global_position.y = camera.limit_top + 16
	if global_position.y <= camera.limit_top:
		global_position.y = camera.limit_bottom - 16

#-------------------------------------------------------------------------------

#State machine for basic physics

func _state_idle(input_v: Vector2, delta: float) -> void:
	if (_check_fall()): return
	if (_check_walk(input_v)): return
	if (_check_jump(input_v)): return
	_ground_controls(input_v, delta)

func _state_walk(input_v: Vector2, delta: float) -> void:
	if (_check_fall()): return
	if (_check_jump(input_v)): return
	if (_check_idle(input_v)): return
	_ground_controls(input_v, delta)

func _state_jump(input_v: Vector2, delta: float) -> void:
	if (_check_fall()): return
	if (_check_walk(input_v)): return
	if (_check_idle(input_v)): return
	_air_controls(input_v, delta)

func _state_fall(input_v: Vector2, delta: float) -> void:
	# Control in air
	if (!is_on_floor()):
		_air_controls(input_v, delta)
		return
	# Revert to IDLE on the ground
	state = State.IDLE
	land_sfx.play()

#-------------------------------------------------------------------------------

func jump() -> void:
	if (state == State.JUMP): return
	state = State.JUMP
	velocity.y = -JUMP_POWER
	jump_sfx.play()

#-------------------------------------------------------------------------------

#Physics helper functions

func _check_fall() -> bool:
	if (!is_on_floor() && velocity.y > 0.0):
		state = State.FALL
		return true
	return false

func _check_jump(input_v: Vector2) -> bool:
	if (input_v.y < 0.0 && is_on_floor()):
		jump()
		return true
	return false
	
func _check_walk(input_v: Vector2) -> bool:
	if (!is_zero_approx(input_v.x) && is_on_floor()):
		state = State.WALK
		return true
	return false

func _check_idle(input_v: Vector2) -> bool:
	if (is_zero_approx(input_v.x) && is_on_floor()):
		state = State.IDLE
		return true
	return false

func _ground_controls(input_v: Vector2, delta: float) -> void:
	# Face input direction
	if (!is_zero_approx(input_v.x)): direction = roundf(input_v.x)
	# Accelerate
	velocity.x = move_toward(velocity.x, SPEED * input_v.x, GROUND_ACCEL * delta)

func _air_controls(input_v: Vector2, delta: float) -> void:
	if (!is_zero_approx(input_v.x)): direction = roundf(input_v.x)
	velocity.x = move_toward(velocity.x, SPEED * input_v.x, AIR_ACCEL * delta)
	
#-------------------------------------------------------------------------------

#Explosion  logic

@rpc("any_peer", "call_local", "reliable")
func explode()->void:
	if self.mode == Mode.SPECTATE: return	# Don't explode ghosts.
	
	spawn_explosion.rpc(global_position, Color(color_id))
	self.mode = Mode.SPECTATE
	$AnimatedSprite2D.play("ded")
	$Sprite2D.modulate.a = .5
	$CollisionShape2D.set_deferred("disabled",true)
	
	#Unequip weapons if necessary
	var weapon:Weapon = $Socket.get_node_or_null("Weapon")
	if weapon:
		get_tree().current_scene.get_player(weapon.target).unequip_weapon.rpc()
		unequip_weapon.rpc() 
	
	
	z_index = 100
	
	hide_player.rpc()
	
	var lobby:Lobby = get_tree().current_scene
	lobby.remove_contestant.rpc_id(1, peer_id)
	
	#Delete an entry box if necessary
	var lobby_ui:Array[Node] = lobby.get_node("UI").get_children()
	for child:Node in lobby_ui:
		if child is EntryBox:
			child.queue_free()
	
	emit_exploded_signal.rpc_id(1, peer_id)

##Explosion are not a syncronized object, but rather every player spawns one at the correct position
@rpc("any_peer", "call_local", "reliable")
func spawn_explosion(pos: Vector2, color: Color):
	var explosion: Explosion = death_scene.instantiate()
	explosion.global_position = pos
	explosion.modulate = color
	get_tree().current_scene.get_node("Effects").add_child(explosion)
	explosion.emitting = true
	
##Kill the player on other screens
@rpc("any_peer", "call_remote", "reliable")
func hide_player():
	hide()
	
	var collider:CollisionShape2D = get_node_or_null("CollisionShape2D") #safer collider removal
	if collider:
		collider.queue_free()
		my_label.queue_free()
	
	unequip_weapon() #hidden players should not have weapons

@rpc("any_peer", "call_local", "reliable")
func emit_exploded_signal(id: int) -> void:
	exploded.emit(id)

#-------------------------------------------------------------------------------

#Player label and color logic

##Label offset calculations for when size changes happen
func update_label_offset() :
	var frame:Texture = $AnimatedSprite2D.sprite_frames.get_frame_texture(
		$AnimatedSprite2D.animation,
		$AnimatedSprite2D.frame
	)
	var half_height:float = frame.get_height() * 0.5 * 5
	label_offset.y = -(half_height * (scale.y - 1.0))

##Updates the player's label
func update_label(label:String)->void:
	#print(label)
	player_name = label
	my_label.text = player_name
	my_label.modulate = Color(color_id)

##Instantiates the players label and adds it to the UI
func create_label() -> void:
	var player_label: NameLabel = preload("res://Objects/NameLabel/NameLabel.tscn").instantiate()
	player_label.set_label(player_name, color_id)
	my_label = player_label
	get_node("/root/Lobby/UI").add_child(player_label)
	
	self.tree_exiting.connect(my_label.queue_free) #Ensure label dies with a given player

##Request for players to name themselves
#TODO probably needs better validation
func ask_name()->void:
	if (!local): return
	
	mode = Mode.PAUSE  #pause player
	
	var name_box:EntryBox = preload("res://Objects/Entry Box/EntryBox.tscn").instantiate()
	get_node("/root/Lobby/UI").add_child(name_box)
	
	name_box.set_up(func(): #Set up entry box to name the player
		var name_text:String = name_box.my_entry.text
		if name_text.is_empty(): return
		
		set_player_name.rpc(name_text)
		mode = Mode.PLAY
		name_box.queue_free.call_deferred(),
		9,
		"Enter a Name:")

#-------------------------------------------------------------------------------

#Player mutation logic

##Change a players size
@rpc("any_peer", "call_local")
func change_size(change:int)->void:
	size_scale = (size_scale + change) as Size

##Synchronize name changes across clients
@rpc("any_peer", "call_local")
func set_player_name(new_name: String):
	player_name = new_name
	my_label.text = new_name
	my_label.modulate = Color(color_id)

#Rpc call to handle updates to the players color
@rpc("any_peer", "call_local", "reliable")
func update_color(color:String)->void:
	color_id = color
	my_label.modulate = Color(color)
	$Sprite2D.modulate = Color(color)

## Wrapper to play the MutationSFX for all clients.
## Used by the EventManager during Mutation events.
@rpc("authority", "call_local", "reliable")
func play_mutation_sfx() -> void:
	_mutation_sfx.play()

#-------------------------------------------------------------------------------

#Weapon logic

#Adds a weapon to a player socket
@rpc("any_peer", "call_local")
func equip_weapon(weapon_scn:String, target:int, weapon_owner:int)->void:
	var weapon:Weapon = load(weapon_scn).instantiate()
	weapon.set_up(target, weapon_owner)
	$Socket.equip_weapon(weapon)

#Removes a weapon from a player's socket
@rpc("any_peer", "call_local")
func unequip_weapon()->void:
	var potential_weapon:Node2D = $Socket.get_node_or_null("Weapon")
	if potential_weapon: potential_weapon.queue_free()
	
	duel_complete.emit() #Removing a weapon emits the duel complete signal used by the EM

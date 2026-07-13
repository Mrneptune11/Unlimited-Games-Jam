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

var peer_id: int = 1 # The peer that controls this player
var local: bool = true # If this player belongs to the local peer

#Color id of the player
var color_id:String = "#FFFFFF"

##Label for the player
var my_label:Label = null
var label_pos:Vector2 = Vector2.ZERO

var character: int = 0 : # Determines which character to display as
	set(value):
		# Limit the value to the bounds of CHARACTERS
		character = clampi(value, 0, 50)
		# Update sprite to display as the new character
		$Sprite2D.modulate = Color(color_id)
		print(color_id)

var state: State = State.IDLE : # The current state the player is in
	set(value):
		var sprite: AnimatedSprite2D = $AnimatedSprite2D
		
		# Limit the value to the bounds of State
		state = clampi(value, 0, State.size() - 1) as State
		#TODO Change sprite animation based on state
		if state != State.WALK:
			sprite.frame = 0
			sprite.pause()
		else:
			sprite.play()
			

var mode: Mode = Mode.PAUSE :
	set (value):
		mode = value

var direction: float = 1.0 : # Which direction the player is facing
	set(value):
		# Restrict to either exactly 1.0 or -1.0
		direction = 1.0 if (value > 0.0) else -1.0
		# Flip sprite
		$AnimatedSprite2D.flip_h = (direction < 0.0)


var player_name:String = "" :
	set(value):
		player_name = value
#-------------------------------------------------------------------------------

var death_scene:PackedScene = preload("res://Objects/Death/explosion.tscn") #Explosion scene

# Life cycle 

func _enter_tree() -> void:
	# Set node authority
	peer_id = int(name)
	$ClientSync.set_multiplayer_authority(peer_id)
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
func teleport(new_pos: Vector2) -> void:
	velocity = Vector2.ZERO
	global_position = new_pos
	state = State.IDLE

#-------------------------------------------------------------------------------

func _input(_event: InputEvent) -> void:
	if (!local || mode == Mode.PAUSE): return #Prevent input from others / during pause
		
	#Test for explosions
	if Input.is_key_label_pressed(KEY_0):
		explode()

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
	#Sync the ui labels with the player
	var screen_pos = get_viewport().get_canvas_transform() * global_position
	label_pos = screen_pos
	
	if my_label:
		my_label.position = label_pos

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
	_air_controls(input_v, delta)

func _state_fall(input_v: Vector2, delta: float) -> void:
	# Control in air
	if (!is_on_floor()):
		_air_controls(input_v, delta)
		return
	# Revert to IDLE on the ground
	state = State.IDLE

#-------------------------------------------------------------------------------

func jump() -> void:
	if (state == State.JUMP): return
	state = State.JUMP
	velocity.y = -JUMP_POWER

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
	if (!is_zero_approx(input_v.x)):
		state = State.WALK
		return true
	return false

func _check_idle(input_v: Vector2) -> bool:
	if (is_zero_approx(input_v.x)):
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

#Wrapper for the rpc call
func explode()->void:
	spawn_explosion.rpc(global_position, Color(color_id))
	self.mode = Mode.SPECTATE
	$AnimatedSprite2D.play("ded")
	$Sprite2D.modulate.a = .5
	z_index = 100
	hide_player.rpc()
	
	
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
	$CollisionShape2D.queue_free()
	my_label.queue_free()
	

	
#-------------------------------------------------------------------------------

##Updates the player's label
func update_label(label:String)->void:
	#print(label)
	player_name = label
	my_label.text = player_name

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
	
	mode = Mode.PAUSE
	
	var name_box:EntryBox = preload("res://Objects/Entry Box/EntryBox.tscn").instantiate()
	get_node("/root/Lobby/UI").add_child(name_box)
	name_box.my_button.pressed.connect(func():
		set_player_name.rpc(name_box.my_entry.text)
		mode = Mode.PLAY
	)

##Synchronize name changes across clients
@rpc("any_peer", "call_local")
func set_player_name(new_name: String):
	player_name = new_name
	my_label.text = new_name

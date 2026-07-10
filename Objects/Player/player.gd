class_name Player extends CharacterBody2D

# Physics/control parameters
const GRAVITY: float = 1024.0
const SPEED: float = 512.0
const JUMP_POWER: float = 512.0
const GROUND_ACCEL: float = 1024.0
const AIR_ACCEL: float = 512.0
const FRICTION: float = 1024.0
const SLIDE_FRICTION: float = 512.0
const AIR_DRAG: float = 512.0
const HIT_COOLDOWN_MS: int = 250

#  player states
enum State {
	IDLE = 0,
	WALK = 1,
	JUMP = 2,
	FALL = 3,
}

var peer_id: int = 1 # The peer that controls this player
var local: bool = true # If this player belongs to the local peer

#Color id of the player
var color_id:String = ""

var character: int = 0 : # Determines which character to display as
	set(value):
		# Limit the value to the bounds of CHARACTERS
		character = clampi(value, 0, 50)
		# Update sprite to display as the new character
		var sprite: AnimatedSprite2D = $AnimatedSprite2D
		color_id = gen_id()
		$Sprite2D.modulate = Color(color_id)
		print(color_id)

var state: State = State.IDLE : # The current state the player is in
	set(value):
		# Limit the value to the bounds of State
		state = clampi(value, 0, State.size() - 1) as State
		#TODO Change sprite animation based on state

var direction: float = 1.0 : # Which direction the player is facing
	set(value):
		# Restrict to either exactly 1.0 or -1.0
		direction = 1.0 if (value > 0.0) else -1.0
		# Flip sprite
		$AnimatedSprite2D.flip_h = (direction < 0.0)

#-------------------------------------------------------------------------------

##Creates a color / id for a given player 
func gen_id()->String:
	var rng:RandomNumberGenerator = RandomNumberGenerator.new()
	var id:String = "%06x" % rng.randi_range(0x000000,0xFFFFFF)
	return "#" + id

#-------------------------------------------------------------------------------

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

@rpc("authority", "call_local", "reliable")
func teleport(new_pos: Vector2) -> void:
	velocity = Vector2.ZERO
	global_position = new_pos
	state = State.IDLE

#-------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	# Only process physics if local
	if (!local): return

	# Retrieve inputs as a convenient vector
	var input_v: Vector2 = Input.get_vector(
		&"move_left", &"move_right", &"move_up", &"move_down"
	)
	
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
	
#-------------------------------------------------------------------------------

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

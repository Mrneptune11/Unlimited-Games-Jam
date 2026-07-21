## UI element that changes its Kaomoji text depending on the current event.
class_name Kaomoji extends RichTextLabel

## The raw event JSON data.
## This data is parsed to populate the _animations Dictionary.
@export var _event_data: JSON

## JSON data for non-event animations like when a player explodes, during the event countdown, etc.
@export var _misc_data: JSON

## Contains the kaomoji frames & framerates associated with each in-game event.
## Key is the Event ID.
## Value is class containing kaomoji frames & framerate.
var _animations: Dictionary[StringName, AnimationData]

## The current animation being played.
## These animations will loop until a new animation is called.
var _current_animation: AnimationData

## If not null, this animation will be played instead of the 
## one in _current_animation. When this animation finishes, this variable 
## becomes null and _current_animation starts playing.
## NOTE: override animations should be used for one-off animations that do NOT loop.
var _override_animation: AnimationData

## Timer for a Kaomoji animation. Starts from 0 and increases over time.
## Resets to 0 when a new animation starts playing.
var _frame_timer: float

## Holds the frame data for a Kaomoji animation and associated Event ID.
class AnimationData:
	var frames: Array	## String array of all String "frames" in the animation.
	var framerate: float	## Frames to move through per SECOND.
	var loops: int	## If <= 0, do infinite loops. Otherwise, loop X num. times.
	
	func _init(new_frames: Array, new_framerate: float, new_loops: int) -> void:
		frames = new_frames
		framerate = new_framerate
		loops = new_loops

# Populate _animations array.
func _ready() -> void:
	# First, load data for non-event animations.
	for animation: Dictionary in _misc_data.data:
		add_animation(animation.id, animation.frames, animation.framerate, animation.loops)
	
	# Next, load event-specific animations.
	for event: Dictionary in _event_data.data:
		var animation = event.get(&"kaomoji")
		
		if (animation == null): continue	# Event has no kaomoji animation...
		
		add_animation(event.id, animation.frames, animation.framerate)
	
	# Subscribe to event start signal to change kaomojis.
	EM.event_started.connect(load_kaomoji.rpc)
	
	# Subscribe to misc. signals
	var lobby: Lobby = get_tree().current_scene as Lobby
	
	# Jank method to load an animation whenever a player dies.
	# Very, very jank. But functional!
	lobby.event_cycle_started.connect(
		func():
			for player: Player in lobby.get_players():
				player.exploded.connect(load_kaomoji.rpc.bind(&"player_exploded", true).unbind(1))
	, CONNECT_ONE_SHOT
	)
	
	lobby.event_cycle_started.connect(load_kaomoji.rpc.bind(&"event_countdown"))
	lobby.game_ended.connect(
		func(no_winners: bool):
			if no_winners: load_kaomoji.rpc(&"game_over_no_winners")
			else: load_kaomoji.rpc(&"game_over")
	)
	
	load_kaomoji(&"lobby")

# Update the current kaomoji animation's frame and the associated frame timer.
func _process(delta: float) -> void:
	if (_current_animation == null):
		load_kaomoji(&"default")
	
	_frame_timer += delta
	
	var animation_to_play: AnimationData = _current_animation
	
	# First, check if an override animation exists.
	if _override_animation:
		# If animation has completed its full number of loops...
		if (_frame_timer >= (_override_animation.frames.size() / _override_animation.framerate) * _override_animation.loops):
			_override_animation = null
			_frame_timer = 0.0
		
		else:	# Else, play the override animation.
			animation_to_play = _override_animation
	
	# Play the given animation.
	var frame: int = _compute_frame(animation_to_play, _frame_timer)
	text = animation_to_play.frames[frame]

## Adds a new animation to the Kaomoji's animation list.
func add_animation(id: StringName, frames: Array, framerate: float, loops: int = 0) -> void:
	var data: AnimationData = AnimationData.new(frames, framerate, loops)
	_animations.get_or_add(id, data)

## Returns the zero-indexed frame number that the animation should be on at the given time.
func _compute_frame(animation: AnimationData, time_elapsed: float) -> int:
	return ((1 + int(time_elapsed * animation.framerate)) % animation.frames.size()) - 1

## Loads the animation with the given ID. If override is true, overrides the 
## current animation with the new one until all of its loops have been completed.
@rpc("authority", "call_local", "reliable")
func load_kaomoji(event_id: StringName, override: bool = false) -> void:
	var new_animation: AnimationData = _animations.get(event_id, _animations.get(&"default"))
	
	if override:
		_override_animation = new_animation
	else:
		_override_animation = null	# Cancel current override animation.
		_current_animation = new_animation
	
	_frame_timer = 0.0

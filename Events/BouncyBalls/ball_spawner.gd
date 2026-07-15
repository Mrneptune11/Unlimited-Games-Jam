extends Node2D
class_name BallSpawner

@export var _ball_projectile_scene: PackedScene

## How long (in seconds) to wait before spawning another bouncy ball.
@export_range(0.0, 10.0, 0.1, "or_greater")
var _sec_between_balls: float = 0.5

## The ball's minimum & maximum initial velocity.
@export var _ball_initial_velocity: Vector2 = Vector2(100.0, 200.0)

## Position offset to spawn each bouncy ball at (initial x-position is still randomized in tilemap bounds)
@export var _spawn_pos_offset: Vector2 = Vector2(0.0, -200.0)

@onready var _spawn_timer: Timer = %SpawnTimer

## While true, continuously spawns bouncy balls.
var spawning: bool = true:
	set(value):
		spawning = value
		
		if (spawning):
			_spawn_timer.start(_sec_between_balls)
		else:
			_spawn_timer.stop()

func _ready() -> void:
	_spawn_timer.start(_sec_between_balls)

func _spawn_ball() -> void:
	# Get a random horizontal tile position in the level.
	# The ball will be spawned above this tile.
	var lobby: Lobby = get_tree().current_scene as Lobby
	
	var tilemap: TileMapLayer = lobby.level.get_node(^"TileMapLayer")
	var tile_rect: Rect2i = tilemap.get_used_rect()
	var tilemap_bounds_x: Vector2i = Vector2i(tile_rect.position.x, tile_rect.position.x + tile_rect.size.x)
	
	var spawn_pos: Vector2 = Vector2(randi_range(tilemap_bounds_x.x, tilemap_bounds_x.y), tile_rect.position.y)
	
	# First, randomly determine the ball's initial velocity (within bounds).
	var initial_velocity: float = randf_range(_ball_initial_velocity.x, _ball_initial_velocity.y)
	
	# Next, determine a velocity direction within a downward semi-circle.
	var initial_direction: Vector2 = Vector2.DOWN
	
	# Random deviation between -0.5 to 0.5 radians.
	var deviation_rad: float = randf_range(-0.5, 0.5) * PI
	
	var final_direction: Vector2 = initial_direction.rotated(deviation_rad) * initial_velocity
	
	# Finally, spawn a ball!
	var projectile: BallProjectile = _ball_projectile_scene.instantiate()
	
	projectile.global_position = spawn_pos + _spawn_pos_offset
	projectile.apply_impulse(final_direction)
	
	add_child(projectile, true)
	
	#print("Spawned bouncy ball")

func _on_spawn_timer_timeout() -> void:
	if multiplayer.is_server():
		_spawn_ball()

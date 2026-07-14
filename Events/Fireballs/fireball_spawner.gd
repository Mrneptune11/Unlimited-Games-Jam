extends Node2D
class_name FireballSpawner

@export var fireball_projectile_scene: PackedScene

## How long (in seconds) to wait before spawning another fireball.
@export_range(0.0, 10.0, 0.1, "or_greater")
var sec_between_fireballs: float = 0.5

## The fireball's position offset from its target position.
@export var fireball_offset: Vector2 = Vector2(150, -200.0)

@onready var spawn_timer: Timer = %SpawnTimer

func _ready() -> void:
	spawn_timer.start(sec_between_fireballs)

func _spawn_fireball() -> void:
	# Get a random tile position in the level.
	# This will be the fireball's target position.
	var lobby: Lobby = get_tree().current_scene as Lobby
	
	var tilemap: TileMapLayer = lobby.level.get_node(^"TileMapLayer")
	var tiles: Array[Vector2i] = tilemap.get_used_cells()
	
	var target_position: Vector2 = tilemap.to_global(tilemap.map_to_local(tiles.pick_random()))
	
	var projectile: FireballProjectile = fireball_projectile_scene.instantiate()
	
	projectile.target_position = target_position
	projectile.global_position = target_position + fireball_offset
	add_child(projectile, true)
	
	#print("Spawned fireball")

func _on_spawn_timer_timeout() -> void:
	if multiplayer.is_server():
		_spawn_fireball()

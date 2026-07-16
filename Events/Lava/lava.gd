extends Area2D
class_name Lava

signal max_height_reached()

## How far from the bottom-middle of the tilemap bounds to spawn the lava.
@export var spawn_pos_offset: Vector2 = Vector2(0.0, 75.0)

## How many units upward the lava moves every second.
@export_range(0.0, 500.0, 0.1, "or_greater")
var speed: float = 10.0

## When the lava is this far or less from the target Y-position, it will stop moving.
@export_range(0.0, 500.0, 0.1, "or_greater")
var max_height_offset: float = 10.0

## The target Y-position for the lava to move to (but not past).
## This should be a certain distance below the top of the tilemap.
var _target_pos_y: float

func _ready() -> void:
	if not is_multiplayer_authority():
		return
	
	# Move the lava's position to be at the bottom-middle of the map.
	var lobby: Lobby = get_tree().current_scene as Lobby
	
	var tilemap: TileMapLayer = lobby.level.get_node(^"TileMapLayer")
	var tile_rect: Rect2i = tilemap.get_used_rect()
	
	var tilemap_pos_global: Vector2 = tilemap.to_global(tilemap.map_to_local(tile_rect.position))
	var tilemap_size_global: Vector2 = tilemap.to_global(tilemap.map_to_local(tile_rect.size))
	
	print("Rect pos: ", tilemap_pos_global)
	print("Rect size: ", tilemap_size_global)
	
	var tilemap_bottom_middle: Vector2 = Vector2(
		tilemap_pos_global.x + (tilemap_size_global.x / 2.0), 
		tilemap_pos_global.y + tilemap_size_global.y
	)
	
	global_position = tilemap_bottom_middle + spawn_pos_offset
	
	_target_pos_y = tilemap_pos_global.y

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	global_position = global_position.move_toward(Vector2(0.0, _target_pos_y + max_height_offset), speed * delta)
	
	if (global_position.y <= _target_pos_y + max_height_offset):	# If max height reached...
		max_height_reached.emit()

func _on_body_entered(body: Node2D) -> void:
	if (body is Player):
		if (body.mode == Player.Mode.PLAY):
			body.explode()

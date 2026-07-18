extends Area2D
class_name FireballProjectile

@export var _hit_particles_scene: PackedScene

## How many units the projectile moves every second.
@export_range(0.0, 100.0, 0.1, "or_greater")
var speed: float

## The projectile moves toward this target position every frame.
## This value is randomly set by the Fireball event.
var target_position: Vector2

func _physics_process(delta: float) -> void:
	if (global_position == target_position):
		_spawn_hit_particles.rpc()
		queue_free()
	else:
		global_position = global_position.move_toward(target_position, speed * delta)

func _on_body_entered(body: Node2D) -> void:
	if (body is Player):
		if (body.mode == Player.Mode.PLAY):
			body.explode()

@rpc("any_peer", "call_local", "reliable")
func _spawn_hit_particles() -> void:
	var particles: FireballParticles = _hit_particles_scene.instantiate()
	particles.global_position = global_position
	get_tree().current_scene.get_node("Effects").add_child(particles)
	particles.emitting = true

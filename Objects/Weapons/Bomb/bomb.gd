class_name Bomb extends Weapon

@export var blast_particles_scene: PackedScene

@export_range(0.0, 10.0, 0.1, "or_greater")
var fuse_time: float = 5.0

@onready var fuse: Timer = %FuseTimer
@onready var blast_zone: Area2D = %BlastZone

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fuse.start(fuse_time)
	$Sprite2D.modulate = Color(lobby.get_player(my_owner).color_id)

# Update label text with fuse time left.
func _process(_delta: float) -> void:
	# If Weapon node is flipped, also flip label to preserve text orientation.
	scale = scale.abs() * (get_parent() as Node2D).scale.sign()
	
	$AnimatedSprite2D.frame = int(fuse.time_left)

func _on_fuse_timer_timeout() -> void:
	if not is_multiplayer_authority():	# Only run on server.
		return
	
	var blast_bodies: Array[Node2D] = blast_zone.get_overlapping_bodies()
	
	# Explode all living players within the blast radius.
	for body in blast_bodies:
		if body is Player:
			var is_alive: bool = body.mode == Player.Mode.PLAY
			var is_not_owner: bool = body.peer_id != my_owner
			
			if is_alive and is_not_owner:
				body.explode.rpc_id(body.peer_id)
	
	# Spawn blast particles.
	_spawn_blast_particles.rpc()
	
	# Finally, explode yourself.
	lobby.get_player(my_owner).explode.rpc_id(my_owner)

@rpc("any_peer", "call_local", "reliable")
func _spawn_blast_particles() -> void:
	var blast_particles: BlastParticles = blast_particles_scene.instantiate()
	blast_particles.global_position = global_position
	get_tree().current_scene.get_node("Effects").add_child(blast_particles)
	blast_particles.emitting = true

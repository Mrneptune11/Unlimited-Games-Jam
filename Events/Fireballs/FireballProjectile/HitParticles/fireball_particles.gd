class_name FireballParticles extends GPUParticles2D

@onready var _sfx: AudioStreamPlayer2D = %AudioStreamPlayer2D

var _particles_finished: bool = false
var _sfx_finished: bool = false

##Kill self when done
func _ready()->void:
	self.finished.connect(func(): _particles_finished = true)
	_sfx.finished.connect(func(): _sfx_finished = true)

func _process(_delta: float) -> void:
	if _particles_finished and _sfx_finished:
		queue_free()

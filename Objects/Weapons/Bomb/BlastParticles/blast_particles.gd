class_name BlastParticles extends GPUParticles2D

@onready var _explode_sfx: AudioStreamPlayer2D = %ExplodeSFX

var _particles_finished: bool = false
var _sfx_finished: bool = false

##Kill self when done
func _ready()->void:
	self.finished.connect(func(): _particles_finished = true)
	_explode_sfx.finished.connect(func(): _sfx_finished = true)

func _process(_delta: float) -> void:
	if _particles_finished and _sfx_finished:
		queue_free()

class_name Explosion extends GPUParticles2D

##Kill self when done
func _ready()->void:
	self.finished.connect(queue_free)

class_name Explosion extends GPUParticles2D

func _ready()->void:
	self.finished.connect(queue_free)

extends Node

enum Track {
	NONE = -1,
	STUFF = 0,
	HAPPENS = 1,
}

var current_track:Track = Track.NONE

@rpc("any_peer", "call_local", "reliable")
func play_music(track:Track)->AudioStreamPlayer:
	if current_track == track: return 
	
	for player:Node in self.get_children():
		if player is AudioStreamPlayer:
			player.stop()
	
	match track:
		0:
			$Stuff.play()
			return $Stuff
		1:
			$Happens.play()
			return $Happens
	
	return null
	

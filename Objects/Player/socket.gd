class_name Socket extends Marker2D

#Equips a weapon to the socket
func equip_weapon(weapon:Weapon)->void:
	self.add_child(weapon)

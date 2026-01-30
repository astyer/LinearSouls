extends Node

var parryTimer = Timer.new()

func _ready():
	parryTimer.one_shot = true
	add_child(parryTimer)
	
func start_parry_timer(timeout: float): 
	parryTimer.start(timeout)

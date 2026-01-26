extends Node

var parryTimer = Timer.new()

func _ready():
	parryTimer.one_shot = true
	add_child(parryTimer)
	SignalBus.connect('hit_parry', start_parry_timer)
	
func start_parry_timer():
	parryTimer.start(0.8)

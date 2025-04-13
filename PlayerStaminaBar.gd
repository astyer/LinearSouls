extends ProgressBar

const MAX_STAMINA = 100

var regen_tween

func _ready() -> void:
	max_value = MAX_STAMINA
	value = MAX_STAMINA
	
func _process(delta) -> void:
	#print(value)
	pass
	
func _on_player_stamina_used(amount: int) -> void:
	#pass
	value -= amount
	if regen_tween:
		regen_tween.kill()
	regen_tween = get_tree().create_tween()
	regen_tween.tween_property(self, 'value', 100, (MAX_STAMINA - value) / 10) # lower number = slower regen

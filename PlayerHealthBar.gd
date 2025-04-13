extends ProgressBar

const MAX_HEALTH = 100

func _ready() -> void:
	max_value = MAX_HEALTH
	value = MAX_HEALTH

func _on_player_damaged(damage: int) -> void:
	value -= damage
	if(value <= 0):
		value = MAX_HEALTH

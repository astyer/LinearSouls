extends ProgressBar

const MAX_HEALTH = 100

func _ready() -> void:
	max_value = MAX_HEALTH
	value = MAX_HEALTH
	SignalBus.boss_damaged.connect(_on_boss_damaged)

func _on_boss_damaged(damage: int) -> void:
	value -= damage
	if(value <= 0):
		value = MAX_HEALTH

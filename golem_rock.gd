class_name GolemRock

extends CharacterBody2D

var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

var isOnFloor: bool = false

func _ready() -> void:
	$AP.play('RESET')
	var players = get_tree().get_nodes_in_group("players")
	if players.size() == 0:
		return
	var player: Player = players[0]
	
	var directionToPlayer = signf(global_position.direction_to(player.global_position).x)
	var distanceToPlayer = global_position.distance_to(player.global_position)

	global_position.x = global_position.x + (200 * directionToPlayer)
	global_position.y -= 300
	
	velocity.x = directionToPlayer * distanceToPlayer * 1.8
	
func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	velocity.x = move_toward(velocity.x, 0, 10)
	
	if $AP.current_animation == 'Break':
		velocity.y = 0
		velocity.x = 0
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		$AP.play('Break')
		if collision.get_collider().is_in_group('players'):
			SignalBus.hit_player.emit(15, velocity.x)

func _on_ap_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		'Break':
			queue_free()


func _on_detector_area_2d_area_entered(area: Area2D) -> void:
	$AP.play('Break')

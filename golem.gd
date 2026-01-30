class_name Golem

extends CharacterBody2D

var golem_rock_scene = preload("res://scenes/golem_rock.tscn")

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity") * 2

var directionFacing: int = -1
var isOnFloor: bool = false
var isLandingJump: bool = false

var directionToPlayer: int
var distanceToPlayer: float

func _ready():
	SignalBus.hit_boss.connect(_on_hit_boss)
	Globals.parryTimer.connect("timeout", on_parry_timer_timeout)
	$AP.play('Idle')
	
func _physics_process(delta: float) -> void:
	if !isOnFloor:
		velocity.y += gravity * delta 
		
	var players = get_tree().get_nodes_in_group("players")
	if players.size() == 0:
		return
	var player: Player = players[0]
	
	var new_x_velocity: float = move_toward(velocity.x, 0, 40)
	
	directionToPlayer = signf(position.direction_to(player.position).x)
	distanceToPlayer = position.distance_to(player.position)
	
	match $AP.assigned_animation:
		'Idle':
			face_player()
			if($AttackCooldownTimer.is_stopped()):
				$AP.play('Idle')
				#if(distanceToPlayer <= 250):
					#BossHelpers.play_random_animation($AP, {'Stomp': 60, 'JumpStart': 10, 'RockPickup': 30})
				#elif(distanceToPlayer <= 600):
					#BossHelpers.play_random_animation($AP, {'JumpStart': 10, 'RockPickup': 90})
				#else:
					#$AP.play('RockPickup')
		'Jump':
			if(isOnFloor):
				if isLandingJump:
					$AttackCooldownTimer.start(2)
					isLandingJump = false
				$GolemSprite/JumpArea2D/JumpHitbox.disabled = true
				new_x_velocity = move_toward(velocity.x, 0, 20)
				#@todo get up animation
				if ($AttackCooldownTimer.is_stopped()):
					$AP.play('Idle')
			else:
				new_x_velocity = move_toward(velocity.x, 0, 10)
		'RockHold':
			face_player()
			if($AttackCooldownTimer.is_stopped()):
				if(distanceToPlayer <= 250):
					$AP.play('RockSlam')
				elif(distanceToPlayer <= 350):
					BossHelpers.play_random_animation($AP, {'RockSlam': 90, 'RockThrow': 10})
				elif(distanceToPlayer <= 500):
					BossHelpers.play_random_animation($AP, {'RockSlam': 40, 'RockThrow': 60})
				else:
					$AP.play('RockThrow')
			
	velocity.x = new_x_velocity
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		if(collision.get_collider().name.contains('Wall')):
			velocity = velocity.slide(collision.get_normal())
		if(collision.get_collider().name == 'Floor'):
			velocity = velocity.slide(collision.get_normal())
			isOnFloor = true

func _on_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		'Stomp':
			#@todo play slowdown animation and slow down over time
			$AP.play('Idle')
			$AttackCooldownTimer.start(1.5)
		'JumpStart':
			$AP.play('Jump')
			velocity.y = -1500
			velocity.x = directionToPlayer * distanceToPlayer * 2
			isOnFloor = false
		'Jump':
			isLandingJump = true
		'RockPickup':
			$AP.play('RockHold')
			$AttackCooldownTimer.start(0.5)
		'RockSlam':
			$AP.play('RockHold')
			$AttackCooldownTimer.start(0.5)
		'RockThrow':
			$AP.play('Idle')
			$AttackCooldownTimer.start(2)
			
func face_player() -> void:
	if(directionFacing != directionToPlayer):
		#@todo turnaround animation				
		directionFacing = directionToPlayer
		scale.x *= -1

func handle_golem_stomp_move() -> void:
	velocity.x = directionFacing * 500
	
func throw_rock() -> void:
	var rock = golem_rock_scene.instantiate()
	add_child(rock)
	
func hit_player(damage: int, hitVelocity: int, requireOnFloor: bool = false) -> void:
	if !$AttackCooldownTimer.is_stopped(): # check the attack wasn't already canceled from parry
		return
	$HitPlayerTimer.start()
	SignalBus.hit_player.emit(damage, hitVelocity, requireOnFloor)
	
func on_parried(cooldown: int) -> void:
	$AttackCooldownTimer.start(cooldown)
	z_index = -1
	SignalBus.hit_parry.emit()
	call_deferred('on_parried_deferred')
	
func on_parried_deferred() -> void:
	reset_state()
	process_mode = Node.PROCESS_MODE_DISABLED
	
func on_parry_timer_timeout() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	$AP.play('Idle')

func _on_stomp_area_2d_body_entered(_body: Node2D) -> void:
	call_deferred('hit_player', 25, 800 * directionFacing)

func _on_stomp_area_2d_area_entered(area: Area2D) -> void:
	on_parried(1.5)

func _on_jump_area_2d_body_entered(_body: Node2D) -> void:
	hit_player(60, 1200 * directionToPlayer, true)

func _on_rock_up_area_2d_body_entered(_body: Node2D) -> void:
	call_deferred('hit_player', 15, 600 * directionFacing)
	
func _on_rock_up_area_2d_area_entered(area: Area2D) -> void: # maybe make not parryable
	on_parried(1)

func _on_rock_slam_area_2d_body_entered(_body: Node2D) -> void:
	call_deferred('hit_player', 20, 400 * directionFacing)
	
func _on_rock_slam_area_2d_area_entered(area: Area2D) -> void:
	on_parried(2)
	
func _on_hit_boss(damage: int, hitVelocity: int) -> void:
	if !$HitPlayerTimer.is_stopped(): # prevent player from hitting boss in same moment they were hit
		return
	SignalBus.boss_damaged.emit(damage)
	velocity.x = hitVelocity
	var dmg_tween = get_tree().create_tween()
	dmg_tween.tween_method(func(value): $GolemSprite.material.set_shader_parameter("amplifier", value), .5, 0, .15);
	
# having this use all RESET animation track values is tricky (and probably unnecessary) so can update this as needed
func reset_state():
	$GolemSprite/StompArea2D/StompHitbox.disabled = true
	$GolemSprite/RockUpArea2D/RockUpHitbox.disabled = true
	$GolemSprite/RockSlamArea2D/RockSlamHitbox.disabled = true

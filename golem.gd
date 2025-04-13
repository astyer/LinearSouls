class_name Golem

extends CharacterBody2D

var golem_rock_scene = preload("res://scenes/golem_rock.tscn")

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity") * 2

var directionFacing: int = -1
var isOnFloor: bool = false

var directionToPlayer: int
var distanceToPlayer: float

func _ready():
	$AP.play('Idle')

func _physics_process(delta: float) -> void:
	if !isOnFloor:
		velocity.y += gravity * delta
		
	var players = get_tree().get_nodes_in_group("players")
	if players.size() == 0:
		return
	var player: Player = players[0]
	
	var new_x_velocity: float = velocity.x
	
	directionToPlayer = signf(position.direction_to(player.position).x)
	distanceToPlayer = position.distance_to(player.position)
	
	match $AP.assigned_animation:
		'Idle':
			new_x_velocity = move_toward(velocity.x, 0, 40)
			face_player()
			if($AttackCooldownTimer.is_stopped()):
				if(distanceToPlayer <= 300):
					BossHelpers.play_random_animation($AP, ['Stomp', 'JumpStart', 'RockPickup'])
				elif(distanceToPlayer <= 500):
					BossHelpers.play_random_animation($AP, ['JumpStart', 'RockPickup'])
				else:
					$AP.play('RockPickup')
		'Jump':
			if(isOnFloor):
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
				if(distanceToPlayer <= 400):
					$AP.play('RockSlam')
				else:
					$AP.play('RockThrow')
			
	velocity.x = new_x_velocity
	
	var collision = move_and_collide(velocity * delta)
	if collision:
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
			$AttackCooldownTimer.start(2)
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

func _on_stomp_area_2d_body_entered(_body: Node2D) -> void:
	SignalBus.hit_player.emit(25)

func _on_jump_area_2d_body_entered(_body: Node2D) -> void:
	SignalBus.hit_player.emit(60, true)

func _on_rock_up_area_2d_body_entered(_body: Node2D) -> void:
	SignalBus.hit_player.emit(15)

func _on_rock_slam_area_2d_body_entered(_body: Node2D) -> void:
	SignalBus.hit_player.emit(20)

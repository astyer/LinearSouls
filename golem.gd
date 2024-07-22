class_name Golem

extends CharacterBody2D

signal hit_player

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity") * 2

var directionFacing: int = -1
var isOnFloor: bool = false
var isPaused: bool = false

func _ready():
	$AP.play('Idle')

func _physics_process(delta: float) -> void:
	if(isPaused):
		return
	if !isOnFloor:
		velocity.y += gravity * delta
		
	var players = get_tree().get_nodes_in_group("players")
	if players.size() == 0:
		return
	var player: Player = players[0]
	
	var new_x_velocity: int = velocity.x
	
	var directionToPlayer := signf(position.direction_to(player.position).x)
	var distanceToPlayer := position.distance_to(player.position)
	
	match $AP.assigned_animation:
		'Idle':
			new_x_velocity = move_toward(velocity.x, 0, 40)
			if(directionFacing != directionToPlayer):
				#@todo turnaround animation				
				directionFacing = directionToPlayer
				scale.x *= -1
			if($AttackCooldownTimer.is_stopped()):
				if(distanceToPlayer <= 200):
					$AP.play('Stomp')
				elif(distanceToPlayer <= 400):
					$AP.play('JumpStart')
		'Jump':
			if(isOnFloor && $AttackCooldownTimer.is_stopped()):
				#@todo get up animation
				$AttackCooldownTimer.start(2)
				$AP.play('Idle')
			
	velocity.x = new_x_velocity
	
	#move_and_slide()
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		print(collision.get_collider().name)
		if(collision.get_collider().name == 'Floor'):
			velocity = velocity.slide(collision.get_normal())
			isOnFloor = true
		if(collision.get_collider().name == 'Player'):
			isPaused = true


func _on_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		'Stomp':
			# play slowdown animation and slow down over time
			$AP.play('Idle')
			$AttackCooldownTimer.start(1.5)
		'JumpStart':
			$AP.play('Jump')
			velocity.y = -1750
			isOnFloor = false
			$AttackCooldownTimer.start(3)
			
func handle_golem_stomp_move() -> void:
	velocity.x = directionFacing * 500

func _on_stomp_area_2d_body_entered(body: Node2D) -> void:
	emit_signal('hit_player', 25)

class_name Player

extends CharacterBody2D

signal stamina_used
signal hit_boss

const MAX_X_SPEED = 400
const X_ACCELERATION = 35
const X_DECELERATION = 25
const JUMP_VELOCITY = -600.0

#stamina
const ROLL_STAMINA = 20
const COMBO_1_STAMINA = 15
const COMBO_2_STAMINA = 15
const COMBO_3_STAMINA = 20

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

var prev_x_velocity: int = 0
var last_pressed_direction: int = 1
var current_stamina: int = 100

var directionFacing: int = 1
var isAttacking: bool = false
var nextAttackRequested: bool = false
var isOnFloor: bool = false

func _ready():
	$AP.play('Idle')

func _physics_process(delta: float) -> void:
	current_stamina = get_tree().get_nodes_in_group("staminaBar")[0].value
	
	process_attacks()
	process_roll()
	process_y_velocity(delta)
	process_x_velocity()
	
	move_and_slide()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if(collision.get_collider().is_in_group('Bosses')):
			print(collision.get_depth())
			if(collision.get_depth() > 0.1):
				print('inside')
	
	
	
func process_roll() -> void:
	if(isAttacking):
		return
	if Input.is_action_just_pressed('space') && is_on_floor() && current_stamina >= ROLL_STAMINA:
		$AP.play('Roll')
		stamina_used.emit(ROLL_STAMINA)
	
func process_attacks() -> void:
	if isAttacking && Input.is_action_just_pressed('mouse1'):
		nextAttackRequested = true
		return
	if Input.is_action_just_pressed('mouse1') && is_on_floor() && $AP.current_animation != 'Roll' && current_stamina >= COMBO_1_STAMINA:
		$AP.play('OverheadCombo1')
		stamina_used.emit(COMBO_1_STAMINA)
		isAttacking = true
	
func process_y_velocity(delta: float) -> void:
	if !is_on_floor():
		velocity.y += gravity * delta
	if isAttacking || $AP.current_animation == 'Roll':
		return
	if Input.is_action_just_pressed('up') && is_on_floor(): 
		$AP.play('Jump')
	
func process_x_velocity() -> void:
	if(isAttacking):
		velocity.x = 0
		return
	  
	if($AP.current_animation == 'Roll'):
		velocity.x = move_toward(velocity.x, last_pressed_direction * MAX_X_SPEED, X_ACCELERATION * 3)
		return
		
	if($AP.current_animation == 'Jump'):
		velocity.x = move_toward(velocity.x, 0, X_ACCELERATION)
		return
	
	var direction := Input.get_axis("left", "right")
	
	if direction != 0 && direction != directionFacing:
		directionFacing = direction
		scale.x *= -1
	
	if(!direction && (abs(velocity.x) < abs(prev_x_velocity)) && $AP.current_animation == 'Run'):
		$AP.play_backwards('Accelerate')
	if(direction && velocity.x == 0 && prev_x_velocity == 0): #(Input.is_action_just_pressed('right') || Input.is_action_just_pressed('left'))
		$AP.play('Accelerate')
		
	var new_x_velocity: int = velocity.x
	if direction:
		new_x_velocity = move_toward(velocity.x, direction * MAX_X_SPEED, X_ACCELERATION)
	else:
		new_x_velocity = move_toward(velocity.x, 0, X_DECELERATION)
		
	if !$AP.current_animation:
		if velocity.x == 0 && new_x_velocity == 0:
			$AP.play('Idle')
		elif direction:
			$AP.play('Run')
	
	if direction:
		last_pressed_direction = direction
	prev_x_velocity = velocity.x
	velocity.x = new_x_velocity

func _on_player_animation_finished(anim_name: StringName) -> void:
	var direction := Input.get_axis("left", "right")
	match anim_name:
		'Jump':
			velocity.y = JUMP_VELOCITY
			#isOnFloor = false
		'Roll':
			if(direction):
				$AP.play('Run')
				return
			$AP.play_backwards('Accelerate')
		'OverheadCombo1':
			if nextAttackRequested && current_stamina >= COMBO_2_STAMINA:
				$AP.play('OverheadCombo2')
				stamina_used.emit(COMBO_2_STAMINA)
				nextAttackRequested = false
			else:
				$AP.play('OverheadComboSheath')				
		'OverheadCombo2':
			if nextAttackRequested && current_stamina >= COMBO_3_STAMINA:
				$AP.play('OverheadCombo3')
				stamina_used.emit(COMBO_3_STAMINA)
				nextAttackRequested = false
			else:
				$AP.play('OverheadComboSheath')	
		'OverheadComboSheath':
			isAttacking = false
		'OverheadCombo3':
			isAttacking = false	


func _on_oc_1_area_body_entered(body: Node2D) -> void:
	emit_signal('hit_boss', 5)

func _on_oc_2_area_body_entered(body: Node2D) -> void:
	emit_signal('hit_boss', 5)

func _on_oc_3_area_body_entered(body: Node2D) -> void:
	emit_signal('hit_boss', 15)

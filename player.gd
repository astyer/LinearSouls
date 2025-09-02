class_name Player

extends CharacterBody2D

signal stamina_used
signal boss_damaged
signal player_damaged

const MAX_X_SPEED = 400
const X_ACCELERATION = 35
const X_DECELERATION = 25
const JUMP_VELOCITY = -600.0

const unstoppableAnimations = ['Roll', 'Jump', 'Knocked', 'Getup']
const attackAnimations = ['OverheadCombo1', 'OverheadCombo2', 'OverheadCombo3', 'OverheadComboSheath']

#stamina
const ROLL_STAMINA = 20
const COMBO_1_STAMINA = 15
const COMBO_2_STAMINA = 15
const COMBO_3_STAMINA = 20

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

var prev_x_velocity: float = 0
var current_pressed_direction: int = 0
var last_pressed_direction: int = 1
var current_stamina: int = 100

var directionFacing: int = 1
var nextAttackRequested: bool = false

func _ready():
	SignalBus.hit_player.connect(_on_hit_player)
	$AP.play('Idle')

func _physics_process(delta: float) -> void:
	current_stamina = get_tree().get_nodes_in_group("staminaBar")[0].value
	current_pressed_direction = Input.get_axis("left", "right")
	
	process_attacks()
	process_roll()
	process_jump()
	process_y_velocity(delta)
	process_x_velocity()
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if(collision.get_collider().is_in_group('Bosses')):
			if(collision.get_depth() > 4): #probably need to adjust
				print('inside boss')
	
	move_and_slide()
	
func process_roll() -> void:
	if(unstoppableAnimations.has($AP.current_animation) || attackAnimations.has($AP.current_animation)):
		return
	if Input.is_action_just_pressed('space') && is_on_floor() && current_stamina >= ROLL_STAMINA:
		if current_pressed_direction:
			last_pressed_direction = current_pressed_direction
		$AP.play('Roll')
		stamina_used.emit(ROLL_STAMINA)
		
func process_jump() -> void:
	if(unstoppableAnimations.has($AP.current_animation) || attackAnimations.has($AP.current_animation)):
		return
	if Input.is_action_just_pressed('up') && is_on_floor(): 
		$AP.play('Jump')

func process_attacks() -> void:
	if(unstoppableAnimations.has($AP.current_animation)):
		return
	if attackAnimations.has($AP.current_animation) && Input.is_action_just_pressed('mouse1'):
		nextAttackRequested = true
		return
	if Input.is_action_just_pressed('mouse1') && is_on_floor() && current_stamina >= COMBO_1_STAMINA:
		$AP.play('OverheadCombo1')
		stamina_used.emit(COMBO_1_STAMINA)
	
func process_y_velocity(delta: float) -> void:
	if !is_on_floor():
		velocity.y += gravity * delta
	
func process_x_velocity() -> void:
	match $AP.current_animation:
		'Roll':
			velocity.x = move_toward(velocity.x, last_pressed_direction * MAX_X_SPEED, X_ACCELERATION * 3)
			return
		'Jump':
			velocity.x = move_toward(velocity.x, 0, X_ACCELERATION)
			return
		'Knocked':
			velocity.x = move_toward(velocity.x, 0, X_DECELERATION)
			return
	
	if(unstoppableAnimations.has($AP.current_animation) || attackAnimations.has($AP.current_animation)):
		velocity.x = 0
		return
			
	if current_pressed_direction && current_pressed_direction != directionFacing:
		directionFacing = current_pressed_direction
		scale.x *= -1
	
	if(!current_pressed_direction && (abs(velocity.x) < abs(prev_x_velocity)) && $AP.current_animation == 'Run'):
		$AP.play_backwards('Accelerate')
	if(current_pressed_direction && velocity.x == 0 && prev_x_velocity == 0):
		$AP.play('Accelerate')
		
	var new_x_velocity: float = velocity.x
	if current_pressed_direction:
		new_x_velocity = move_toward(velocity.x, current_pressed_direction * MAX_X_SPEED, X_ACCELERATION)
	else:
		new_x_velocity = move_toward(velocity.x, 0, X_DECELERATION)
		
	if !$AP.current_animation:
		if velocity.x == 0 && new_x_velocity == 0:
			$AP.play('Idle')
		elif current_pressed_direction:
			$AP.play('Run')
			
	if current_pressed_direction:
		last_pressed_direction = current_pressed_direction
	prev_x_velocity = velocity.x
	velocity.x = new_x_velocity

func _on_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		'Jump':
			velocity.y = JUMP_VELOCITY
			#@todo airborne animation
		'Roll':
			if(current_pressed_direction):
				$AP.play('Run')
			else:
				$AP.play_backwards('Accelerate')
		'Knocked':
			$AP.play('Getup')
		'Getup':
			$InvulnerableTimer.start()
			if(current_pressed_direction):
				$AP.play('Accelerate')
			else:
				$AP.play('Idle')
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
			if(current_pressed_direction):
				$AP.play('Accelerate')
			else:
				$AP.play('Idle')
		
func handle_hit_boss(damage: int, hitVelocity: int) -> void:
	# prevent weird multi hit bugs
	if $AttackHitTimer.is_stopped():
		SignalBus.hit_boss.emit(hitVelocity)
		boss_damaged.emit(damage) # maybe freeze time on boss hit and player hit? maybe just parry?
		$AttackHitTimer.start()
		
func _on_invulnerable_timer_timeout() -> void:
	set_collision_layer_value(2, true)

func _on_oc_1_area_body_entered(_body: Node2D) -> void:
	handle_hit_boss(2, 200 * directionFacing)

func _on_oc_2_area_body_entered(_body: Node2D) -> void:
	handle_hit_boss(2, 200 * directionFacing)

func _on_oc_3_area_body_entered(_body: Node2D) -> void:
	handle_hit_boss(6, 600 * directionFacing)
	
func _on_hit_player(damage: int, hitVelocity: int, requireOnFloor: bool = false) -> void:
	if((requireOnFloor && is_on_floor()) || !requireOnFloor):
		player_damaged.emit(damage)
		$AP.play('RESET') # reset properties (so hitboxes aren't active for example)
		$AP.advance(0)
		$AP.play('Knocked')
		velocity.x = hitVelocity

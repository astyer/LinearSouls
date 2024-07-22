extends Area2D

var speed = 200

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var players = get_tree().get_nodes_in_group("players")
	if players.size() == 0:
		return
	var player: Player = players[0]
	
	look_at(player.position)
	rotate(deg_to_rad(-90))
	var distanceToPlayer = position.distance_to(player.position)
	if(distanceToPlayer <= 40):
		$AnimationPlayer.play('swing')	
		return
	
	var directionToPlayer = position.direction_to(player.position)
	var velocity = directionToPlayer * speed
	position += velocity * delta

extends Node

func play_random_animation(AP: AnimationPlayer, options: Array[String]):
	AP.play(options[randi() % options.size()])

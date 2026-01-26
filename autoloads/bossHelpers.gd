extends Node

# pass options in the form { 'animName1': % likelihood, ... }
func play_random_animation(AP: AnimationPlayer, options: Dictionary[String, int]):
	var randNum = (randi() % 100)
	
	var sortedOptionKeys = options.keys()
	sortedOptionKeys.sort_custom(func(a, b): return options[a] < options[b])
	
	var adjustedOptionValues = []
	for i in sortedOptionKeys.size():
		var option = sortedOptionKeys[i]
		if i == 0:
			adjustedOptionValues.append(options[option])
		else:
			var prevAdjustedValue = adjustedOptionValues[i-1]
			adjustedOptionValues.append(options[option] + prevAdjustedValue)
		i+=1
		
	for i in sortedOptionKeys.size():
		if randNum < adjustedOptionValues[i] || i == sortedOptionKeys.size() - 1:
			AP.play(sortedOptionKeys[i])
			return
		i+=1

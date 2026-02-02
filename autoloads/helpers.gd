extends Node

# pass options in the form { 'optionKey': % likelihood, ... }
func rand_option(options: Dictionary[Variant, int]):
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
			return sortedOptionKeys[i]
		i+=1

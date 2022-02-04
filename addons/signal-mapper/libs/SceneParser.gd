extends Object

static func parse_scene(filename, node_name) -> Array:
	var file := File.new()
	
	var signals = []
	
	file.open(filename, File.READ)
	
	var file_content = file.get_as_text().split("\n")
	
	for line in file_content:
		if line.begins_with("[connection "):
			var tokens = line.split(" ")
			
			var from = get_value(tokens[2])
			var to = get_value(tokens[3])
			
			signals.append({
				"signal": get_value(tokens[1]),
				"from": from,
				"to": to,
				"method": get_value(tokens[4], -1)
			})
		

	file.close()
	return signals
	
static func get_value(attribute: String, offset=0):
	var tokens := attribute.split("=")
	
	return tokens[1].substr(1, len(tokens[1])-2+offset)

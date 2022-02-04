extends Object

static func parse_scene(filename) -> Array:
	var file := File.new()
	
	var signals = []
	
	file.open(filename, File.READ)
	
	var file_content = file.get_as_text().split("\n")
	
	for line in file_content:
		if line.begins_with("[connection "):
			var line_trimmed: String = line.substr(10, len(line)-11)
			
			var sig = {}
			
			
			var i = 0
			var ind = 0
			while true:
				var pre_ind = ind
				ind = line_trimmed.find("=", ind + 1)
				
				if ind == -1:
					break
					
				var next_ind = line_trimmed.find("=", ind + 1)
				var section = line_trimmed.substr(ind + 1, next_ind - ind)
			
				var key: String = line_trimmed.substr(pre_ind, ind - pre_ind).split(" ")[1].strip_edges()
				var value  = section.split(" ")[0].strip_edges()
				
				if value == "":
					value = line_trimmed.substr(ind + 1, len(line_trimmed) - ind)
				
				value = value.strip_edges().trim_prefix('"').trim_suffix('"')

				if key == "binds":
					value = parse_json(value)
				
				sig[key] = value
				
			
			var tokens = line.substr(12, len(line)-13).split(" ")
			
			signals.append(sig)
		

	file.close()
	return signals
	
static func get_value(attribute: String):
	var tokens := attribute.split("=")
	
	var word := tokens[1].substr(1, len(tokens[1])-2)

	return word.replace('"', "").replace("]", "")

extends PanelContainer
tool


const Parser = preload("res://addons/signal-mapper/libs/SceneParser.gd")

var _plugin: EditorPlugin
var signals = []

var node2graph := {} # <NodePath, GraphNode>
var graph_nodes := {} # <NodePath, GraphNode>

var latest_node: String = ""

onready var graph_parent: Control = $MarginContainer/VBoxContainer/MarginContainer
var graph: CustomGraphEdit

func init(plugin: EditorPlugin):
	_plugin = plugin
	
	plugin.connect("scene_changed", self, "set_root")


func set_root(node: Node):
	# Reset graph edit
	if graph:
		graph.queue_free()
	graph = CustomGraphEdit.new()
	graph_parent.add_child(graph)
	graph.connect("connection_request", self, "_on_connection_request")
			
	node2graph = {}
	graph_nodes = {}
			
	if node == null:
		return
	
	signals = Parser.parse_scene(node.filename)

	_set_node_recursive(node, node, graph)
		
	for sig in signals:
		node2graph[sig.from].add_signal(sig.signal)
	
	for node in graph.get_children():
		if node is NodeGraphNode:
			node.create_option_slot(NodeGraphNode.TYPE_SIGNAL)
	
	for sig in signals:
		var from: NodeGraphNode = node2graph[sig.from]
		var to: NodeGraphNode = node2graph[sig.to]
		
		to.add_method(sig.method)
		
		var to_name = to.name
		var to_slot = to.get_method_slot(sig.method)
		var from_name = from.name
		var from_slot = from.get_signal_slot(sig.signal)
		
		if from.offset < to.offset:
			var temp_name = to_name
			var temp_slot = to_slot
			to_name = from_name
			to_slot = from_slot
			from_name = temp_name
			from_slot = temp_slot
				
		graph.connect_node(to_name, to_slot, from_name, from_slot)
	
	for node in graph.get_children():
		if node is NodeGraphNode:
			node.create_option_slot(NodeGraphNode.TYPE_METHOD)
	
func _set_node_recursive(root: Node, node: Node, graph: GraphEdit, x=0, y=0):	
	# Check if not in-built children
	if node != root and node.owner == null:
		return
	
	var node_model := NodeGraphNode.new(_plugin, node)
	var node_path = root.get_path_to(node)
	
	if node_path != ".":
		node_model.title = "/" + String(node_path)
	else:
		node_model.title = root.name

	graph.add_child(node_model)
	
	node2graph[String(node_path)] = node_model
	graph_nodes[node_model.name] = node_model
	
	node_model.offset = Vector2(x, y)
	
	node_model.connect("dragged", self, "_on_node_dragged", [node_model])
	
	for i in node.get_child_count():
		_set_node_recursive(
			root, 
			node.get_child(i), 
			graph, 
			x + node_model.rect_size.x + 200, 
			i * (node_model.rect_size.y + 100))

func _on_connection_request(from, from_slot, to, to_slot):
	var from_node: NodeGraphNode = graph_nodes[from]
	var to_node: NodeGraphNode = graph_nodes[to]
	
	var from_type = from_node.get_slot_type(from_slot)
	var to_type = from_node.get_slot_type(to_slot)
	
	print(from_type, " | ", to_type)
	if (from_type + to_type) % 2 == 0:
		return
		
	graph.connect_node(from, from_slot, to, to_slot)
	

func _on_node_dragged(from, to, node):
	for c in graph.get_connection_list():
		graph.disconnect_node(c.from, c.from_port, c.to, c.to_port)
		
		if not graph.has_node(c.from) or not graph.has_node(c.to):
			return

		if graph.get_node(c.from).offset > graph.get_node(c.to).offset:
				graph.connect_node(
					c.to,
					c.to_port,
					c.from, 
					c.from_port
					)
		else:
			graph.connect_node(
				c.from, 
				c.from_port,
				c.to,
				c.to_port
				)
		

class NodeGraphNode extends GraphNode:
	const TYPE_SIGNAL = 0
	const TYPE_METHOD = 1
	const TYPE_NEW_SIGNAL = 2
	const TYPE_NEW_METHOD = 3
	
	var slot = 0
	
	# <name: String, slot: int>
	var _signals_slots = {}
	var _methods_slots = {}
	
	# <slot: int, name: String>
	var _signals = {}
	var _methods = {}
	var _types = {}
	
	var _plugin: EditorPlugin
	var _node: Node
	
	func _init(plugin, node):
		_plugin = plugin
		_node = node
		
	func get_signal_slot(_name):
		return _signals_slots[_name]
		
	func get_method_slot(_name):
		return _methods_slots[_name]
		
	func get_slot_type(_slot):
		return _types[_slot]
		
	func get_signal(slot):
		return _signals[slot]
		
	func get_method(slot):
		return _methods[slot]

	func add_signal(_name) :
		if _signals_slots.has(_name):
			return
		add_child(_create_slot(_name, TYPE_SIGNAL))
		set_slot(slot, true, TYPE_SIGNAL, Color.white,
			true, TYPE_SIGNAL, Color.white)
		_signals_slots[_name] = slot
		_signals[slot] = _name
		_types[slot] = TYPE_SIGNAL
		slot += 1
		
	func add_method(_name):
		if _methods_slots.has(_name):
			return
		add_child(_create_slot(_name, TYPE_METHOD))
		set_slot(slot, true, TYPE_METHOD, Color.lightcoral,
			true, TYPE_METHOD, Color.lightcoral)
		_methods_slots[_name] = slot
		_methods[slot] = _name
		_types[slot] = TYPE_METHOD
		slot += 1

		
	func create_option_slot(type):
		var hbox = HBoxContainer.new()
		
		var list = []
		
		if type == TYPE_SIGNAL:
			list = _node.get_signal_list()
		else:
			list = _node.get_method_list()
		
		var options = OptionButton.new()
		
		for i in range(len(list)):
			options.add_item(list[i].name, i)
			
		var icon := TextureRect.new()
		var icon_container := CenterContainer.new()
		
		icon.texture = _get_node_icon(
			"Signals" if type == TYPE_SIGNAL else "Signal"
			)
			
		icon_container.add_child(icon)
		hbox.add_child(icon_container)
		hbox.add_child(options)
			
		add_child(hbox)
		
		var color = Color.lightcoral if type == TYPE_METHOD else Color.white
		
		set_slot(slot, true, type + 2, color, true, type + 2, color, _get_node_icon("Add"), _get_node_icon("Add"))
		
		set_slot_enabled_left(slot, true)
		set_slot_enabled_right(slot, true)
		
		if type == TYPE_METHOD:
			set_slot_color_left(slot, Color.lightcoral)
			set_slot_color_right(slot, Color.lightcoral)
			
		_types[slot] = type + 2
		
		slot += 1
		

	func _create_slot(_name, type):
		var hbox := HBoxContainer.new()
		
		var icon := TextureRect.new()
		var icon_container := CenterContainer.new()
		
		icon.texture = _get_node_icon(
			"Signals" if type == TYPE_SIGNAL else "Signal"
			)
		
		var label = Label.new()
		label.text = _name
		
		icon_container.add_child(icon)
		
		hbox.add_child(icon_container)
		hbox.add_child(label)
		
		return hbox

	func _get_node_icon(node):
		var gui = _plugin.get_editor_interface().get_base_control()
		return gui.get_icon(node, "EditorIcons")


class CustomGraphEdit extends GraphEdit:
	func _ready():
		add_valid_connection_type(1, 0)
		add_valid_connection_type(0, 1)
		add_valid_connection_type(0, 3)
		add_valid_connection_type(3, 0)
		add_valid_connection_type(1, 2)
		add_valid_connection_type(2, 1)


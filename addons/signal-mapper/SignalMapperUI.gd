extends PanelContainer
tool


const Parser = preload("res://addons/signal-mapper/libs/SceneParser.gd")

var _plugin: EditorPlugin
var signals = []

var graph_nodes = {}

var latest_node: String = ""

onready var graph: GraphEdit = $MarginContainer/VBoxContainer/MarginContainer/GraphEdit

func init(plugin: EditorPlugin):
	_plugin = plugin
	
	plugin.connect("scene_changed", self, "set_root")


func set_root(node: Node):
	if node == null:
		return
	
	signals = Parser.parse_scene(node.filename, node.name)

	# Reset graph edit
	for child in graph.get_children():
		if child is GraphNode:
			child.queue_free()
	
	_set_node_recursive(node, node, graph)
		
	for sig in signals:
		graph_nodes[sig.from].add_signal(sig.signal)
	
	for node in graph.get_children():
		if node is NodeGraphNode:
			node.create_option_slot(NodeGraphNode.TYPE_SIGNAL)
	
	for sig in signals:
		var from = graph_nodes[sig.from]
		var to = graph_nodes[sig.to]
		
		to.add_method(sig.method)
		
		if from.offset > to.offset:
			graph.connect_node(
				to.name,
				to.methods[sig.method],
				from.name, 
				from.signals[sig.signal]
				)
		else:
			graph.connect_node(
				from.name, 
				from.signals[sig.signal],
				to.name,
				to.methods[sig.method]
				)
	
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
	
	graph_nodes[String(node_path)] = node_model
	
	node_model.offset = Vector2(x, y)
	
	node_model.connect("dragged", self, "_on_node_dragged", [node_model])
	
	for i in node.get_child_count():
		_set_node_recursive(
			root, 
			node.get_child(i), 
			graph, 
			x + node_model.rect_size.x + 200, 
			i * node_model.rect_size.y + 200)

func _on_connection_request(from, from_slot, to, to_slot):
	pass

func _on_node_dragged(from, to, node):
	for c in graph.get_connection_list():
		graph.disconnect_node(c.from, c.from_port, c.to, c.to_port)

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
	
	var slot = 0
	
	var signals = {}
	var methods = {}
	
	var _plugin: EditorPlugin
	var _node: Node
	
	func _init(plugin, node):
		_plugin = plugin
		_node = node

	func add_signal(_name) :
		add_child(_create_slot(_name, TYPE_SIGNAL))
		set_slot_enabled_left(slot, true)
		set_slot_enabled_right(slot, true)
		signals[_name] = slot
		slot += 1
		
	func add_method(_name):
		add_child(_create_slot(_name, TYPE_METHOD))
		set_slot_enabled_left(slot, true)
		set_slot_enabled_right(slot, true)
		set_slot_color_left(slot, Color.lightcoral)
		set_slot_color_right(slot, Color.lightcoral)
		methods[_name] = slot
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
		
		set_slot_enabled_left(slot, true)
		set_slot_enabled_right(slot, true)
		
		if type == TYPE_METHOD:
			set_slot_color_left(slot, Color.lightcoral)
			set_slot_color_right(slot, Color.lightcoral)
		
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

extends GraphNode

var _node
var _signals = []
var _methods = []

func _init(node: Node):
	_node = node

func add_signal(sig, to):
	var signal_label = _create_slot(name)
	_signals.append(SignalAttr.new(sig, SignalAttr.TYPE_SIGNAL, to))
	
func add_method(met, from):
	_methods.append(SignalAttr.new(met, SignalAttr.TYPE_METHOD, from))
	
func update_ports():
	var i = 0
	for sig in _signals:
		_create_slot(sig.name)
		set_slot_enabled_right(i, true)
		i += 1
	
	for con in _methods:
		_create_slot(con.name)
		set_slot_enabled_left(i, true)
		
		i += 1
		
func _create_slot(name):
	var label = Label.new()
	label.text = name
	add_child(label)
	
class SignalAttr:
	const TYPE_SIGNAL = 0
	const TYPE_METHOD = 1
	
	func _init(_name: String, _type: int, _connection: String):
		name = _name
		type = _type
		connection = _connection
	
	var name: String
	var type: int
	var connection: String

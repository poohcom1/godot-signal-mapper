tool
extends EditorPlugin

const SignalMapperUI = preload("res://addons/signal-mapper/SignalMapperUI.tscn")
var ui: Control


func _enter_tree():
	ui = SignalMapperUI.instance()
	ui.init(self)
	add_control_to_bottom_panel(ui, "Signals")

func _exit_tree():
	if ui:
		ui.queue_free()
		remove_control_from_bottom_panel(ui)

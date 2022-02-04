tool
extends EditorPlugin

const SignalMapperUI = preload("res://addons/signal-mapper/SignalMapperUI.tscn")
var ui: Control

 
func _enter_tree():
	ui = SignalMapperUI.instance()
	ui.init(self)
	
	# Add the main panel to the editor's main viewport.
	get_editor_interface().get_editor_viewport().add_child(ui)
	# Hide the main panel. Very much required.
	make_visible(false)
	
func _exit_tree():
	if ui:
		ui.queue_free()

func has_main_screen():
	return true


func make_visible(visible):
	if ui:
		ui.visible = visible


func get_plugin_name():
	return "Signals"


func get_plugin_icon():
	return get_editor_interface().get_base_control().get_icon("Signals", "EditorIcons")

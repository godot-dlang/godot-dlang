extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	# var t: TestD = TestD.new()
	# t.write_stuff()
	# $Panel/Label.set_text(str(t.writeStuffInt(42)))
	# t.test()
	# t._ready()
	# print("using static method: ", TestD.get_some_number())
	# print("int in variant: ", TestD.get_number_as_variant())
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_label_send_message(arg0):
	print("send_message received: ", arg0)
	$Panel/Label/One/Looooong/Incredibly/Unbroken/Node/Path/Label2.set_text(arg0)
	pass # Replace with function body.

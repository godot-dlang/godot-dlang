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
	
	var base = SomeConcreteClass.new() as SomeBaseClass
	
	# 'is' keyword should be able to handle inheritance, 
	# but base.get_class() will actually return SomeConcreteClass here
	# Object.is_class('name of class') will work just like 'is' though
	assert(base.is_class("SomeBaseClass"))
	assert(base is SomeBaseClass) 
	base.do_something()
	assert(base.foo == 42, "do_something expected to set base.foo, did you broke virtual call resolution?")
	
	# since this is an Object it is up to you to release it when you've done with it
	# don't forget to free it when it is no longer in use
	base.free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_label_send_message(arg0):
	print("send_message received: ", arg0)
	$Panel/Label/One/Looooong/Incredibly/Unbroken/Node/Path/Label2.set_text(arg0)

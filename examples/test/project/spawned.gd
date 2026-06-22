extends Node2D

# D side expects this to be 42, default 0, so the value comes from instantiated scene
@export var test: int

func _ready() -> void:
	print_debug("yay i am spawned")

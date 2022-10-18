module godot.c.arvr;

import godot.c.core;

version(none):
@nogc nothrow:
extern(C):

struct godot_xr_interface_gdnative
{
	void* function(godot_object) constructor;
	void function(void*) destructor;
	godot_string function(const void*) get_name;
	godot_int function(const void*) get_capabilities;
	godot_bool function(const void*) get_anchor_detection_is_enabled;
	void function(void*, godot_bool) set_anchor_detection_is_enabled;
	godot_bool function(const void*) is_stereo;
	godot_bool function(const void*) is_initialized;
	godot_bool function(void*) initialize;
	void function(void*) uninitialize;
	godot_vector2 function(const void*) get_render_targetsize;
	godot_transform function(void*, godot_int, godot_transform*) get_transform_for_eye;
	void function(void*, godot_float*, godot_int, godot_float, godot_float, godot_float) fill_projection_for_eye;
	void function(void*, godot_int, godot_rid*, godot_rect2*) commit_for_eye;
	void function(void*) process;
	godot_int function(void *, godot_int) get_external_texture_for_eye;
	void function(void *, godot_int) notification;
	godot_int function(void *) get_camera_feed_id;
}




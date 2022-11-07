module godot.abi.core;

// public import core.stdc.stddef : wchar_t;
public import godot.abi.gdextension;
import godot.api.types;


@nogc nothrow:
extern (C):

alias godot_api = GDNativeInterface;

// TODO: make sure it is propely loaded within extensions
__gshared GDNativeInterface* _godot_api;

enum GODOT_API_VERSION = 1;

////// MethodBind API

struct godot_method_bind {
    GDNativeMethodBindPtr ptr; // TODO
    alias ptr this;
}
/*
struct godot_gdnative_api_version {
	uint major;
	uint minor;
}

struct godot_gdnative_init_options {
	godot_bool in_editor;
	ulong core_api_hash;
	ulong editor_api_hash;
	ulong no_api_hash;
	void function(const godot_object p_library, const char *p_what, godot_gdnative_api_version p_want, godot_gdnative_api_version p_have) report_version_mismatch;
	void function(const godot_object p_library, const char *p_what) report_loading_error;
	godot_object gd_native_library; // pointer to GDNativeLibrary that is being initialized
	const(godot_gdnative_core_api_struct)* api_struct; // contains all C function pointers
	const(godot_string)* active_library_path;
}

struct godot_gdnative_terminate_options {
	godot_bool in_editor;
}
*/
// Alignment hardcoded in `core/variant/callable.h`.
enum GODOT_SIGNAL_SIZE = 16;

struct godot_signal {
    ubyte[GODOT_SIGNAL_SIZE] _opaque;
}

version (none)  : alias godot_class_constructor = godot_object function();

////// GDNative procedure types
alias godot_gdnative_init_fn = void function(godot_gdnative_init_options*);
alias godot_gdnative_terminate_fn = void function(godot_gdnative_terminate_options*);
alias godot_gdnative_procedure_fn = godot_variant function(void*, godot_array*);

alias native_call_cb = godot_variant function(void*, godot_array*);

// Types for function pointers.
alias godot_validated_operator_evaluator = void function(const godot_variant* p_left, const godot_variant* p_right, godot_variant* r_result);
alias godot_ptr_operator_evaluator = void function(const void* p_left, const void* p_right, void* r_result);
alias godot_validated_builtin_method = void function(godot_variant* p_base, const godot_variant** p_args, int p_argument_count, godot_variant* r_return);
alias godot_ptr_builtin_method = void function(void* p_base, const void** p_args, void* r_return, int p_argument_count);
alias godot_validated_constructor = void function(godot_variant* p_base, const godot_variant** p_args);
alias godot_ptr_constructor = void function(void* p_base, const void** p_args);
alias godot_validated_setter = void function(godot_variant* p_base, const godot_variant* p_value);
alias godot_validated_getter = void function(const godot_variant* p_base, godot_variant* r_value);
alias godot_ptr_setter = void function(void* p_base, const void* p_value);
alias godot_ptr_getter = void function(const void* p_base, void* r_value);
alias godot_validated_indexed_setter = void function(godot_variant* p_base, godot_int p_index, const godot_variant* p_value, bool* r_oob);
alias godot_validated_indexed_getter = void function(const godot_variant* p_base, godot_int p_index, godot_variant* r_value, bool* r_oob);
alias godot_ptr_indexed_setter = void function(void* p_base, godot_int p_index, const void* p_value);
alias godot_ptr_indexed_getter = void function(const void* p_base, godot_int p_index, void* r_value);
alias godot_validated_keyed_setter = void function(godot_variant* p_base, const godot_variant* p_key, const godot_variant* p_value, bool* r_valid);
alias godot_validated_keyed_getter = void function(const godot_variant* p_base, const godot_variant* p_key, godot_variant* r_value, bool* r_valid);
alias godot_validated_keyed_checker = bool function(const godot_variant* p_base, const godot_variant* p_key, bool* r_valid);
alias godot_ptr_keyed_setter = void function(void* p_base, const void* p_key, const void* p_value);
alias godot_ptr_keyed_getter = void function(const void* p_base, const void* p_key, void* r_value);
alias godot_ptr_keyed_checker = uint function(const godot_variant* p_base, const godot_variant* p_key);
alias godot_validated_utility_function = void function(godot_variant* r_return, const godot_variant** p_arguments, int p_argument_count);
alias godot_ptr_utility_function = void function(void* r_return, const void** p_arguments, int p_argument_count);

module godot.c.core;

public import core.stdc.stddef : wchar_t;
public import godot.c.gdnative_interface;
import godot.core.defs;

//import godot.c.api;

@nogc nothrow:
extern (C):

alias godot_api = GDNativeInterface;

// TODO: make sure it is propely loaded within extensions
__gshared GDNativeInterface* _godot_api;

enum GODOT_API_VERSION = 1;

////// Error

enum godot_error {
    GODOT_OK,
    GODOT_FAILED, ///< Generic fail error
    GODOT_ERR_UNAVAILABLE, ///< What is requested is unsupported/unavailable
    GODOT_ERR_UNCONFIGURED, ///< The object being used hasnt been properly set up yet
    GODOT_ERR_UNAUTHORIZED, ///< Missing credentials for requested resource
    GODOT_ERR_PARAMETER_RANGE_ERROR, ///< Parameter given out of range (5)
    GODOT_ERR_OUT_OF_MEMORY, ///< Out of memory
    GODOT_ERR_FILE_NOT_FOUND,
    GODOT_ERR_FILE_BAD_DRIVE,
    GODOT_ERR_FILE_BAD_PATH,
    GODOT_ERR_FILE_NO_PERMISSION, // (10)
    GODOT_ERR_FILE_ALREADY_IN_USE,
    GODOT_ERR_FILE_CANT_OPEN,
    GODOT_ERR_FILE_CANT_WRITE,
    GODOT_ERR_FILE_CANT_READ,
    GODOT_ERR_FILE_UNRECOGNIZED, // (15)
    GODOT_ERR_FILE_CORRUPT,
    GODOT_ERR_FILE_MISSING_DEPENDENCIES,
    GODOT_ERR_FILE_EOF,
    GODOT_ERR_CANT_OPEN, ///< Can't open a resource/socket/file
    GODOT_ERR_CANT_CREATE, // (20)
    GODOT_ERR_QUERY_FAILED,
    GODOT_ERR_ALREADY_IN_USE,
    GODOT_ERR_LOCKED, ///< resource is locked
    GODOT_ERR_TIMEOUT,
    GODOT_ERR_CANT_CONNECT, // (25)
    GODOT_ERR_CANT_RESOLVE,
    GODOT_ERR_CONNECTION_ERROR,
    GODOT_ERR_CANT_ACQUIRE_RESOURCE,
    GODOT_ERR_CANT_FORK,
    GODOT_ERR_INVALID_DATA, ///< Data passed is invalid	(30)
    GODOT_ERR_INVALID_PARAMETER, ///< Parameter passed is invalid
    GODOT_ERR_ALREADY_EXISTS, ///< When adding, item already exists
    GODOT_ERR_DOES_NOT_EXIST, ///< When retrieving/erasing, it item does not exist
    GODOT_ERR_DATABASE_CANT_READ, ///< database is full
    GODOT_ERR_DATABASE_CANT_WRITE, ///< database is full	(35)
    GODOT_ERR_COMPILATION_FAILED,
    GODOT_ERR_METHOD_NOT_FOUND,
    GODOT_ERR_LINK_FAILED,
    GODOT_ERR_SCRIPT_FAILED,
    GODOT_ERR_CYCLIC_LINK, // (40)
    GODOT_ERR_INVALID_DECLARATION,
    GODOT_ERR_DUPLICATE_SYMBOL,
    GODOT_ERR_PARSE_ERROR,
    GODOT_ERR_BUSY,
    GODOT_ERR_SKIP, // (45)
    GODOT_ERR_HELP, ///< user requested help!!
    GODOT_ERR_BUG, ///< a bug in the software certainly happened, due to a double check failing or unexpected behavior.
    GODOT_ERR_PRINTER_ON_FIRE, /// the parallel port printer is engulfed in flames
    GODOT_ERR_OMFG_THIS_IS_VERY_VERY_BAD, ///< shit happens, has never been used, though
    GODOT_ERR_WTF = GODOT_ERR_OMFG_THIS_IS_VERY_VERY_BAD ///< short version of the above
}

////// bool

alias godot_bool = bool;

enum GODOT_TRUE = 1;
enum GODOT_FALSE = 0;

/////// int

alias godot_int = int;

/////// real
version (GODOT_USE_DOUBLE)
    alias godot_real_t = double;
else
    alias godot_real_t = float;

// TODO: use proper config for GODOT_USE_DOUBLE
alias godot_float = double;

alias uint64 = ulong;
alias uint64_t = uint64;
alias int64 = long;
alias int64_t = int64;
alias uint32 = uint;
alias uint32_t = uint32;
alias int32 = int;
alias int32_t = int32;
alias uint16 = ushort;
alias uint16_t = uint16;
alias int16 = short;
alias int16_t = int16;
alias uint8 = ubyte;
alias uint8_t = uint8;
alias int8 = byte;
alias int8_t = int8;

// AFAIK this is not related to godot_float and always has fixed size
//alias real_t = double;
alias real_t = godot.core.defs.real_t;

// internal godot id
struct ObjectID {
    uint64_t id;
}

alias char16_t = ushort;
alias char32_t = uint;

/////// Object reference (type-safe void pointer)
struct godot_object {
    package(godot) void* ptr;
}

// core types
// NOTE: quite a few of these have sizes that cause D to generate incorrect
// calling convention for SysV ABI (bugs 5570 & 13207). Partial workaround is
// using larger integers instead of byte arrays. Needs fixing eventually...

struct godot_array {
    size_t _opaque;
}

struct godot_basis {
    uint[9] _opaque;
}

struct godot_color {
    ulong[2] _opaque;
}

struct godot_dictionary {
    size_t _opaque;
}

struct godot_node_path {
    ubyte[8] _opaque;
}

struct godot_plane {
    ubyte[4 * godot_real_t.sizeof] _opaque;
}

mixin template PackedArray(Type, string name) {
    mixin("struct godot_packed_" ~ name ~ "_array { size_t _opaque; }");
    //mixin("struct godot_packed_"~name~"_array_read_access { ubyte _opaque; }");
    //mixin("struct godot_packed_"~name~"_array_write_access { ubyte _opaque; }");
}

mixin PackedArray!(ubyte, "byte");
mixin PackedArray!(int, "int32");
mixin PackedArray!(long, "int64");
mixin PackedArray!(float, "float32");
mixin PackedArray!(double, "float64");
mixin PackedArray!(godot_string, "string");
mixin PackedArray!(godot_vector2, "vector2");
mixin PackedArray!(godot_vector3, "vector3");
mixin PackedArray!(godot_color, "color");

// Alignment hardcoded in `core/variant/callable.h`.
enum GODOT_CALLABLE_SIZE = 16;

struct godot_callable {
    ubyte[GODOT_CALLABLE_SIZE] _opaque;
}

struct godot_quaternion {
    ubyte[4 * godot_real_t.sizeof] _opaque;
}

struct godot_rect2 {
    ubyte[4 * godot_real_t.sizeof] _opaque;
}

struct godot_rect2i {
    ubyte[4 * int.sizeof] _opaque;
}

struct godot_aabb {
    ubyte[6 * godot_real_t.sizeof] _opaque;
}

struct godot_rid {
    ulong _opaque;
}

struct godot_string {
    size_t _opaque;
}

struct godot_char_string {
    size_t _opaque;
}

struct godot_transform3d {
    ubyte[12 * godot_real_t.sizeof] _opaque;
}

struct godot_transform2d {
    ubyte[6 * godot_real_t.sizeof] _opaque;
}

struct godot_variant {
    ubyte[24] _opaque;
}

enum godot_variant_type {
    GODOT_VARIANT_TYPE_NIL,

    // atomic types
    GODOT_VARIANT_TYPE_BOOL,
    GODOT_VARIANT_TYPE_INT,
    GODOT_VARIANT_TYPE_FLOAT,
    GODOT_VARIANT_TYPE_STRING,

    // math types

    GODOT_VARIANT_TYPE_VECTOR2, // 5
    GODOT_VARIANT_TYPE_VECTOR2I,
    GODOT_VARIANT_TYPE_RECT2,
    GODOT_VARIANT_TYPE_RECT2I,
    GODOT_VARIANT_TYPE_VECTOR3,
    GODOT_VARIANT_TYPE_VECTOR3I, // 10
    GODOT_VARIANT_TYPE_TRANSFORM2D,
    GODOT_VARIANT_TYPE_VECTOR4,
    GODOT_VARIANT_TYPE_VECTOR4I, // 10
    GODOT_VARIANT_TYPE_PLANE,
    GODOT_VARIANT_TYPE_QUATERNION,
    GODOT_VARIANT_TYPE_AABB,
    GODOT_VARIANT_TYPE_BASIS, // 15
    GODOT_VARIANT_TYPE_TRANSFORM3D,
    GODOT_VARIANT_TYPE_PROJECTION,

    // misc types
    GODOT_VARIANT_TYPE_COLOR,
    GODOT_VARIANT_TYPE_STRING_NAME,
    GODOT_VARIANT_TYPE_NODE_PATH,
    GODOT_VARIANT_TYPE_RID, // 20
    GODOT_VARIANT_TYPE_OBJECT,
    GODOT_VARIANT_TYPE_CALLABLE,
    GODOT_VARIANT_TYPE_SIGNAL,
    GODOT_VARIANT_TYPE_DICTIONARY,
    GODOT_VARIANT_TYPE_ARRAY, // 25

    // arrays
    GODOT_VARIANT_TYPE_PACKED_BYTE_ARRAY,
    GODOT_VARIANT_TYPE_PACKED_INT32_ARRAY,
    GODOT_VARIANT_TYPE_PACKED_INT64_ARRAY,
    GODOT_VARIANT_TYPE_PACKED_FLOAT32_ARRAY,
    GODOT_VARIANT_TYPE_PACKED_FLOAT64_ARRAY, // 30
    GODOT_VARIANT_TYPE_PACKED_STRING_ARRAY,
    GODOT_VARIANT_TYPE_PACKED_VECTOR2_ARRAY,
    GODOT_VARIANT_TYPE_PACKED_VECTOR3_ARRAY,
    GODOT_VARIANT_TYPE_PACKED_COLOR_ARRAY,
}

enum godot_variant_call_error_error {
    GODOT_CALL_ERROR_CALL_OK,
    GODOT_CALL_ERROR_CALL_ERROR_INVALID_METHOD,
    GODOT_CALL_ERROR_CALL_ERROR_INVALID_ARGUMENT,
    GODOT_CALL_ERROR_CALL_ERROR_TOO_MANY_ARGUMENTS,
    GODOT_CALL_ERROR_CALL_ERROR_TOO_FEW_ARGUMENTS,
    GODOT_CALL_ERROR_CALL_ERROR_INSTANCE_IS_NULL,
}

struct godot_variant_call_error {
    godot_variant_call_error_error error;
    int argument;
    godot_variant_type expected;
}

enum godot_variant_operator {
    // comparison
    GODOT_VARIANT_OP_EQUAL,
    GODOT_VARIANT_OP_NOT_EQUAL,
    GODOT_VARIANT_OP_LESS,
    GODOT_VARIANT_OP_LESS_EQUAL,
    GODOT_VARIANT_OP_GREATER,
    GODOT_VARIANT_OP_GREATER_EQUAL,

    // mathematic
    GODOT_VARIANT_OP_ADD,
    GODOT_VARIANT_OP_SUBTRACT,
    GODOT_VARIANT_OP_MULTIPLY,
    GODOT_VARIANT_OP_DIVIDE,
    GODOT_VARIANT_OP_NEGATE,
    GODOT_VARIANT_OP_POSITIVE,
    GODOT_VARIANT_OP_MODULE,
    //GODOT_VARIANT_OP_STRING_CONCAT,

    // bitwise
    GODOT_VARIANT_OP_SHIFT_LEFT,
    GODOT_VARIANT_OP_SHIFT_RIGHT,
    GODOT_VARIANT_OP_BIT_AND,
    GODOT_VARIANT_OP_BIT_OR,
    GODOT_VARIANT_OP_BIT_XOR,
    GODOT_VARIANT_OP_BIT_NEGATE,

    // logic
    GODOT_VARIANT_OP_AND,
    GODOT_VARIANT_OP_OR,
    GODOT_VARIANT_OP_XOR,
    GODOT_VARIANT_OP_NOT,

    // containment
    GODOT_VARIANT_OP_IN,

    GODOT_VARIANT_OP_MAX,
}

enum godot_variant_utility_function_type {
    GODOT_UTILITY_FUNC_TYPE_MATH,
    GODOT_UTILITY_FUNC_TYPE_RANDOM,
    GODOT_UTILITY_FUNC_TYPE_GENERAL
}

struct godot_vector2 {
    ubyte[2 * godot_real_t.sizeof] _opaque;
}

struct godot_vector2i {
    uint[2] _opaque;
}

struct godot_vector3 {
    ubyte[3 * godot_real_t.sizeof] _opaque;
}

struct godot_vector3i {
    uint[3] _opaque;
}

struct godot_vector4 {
    ubyte[4 * godot_real_t.sizeof] _opaque;
}

struct godot_vector4i {
    uint[4] _opaque;
}

struct godot_projection {
    godot_vector4[4] _opaque;
}

enum godot_vector3_axis {
    GODOT_VECTOR3_AXIS_X,
    GODOT_VECTOR3_AXIS_Y,
    GODOT_VECTOR3_AXIS_Z,
}

// Packed arrays
struct godot_packed_byte_array {
    size_t[2] _opaque;
}

struct godot_packed_int32_array {
    size_t[2] _opaque;
}

struct godot_packed_int64_array {
    size_t[2] _opaque;
}

struct godot_packed_float32_array {
    size_t[2] _opaque;
}

struct godot_packed_float64_array {
    size_t[2] _opaque;
}

struct godot_packed_string_array {
    size_t[2] _opaque;
}

struct godot_packed_vector2_array {
    size_t[2] _opaque;
}

struct godot_packed_vector2i_array {
    size_t[2] _opaque;
}

struct godot_packed_vector3_array {
    size_t[2] _opaque;
}

struct godot_packed_vector3i_array {
    size_t[2] _opaque;
}

struct godot_packed_color_array {
    size_t[2] _opaque;
}

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

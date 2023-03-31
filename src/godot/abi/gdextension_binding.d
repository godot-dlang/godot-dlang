/*************************************************************************/
/*  gdextension_interface.h                                              */
/*************************************************************************/
/*                       This file is part of:                           */
/*                           GODOT ENGINE                                */
/*                      https://godotengine.org                          */
/*************************************************************************/
/* Copyright (c) 2007-2022 Juan Linietsky, Ariel Manzur.                 */
/* Copyright (c) 2014-2022 Godot Engine contributors (cf. AUTHORS.md).   */
/*                                                                       */
/* Permission is hereby granted, free of charge, to any person obtaining */
/* a copy of this software and associated documentation files (the       */
/* "Software"), to deal in the Software without restriction, including   */
/* without limitation the rights to use, copy, modify, merge, publish,   */
/* distribute, sublicense, and/or sell copies of the Software, and to    */
/* permit persons to whom the Software is furnished to do so, subject to */
/* the following conditions:                                             */
/*                                                                       */
/* The above copyright notice and this permission notice shall be        */
/* included in all copies or substantial portions of the Software.       */
/*                                                                       */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF    */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.*/
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY  */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,  */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE     */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                */
/*************************************************************************/

/* This is a C class header, you can copy it and use it directly in your own binders.
 * Together with the JSON file, you should be able to generate any binder.
 */

module godot.abi.gdextension_binding;

import godot.abi.types;
import core.stdc.config;
public import core.stdc.stddef : wchar_t;

extern (C):
//@nogc nothrow:

/* VARIANT TYPES */

alias GDExtensionVariantType = int;
enum : GDExtensionVariantType {
    GDEXTENSION_VARIANT_TYPE_NIL,

    /*  atomic types */
    GDEXTENSION_VARIANT_TYPE_BOOL,
    GDEXTENSION_VARIANT_TYPE_INT,
    GDEXTENSION_VARIANT_TYPE_FLOAT,
    GDEXTENSION_VARIANT_TYPE_STRING,

    /* math types */
    GDEXTENSION_VARIANT_TYPE_VECTOR2,
    GDEXTENSION_VARIANT_TYPE_VECTOR2I,
    GDEXTENSION_VARIANT_TYPE_RECT2,
    GDEXTENSION_VARIANT_TYPE_RECT2I,
    GDEXTENSION_VARIANT_TYPE_VECTOR3,
    GDEXTENSION_VARIANT_TYPE_VECTOR3I,
    GDEXTENSION_VARIANT_TYPE_TRANSFORM2D,
    GDEXTENSION_VARIANT_TYPE_VECTOR4,
    GDEXTENSION_VARIANT_TYPE_VECTOR4I,
    GDEXTENSION_VARIANT_TYPE_PLANE,
    GDEXTENSION_VARIANT_TYPE_QUATERNION,
    GDEXTENSION_VARIANT_TYPE_AABB,
    GDEXTENSION_VARIANT_TYPE_BASIS,
    GDEXTENSION_VARIANT_TYPE_TRANSFORM3D,
    GDEXTENSION_VARIANT_TYPE_PROJECTION,

    /* misc types */
    GDEXTENSION_VARIANT_TYPE_COLOR,
    GDEXTENSION_VARIANT_TYPE_STRING_NAME,
    GDEXTENSION_VARIANT_TYPE_NODE_PATH,
    GDEXTENSION_VARIANT_TYPE_RID,
    GDEXTENSION_VARIANT_TYPE_OBJECT,
    GDEXTENSION_VARIANT_TYPE_CALLABLE,
    GDEXTENSION_VARIANT_TYPE_SIGNAL,
    GDEXTENSION_VARIANT_TYPE_DICTIONARY,
    GDEXTENSION_VARIANT_TYPE_ARRAY,

    /* typed arrays */
    GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY,
    GDEXTENSION_VARIANT_TYPE_PACKED_INT32_ARRAY,
    GDEXTENSION_VARIANT_TYPE_PACKED_INT64_ARRAY,
    GDEXTENSION_VARIANT_TYPE_PACKED_FLOAT32_ARRAY,
    GDEXTENSION_VARIANT_TYPE_PACKED_FLOAT64_ARRAY,
    GDEXTENSION_VARIANT_TYPE_PACKED_STRING_ARRAY,
    GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR2_ARRAY,
    GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR3_ARRAY,
    GDEXTENSION_VARIANT_TYPE_PACKED_COLOR_ARRAY,

    GDEXTENSION_VARIANT_TYPE_VARIANT_MAX
}

alias GDExtensionVariantOperator = int;
enum : GDExtensionVariantOperator {
    /* comparison */
    GDEXTENSION_VARIANT_OP_EQUAL,
    GDEXTENSION_VARIANT_OP_NOT_EQUAL,
    GDEXTENSION_VARIANT_OP_LESS,
    GDEXTENSION_VARIANT_OP_LESS_EQUAL,
    GDEXTENSION_VARIANT_OP_GREATER,
    GDEXTENSION_VARIANT_OP_GREATER_EQUAL,

    /* mathematic */
    GDEXTENSION_VARIANT_OP_ADD,
    GDEXTENSION_VARIANT_OP_SUBTRACT,
    GDEXTENSION_VARIANT_OP_MULTIPLY,
    GDEXTENSION_VARIANT_OP_DIVIDE,
    GDEXTENSION_VARIANT_OP_NEGATE,
    GDEXTENSION_VARIANT_OP_POSITIVE,
    GDEXTENSION_VARIANT_OP_MODULE,
    GDEXTENSION_VARIANT_OP_POWER,

    /* bitwise */
    GDEXTENSION_VARIANT_OP_SHIFT_LEFT,
    GDEXTENSION_VARIANT_OP_SHIFT_RIGHT,
    GDEXTENSION_VARIANT_OP_BIT_AND,
    GDEXTENSION_VARIANT_OP_BIT_OR,
    GDEXTENSION_VARIANT_OP_BIT_XOR,
    GDEXTENSION_VARIANT_OP_BIT_NEGATE,

    /* logic */
    GDEXTENSION_VARIANT_OP_AND,
    GDEXTENSION_VARIANT_OP_OR,
    GDEXTENSION_VARIANT_OP_XOR,
    GDEXTENSION_VARIANT_OP_NOT,

    /* containment */
    GDEXTENSION_VARIANT_OP_IN,
    GDEXTENSION_VARIANT_OP_MAX

}

alias GDExtensionVariantPtr = void*;
alias GDExtensionConstVariantPtr = const(void)*;
alias GDExtensionStringNamePtr = void*;
alias GDExtensionConstStringNamePtr = const(void)*;
alias GDExtensionStringPtr = void*;
alias GDExtensionConstStringPtr = const(void)*;
alias GDExtensionObjectPtr = void*;
alias GDExtensionConstObjectPtr = const(void)*;
alias GDExtensionTypePtr = void*;
alias GDExtensionConstTypePtr = const(void)*;
alias GDExtensionMethodBindPtr = const(void)*;
alias GDExtensionInt = int64_t;
alias GDExtensionBool = uint8_t;
alias GDObjectInstanceID = uint64_t;
alias GDExtensionRefPtr = void*;
alias GDExtensionConstRefPtr = const(void)*;

/* VARIANT DATA I/O */

alias GDExtensionCallErrorType = int;
enum : GDExtensionCallErrorType {
    GDEXTENSION_CALL_OK,
    GDEXTENSION_CALL_ERROR_INVALID_METHOD,
    GDEXTENSION_CALL_ERROR_INVALID_ARGUMENT, // Expected a different variant type.
    GDEXTENSION_CALL_ERROR_TOO_MANY_ARGUMENTS, // Expected lower number of arguments.
    GDEXTENSION_CALL_ERROR_TOO_FEW_ARGUMENTS, // Expected higher number of arguments.
    GDEXTENSION_CALL_ERROR_INSTANCE_IS_NULL,
    GDEXTENSION_CALL_ERROR_METHOD_NOT_CONST, // Used for const call.

}

struct GDExtensionCallError {
    //@nogc nothrow:
    GDExtensionCallErrorType error;
    int32_t argument;
    int32_t expected;
}

alias GDExtensionVariantFromTypeConstructorFunc = void function(GDExtensionVariantPtr, GDExtensionTypePtr);
alias GDExtensionTypeFromVariantConstructorFunc = void function(GDExtensionTypePtr, GDExtensionVariantPtr);
alias GDExtensionPtrOperatorEvaluator = void function(const GDExtensionTypePtr p_left, const GDExtensionTypePtr p_right, GDExtensionTypePtr r_result);
alias GDExtensionPtrBuiltInMethod = void function(GDExtensionTypePtr p_base, const GDExtensionTypePtr* p_args, GDExtensionTypePtr r_return, int p_argument_count);
alias GDExtensionPtrConstructor = void function(GDExtensionTypePtr p_base, const GDExtensionTypePtr* p_args);
alias GDExtensionPtrDestructor = void function(GDExtensionTypePtr p_base);
alias GDExtensionPtrSetter = void function(GDExtensionTypePtr p_base, const GDExtensionTypePtr p_value);
alias GDExtensionPtrGetter = void function(const GDExtensionTypePtr p_base, GDExtensionTypePtr r_value);
alias GDExtensionPtrIndexedSetter = void function(GDExtensionTypePtr p_base, GDExtensionInt p_index, const GDExtensionTypePtr p_value);
alias GDExtensionPtrIndexedGetter = void function(const GDExtensionTypePtr p_base, GDExtensionInt p_index, GDExtensionTypePtr r_value);
alias GDExtensionPtrKeyedSetter = void function(GDExtensionTypePtr p_base, const GDExtensionTypePtr p_key, const GDExtensionTypePtr p_value);
alias GDExtensionPtrKeyedGetter = void function(const GDExtensionTypePtr p_base, const GDExtensionTypePtr p_key, GDExtensionTypePtr r_value);
alias GDExtensionPtrKeyedChecker = uint32_t function(const GDExtensionVariantPtr p_base, const GDExtensionVariantPtr p_key);
alias GDExtensionPtrUtilityFunction = void function(GDExtensionTypePtr r_return, const GDExtensionTypePtr* p_arguments, int p_argument_count);

alias GDExtensionClassConstructor = GDExtensionObjectPtr function();

alias GDExtensionInstanceBindingCreateCallback = void* function(void* p_token, void* p_instance);
alias GDExtensionInstanceBindingFreeCallback = void function(void* p_token, void* p_instance, void* p_binding);
alias GDExtensionInstanceBindingReferenceCallback = GDExtensionBool function(
    void* p_token, void* p_binding, GDExtensionBool p_reference);

struct GDExtensionInstanceBindingCallbacks {
    //@nogc nothrow:
    GDExtensionInstanceBindingCreateCallback create_callback;
    GDExtensionInstanceBindingFreeCallback free_callback;
    GDExtensionInstanceBindingReferenceCallback reference_callback;
}

/* EXTENSION CLASSES */

alias GDExtensionClassInstancePtr = void*;

alias GDExtensionClassSet = GDExtensionBool function(GDExtensionClassInstancePtr p_instance, const GDExtensionStringNamePtr p_name, const GDExtensionVariantPtr p_value);
alias GDExtensionClassGet = GDExtensionBool function(GDExtensionClassInstancePtr p_instance, const GDExtensionStringNamePtr p_name, GDExtensionVariantPtr r_ret);
alias GDExtensionClassGetRID = uint64_t function(GDExtensionClassInstancePtr p_instance);

struct GDExtensionPropertyInfo {
    //@nogc nothrow:
    GDExtensionVariantType type;
    GDExtensionStringNamePtr name;
    GDExtensionStringNamePtr class_name;
    uint32_t hint; // Bitfield of `PropertyHint` (defined in `extension_api.json`).
    GDExtensionStringNamePtr hint_string;
    uint32_t usage; // Bitfield of `PropertyUsageFlags` (defined in `extension_api.json`).
}

struct GDExtensionMethodInfo {
    //@nogc nothrow:
    GDExtensionStringNamePtr name;
    GDExtensionPropertyInfo return_value;
    uint32_t flags; // Bitfield of `GDExtensionClassMethodFlags`.
    int32_t id;

    /* Arguments: `default_arguments` is an array of size `argument_count`. */
    uint32_t argument_count;
    GDExtensionPropertyInfo* arguments;

    /* Default arguments: `default_arguments` is an array of size `default_argument_count`. */
    uint32_t default_argument_count;
    GDExtensionVariantPtr* default_arguments;
}

alias GDExtensionClassGetPropertyList = const GDExtensionPropertyInfo* function(
    GDExtensionClassInstancePtr p_instance, uint32_t* r_count);
alias GDExtensionClassFreePropertyList = void function(
    GDExtensionClassInstancePtr p_instance, const GDExtensionPropertyInfo* p_list);
alias GDExtensionClassPropertyCanRevert = GDExtensionBool function(
    GDExtensionClassInstancePtr p_instance, const GDExtensionStringNamePtr p_name);
alias GDExtensionClassPropertyGetRevert = GDExtensionBool function(
    GDExtensionClassInstancePtr p_instance, const GDExtensionStringNamePtr p_name, GDExtensionVariantPtr r_ret);
alias GDExtensionClassNotification = void function(
    GDExtensionClassInstancePtr p_instance, int32_t p_what);
alias GDExtensionClassToString = void function(
    GDExtensionClassInstancePtr p_instance, GDExtensionBool *r_is_valid, GDExtensionStringPtr p_out);
alias GDExtensionClassReference = void function(GDExtensionClassInstancePtr p_instance);
alias GDExtensionClassUnreference = void function(GDExtensionClassInstancePtr p_instance);
alias GDExtensionClassCallVirtual = void function(GDExtensionClassInstancePtr p_instance, const GDExtensionTypePtr* p_args, GDExtensionTypePtr r_ret);
alias GDExtensionClassCreateInstance = GDExtensionObjectPtr function(void* p_userdata);
alias GDExtensionClassFreeInstance = void function(void* p_userdata, GDExtensionClassInstancePtr p_instance);
alias GDExtensionClassGetVirtual = GDExtensionClassCallVirtual function(
    void* p_userdata, const GDExtensionStringNamePtr p_name);

struct GDExtensionClassCreationInfo {
    //@nogc nothrow:
    GDExtensionBool is_virtual;
    GDExtensionBool is_abstract;
    GDExtensionClassSet set_func;
    GDExtensionClassGet get_func;
    GDExtensionClassGetPropertyList get_property_list_func;
    GDExtensionClassFreePropertyList free_property_list_func;
    GDExtensionClassPropertyCanRevert property_can_revert_func;
    GDExtensionClassPropertyGetRevert property_get_revert_func;
    GDExtensionClassNotification notification_func;
    GDExtensionClassToString to_string_func;
    GDExtensionClassReference reference_func;
    GDExtensionClassUnreference unreference_func;
    GDExtensionClassCreateInstance create_instance_func; // (Default) constructor; mandatory. If the class is not instantiable, consider making it virtual or abstract.
    GDExtensionClassFreeInstance free_instance_func; // Destructor; mandatory.
    GDExtensionClassGetVirtual get_virtual_func; // Queries a virtual function by name and returns a callback to invoke the requested virtual function.
    GDExtensionClassGetRID get_rid_func;
    void* class_userdata; // Per-class user data, later accessible in instance bindings.
}

alias GDExtensionClassLibraryPtr = void*;

/* Method */

alias GDExtensionClassMethodFlags = int;
enum : GDExtensionClassMethodFlags {
    GDEXTENSION_METHOD_FLAG_NORMAL = 1,
    GDEXTENSION_METHOD_FLAG_EDITOR = 2,
    GDEXTENSION_METHOD_FLAG_CONST = 4,
    GDEXTENSION_METHOD_FLAG_VIRTUAL = 8,
    GDEXTENSION_METHOD_FLAG_VARARG = 16,
    GDEXTENSION_METHOD_FLAG_STATIC = 32,
    GDEXTENSION_METHOD_FLAGS_DEFAULT = GDEXTENSION_METHOD_FLAG_NORMAL,
}

alias GDExtensionClassMethodArgumentMetadata = int;
enum : GDExtensionClassMethodArgumentMetadata {
    GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE,
    GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_INT8,
    GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_INT16,
    GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_INT32,
    GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_INT64,
    GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_UINT8,
    GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_UINT16,
    GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_UINT32,
    GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_UINT64,
    GDEXTENSION_METHOD_ARGUMENT_METADATA_REAL_IS_FLOAT,
    GDEXTENSION_METHOD_ARGUMENT_METADATA_REAL_IS_DOUBLE
}

alias GDExtensionClassMethodCall = void function(void* method_userdata, GDExtensionClassInstancePtr p_instance, const(GDExtensionVariantPtr)* p_args, GDExtensionInt p_argument_count, GDExtensionVariantPtr r_return, GDExtensionCallError* r_error);
alias GDExtensionClassMethodPtrCall = void function(void* method_userdata, GDExtensionClassInstancePtr p_instance, const(GDExtensionTypePtr)* p_args, GDExtensionTypePtr r_ret);

/* passing -1 as argument in the following functions refers to the return type */
alias GDExtensionClassMethodGetArgumentType = GDExtensionVariantType function(
    void* p_method_userdata, int32_t p_argument);
alias GDExtensionClassMethodGetArgumentInfo = void function(
    void* p_method_userdata, int32_t p_argument, GDExtensionPropertyInfo* r_info);
alias GDExtensionClassMethodGetArgumentMetadata = GDExtensionClassMethodArgumentMetadata function(
    void* p_method_userdata, int32_t p_argument);

struct GDExtensionClassMethodInfo {
    //@nogc nothrow:
    GDExtensionStringNamePtr name;
    void* method_userdata;
    GDExtensionClassMethodCall call_func;
    GDExtensionClassMethodPtrCall ptrcall_func;
    uint32_t method_flags; // Bitfield of `GDExtensionClassMethodFlags`.

	/* If `has_return_value` is false, `return_value_info` and `return_value_metadata` are ignored. */
	GDExtensionBool has_return_value;
	GDExtensionPropertyInfo* return_value_info;
	GDExtensionClassMethodArgumentMetadata return_value_metadata;

	/* Arguments: `arguments_info` and `arguments_metadata` are array of size `argument_count`.
	 * Name and hint information for the argument can be omitted in release builds. Class name should always be present if it applies.
	 */
	uint32_t argument_count;
	GDExtensionPropertyInfo* arguments_info;
	GDExtensionClassMethodArgumentMetadata* arguments_metadata;

	/* Default arguments: `default_arguments` is an array of size `default_argument_count`. */
	uint32_t default_argument_count;
	GDExtensionVariantPtr* default_arguments;
}

/* SCRIPT INSTANCE EXTENSION */

alias GDExtensionScriptInstanceDataPtr = void*; // Pointer to custom ScriptInstance native implementation.

alias GDExtensionScriptInstanceSet = GDExtensionBool function(GDExtensionScriptInstanceDataPtr p_instance, const GDExtensionStringNamePtr p_name, const GDExtensionVariantPtr p_value);
alias GDExtensionScriptInstanceGet = GDExtensionBool function(GDExtensionScriptInstanceDataPtr p_instance, const GDExtensionStringNamePtr p_name, GDExtensionVariantPtr r_ret);
alias GDExtensionScriptInstanceGetPropertyList = const GDExtensionPropertyInfo function(
    GDExtensionScriptInstanceDataPtr p_instance, uint32_t* r_count);
alias GDExtensionScriptInstanceFreePropertyList = void function(
    GDExtensionScriptInstanceDataPtr p_instance, const GDExtensionPropertyInfo* p_list);
alias GDExtensionScriptInstanceGetPropertyType = GDExtensionVariantType function(
    GDExtensionScriptInstanceDataPtr p_instance, const GDExtensionStringNamePtr p_name, GDExtensionBool* r_is_valid);

alias GDExtensionScriptInstancePropertyCanRevert = GDExtensionBool function(
    GDExtensionScriptInstanceDataPtr p_instance, const GDExtensionStringNamePtr p_name);
alias GDExtensionScriptInstancePropertyGetRevert = GDExtensionBool function(
    GDExtensionScriptInstanceDataPtr p_instance, const GDExtensionStringNamePtr p_name, GDExtensionVariantPtr r_ret);

alias GDExtensionScriptInstanceGetOwner = GDExtensionObjectPtr function(
    GDExtensionScriptInstanceDataPtr p_instance);
alias GDExtensionScriptInstancePropertyStateAdd = void function(
    const GDExtensionStringNamePtr p_name, const GDExtensionVariantPtr p_value, void* p_userdata);
alias GDExtensionScriptInstanceGetPropertyState = void function(GDExtensionScriptInstanceDataPtr p_instance, GDExtensionScriptInstancePropertyStateAdd p_add_func, void* p_userdata);

alias GDExtensionScriptInstanceGetMethodList = const GDExtensionMethodInfo function(
    GDExtensionScriptInstanceDataPtr p_instance, uint32_t* r_count);
alias GDExtensionScriptInstanceFreeMethodList = void function(
    GDExtensionScriptInstanceDataPtr p_instance, const GDExtensionMethodInfo* p_list);

alias GDExtensionScriptInstanceHasMethod = GDExtensionBool function(
    GDExtensionScriptInstanceDataPtr p_instance, const GDExtensionStringNamePtr p_name);

alias GDExtensionScriptInstanceCall = void function(
    GDExtensionScriptInstanceDataPtr p_self, const GDExtensionStringNamePtr p_method, const GDExtensionVariantPtr* p_args, const GDExtensionInt p_argument_count, GDExtensionVariantPtr r_return, GDExtensionCallError* r_error);
alias GDExtensionScriptInstanceNotification = void function(
    GDExtensionScriptInstanceDataPtr p_instance, int32_t p_what);
alias GDExtensionScriptInstanceToString = void function(
    GDExtensionScriptInstanceDataPtr p_instance, GDExtensionBool* r_is_valid, GDExtensionStringPtr r_out);

alias GDExtensionScriptInstanceRefCountIncremented = void function(
    GDExtensionScriptInstanceDataPtr p_instance);
alias GDExtensionScriptInstanceRefCountDecremented = GDExtensionBool function(
    GDExtensionScriptInstanceDataPtr p_instance);

alias GDExtensionScriptInstanceGetScript = GDExtensionObjectPtr function(
    GDExtensionScriptInstanceDataPtr p_instance);
alias GDExtensionScriptInstanceIsPlaceholder = GDExtensionBool function(
    GDExtensionScriptInstanceDataPtr p_instance);

alias GDExtensionScriptLanguagePtr = void*;

alias GDExtensionScriptInstanceGetLanguage = GDExtensionScriptLanguagePtr function(
    GDExtensionScriptInstanceDataPtr p_instance);

alias GDExtensionScriptInstanceFree = void function(
    GDExtensionScriptInstanceDataPtr p_instance);

alias GDExtensionScriptInstancePtr = void*; // Pointer to ScriptInstance.

struct GDExtensionScriptInstanceInfo {
    //@nogc nothrow:
    GDExtensionScriptInstanceSet set_func;
    GDExtensionScriptInstanceGet get_func;
    GDExtensionScriptInstanceGetPropertyList get_property_list_func;
    GDExtensionScriptInstanceFreePropertyList free_property_list_func;

    GDExtensionScriptInstancePropertyCanRevert property_can_revert_func;
    GDExtensionScriptInstancePropertyGetRevert property_get_revert_func;

    GDExtensionScriptInstanceGetOwner get_owner_func;
    GDExtensionScriptInstanceGetPropertyState get_property_state_func;

    GDExtensionScriptInstanceGetMethodList get_method_list_func;
    GDExtensionScriptInstanceFreeMethodList free_method_list_func;
    GDExtensionScriptInstanceGetPropertyType get_property_type_func;

    GDExtensionScriptInstanceHasMethod has_method_func;

    GDExtensionScriptInstanceCall call_func;
    GDExtensionScriptInstanceNotification notification_func;

    GDExtensionScriptInstanceToString to_string_func;

    GDExtensionScriptInstanceRefCountIncremented refcount_incremented_func;
    GDExtensionScriptInstanceRefCountDecremented refcount_decremented_func;

    GDExtensionScriptInstanceGetScript get_script_func;

    GDExtensionScriptInstanceIsPlaceholder is_placeholder_func;

    GDExtensionScriptInstanceSet set_fallback_func;
    GDExtensionScriptInstanceGet get_fallback_func;

    GDExtensionScriptInstanceGetLanguage get_language_func;

    GDExtensionScriptInstanceFree free_func;
}

/* INTERFACE */

struct GDExtensionInterface {
    //@nogc nothrow:
    uint32_t version_major;
    uint32_t version_minor;
    uint32_t version_patch;
    const(char)* version_string;

    /* GODOT CORE */

    void* function(size_t p_bytes) mem_alloc;
    void* function(void* p_ptr, size_t p_bytes) mem_realloc;
    void function(void* p_ptr) mem_free;

    nothrow void function(const(char)* p_description, const(char)* p_function, const(char)* p_file, int32_t p_line, GDExtensionBool p_editor_notify) print_error;
	nothrow void function(const(char)* p_description, const(char)* p_message, const(char)* p_function, const(char)* p_file, int32_t p_line, GDExtensionBool p_editor_notify) print_error_with_message;
	nothrow void function(const(char)* p_description, const(char)* p_function, const(char)* p_file, int32_t p_line, GDExtensionBool p_editor_notify) print_warning;
	nothrow void function(const(char)* p_description, const(char)* p_message, const(char)* p_function, const(char)* p_file, int32_t p_line, GDExtensionBool p_editor_notify) print_warning_with_message;
	nothrow void function(const(char)* p_description, const(char)* p_function, const(char)* p_file, int32_t p_line, GDExtensionBool p_editor_notify) print_script_error;
	nothrow void function(const(char)* p_description, const(char)* p_message, const(char)* p_function, const(char)* p_file, int32_t p_line, GDExtensionBool p_editor_notify) print_script_error_with_message;

    uint64_t function(const GDExtensionStringNamePtr p_name) get_native_struct_size;

    /* GODOT VARIANT */

    /* variant general */
    void function(GDExtensionVariantPtr r_dest, const GDExtensionVariantPtr p_src) variant_new_copy;
    void function(GDExtensionVariantPtr r_dest) variant_new_nil;
    void function(GDExtensionVariantPtr p_self) variant_destroy;

    /* variant type */
    void function(GDExtensionVariantPtr p_self, const GDExtensionStringNamePtr p_method, const GDExtensionVariantPtr* p_args, const GDExtensionInt p_argument_count, GDExtensionVariantPtr r_return, GDExtensionCallError* r_error) variant_call;
    void function(GDExtensionVariantType p_type, const GDExtensionStringNamePtr p_method, const GDExtensionVariantPtr* p_args, const GDExtensionInt p_argument_count, GDExtensionVariantPtr r_return, GDExtensionCallError* r_error) variant_call_static;
    void function(GDExtensionVariantOperator p_op, const GDExtensionVariantPtr p_a, const GDExtensionVariantPtr p_b, GDExtensionVariantPtr r_return, GDExtensionBool* r_valid) variant_evaluate;
    void function(GDExtensionVariantPtr p_self, const GDExtensionVariantPtr p_key, const GDExtensionVariantPtr p_value, GDExtensionBool* r_valid) variant_set;
    void function(GDExtensionVariantPtr p_self, const GDExtensionStringNamePtr p_key, const GDExtensionVariantPtr p_value, GDExtensionBool* r_valid) variant_set_named;
    void function(GDExtensionVariantPtr p_self, const GDExtensionVariantPtr p_key, const GDExtensionVariantPtr p_value, GDExtensionBool* r_valid) variant_set_keyed;
    void function(GDExtensionVariantPtr p_self, GDExtensionInt p_index, const GDExtensionVariantPtr p_value, GDExtensionBool* r_valid, GDExtensionBool* r_oob) variant_set_indexed;
    void function(const GDExtensionVariantPtr p_self, const GDExtensionVariantPtr p_key, GDExtensionVariantPtr r_ret, GDExtensionBool* r_valid) variant_get;
    void function(const GDExtensionVariantPtr p_self, const GDExtensionStringNamePtr p_key, GDExtensionVariantPtr r_ret, GDExtensionBool* r_valid) variant_get_named;
    void function(const GDExtensionVariantPtr p_self, const GDExtensionVariantPtr p_key, GDExtensionVariantPtr r_ret, GDExtensionBool* r_valid) variant_get_keyed;
    void function(const GDExtensionVariantPtr p_self, GDExtensionInt p_index, GDExtensionVariantPtr r_ret, GDExtensionBool* r_valid, GDExtensionBool* r_oob) variant_get_indexed;
    GDExtensionBool function(const GDExtensionVariantPtr p_self, GDExtensionVariantPtr r_iter, GDExtensionBool* r_valid) variant_iter_init;
    GDExtensionBool function(const GDExtensionVariantPtr p_self, GDExtensionVariantPtr r_iter, GDExtensionBool* r_valid) variant_iter_next;
    void function(const GDExtensionVariantPtr p_self, GDExtensionVariantPtr r_iter, GDExtensionVariantPtr r_ret, GDExtensionBool* r_valid) variant_iter_get;
    GDExtensionInt function(const GDExtensionVariantPtr p_self) variant_hash;
    GDExtensionInt function(const GDExtensionVariantPtr p_self, GDExtensionInt p_recursion_count) variant_recursive_hash;
    GDExtensionBool function(const GDExtensionVariantPtr p_self, const GDExtensionVariantPtr p_other) variant_hash_compare;
    GDExtensionBool function(const GDExtensionVariantPtr p_self) variant_booleanize;
    void function(const GDExtensionVariantPtr p_self, GDExtensionVariantPtr r_ret, GDExtensionBool p_deep) variant_duplicate;
    void function(const GDExtensionVariantPtr p_self, GDExtensionStringPtr r_ret) variant_stringify;

    GDExtensionVariantType function(const GDExtensionVariantPtr p_self) variant_get_type;
    GDExtensionBool function(const GDExtensionVariantPtr p_self, const GDExtensionStringNamePtr p_method) variant_has_method;
    GDExtensionBool function(GDExtensionVariantType p_type, const GDExtensionStringNamePtr p_member) variant_has_member;
    GDExtensionBool function(const GDExtensionVariantPtr p_self, const GDExtensionVariantPtr p_key, GDExtensionBool* r_valid) variant_has_key;
    void function(GDExtensionVariantType p_type, GDExtensionStringPtr r_name) variant_get_type_name;
    GDExtensionBool function(GDExtensionVariantType p_from, GDExtensionVariantType p_to) variant_can_convert;
    GDExtensionBool function(GDExtensionVariantType p_from, GDExtensionVariantType p_to) variant_can_convert_strict;

    /* ptrcalls */
    GDExtensionVariantFromTypeConstructorFunc function(GDExtensionVariantType p_type) get_variant_from_type_constructor;
    GDExtensionTypeFromVariantConstructorFunc function(GDExtensionVariantType p_type) get_variant_to_type_constructor;
    GDExtensionPtrOperatorEvaluator function(GDExtensionVariantOperator p_operator, GDExtensionVariantType p_type_a, GDExtensionVariantType p_type_b) variant_get_ptr_operator_evaluator;
    GDExtensionPtrBuiltInMethod function(GDExtensionVariantType p_type, const GDExtensionStringNamePtr p_method, GDExtensionInt p_hash) variant_get_ptr_builtin_method;
    GDExtensionPtrConstructor function(GDExtensionVariantType p_type, int32_t p_constructor) variant_get_ptr_constructor;
    GDExtensionPtrDestructor function(GDExtensionVariantType p_type) variant_get_ptr_destructor;
    void function(GDExtensionVariantType p_type, GDExtensionVariantPtr p_base, const(GDExtensionVariantPtr)* p_args, int32_t p_argument_count, GDExtensionCallError* r_error) variant_construct;
    GDExtensionPtrSetter function(GDExtensionVariantType p_type, const GDExtensionStringNamePtr p_member) variant_get_ptr_setter;
    GDExtensionPtrGetter function(GDExtensionVariantType p_type, const GDExtensionStringNamePtr p_member) variant_get_ptr_getter;
    GDExtensionPtrIndexedSetter function(GDExtensionVariantType p_type) variant_get_ptr_indexed_setter;
    GDExtensionPtrIndexedGetter function(GDExtensionVariantType p_type) variant_get_ptr_indexed_getter;
    GDExtensionPtrKeyedSetter function(GDExtensionVariantType p_type) variant_get_ptr_keyed_setter;
    GDExtensionPtrKeyedGetter function(GDExtensionVariantType p_type) variant_get_ptr_keyed_getter;
    GDExtensionPtrKeyedChecker function(GDExtensionVariantType p_type) variant_get_ptr_keyed_checker;
    void function(GDExtensionVariantType p_type, const GDExtensionStringNamePtr p_constant, GDExtensionVariantPtr r_ret) variant_get_constant_value;
    GDExtensionPtrUtilityFunction function(const GDExtensionStringNamePtr p_function, GDExtensionInt p_hash) variant_get_ptr_utility_function;

    /*  extra utilities */
    void function(GDExtensionStringPtr r_dest, const(char)* p_contents) string_new_with_latin1_chars;
    void function(GDExtensionStringPtr r_dest, const(char)* p_contents) string_new_with_utf8_chars;
    void function(GDExtensionStringPtr r_dest, const(char16_t)* p_contents) string_new_with_utf16_chars;
    void function(GDExtensionStringPtr r_dest, const(char32_t)* p_contents) string_new_with_utf32_chars;
    void function(GDExtensionStringPtr r_dest, const(wchar_t)* p_contents) string_new_with_wide_chars;
    void function(GDExtensionStringPtr r_dest, const(char)* p_contents, const GDExtensionInt p_size) string_new_with_latin1_chars_and_len;
    void function(GDExtensionStringPtr r_dest, const(char)* p_contents, const GDExtensionInt p_size) string_new_with_utf8_chars_and_len;
    void function(GDExtensionStringPtr r_dest, const(char16_t)* p_contents, const GDExtensionInt p_size) string_new_with_utf16_chars_and_len;
    void function(GDExtensionStringPtr r_dest, const(char32_t)* p_contents, const GDExtensionInt p_size) string_new_with_utf32_chars_and_len;
    void function(GDExtensionStringPtr r_dest, const(wchar_t)* p_contents, const GDExtensionInt p_size) string_new_with_wide_chars_and_len;

    /* Information about the following functions:
	 * - The return value is the resulting encoded string length.
	 * - The length returned is in characters, not in bytes. It also does not include a trailing zero.
	 * - These functions also do not write trailing zero, If you need it, write it yourself at the position indicated by the length (and make sure to allocate it).
	 * - Passing NULL in r_text means only the length is computed (again, without including trailing zero).
	 * - p_max_write_length argument is in characters, not bytes. It will be ignored if r_text is NULL.
	 * - p_max_write_length argument does not affect the return value, it's only to cap write length.
	 */
    GDExtensionInt function(const GDExtensionStringPtr p_self, char* r_text, GDExtensionInt p_max_write_length) string_to_latin1_chars;
    GDExtensionInt function(const GDExtensionStringPtr p_self, char* r_text, GDExtensionInt p_max_write_length) string_to_utf8_chars;
    GDExtensionInt function(const GDExtensionStringPtr p_self, char16_t* r_text, GDExtensionInt p_max_write_length) string_to_utf16_chars;
    GDExtensionInt function(const GDExtensionStringPtr p_self, char32_t* r_text, GDExtensionInt p_max_write_length) string_to_utf32_chars;
    GDExtensionInt function(const GDExtensionStringPtr p_self, wchar_t* r_text, GDExtensionInt p_max_write_length) string_to_wide_chars;
    char32_t* function(GDExtensionStringPtr p_self, GDExtensionInt p_index) string_operator_index;
    const(char32_t)* function(const GDExtensionStringPtr p_self, GDExtensionInt p_index) string_operator_index_const;

    void function(GDExtensionStringPtr p_self, GDExtensionConstStringPtr p_b) string_operator_plus_eq_string;
	void function(GDExtensionStringPtr p_self, char32_t p_b) string_operator_plus_eq_char;
	void function(GDExtensionStringPtr p_self, const(char)* p_b) string_operator_plus_eq_cstr;
	void function(GDExtensionStringPtr p_self, const(wchar_t)* p_b) string_operator_plus_eq_wcstr;
	void function(GDExtensionStringPtr p_self, const(char32_t)* p_b) string_operator_plus_eq_c32str;

	/*  XMLParser extra utilities */

	GDExtensionInt function(GDExtensionObjectPtr p_instance, const(uint8_t)* p_buffer, size_t p_size) xml_parser_open_buffer;

	/*  FileAccess extra utilities */

	void function(GDExtensionObjectPtr p_instance, const(uint8_t)* p_src, uint64_t p_length) file_access_store_buffer;
	uint64_t function(GDExtensionConstObjectPtr p_instance, uint8_t* p_dst, uint64_t p_length) file_access_get_buffer;

	/*  WorkerThreadPool extra utilities */

	int64_t function(GDExtensionObjectPtr p_instance, void function(void*, uint32_t) p_func, void* p_userdata, int p_elements, int p_tasks, GDExtensionBool p_high_priority, GDExtensionConstStringPtr p_description) worker_thread_pool_add_native_group_task;
	int64_t function(GDExtensionObjectPtr p_instance, void function(void*) p_func, void* p_userdata, GDExtensionBool p_high_priority, GDExtensionConstStringPtr p_description) worker_thread_pool_add_native_task;


    /* Packed array functions */

    uint8_t* function(GDExtensionTypePtr p_self, GDExtensionInt p_index) packed_byte_array_operator_index; // p_self should be a PackedByteArray
    const(uint8_t)* function(const GDExtensionTypePtr p_self, GDExtensionInt p_index) packed_byte_array_operator_index_const; // p_self should be a PackedByteArray

    GDExtensionTypePtr function(GDExtensionTypePtr p_self, GDExtensionInt p_index) packed_color_array_operator_index; // p_self should be a PackedColorArray, returns Color ptr
    GDExtensionTypePtr function(const GDExtensionTypePtr p_self, GDExtensionInt p_index) packed_color_array_operator_index_const; // p_self should be a PackedColorArray, returns Color ptr

    float* function(GDExtensionTypePtr p_self, GDExtensionInt p_index) packed_float32_array_operator_index; // p_self should be a PackedFloat32Array
    const(float)* function(const GDExtensionTypePtr p_self, GDExtensionInt p_index) packed_float32_array_operator_index_const; // p_self should be a PackedFloat32Array
    double* function(GDExtensionTypePtr p_self, GDExtensionInt p_index) packed_float64_array_operator_index; // p_self should be a PackedFloat64Array
    const(double)* function(const GDExtensionTypePtr p_self, GDExtensionInt p_index) packed_float64_array_operator_index_const; // p_self should be a PackedFloat64Array

    int32_t* function(GDExtensionTypePtr p_self, GDExtensionInt p_index) packed_int32_array_operator_index; // p_self should be a PackedInt32Array
    const(int32_t)* function(const GDExtensionTypePtr p_self, GDExtensionInt p_index) packed_int32_array_operator_index_const; // p_self should be a PackedInt32Array
    int64_t* function(GDExtensionTypePtr p_self, GDExtensionInt p_index) packed_int64_array_operator_index; // p_self should be a PackedInt32Array
    const(int64_t)* function(const GDExtensionTypePtr p_self, GDExtensionInt p_index) packed_int64_array_operator_index_const; // p_self should be a PackedInt32Array

    GDExtensionStringPtr function(GDExtensionTypePtr p_self, GDExtensionInt p_index) packed_string_array_operator_index; // p_self should be a PackedStringArray
    GDExtensionStringPtr function(const GDExtensionTypePtr p_self, GDExtensionInt p_index) packed_string_array_operator_index_const; // p_self should be a PackedStringArray

    GDExtensionTypePtr function(GDExtensionTypePtr p_self, GDExtensionInt p_index) packed_vector2_array_operator_index; // p_self should be a PackedVector2Array, returns Vector2 ptr
    GDExtensionTypePtr function(const GDExtensionTypePtr p_self, GDExtensionInt p_index) packed_vector2_array_operator_index_const; // p_self should be a PackedVector2Array, returns Vector2 ptr
    GDExtensionTypePtr function(GDExtensionTypePtr p_self, GDExtensionInt p_index) packed_vector3_array_operator_index; // p_self should be a PackedVector3Array, returns Vector3 ptr
    GDExtensionTypePtr function(const GDExtensionTypePtr p_self, GDExtensionInt p_index) packed_vector3_array_operator_index_const; // p_self should be a PackedVector3Array, returns Vector3 ptr

    GDExtensionVariantPtr function(GDExtensionTypePtr p_self, GDExtensionInt p_index) array_operator_index; // p_self should be an Array ptr
    GDExtensionVariantPtr function(const GDExtensionTypePtr p_self, GDExtensionInt p_index) array_operator_index_const; // p_self should be an Array ptr
    void function(GDExtensionTypePtr p_self, GDExtensionConstTypePtr p_from) array_ref; // p_self should be an Array ptr
	void function(GDExtensionTypePtr p_self, GDExtensionVariantType p_type, GDExtensionConstStringNamePtr p_class_name, GDExtensionConstVariantPtr p_script) array_set_typed; // p_self should be an Array ptr

    /* Dictionary functions */

    GDExtensionVariantPtr function(GDExtensionTypePtr p_self, const GDExtensionVariantPtr p_key) dictionary_operator_index; // p_self should be an Dictionary ptr
    GDExtensionVariantPtr function(const GDExtensionTypePtr p_self, const GDExtensionVariantPtr p_key) dictionary_operator_index_const; // p_self should be an Dictionary ptr

    /* OBJECT */

    void function(const GDExtensionMethodBindPtr p_method_bind, GDExtensionObjectPtr p_instance, const GDExtensionVariantPtr* p_args, GDExtensionInt p_arg_count, GDExtensionVariantPtr r_ret, GDExtensionCallError* r_error) object_method_bind_call;
    void function(const GDExtensionMethodBindPtr p_method_bind, GDExtensionObjectPtr p_instance, const GDExtensionTypePtr* p_args, GDExtensionTypePtr r_ret) object_method_bind_ptrcall;
    void function(GDExtensionObjectPtr p_o) object_destroy;
    GDExtensionObjectPtr function(const GDExtensionStringNamePtr p_name) global_get_singleton;

    void* function(GDExtensionObjectPtr p_o, void* p_token, const GDExtensionInstanceBindingCallbacks* p_callbacks) object_get_instance_binding;
    void function(GDExtensionObjectPtr p_o, void* p_token, void* p_binding, const GDExtensionInstanceBindingCallbacks* p_callbacks) object_set_instance_binding;

    void function(GDExtensionObjectPtr p_o, const GDExtensionStringNamePtr p_classname, GDExtensionClassInstancePtr p_instance) object_set_instance; /* p_classname should be a registered extension class and should extend the p_o object's class. */

    GDExtensionObjectPtr function(const GDExtensionObjectPtr p_object, void* p_class_tag) object_cast_to;
    GDExtensionObjectPtr function(GDObjectInstanceID p_instance_id) object_get_instance_from_id;
    GDObjectInstanceID function(const GDExtensionObjectPtr p_object) object_get_instance_id;

    /* REFERENCE */

	GDExtensionObjectPtr function(GDExtensionConstRefPtr p_ref) ref_get_object;
	void function(GDExtensionRefPtr p_ref, GDExtensionObjectPtr p_object) ref_set_object;

    /* SCRIPT INSTANCE */

    GDExtensionScriptInstancePtr function(const GDExtensionScriptInstanceInfo* p_info, GDExtensionScriptInstanceDataPtr p_instance_data) script_instance_create;

    /* CLASSDB */

    GDExtensionObjectPtr function(const GDExtensionStringNamePtr p_classname) classdb_construct_object; /* The passed class must be a built-in godot class, or an already-registered extension class. In both case, object_set_instance should be called to fully initialize the object. */
    GDExtensionMethodBindPtr function(const GDExtensionStringNamePtr p_classname, const GDExtensionStringNamePtr p_methodname, GDExtensionInt p_hash) classdb_get_method_bind;
    void* function(const GDExtensionStringNamePtr p_classname) classdb_get_class_tag;

    /* CLASSDB EXTENSION */

    /* Provided parameters for `classdb_register_extension_*` can be safely freed once the function returns. */
	void function(const GDExtensionClassLibraryPtr p_library, const GDExtensionStringNamePtr p_class_name, const GDExtensionStringNamePtr p_parent_class_name, const GDExtensionClassCreationInfo* p_extension_funcs) classdb_register_extension_class;
	void function(const GDExtensionClassLibraryPtr p_library, const GDExtensionStringNamePtr p_class_name, const GDExtensionClassMethodInfo* p_method_info) classdb_register_extension_class_method;
	void function(const GDExtensionClassLibraryPtr p_library, const GDExtensionStringNamePtr p_class_name, const GDExtensionStringNamePtr p_enum_name, const GDExtensionStringNamePtr p_constant_name, GDExtensionInt p_constant_value, GDExtensionBool p_is_bitfield) classdb_register_extension_class_integer_constant;
	void function(const GDExtensionClassLibraryPtr p_library, const GDExtensionStringNamePtr p_class_name, const GDExtensionPropertyInfo* p_info, const GDExtensionStringNamePtr p_setter, const GDExtensionStringNamePtr p_getter) classdb_register_extension_class_property;
	void function(const GDExtensionClassLibraryPtr p_library, const GDExtensionStringNamePtr p_class_name, const GDExtensionStringPtr p_group_name, const GDExtensionStringPtr p_prefix) classdb_register_extension_class_property_group;
	void function(const GDExtensionClassLibraryPtr p_library, const GDExtensionStringNamePtr p_class_name, const GDExtensionStringPtr p_subgroup_name, const GDExtensionStringPtr p_prefix) classdb_register_extension_class_property_subgroup;
	void function(const GDExtensionClassLibraryPtr p_library, const GDExtensionStringNamePtr p_class_name, const GDExtensionStringNamePtr p_signal_name, const GDExtensionPropertyInfo* p_argument_info, GDExtensionInt p_argument_count) classdb_register_extension_class_signal;
	void function(const GDExtensionClassLibraryPtr p_library, const GDExtensionStringNamePtr p_class_name) classdb_unregister_extension_class; /* Unregistering a parent class before a class that inherits it will result in failure. Inheritors must be unregistered first. */

    void function(const GDExtensionClassLibraryPtr p_library, GDExtensionStringPtr r_path) get_library_path;

}

/* INITIALIZATION */
alias GDExtensionInitializationLevel = int;
enum : GDExtensionInitializationLevel {
    GDEXTENSION_INITIALIZATION_CORE,
    GDEXTENSION_INITIALIZATION_SERVERS,
    GDEXTENSION_INITIALIZATION_SCENE,
    GDEXTENSION_INITIALIZATION_EDITOR,
    GDEXTENSION_MAX_INITIALIZATION_LEVEL,
}

struct GDExtensionInitialization {
    //@nogc nothrow:
    /* Minimum initialization level required.
	 * If Core or Servers, the extension needs editor or game restart to take effect */
    GDExtensionInitializationLevel minimum_initialization_level;
    /* Up to the user to supply when initializing */
    void* userdata;
    /* This function will be called multiple times for each initialization level. */
    void function(void* userdata, GDExtensionInitializationLevel p_level) initialize;
    void function(void* userdata, GDExtensionInitializationLevel p_level) deinitialize;
}

/* Define a C function prototype that implements the function below and expose it to dlopen() (or similar).
 * This is the entry point of the GDExtension library and will be called on initialization.
 * It can be used to set up different init levels, which are called during various stages of initialization/shutdown.
 * The function name must be a unique one specified in the .gdextension config file.
 */
alias GDExtensionInitializationFunction = GDExtensionBool function(const GDExtensionInterface* p_interface, const GDExtensionClassLibraryPtr p_library, GDExtensionInitialization* r_initialization);

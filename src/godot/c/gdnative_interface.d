/*************************************************************************/
/*  gdnative_interface.h                                                 */
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

module godot.c.gdnative_interface;

import godot.c.core;
import core.stdc.config;

extern(C):
//@nogc nothrow:

/* VARIANT TYPES */

alias GDNativeVariantType = int;
enum : GDNativeVariantType 
{
	GDNATIVE_VARIANT_TYPE_NIL,

	/*  atomic types */
	GDNATIVE_VARIANT_TYPE_BOOL,
	GDNATIVE_VARIANT_TYPE_INT,
	GDNATIVE_VARIANT_TYPE_FLOAT,
	GDNATIVE_VARIANT_TYPE_STRING,

	/* math types */
	GDNATIVE_VARIANT_TYPE_VECTOR2,
	GDNATIVE_VARIANT_TYPE_VECTOR2I,
	GDNATIVE_VARIANT_TYPE_RECT2,
	GDNATIVE_VARIANT_TYPE_RECT2I,
	GDNATIVE_VARIANT_TYPE_VECTOR3,
	GDNATIVE_VARIANT_TYPE_VECTOR3I,
	GDNATIVE_VARIANT_TYPE_TRANSFORM2D,
	GDNATIVE_VARIANT_TYPE_VECTOR4,
	GDNATIVE_VARIANT_TYPE_VECTOR4I,
	GDNATIVE_VARIANT_TYPE_PLANE,
	GDNATIVE_VARIANT_TYPE_QUATERNION,
	GDNATIVE_VARIANT_TYPE_AABB,
	GDNATIVE_VARIANT_TYPE_BASIS,
	GDNATIVE_VARIANT_TYPE_TRANSFORM3D,
	GDNATIVE_VARIANT_TYPE_PROJECTION,

	/* misc types */
	GDNATIVE_VARIANT_TYPE_COLOR,
	GDNATIVE_VARIANT_TYPE_STRING_NAME,
	GDNATIVE_VARIANT_TYPE_NODE_PATH,
	GDNATIVE_VARIANT_TYPE_RID,
	GDNATIVE_VARIANT_TYPE_OBJECT,
	GDNATIVE_VARIANT_TYPE_CALLABLE,
	GDNATIVE_VARIANT_TYPE_SIGNAL,
	GDNATIVE_VARIANT_TYPE_DICTIONARY,
	GDNATIVE_VARIANT_TYPE_ARRAY,

	/* typed arrays */
	GDNATIVE_VARIANT_TYPE_PACKED_BYTE_ARRAY,
	GDNATIVE_VARIANT_TYPE_PACKED_INT32_ARRAY,
	GDNATIVE_VARIANT_TYPE_PACKED_INT64_ARRAY,
	GDNATIVE_VARIANT_TYPE_PACKED_FLOAT32_ARRAY,
	GDNATIVE_VARIANT_TYPE_PACKED_FLOAT64_ARRAY,
	GDNATIVE_VARIANT_TYPE_PACKED_STRING_ARRAY,
	GDNATIVE_VARIANT_TYPE_PACKED_VECTOR2_ARRAY,
	GDNATIVE_VARIANT_TYPE_PACKED_VECTOR3_ARRAY,
	GDNATIVE_VARIANT_TYPE_PACKED_COLOR_ARRAY,

	GDNATIVE_VARIANT_TYPE_VARIANT_MAX
}

alias GDNativeVariantOperator = int;
enum : GDNativeVariantOperator
{
	/* comparison */
	GDNATIVE_VARIANT_OP_EQUAL,
	GDNATIVE_VARIANT_OP_NOT_EQUAL,
	GDNATIVE_VARIANT_OP_LESS,
	GDNATIVE_VARIANT_OP_LESS_EQUAL,
	GDNATIVE_VARIANT_OP_GREATER,
	GDNATIVE_VARIANT_OP_GREATER_EQUAL,
	/* mathematic */
	GDNATIVE_VARIANT_OP_ADD,
	GDNATIVE_VARIANT_OP_SUBTRACT,
	GDNATIVE_VARIANT_OP_MULTIPLY,
	GDNATIVE_VARIANT_OP_DIVIDE,
	GDNATIVE_VARIANT_OP_NEGATE,
	GDNATIVE_VARIANT_OP_POSITIVE,
	GDNATIVE_VARIANT_OP_MODULE,
	GDNATIVE_VARIANT_OP_POWER,
	/* bitwise */
	GDNATIVE_VARIANT_OP_SHIFT_LEFT,
	GDNATIVE_VARIANT_OP_SHIFT_RIGHT,
	GDNATIVE_VARIANT_OP_BIT_AND,
	GDNATIVE_VARIANT_OP_BIT_OR,
	GDNATIVE_VARIANT_OP_BIT_XOR,
	GDNATIVE_VARIANT_OP_BIT_NEGATE,
	/* logic */
	GDNATIVE_VARIANT_OP_AND,
	GDNATIVE_VARIANT_OP_OR,
	GDNATIVE_VARIANT_OP_XOR,
	GDNATIVE_VARIANT_OP_NOT,
	/* containment */
	GDNATIVE_VARIANT_OP_IN,
	GDNATIVE_VARIANT_OP_MAX

}

alias GDNativeVariantPtr = void *;
alias GDNativeStringNamePtr = void *;
alias GDNativeStringPtr = void *;
alias GDNativeObjectPtr = void *;
alias GDNativeTypePtr = void *;
alias GDNativeExtensionPtr = void *;
alias GDNativeMethodBindPtr = void *;
alias GDNativeInt = int64_t ;
alias GDNativeBool = uint8_t ;
alias GDObjectInstanceID = uint64_t ;

/* VARIANT DATA I/O */

alias GDNativeCallErrorType = int;
enum : GDNativeCallErrorType
{
	GDNATIVE_CALL_OK,
	GDNATIVE_CALL_ERROR_INVALID_METHOD,
	GDNATIVE_CALL_ERROR_INVALID_ARGUMENT, /* expected is variant type */
	GDNATIVE_CALL_ERROR_TOO_MANY_ARGUMENTS, /* expected is number of arguments */
	GDNATIVE_CALL_ERROR_TOO_FEW_ARGUMENTS, /*  expected is number of arguments */
	GDNATIVE_CALL_ERROR_INSTANCE_IS_NULL,
	GDNATIVE_CALL_ERROR_METHOD_NOT_CONST, /* used for const call */
}

struct GDNativeCallError
{
//@nogc nothrow:
	GDNativeCallErrorType error;
	int32_t argument;
	int32_t expected;
}

alias GDNativeVariantFromTypeConstructorFunc = void function(GDNativeVariantPtr, GDNativeTypePtr);
alias GDNativeTypeFromVariantConstructorFunc = void function(GDNativeTypePtr, GDNativeVariantPtr);
alias GDNativePtrOperatorEvaluator = void function(const GDNativeTypePtr p_left, const GDNativeTypePtr p_right, GDNativeTypePtr r_result);
alias GDNativePtrBuiltInMethod = void function(GDNativeTypePtr p_base, const GDNativeTypePtr* p_args, GDNativeTypePtr r_return, int p_argument_count);
alias GDNativePtrConstructor = void function(GDNativeTypePtr p_base, const GDNativeTypePtr* p_args);
alias GDNativePtrDestructor = void function(GDNativeTypePtr p_base);
alias GDNativePtrSetter = void function(GDNativeTypePtr p_base, const GDNativeTypePtr p_value);
alias GDNativePtrGetter = void function(const GDNativeTypePtr p_base, GDNativeTypePtr r_value);
alias GDNativePtrIndexedSetter = void function(GDNativeTypePtr p_base, GDNativeInt p_index, const GDNativeTypePtr p_value);
alias GDNativePtrIndexedGetter = void function(const GDNativeTypePtr p_base, GDNativeInt p_index, GDNativeTypePtr r_value);
alias GDNativePtrKeyedSetter = void function(GDNativeTypePtr p_base, const GDNativeTypePtr p_key, const GDNativeTypePtr p_value);
alias GDNativePtrKeyedGetter = void function(const GDNativeTypePtr p_base, const GDNativeTypePtr p_key, GDNativeTypePtr r_value);
alias GDNativePtrKeyedChecker = uint32_t function(const GDNativeVariantPtr p_base, const GDNativeVariantPtr p_key);
alias GDNativePtrUtilityFunction = void function(GDNativeTypePtr r_return, const GDNativeTypePtr* p_arguments, int p_argument_count);

alias GDNativeClassConstructor = GDNativeObjectPtr function();

alias GDNativeInstanceBindingCreateCallback = void* function(void* p_token, void* p_instance);
alias GDNativeInstanceBindingFreeCallback = void function(void* p_token, void* p_instance, void* p_binding);
alias GDNativeInstanceBindingReferenceCallback = GDNativeBool function(void* p_token, void* p_binding, GDNativeBool p_reference);

struct GDNativeInstanceBindingCallbacks 
{
//@nogc nothrow:
	GDNativeInstanceBindingCreateCallback create_callback;
	GDNativeInstanceBindingFreeCallback free_callback;
	GDNativeInstanceBindingReferenceCallback reference_callback;
}

/* EXTENSION CLASSES */

alias GDExtensionClassInstancePtr = void*;

alias GDNativeExtensionClassSet = GDNativeBool function(GDExtensionClassInstancePtr p_instance, const GDNativeStringNamePtr p_name, const GDNativeVariantPtr p_value);
alias GDNativeExtensionClassGet = GDNativeBool function(GDExtensionClassInstancePtr p_instance, const GDNativeStringNamePtr p_name, GDNativeVariantPtr r_ret);
alias GDNativeExtensionClassGetRID = uint64_t function(GDExtensionClassInstancePtr p_instance);

struct GDNativePropertyInfo
{
//@nogc nothrow:
	uint32_t type;
	const(char)* name;
	const(char)* class_name;
	uint32_t hint;
	const(char)* hint_string;
	uint32_t usage;
}

struct GDNativeMethodInfo
{
//@nogc nothrow:
	const(char)* name;
	GDNativePropertyInfo return_value;
	uint32_t flags; // From GDNativeExtensionClassMethodFlags
	int32_t id;
	GDNativePropertyInfo* arguments;
	uint32_t argument_count;
	GDNativeVariantPtr default_arguments;
	uint32_t default_argument_count;
}

alias GDNativeExtensionClassGetPropertyList = const GDNativePropertyInfo* function(GDExtensionClassInstancePtr p_instance, uint32_t* r_count);
alias GDNativeExtensionClassFreePropertyList = void function(GDExtensionClassInstancePtr p_instance, const GDNativePropertyInfo* p_list);
alias GDNativeExtensionClassPropertyCanRevert = GDNativeBool function(GDExtensionClassInstancePtr p_instance, const GDNativeStringNamePtr p_name);
alias GDNativeExtensionClassPropertyGetRevert = GDNativeBool function(GDExtensionClassInstancePtr p_instance, const GDNativeStringNamePtr p_name, GDNativeVariantPtr r_ret);
alias GDNativeExtensionClassNotification = void function(GDExtensionClassInstancePtr p_instance, int32_t p_what);
alias GDNativeExtensionClassToString = void function(GDExtensionClassInstancePtr p_instance, GDNativeStringPtr p_out);
alias GDNativeExtensionClassReference = void function(GDExtensionClassInstancePtr p_instance);
alias GDNativeExtensionClassUnreference = void function(GDExtensionClassInstancePtr p_instance);
alias GDNativeExtensionClassCallVirtual = void function(GDExtensionClassInstancePtr p_instance, const GDNativeTypePtr *p_args, GDNativeTypePtr r_ret);
alias GDNativeExtensionClassCreateInstance = GDNativeObjectPtr function(void* p_userdata);
alias GDNativeExtensionClassFreeInstance = void function(void* p_userdata, GDExtensionClassInstancePtr p_instance);
alias GDNativeExtensionClassObjectInstance = void function(GDExtensionClassInstancePtr p_instance, GDNativeObjectPtr p_object_instance);
alias GDNativeExtensionClassGetVirtual = GDNativeExtensionClassCallVirtual function(void* p_userdata, const char *p_name);

struct GDNativeExtensionClassCreationInfo
{
//@nogc nothrow:
	GDNativeExtensionClassSet set_func;
	GDNativeExtensionClassGet get_func;
	GDNativeExtensionClassGetPropertyList get_property_list_func;
	GDNativeExtensionClassFreePropertyList free_property_list_func;
	GDNativeExtensionClassPropertyCanRevert property_can_revert_func;
	GDNativeExtensionClassPropertyGetRevert property_get_revert_func;
	GDNativeExtensionClassNotification notification_func;
	GDNativeExtensionClassToString to_string_func;
	GDNativeExtensionClassReference reference_func;
	GDNativeExtensionClassUnreference unreference_func;
	GDNativeExtensionClassCreateInstance create_instance_func; /* this one is mandatory */
	GDNativeExtensionClassFreeInstance free_instance_func; /* this one is mandatory */
	GDNativeExtensionClassGetVirtual get_virtual_func;
	GDNativeExtensionClassGetRID get_rid_func;
	void* class_userdata;
}

alias GDNativeExtensionClassLibraryPtr = void *;

/* Method */

alias GDNativeExtensionClassMethodFlags = int;
enum : GDNativeExtensionClassMethodFlags
{
	GDNATIVE_EXTENSION_METHOD_FLAG_NORMAL = 1,
	GDNATIVE_EXTENSION_METHOD_FLAG_EDITOR = 2,
	GDNATIVE_EXTENSION_METHOD_FLAG_CONST = 4,
	GDNATIVE_EXTENSION_METHOD_FLAG_VIRTUAL = 8,
	GDNATIVE_EXTENSION_METHOD_FLAG_VARARG = 16,
	GDNATIVE_EXTENSION_METHOD_FLAG_STATIC = 32,
	GDNATIVE_EXTENSION_METHOD_FLAGS_DEFAULT = GDNATIVE_EXTENSION_METHOD_FLAG_NORMAL,
}

alias GDNativeExtensionClassMethodArgumentMetadata = int;
enum : GDNativeExtensionClassMethodArgumentMetadata
{
	GDNATIVE_EXTENSION_METHOD_ARGUMENT_METADATA_NONE,
	GDNATIVE_EXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_INT8,
	GDNATIVE_EXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_INT16,
	GDNATIVE_EXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_INT32,
	GDNATIVE_EXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_INT64,
	GDNATIVE_EXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_UINT8,
	GDNATIVE_EXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_UINT16,
	GDNATIVE_EXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_UINT32,
	GDNATIVE_EXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_UINT64,
	GDNATIVE_EXTENSION_METHOD_ARGUMENT_METADATA_REAL_IS_FLOAT,
	GDNATIVE_EXTENSION_METHOD_ARGUMENT_METADATA_REAL_IS_DOUBLE
}

alias GDNativeExtensionClassMethodCall = void function(void *method_userdata, GDExtensionClassInstancePtr p_instance, const GDNativeVariantPtr *p_args, const GDNativeInt p_argument_count, GDNativeVariantPtr r_return, GDNativeCallError *r_error);
alias GDNativeExtensionClassMethodPtrCall = void function(void *method_userdata, GDExtensionClassInstancePtr p_instance, const GDNativeTypePtr *p_args, GDNativeTypePtr r_ret);

/* passing -1 as argument in the following functions refers to the return type */
alias GDNativeExtensionClassMethodGetArgumentType = GDNativeVariantType function(void *p_method_userdata, int32_t p_argument);
alias GDNativeExtensionClassMethodGetArgumentInfo = void function(void *p_method_userdata, int32_t p_argument, GDNativePropertyInfo *r_info);
alias GDNativeExtensionClassMethodGetArgumentMetadata = GDNativeExtensionClassMethodArgumentMetadata function(void *p_method_userdata, int32_t p_argument);

struct GDNativeExtensionClassMethodInfo
{
//@nogc nothrow:
	const char *name;
	void *method_userdata;
	GDNativeExtensionClassMethodCall call_func;
	GDNativeExtensionClassMethodPtrCall ptrcall_func;
	uint32_t method_flags; /* GDNativeExtensionClassMethodFlags */
	uint32_t argument_count;
	GDNativeBool has_return_value;
	GDNativeExtensionClassMethodGetArgumentType get_argument_type_func;
	GDNativeExtensionClassMethodGetArgumentInfo get_argument_info_func; /* name and hint information for the argument can be omitted in release builds. Class name should always be present if it applies. */
	GDNativeExtensionClassMethodGetArgumentMetadata get_argument_metadata_func;
	uint32_t default_argument_count;
	GDNativeVariantPtr *default_arguments;
}

/* SCRIPT INSTANCE EXTENSION */

alias GDNativeExtensionScriptInstanceDataPtr = void*; // Pointer to custom ScriptInstance native implementation

alias GDNativeExtensionScriptInstanceSet = GDNativeBool function(GDNativeExtensionScriptInstanceDataPtr p_instance, const GDNativeStringNamePtr p_name, const GDNativeVariantPtr p_value);
alias GDNativeExtensionScriptInstanceGet = GDNativeBool function(GDNativeExtensionScriptInstanceDataPtr p_instance, const GDNativeStringNamePtr p_name, GDNativeVariantPtr r_ret);
alias GDNativeExtensionScriptInstanceGetPropertyList = const GDNativePropertyInfo function(GDNativeExtensionScriptInstanceDataPtr p_instance, uint32_t *r_count);
alias GDNativeExtensionScriptInstanceFreePropertyList = void function(GDNativeExtensionScriptInstanceDataPtr p_instance, const GDNativePropertyInfo *p_list);
alias GDNativeExtensionScriptInstanceGetPropertyType = GDNativeVariantType function(GDNativeExtensionScriptInstanceDataPtr p_instance, const GDNativeStringNamePtr p_name, GDNativeBool *r_is_valid);

alias GDNativeExtensionScriptInstancePropertyCanRevert = GDNativeBool function(GDNativeExtensionScriptInstanceDataPtr p_instance, const GDNativeStringNamePtr p_name);
alias GDNativeExtensionScriptInstancePropertyGetRevert = GDNativeBool function(GDNativeExtensionScriptInstanceDataPtr p_instance, const GDNativeStringNamePtr p_name, GDNativeVariantPtr r_ret);

alias GDNativeExtensionScriptInstanceGetOwner = GDNativeObjectPtr function(GDNativeExtensionScriptInstanceDataPtr p_instance);
alias GDNativeExtensionScriptInstancePropertyStateAdd = void function(const GDNativeStringNamePtr p_name, const GDNativeVariantPtr p_value, void *p_userdata);
alias GDNativeExtensionScriptInstanceGetPropertyState = void function(GDNativeExtensionScriptInstanceDataPtr p_instance, GDNativeExtensionScriptInstancePropertyStateAdd p_add_func, void *p_userdata);

alias GDNativeExtensionScriptInstanceGetMethodList = const GDNativeMethodInfo function(GDNativeExtensionScriptInstanceDataPtr p_instance, uint32_t *r_count);
alias GDNativeExtensionScriptInstanceFreeMethodList = void function(GDNativeExtensionScriptInstanceDataPtr p_instance, const GDNativeMethodInfo *p_list);

alias GDNativeExtensionScriptInstanceHasMethod = GDNativeBool function(GDNativeExtensionScriptInstanceDataPtr p_instance, const GDNativeStringNamePtr p_name);

alias GDNativeExtensionScriptInstanceCall = void function(GDNativeExtensionScriptInstanceDataPtr p_self, const GDNativeStringNamePtr p_method, const GDNativeVariantPtr *p_args, const GDNativeInt p_argument_count, GDNativeVariantPtr r_return, GDNativeCallError *r_error);
alias GDNativeExtensionScriptInstanceNotification = void function(GDNativeExtensionScriptInstanceDataPtr p_instance, int32_t p_what);
alias GDNativeExtensionScriptInstanceToString = const char* function(GDNativeExtensionScriptInstanceDataPtr p_instance, GDNativeBool *r_is_valid);

alias GDNativeExtensionScriptInstanceRefCountIncremented = void function(GDNativeExtensionScriptInstanceDataPtr p_instance);
alias GDNativeExtensionScriptInstanceRefCountDecremented = GDNativeBool function(GDNativeExtensionScriptInstanceDataPtr p_instance);

alias GDNativeExtensionScriptInstanceGetScript = GDNativeObjectPtr function(GDNativeExtensionScriptInstanceDataPtr p_instance);
alias GDNativeExtensionScriptInstanceIsPlaceholder = GDNativeBool function(GDNativeExtensionScriptInstanceDataPtr p_instance);

alias GDNativeExtensionScriptLanguagePtr = void*;

alias GDNativeExtensionScriptInstanceGetLanguage = GDNativeExtensionScriptLanguagePtr function(GDNativeExtensionScriptInstanceDataPtr p_instance);

alias GDNativeExtensionScriptInstanceFree = void function(GDNativeExtensionScriptInstanceDataPtr p_instance);

alias GDNativeScriptInstancePtr = void*; // Pointer to ScriptInstance.

struct GDNativeExtensionScriptInstanceInfo 
{
//@nogc nothrow:
	GDNativeExtensionScriptInstanceSet set_func;
	GDNativeExtensionScriptInstanceGet get_func;
	GDNativeExtensionScriptInstanceGetPropertyList get_property_list_func;
	GDNativeExtensionScriptInstanceFreePropertyList free_property_list_func;
	GDNativeExtensionScriptInstanceGetPropertyType get_property_type_func;

	GDNativeExtensionScriptInstancePropertyCanRevert property_can_revert_func;
	GDNativeExtensionScriptInstancePropertyGetRevert property_get_revert_func;

	GDNativeExtensionScriptInstanceGetOwner get_owner_func;
	GDNativeExtensionScriptInstanceGetPropertyState get_property_state_func;

	GDNativeExtensionScriptInstanceGetMethodList get_method_list_func;
	GDNativeExtensionScriptInstanceFreeMethodList free_method_list_func;

	GDNativeExtensionScriptInstanceHasMethod has_method_func;

	GDNativeExtensionScriptInstanceCall call_func;
	GDNativeExtensionScriptInstanceNotification notification_func;

	GDNativeExtensionScriptInstanceToString to_string_func;

	GDNativeExtensionScriptInstanceRefCountIncremented refcount_incremented_func;
	GDNativeExtensionScriptInstanceRefCountDecremented refcount_decremented_func;

	GDNativeExtensionScriptInstanceGetScript get_script_func;

	GDNativeExtensionScriptInstanceIsPlaceholder is_placeholder_func;

	GDNativeExtensionScriptInstanceSet set_fallback_func;
	GDNativeExtensionScriptInstanceGet get_fallback_func;

	GDNativeExtensionScriptInstanceGetLanguage get_language_func;

	GDNativeExtensionScriptInstanceFree free_func;
}

/* INTERFACE */

struct GDNativeInterface 
{
//@nogc nothrow:
	uint32_t version_major;
	uint32_t version_minor;
	uint32_t version_patch;
	const(char)* version_string;

	/* GODOT CORE */
	void* function(size_t p_bytes) mem_alloc;
	void* function(void *p_ptr, size_t p_bytes) mem_realloc;
	void function(void *p_ptr) mem_free;

	nothrow void function(const(char)* p_description, const(char)* p_function, const(char)* p_file, int32_t p_line) print_error;
	nothrow void function(const(char)* p_description, const(char)* p_function, const(char)* p_file, int32_t p_line) print_warning;
	nothrow void function(const(char)* p_description, const(char)* p_function, const(char)* p_file, int32_t p_line) print_script_error;

	uint64_t function(const(char)* p_name) get_native_struct_size;

	/* GODOT VARIANT */

	/* variant general */
	void function(GDNativeVariantPtr r_dest, const GDNativeVariantPtr p_src) variant_new_copy;
	void function(GDNativeVariantPtr r_dest) variant_new_nil;
	void function(GDNativeVariantPtr p_self) variant_destroy;

	/* variant type */
	void function(GDNativeVariantPtr p_self, const GDNativeStringNamePtr p_method, const GDNativeVariantPtr *p_args, const GDNativeInt p_argument_count, GDNativeVariantPtr r_return, GDNativeCallError *r_error) variant_call;
	void function(GDNativeVariantType p_type, const GDNativeStringNamePtr p_method, const GDNativeVariantPtr *p_args, const GDNativeInt p_argument_count, GDNativeVariantPtr r_return, GDNativeCallError *r_error) variant_call_static;
	void function(GDNativeVariantOperator p_op, const GDNativeVariantPtr p_a, const GDNativeVariantPtr p_b, GDNativeVariantPtr r_return, GDNativeBool *r_valid) variant_evaluate;
	void function(GDNativeVariantPtr p_self, const GDNativeVariantPtr p_key, const GDNativeVariantPtr p_value, GDNativeBool *r_valid) variant_set;
	void function(GDNativeVariantPtr p_self, const GDNativeStringNamePtr p_key, const GDNativeVariantPtr p_value, GDNativeBool *r_valid) variant_set_named;
	void function(GDNativeVariantPtr p_self, const GDNativeVariantPtr p_key, const GDNativeVariantPtr p_value, GDNativeBool *r_valid) variant_set_keyed;
	void function(GDNativeVariantPtr p_self, GDNativeInt p_index, const GDNativeVariantPtr p_value, GDNativeBool *r_valid, GDNativeBool *r_oob) variant_set_indexed;
	void function(const GDNativeVariantPtr p_self, const GDNativeVariantPtr p_key, GDNativeVariantPtr r_ret, GDNativeBool *r_valid) variant_get;
	void function(const GDNativeVariantPtr p_self, const GDNativeStringNamePtr p_key, GDNativeVariantPtr r_ret, GDNativeBool *r_valid) variant_get_named;
	void function(const GDNativeVariantPtr p_self, const GDNativeVariantPtr p_key, GDNativeVariantPtr r_ret, GDNativeBool *r_valid) variant_get_keyed;
	void function(const GDNativeVariantPtr p_self, GDNativeInt p_index, GDNativeVariantPtr r_ret, GDNativeBool *r_valid, GDNativeBool *r_oob) variant_get_indexed;
	GDNativeBool function(const GDNativeVariantPtr p_self, GDNativeVariantPtr r_iter, GDNativeBool *r_valid) variant_iter_init;
	GDNativeBool function(const GDNativeVariantPtr p_self, GDNativeVariantPtr r_iter, GDNativeBool *r_valid) variant_iter_next;
	void function(const GDNativeVariantPtr p_self, GDNativeVariantPtr r_iter, GDNativeVariantPtr r_ret, GDNativeBool *r_valid) variant_iter_get;
	GDNativeInt function(const GDNativeVariantPtr p_self) variant_hash;
	GDNativeInt function(const GDNativeVariantPtr p_self, GDNativeInt p_recursion_count) variant_recursive_hash;
	GDNativeBool function(const GDNativeVariantPtr p_self, const GDNativeVariantPtr p_other) variant_hash_compare;
	GDNativeBool function(const GDNativeVariantPtr p_self) variant_booleanize;
	void function(const GDNativeVariantPtr p_self, GDNativeVariantPtr r_ret, GDNativeBool p_deep) variant_duplicate;
	void function(const GDNativeVariantPtr p_self, GDNativeStringPtr r_ret) variant_stringify;

	GDNativeVariantType function(const GDNativeVariantPtr p_self) variant_get_type;
	GDNativeBool function(const GDNativeVariantPtr p_self, const GDNativeStringNamePtr p_method) variant_has_method;
	GDNativeBool function(GDNativeVariantType p_type, const GDNativeStringNamePtr p_member) variant_has_member;
	GDNativeBool function(const GDNativeVariantPtr p_self, const GDNativeVariantPtr p_key, GDNativeBool *r_valid) variant_has_key;
	void function(GDNativeVariantType p_type, GDNativeStringPtr r_name) variant_get_type_name;
	GDNativeBool function(GDNativeVariantType p_from, GDNativeVariantType p_to) variant_can_convert;
	GDNativeBool function(GDNativeVariantType p_from, GDNativeVariantType p_to) variant_can_convert_strict;

	/* ptrcalls */
	GDNativeVariantFromTypeConstructorFunc function(GDNativeVariantType p_type) get_variant_from_type_constructor;
	GDNativeTypeFromVariantConstructorFunc function(GDNativeVariantType p_type) get_variant_to_type_constructor;
	GDNativePtrOperatorEvaluator function(GDNativeVariantOperator p_operator, GDNativeVariantType p_type_a, GDNativeVariantType p_type_b) variant_get_ptr_operator_evaluator;
	GDNativePtrBuiltInMethod function(GDNativeVariantType p_type, const(char)* p_method, GDNativeInt p_hash) variant_get_ptr_builtin_method;
	GDNativePtrConstructor function(GDNativeVariantType p_type, int32_t p_constructor) variant_get_ptr_constructor;
	GDNativePtrDestructor function(GDNativeVariantType p_type) variant_get_ptr_destructor;
	void function(GDNativeVariantType p_type, GDNativeVariantPtr p_base, const(GDNativeVariantPtr)* p_args, int32_t p_argument_count, GDNativeCallError* r_error) variant_construct;
	GDNativePtrSetter function(GDNativeVariantType p_type, const(char)* p_member) variant_get_ptr_setter;
	GDNativePtrGetter function(GDNativeVariantType p_type, const(char)* p_member) variant_get_ptr_getter;
	GDNativePtrIndexedSetter function(GDNativeVariantType p_type) variant_get_ptr_indexed_setter;
	GDNativePtrIndexedGetter function(GDNativeVariantType p_type) variant_get_ptr_indexed_getter;
	GDNativePtrKeyedSetter function(GDNativeVariantType p_type) variant_get_ptr_keyed_setter;
	GDNativePtrKeyedGetter function(GDNativeVariantType p_type) variant_get_ptr_keyed_getter;
	GDNativePtrKeyedChecker function(GDNativeVariantType p_type) variant_get_ptr_keyed_checker;
	void function(GDNativeVariantType p_type, const(char)* p_constant, GDNativeVariantPtr r_ret) variant_get_constant_value;
	GDNativePtrUtilityFunction function(const (char)* p_function, GDNativeInt p_hash) variant_get_ptr_utility_function;

	/*  extra utilities */

	void function(GDNativeStringPtr r_dest, const(char)* p_contents) string_new_with_latin1_chars;
	void function(GDNativeStringPtr r_dest, const(char)* p_contents) string_new_with_utf8_chars;
	void function(GDNativeStringPtr r_dest, const(char16_t)* p_contents) string_new_with_utf16_chars;
	void function(GDNativeStringPtr r_dest, const(char32_t)* p_contents) string_new_with_utf32_chars;
	void function(GDNativeStringPtr r_dest, const(wchar_t)* p_contents) string_new_with_wide_chars;
	void function(GDNativeStringPtr r_dest, const(char)* p_contents, const GDNativeInt p_size) string_new_with_latin1_chars_and_len;
	void function(GDNativeStringPtr r_dest, const(char)* p_contents, const GDNativeInt p_size) string_new_with_utf8_chars_and_len;
	void function(GDNativeStringPtr r_dest, const(char16_t)* p_contents, const GDNativeInt p_size) string_new_with_utf16_chars_and_len;
	void function(GDNativeStringPtr r_dest, const(char32_t)* p_contents, const GDNativeInt p_size) string_new_with_utf32_chars_and_len;
	void function(GDNativeStringPtr r_dest, const(wchar_t)* p_contents, const GDNativeInt p_size) string_new_with_wide_chars_and_len;
	/* Information about the following functions:
	 * - The return value is the resulting encoded string length.
	 * - The length returned is in characters, not in bytes. It also does not include a trailing zero.
	 * - These functions also do not write trailing zero, If you need it, write it yourself at the position indicated by the length (and make sure to allocate it).
	 * - Passing NULL in r_text means only the length is computed (again, without including trailing zero).
	 * - p_max_write_length argument is in characters, not bytes. It will be ignored if r_text is NULL.
	 * - p_max_write_length argument does not affect the return value, it's only to cap write length.
	 */
	GDNativeInt function(const GDNativeStringPtr p_self, char* r_text, GDNativeInt p_max_write_length) string_to_latin1_chars;
	GDNativeInt function(const GDNativeStringPtr p_self, char* r_text, GDNativeInt p_max_write_length) string_to_utf8_chars;
	GDNativeInt function(const GDNativeStringPtr p_self, char16_t* r_text, GDNativeInt p_max_write_length) string_to_utf16_chars;
	GDNativeInt function(const GDNativeStringPtr p_self, char32_t* r_text, GDNativeInt p_max_write_length) string_to_utf32_chars;
	GDNativeInt function(const GDNativeStringPtr p_self, wchar_t* r_text, GDNativeInt p_max_write_length) string_to_wide_chars;
	char32_t* function(GDNativeStringPtr p_self, GDNativeInt p_index) string_operator_index;
	const(char32_t)* function(const GDNativeStringPtr p_self, GDNativeInt p_index) string_operator_index_const;

	/* Packed array functions */

	uint8_t* function(GDNativeTypePtr p_self, GDNativeInt p_index) packed_byte_array_operator_index; // p_self should be a PackedByteArray
	const(uint8_t)* function(const GDNativeTypePtr p_self, GDNativeInt p_index) packed_byte_array_operator_index_const; // p_self should be a PackedByteArray

	GDNativeTypePtr function(GDNativeTypePtr p_self, GDNativeInt p_index) packed_color_array_operator_index; // p_self should be a PackedColorArray, returns Color ptr
	GDNativeTypePtr function(const GDNativeTypePtr p_self, GDNativeInt p_index) packed_color_array_operator_index_const; // p_self should be a PackedColorArray, returns Color ptr

	float* function(GDNativeTypePtr p_self, GDNativeInt p_index) packed_float32_array_operator_index; // p_self should be a PackedFloat32Array
	const(float)* function(const GDNativeTypePtr p_self, GDNativeInt p_index) packed_float32_array_operator_index_const; // p_self should be a PackedFloat32Array
	double* function(GDNativeTypePtr p_self, GDNativeInt p_index) packed_float64_array_operator_index; // p_self should be a PackedFloat64Array
	const(double)* function(const GDNativeTypePtr p_self, GDNativeInt p_index) packed_float64_array_operator_index_const; // p_self should be a PackedFloat64Array

	int32_t* function(GDNativeTypePtr p_self, GDNativeInt p_index) packed_int32_array_operator_index; // p_self should be a PackedInt32Array
	const(int32_t)* function(const GDNativeTypePtr p_self, GDNativeInt p_index) packed_int32_array_operator_index_const; // p_self should be a PackedInt32Array
	int64_t* function(GDNativeTypePtr p_self, GDNativeInt p_index) packed_int64_array_operator_index; // p_self should be a PackedInt32Array
	const(int64_t)* function(const GDNativeTypePtr p_self, GDNativeInt p_index) packed_int64_array_operator_index_const; // p_self should be a PackedInt32Array

	GDNativeStringPtr function(GDNativeTypePtr p_self, GDNativeInt p_index) packed_string_array_operator_index; // p_self should be a PackedStringArray
	GDNativeStringPtr function(const GDNativeTypePtr p_self, GDNativeInt p_index) packed_string_array_operator_index_const; // p_self should be a PackedStringArray

	GDNativeTypePtr function(GDNativeTypePtr p_self, GDNativeInt p_index) packed_vector2_array_operator_index; // p_self should be a PackedVector2Array, returns Vector2 ptr
	GDNativeTypePtr function(const GDNativeTypePtr p_self, GDNativeInt p_index) packed_vector2_array_operator_index_const; // p_self should be a PackedVector2Array, returns Vector2 ptr
	GDNativeTypePtr function(GDNativeTypePtr p_self, GDNativeInt p_index) packed_vector3_array_operator_index; // p_self should be a PackedVector3Array, returns Vector3 ptr
	GDNativeTypePtr function(const GDNativeTypePtr p_self, GDNativeInt p_index) packed_vector3_array_operator_index_const; // p_self should be a PackedVector3Array, returns Vector3 ptr

	GDNativeVariantPtr function(GDNativeTypePtr p_self, GDNativeInt p_index) array_operator_index; // p_self should be an Array ptr
	GDNativeVariantPtr function(const GDNativeTypePtr p_self, GDNativeInt p_index) array_operator_index_const; // p_self should be an Array ptr

	/* Dictionary functions */

	GDNativeVariantPtr function(GDNativeTypePtr p_self, const GDNativeVariantPtr p_key) dictionary_operator_index; // p_self should be an Dictionary ptr
	GDNativeVariantPtr function(const GDNativeTypePtr p_self, const GDNativeVariantPtr p_key) dictionary_operator_index_const; // p_self should be an Dictionary ptr

	/* OBJECT */

	void function(const GDNativeMethodBindPtr p_method_bind, GDNativeObjectPtr p_instance, const GDNativeVariantPtr *p_args, GDNativeInt p_arg_count, GDNativeVariantPtr r_ret, GDNativeCallError *r_error) object_method_bind_call;
	void function(const GDNativeMethodBindPtr p_method_bind, GDNativeObjectPtr p_instance, const GDNativeTypePtr *p_args, GDNativeTypePtr r_ret) object_method_bind_ptrcall;
	void function(GDNativeObjectPtr p_o) object_destroy;
	GDNativeObjectPtr function(const(char)* p_name) global_get_singleton;

	void* function(GDNativeObjectPtr p_o, void *p_token, const GDNativeInstanceBindingCallbacks *p_callbacks) object_get_instance_binding;
	void function(GDNativeObjectPtr p_o, void *p_token, void *p_binding, const GDNativeInstanceBindingCallbacks *p_callbacks) object_set_instance_binding;

	void function(GDNativeObjectPtr p_o, const char *p_classname, GDExtensionClassInstancePtr p_instance) object_set_instance; /* p_classname should be a registered extension class and should extend the p_o object's class. */

	GDNativeObjectPtr function(const GDNativeObjectPtr p_object, void *p_class_tag) object_cast_to;
	GDNativeObjectPtr function(GDObjectInstanceID p_instance_id) object_get_instance_from_id;
	GDObjectInstanceID function(const GDNativeObjectPtr p_object) object_get_instance_id;

	/* SCRIPT INSTANCE */

	GDNativeScriptInstancePtr function(const GDNativeExtensionScriptInstanceInfo *p_info, GDNativeExtensionScriptInstanceDataPtr p_instance_data) script_instance_create;

	/* CLASSDB */
	GDNativeObjectPtr function(const char *p_classname) classdb_construct_object; /* The passed class must be a built-in godot class, or an already-registered extension class. In both case, object_set_instance should be called to fully initialize the object. */
	GDNativeMethodBindPtr function(const char *p_classname, const char *p_methodname, GDNativeInt p_hash) classdb_get_method_bind;
	void* function(const char *p_classname) classdb_get_class_tag;

	/* CLASSDB EXTENSION */

	void function(const GDNativeExtensionClassLibraryPtr p_library, const char *p_class_name, const char *p_parent_class_name, const GDNativeExtensionClassCreationInfo *p_extension_funcs) classdb_register_extension_class;
	void function(const GDNativeExtensionClassLibraryPtr p_library, const char *p_class_name, const GDNativeExtensionClassMethodInfo *p_method_info) classdb_register_extension_class_method;
	void function(const GDNativeExtensionClassLibraryPtr p_library, const char *p_class_name, const char *p_enum_name, const char *p_constant_name, GDNativeInt p_constant_value, bool p_is_bitfield) classdb_register_extension_class_integer_constant;
	void function(const GDNativeExtensionClassLibraryPtr p_library, const char *p_class_name, const GDNativePropertyInfo *p_info, const char *p_setter, const char *p_getter) classdb_register_extension_class_property;
	void function(const GDNativeExtensionClassLibraryPtr p_library, const char *p_class_name, const char *p_group_name, const char *p_prefix) classdb_register_extension_class_property_group;
	void function(const GDNativeExtensionClassLibraryPtr p_library, const char *p_class_name, const char *p_subgroup_name, const char *p_prefix) classdb_register_extension_class_property_subgroup;
	void function(const GDNativeExtensionClassLibraryPtr p_library, const char *p_class_name, const char *p_signal_name, const GDNativePropertyInfo *p_argument_info, GDNativeInt p_argument_count) classdb_register_extension_class_signal;
	void function(const GDNativeExtensionClassLibraryPtr p_library, const char *p_class_name) classdb_unregister_extension_class; /* Unregistering a parent class before a class that inherits it will result in failure. Inheritors must be unregistered first. */

	void function(const GDNativeExtensionClassLibraryPtr p_library, GDNativeStringPtr r_path) get_library_path;

}

/* INITIALIZATION */
alias GDNativeInitializationLevel = int;
enum : GDNativeInitializationLevel 
{
	GDNATIVE_INITIALIZATION_CORE,
	GDNATIVE_INITIALIZATION_SERVERS,
	GDNATIVE_INITIALIZATION_SCENE,
	GDNATIVE_INITIALIZATION_EDITOR,
	GDNATIVE_MAX_INITIALIZATION_LEVEL,
}

struct GDNativeInitialization
{
//@nogc nothrow:
	/* Minimum initialization level required.
	 * If Core or Servers, the extension needs editor or game restart to take effect */
	GDNativeInitializationLevel minimum_initialization_level;
	/* Up to the user to supply when initializing */
	void *userdata;
	/* This function will be called multiple times for each initialization level. */
	void function(void *userdata, GDNativeInitializationLevel p_level) initialize;
	void function(void *userdata, GDNativeInitializationLevel p_level) deinitialize;
}

/* Define a C function prototype that implements the function below and expose it to dlopen() (or similar).
 * It will be called on initialization. The name must be an unique one specified in the .gdextension config file.
 */

 alias GDNativeInitializationFunction = GDNativeBool function(const GDNativeInterface *p_interface, const GDNativeExtensionClassLibraryPtr p_library, GDNativeInitialization *r_initialization);


module godot.abi.gdextension_binding;

import godot.abi.types;
import core.stdc.config;

version(WebAssembly) {
    alias wchar_t = dchar;
} 
else {
    public import core.stdc.stddef : wchar_t;
}

extern (C):

/**************************************************************************/
/*  gdextension_interface.h                                               */
/**************************************************************************/
/*                         This file is part of:                          */
/*                             GODOT ENGINE                               */
/*                        https://godotengine.org                         */
/**************************************************************************/
/* Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md). */
/* Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.                  */
/*                                                                        */
/* Permission is hereby granted, free of charge, to any person obtaining  */
/* a copy of this software and associated documentation files (the        */
/* "Software"), to deal in the Software without restriction, including    */
/* without limitation the rights to use, copy, modify, merge, publish,    */
/* distribute, sublicense, and/or sell copies of the Software, and to     */
/* permit persons to whom the Software is furnished to do so, subject to  */
/* the following conditions:                                              */
/*                                                                        */
/* The above copyright notice and this permission notice shall be         */
/* included in all copies or substantial portions of the Software.        */
/*                                                                        */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,        */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. */
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 */
/**************************************************************************/
/* This is a C class header, you can copy it and use it directly in your own binders.
 * Together with the JSON file, you should be able to generate any binder.
 */

alias char32_t = uint32_t;
alias char16_t = uint16_t;

/* VARIANT TYPES */

alias GDExtensionVariantType = int;
enum : GDExtensionVariantType
{
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
    GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR4_ARRAY,
    GDEXTENSION_VARIANT_TYPE_VARIANT_MAX
}

alias GDExtensionVariantOperator = int;
enum : GDExtensionVariantOperator
{
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

// In this API there are multiple functions which expect the caller to pass a pointer
// on return value as parameter.
// In order to make it clear if the caller should initialize the return value or not
// we have two flavor of types:
// - `GDExtensionXXXPtr` for pointer on an initialized value
// - `GDExtensionUninitializedXXXPtr` for pointer on uninitialized value
//
// Notes:
// - Not respecting those requirements can seems harmless, but will lead to unexpected
//   segfault or memory leak (for instance with a specific compiler/OS, or when two
//   native extensions start doing ptrcall on each other).
// - Initialization must be done with the function pointer returned by `variant_get_ptr_constructor`,
//   zero-initializing the variable should not be considered a valid initialization method here !
// - Some types have no destructor (see `extension_api.json`'s `has_destructor` field), for
//   them it is always safe to skip the constructor for the return value if you are in a hurry ;-)

alias GDExtensionVariantPtr = void*;
alias GDExtensionConstVariantPtr = const(void)*;
alias GDExtensionUninitializedVariantPtr = void*;
alias GDExtensionStringNamePtr = void*;
alias GDExtensionConstStringNamePtr = const(void)*;
alias GDExtensionUninitializedStringNamePtr = void*;
alias GDExtensionStringPtr = void*;
alias GDExtensionConstStringPtr = const(void)*;
alias GDExtensionUninitializedStringPtr = void*;
alias GDExtensionObjectPtr = void*;
alias GDExtensionConstObjectPtr = const(void)*;
alias GDExtensionUninitializedObjectPtr = void*;
alias GDExtensionTypePtr = void*;
alias GDExtensionConstTypePtr = const(void)*;
alias GDExtensionUninitializedTypePtr = void*;
alias GDExtensionMethodBindPtr = const(void)*;
alias GDExtensionInt = int64_t;
alias GDExtensionBool = uint8_t;
alias GDObjectInstanceID = uint64_t;
alias GDExtensionRefPtr = void*;
alias GDExtensionConstRefPtr = const(void)*;

/* VARIANT DATA I/O */

alias GDExtensionCallErrorType = int;
enum : GDExtensionCallErrorType
{
    GDEXTENSION_CALL_OK,
    GDEXTENSION_CALL_ERROR_INVALID_METHOD,
    GDEXTENSION_CALL_ERROR_INVALID_ARGUMENT, // Expected a different variant type.
    GDEXTENSION_CALL_ERROR_TOO_MANY_ARGUMENTS, // Expected lower number of arguments.
    GDEXTENSION_CALL_ERROR_TOO_FEW_ARGUMENTS, // Expected higher number of arguments.
    GDEXTENSION_CALL_ERROR_INSTANCE_IS_NULL,
    GDEXTENSION_CALL_ERROR_METHOD_NOT_CONST, // Used for const call.
}

struct GDExtensionCallError
{
    GDExtensionCallErrorType error;
    int32_t argument;
    int32_t expected;
}

alias GDExtensionVariantFromTypeConstructorFunc = void function(GDExtensionUninitializedVariantPtr, GDExtensionTypePtr);
alias GDExtensionTypeFromVariantConstructorFunc = void function(GDExtensionUninitializedTypePtr, GDExtensionVariantPtr);
alias GDExtensionVariantGetInternalPtrFunc = void* function(GDExtensionVariantPtr);
alias GDExtensionPtrOperatorEvaluator = void function(GDExtensionConstTypePtr p_left, GDExtensionConstTypePtr p_right, GDExtensionTypePtr r_result);
alias GDExtensionPtrBuiltInMethod = void function(GDExtensionTypePtr p_base, const(GDExtensionConstTypePtr)* p_args, GDExtensionTypePtr r_return, int p_argument_count);
alias GDExtensionPtrConstructor = void function(GDExtensionUninitializedTypePtr p_base, const(GDExtensionConstTypePtr)* p_args);
alias GDExtensionPtrDestructor = void function(GDExtensionTypePtr p_base);
alias GDExtensionPtrSetter = void function(GDExtensionTypePtr p_base, GDExtensionConstTypePtr p_value);
alias GDExtensionPtrGetter = void function(GDExtensionConstTypePtr p_base, GDExtensionTypePtr r_value);
alias GDExtensionPtrIndexedSetter = void function(GDExtensionTypePtr p_base, GDExtensionInt p_index, GDExtensionConstTypePtr p_value);
alias GDExtensionPtrIndexedGetter = void function(GDExtensionConstTypePtr p_base, GDExtensionInt p_index, GDExtensionTypePtr r_value);
alias GDExtensionPtrKeyedSetter = void function(GDExtensionTypePtr p_base, GDExtensionConstTypePtr p_key, GDExtensionConstTypePtr p_value);
alias GDExtensionPtrKeyedGetter = void function(GDExtensionConstTypePtr p_base, GDExtensionConstTypePtr p_key, GDExtensionTypePtr r_value);
alias GDExtensionPtrKeyedChecker = uint32_t function(GDExtensionConstVariantPtr p_base, GDExtensionConstVariantPtr p_key);
alias GDExtensionPtrUtilityFunction = void function(GDExtensionTypePtr r_return, const(GDExtensionConstTypePtr)* p_args, int p_argument_count);

alias GDExtensionClassConstructor = GDExtensionObjectPtr function();

alias GDExtensionInstanceBindingCreateCallback = void* function(void* p_token, void* p_instance);
alias GDExtensionInstanceBindingFreeCallback = void function(void* p_token, void* p_instance, void* p_binding);
alias GDExtensionInstanceBindingReferenceCallback = GDExtensionBool function(void* p_token, void* p_binding, GDExtensionBool p_reference);

struct GDExtensionInstanceBindingCallbacks
{
    GDExtensionInstanceBindingCreateCallback create_callback;
    GDExtensionInstanceBindingFreeCallback free_callback;
    GDExtensionInstanceBindingReferenceCallback reference_callback;
}

/* EXTENSION CLASSES */

alias GDExtensionClassInstancePtr = void*;

alias GDExtensionClassSet = GDExtensionBool function(GDExtensionClassInstancePtr p_instance, GDExtensionConstStringNamePtr p_name, GDExtensionConstVariantPtr p_value);
alias GDExtensionClassGet = GDExtensionBool function(GDExtensionClassInstancePtr p_instance, GDExtensionConstStringNamePtr p_name, GDExtensionVariantPtr r_ret);
alias GDExtensionClassGetRID = uint64_t function(GDExtensionClassInstancePtr p_instance);

struct GDExtensionPropertyInfo
{
    GDExtensionVariantType type;
    GDExtensionStringNamePtr name;
    GDExtensionStringNamePtr class_name;
    uint32_t hint;
    GDExtensionStringPtr hint_string;
    uint32_t usage;
}

struct GDExtensionMethodInfo
{
    GDExtensionStringNamePtr name;
    GDExtensionPropertyInfo return_value;
    uint32_t flags;
    int32_t id;
    uint32_t argument_count;
    GDExtensionPropertyInfo* arguments;
    uint32_t default_argument_count;
    GDExtensionVariantPtr* default_arguments;
}

alias GDExtensionClassGetPropertyList = const(GDExtensionPropertyInfo) * function(GDExtensionClassInstancePtr p_instance, uint32_t* r_count);
alias GDExtensionClassFreePropertyList = void function(GDExtensionClassInstancePtr p_instance, const(GDExtensionPropertyInfo)* p_list);
alias GDExtensionClassFreePropertyList2 = void function(GDExtensionClassInstancePtr p_instance, const(GDExtensionPropertyInfo)* p_list, uint32_t p_count);
alias GDExtensionClassPropertyCanRevert = GDExtensionBool function(GDExtensionClassInstancePtr p_instance, GDExtensionConstStringNamePtr p_name);
alias GDExtensionClassPropertyGetRevert = GDExtensionBool function(GDExtensionClassInstancePtr p_instance, GDExtensionConstStringNamePtr p_name, GDExtensionVariantPtr r_ret);
alias GDExtensionClassValidateProperty = GDExtensionBool function(GDExtensionClassInstancePtr p_instance, GDExtensionPropertyInfo* p_property);
alias GDExtensionClassNotification = void function(GDExtensionClassInstancePtr p_instance, int32_t p_what);  // Deprecated. Use GDExtensionClassNotification2 instead.
alias GDExtensionClassNotification2 = void function(GDExtensionClassInstancePtr p_instance, int32_t p_what, GDExtensionBool p_reversed);
alias GDExtensionClassToString = void function(GDExtensionClassInstancePtr p_instance, GDExtensionBool* r_is_valid, GDExtensionStringPtr p_out);
alias GDExtensionClassReference = void function(GDExtensionClassInstancePtr p_instance);
alias GDExtensionClassUnreference = void function(GDExtensionClassInstancePtr p_instance);
alias GDExtensionClassCallVirtual = void function(GDExtensionClassInstancePtr p_instance, const(GDExtensionConstTypePtr)* p_args, GDExtensionTypePtr r_ret);
alias GDExtensionClassCreateInstance = GDExtensionObjectPtr function(void* p_class_userdata);
alias GDExtensionClassCreateInstance2 = GDExtensionObjectPtr function(void* p_class_userdata, GDExtensionBool p_notify_postinitialize);
alias GDExtensionClassFreeInstance = void function(void* p_class_userdata, GDExtensionClassInstancePtr p_instance);
alias GDExtensionClassRecreateInstance = GDExtensionClassInstancePtr function(void* p_class_userdata, GDExtensionObjectPtr p_object);
alias GDExtensionClassGetVirtual = GDExtensionClassCallVirtual function(void* p_class_userdata, GDExtensionConstStringNamePtr p_name);
alias GDExtensionClassGetVirtual2 = GDExtensionClassCallVirtual function(void* p_class_userdata, GDExtensionConstStringNamePtr p_name, uint32_t p_hash);
alias GDExtensionClassGetVirtualCallData = void * function(void* p_class_userdata, GDExtensionConstStringNamePtr p_name);
alias GDExtensionClassGetVirtualCallData2 = void * function(void* p_class_userdata, GDExtensionConstStringNamePtr p_name, uint32_t p_hash);
alias GDExtensionClassCallVirtualWithData = void function(GDExtensionClassInstancePtr p_instance, GDExtensionConstStringNamePtr p_name, void* p_virtual_call_userdata, const(GDExtensionConstTypePtr)* p_args, GDExtensionTypePtr r_ret);

// Deprecated. Use GDExtensionClassCreationInfo3 instead.
struct GDExtensionClassCreationInfo
{
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
    GDExtensionClassCreateInstance create_instance_func;
    GDExtensionClassFreeInstance free_instance_func;
    GDExtensionClassGetVirtual get_virtual_func;
    GDExtensionClassGetRID get_rid_func;
    void* class_userdata;
}

// Deprecated. Use GDExtensionClassCreationInfo4 instead.
struct GDExtensionClassCreationInfo2
{
    GDExtensionBool is_virtual;
    GDExtensionBool is_abstract;
    GDExtensionBool is_exposed;
    GDExtensionClassSet set_func;
    GDExtensionClassGet get_func;
    GDExtensionClassGetPropertyList get_property_list_func;
    GDExtensionClassFreePropertyList free_property_list_func;
    GDExtensionClassPropertyCanRevert property_can_revert_func;
    GDExtensionClassPropertyGetRevert property_get_revert_func;
    GDExtensionClassValidateProperty validate_property_func;
    GDExtensionClassNotification2 notification_func;
    GDExtensionClassToString to_string_func;
    GDExtensionClassReference reference_func;
    GDExtensionClassUnreference unreference_func;
    GDExtensionClassCreateInstance create_instance_func;
    GDExtensionClassFreeInstance free_instance_func;
    GDExtensionClassRecreateInstance recreate_instance_func;
    GDExtensionClassGetVirtual get_virtual_func;
    GDExtensionClassGetVirtualCallData get_virtual_call_data_func;
    GDExtensionClassCallVirtualWithData call_virtual_with_data_func;
    GDExtensionClassGetRID get_rid_func;
    void* class_userdata;
}

// Deprecated. Use GDExtensionClassCreationInfo4 instead.
struct GDExtensionClassCreationInfo3
{
    GDExtensionBool is_virtual;
    GDExtensionBool is_abstract;
    GDExtensionBool is_exposed;
    GDExtensionBool is_runtime;
    GDExtensionClassSet set_func;
    GDExtensionClassGet get_func;
    GDExtensionClassGetPropertyList get_property_list_func;
    GDExtensionClassFreePropertyList2 free_property_list_func;
    GDExtensionClassPropertyCanRevert property_can_revert_func;
    GDExtensionClassPropertyGetRevert property_get_revert_func;
    GDExtensionClassValidateProperty validate_property_func;
    GDExtensionClassNotification2 notification_func;
    GDExtensionClassToString to_string_func;
    GDExtensionClassReference reference_func;
    GDExtensionClassUnreference unreference_func;
    GDExtensionClassCreateInstance create_instance_func;
    GDExtensionClassFreeInstance free_instance_func;
    GDExtensionClassRecreateInstance recreate_instance_func;
    GDExtensionClassGetVirtual get_virtual_func;
    GDExtensionClassGetVirtualCallData get_virtual_call_data_func;
    GDExtensionClassCallVirtualWithData call_virtual_with_data_func;
    GDExtensionClassGetRID get_rid_func;
    void* class_userdata;
}


struct GDExtensionClassCreationInfo4
{
    GDExtensionBool is_virtual;
    GDExtensionBool is_abstract;
    GDExtensionBool is_exposed;
    GDExtensionBool is_runtime;
    GDExtensionConstStringPtr icon_path;
    GDExtensionClassSet set_func;
    GDExtensionClassGet get_func;
    GDExtensionClassGetPropertyList get_property_list_func;
    GDExtensionClassFreePropertyList2 free_property_list_func;
    GDExtensionClassPropertyCanRevert property_can_revert_func;
    GDExtensionClassPropertyGetRevert property_get_revert_func;
    GDExtensionClassValidateProperty validate_property_func;
    GDExtensionClassNotification2 notification_func;
    GDExtensionClassToString to_string_func;
    GDExtensionClassReference reference_func;
    GDExtensionClassUnreference unreference_func;
    GDExtensionClassCreateInstance2 create_instance_func;
    GDExtensionClassFreeInstance free_instance_func;
    GDExtensionClassRecreateInstance recreate_instance_func;
    GDExtensionClassGetVirtual2 get_virtual_func;
    GDExtensionClassGetVirtualCallData2 get_virtual_call_data_func;
    GDExtensionClassCallVirtualWithData call_virtual_with_data_func;
    void* class_userdata;
}

alias GDExtensionClassCreationInfo5 = GDExtensionClassCreationInfo4;

alias GDExtensionClassLibraryPtr = void*;

/* Passed a pointer to a PackedStringArray that should be filled with the classes that may be used by the GDExtension. */
alias GDExtensionEditorGetClassesUsedCallback = void function(GDExtensionTypePtr p_packed_string_array);

/* Method */
alias GDExtensionClassMethodFlags = int;
enum : GDExtensionClassMethodFlags
{
    GDEXTENSION_METHOD_FLAG_NORMAL = 1,
    GDEXTENSION_METHOD_FLAG_EDITOR = 2,
    GDEXTENSION_METHOD_FLAG_CONST = 4,
    GDEXTENSION_METHOD_FLAG_VIRTUAL = 8,
    GDEXTENSION_METHOD_FLAG_VARARG = 16,
    GDEXTENSION_METHOD_FLAG_STATIC = 32,
    GDEXTENSION_METHOD_FLAGS_DEFAULT = GDEXTENSION_METHOD_FLAG_NORMAL,
}

alias GDExtensionClassMethodArgumentMetadata = int;
enum : GDExtensionClassMethodArgumentMetadata
{
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
    GDEXTENSION_METHOD_ARGUMENT_METADATA_REAL_IS_DOUBLE,
    GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_CHAR16,
    GDEXTENSION_METHOD_ARGUMENT_METADATA_INT_IS_CHAR32,
}

alias GDExtensionClassMethodCall = void function(void* method_userdata, GDExtensionClassInstancePtr p_instance, const(GDExtensionConstVariantPtr)* p_args, GDExtensionInt p_argument_count, GDExtensionVariantPtr r_return, GDExtensionCallError* r_error);
alias GDExtensionClassMethodValidatedCall = void function(void* method_userdata, GDExtensionClassInstancePtr p_instance, const(GDExtensionConstVariantPtr)* p_args, GDExtensionVariantPtr r_return);
alias GDExtensionClassMethodPtrCall = void function(void* method_userdata, GDExtensionClassInstancePtr p_instance, const(GDExtensionConstTypePtr)* p_args, GDExtensionTypePtr r_ret);

struct GDExtensionClassMethodInfo
{
    GDExtensionStringNamePtr name;
    void* method_userdata;
    GDExtensionClassMethodCall call_func;
    GDExtensionClassMethodPtrCall ptrcall_func;
    uint32_t method_flags;
    GDExtensionBool has_return_value;
    GDExtensionPropertyInfo* return_value_info;
    GDExtensionClassMethodArgumentMetadata return_value_metadata;
    uint32_t argument_count;
    GDExtensionPropertyInfo* arguments_info;
    GDExtensionClassMethodArgumentMetadata* arguments_metadata;
    uint32_t default_argument_count;
    GDExtensionVariantPtr* default_arguments;
}


struct GDExtensionClassVirtualMethodInfo
{
    GDExtensionStringNamePtr name;
    uint32_t method_flags;
    GDExtensionPropertyInfo return_value;
    GDExtensionClassMethodArgumentMetadata return_value_metadata;
    uint32_t argument_count;
    GDExtensionPropertyInfo* arguments;
    GDExtensionClassMethodArgumentMetadata* arguments_metadata;
}

alias GDExtensionCallableCustomCall = void function(void* callable_userdata, const(GDExtensionConstVariantPtr)* p_args, GDExtensionInt p_argument_count, GDExtensionVariantPtr r_return, GDExtensionCallError* r_error);
alias GDExtensionCallableCustomIsValid = GDExtensionBool function(void* callable_userdata);
alias GDExtensionCallableCustomFree = void function(void* callable_userdata);
alias GDExtensionCallableCustomHash = uint32_t function(void* callable_userdata);
alias GDExtensionCallableCustomEqual = GDExtensionBool function(void* callable_userdata_a, void* callable_userdata_b);
alias GDExtensionCallableCustomLessThan = GDExtensionBool function(void* callable_userdata_a, void* callable_userdata_b);
alias GDExtensionCallableCustomToString = void function(void* callable_userdata, GDExtensionBool* r_is_valid, GDExtensionStringPtr r_out);
alias GDExtensionCallableCustomGetArgumentCount = GDExtensionInt function(void* callable_userdata, GDExtensionBool* r_is_valid);

// Deprecated. Use GDExtensionCallableCustomInfo2 instead.
struct GDExtensionCallableCustomInfo
{
    void* callable_userdata;
    void* token;
    GDObjectInstanceID object_id;
    GDExtensionCallableCustomCall call_func;
    GDExtensionCallableCustomIsValid is_valid_func;
    GDExtensionCallableCustomFree free_func;
    GDExtensionCallableCustomHash hash_func;
    GDExtensionCallableCustomEqual equal_func;
    GDExtensionCallableCustomLessThan less_than_func;
    GDExtensionCallableCustomToString to_string_func;
}


struct GDExtensionCallableCustomInfo2
{
    void* callable_userdata;
    void* token;
    GDObjectInstanceID object_id;
    GDExtensionCallableCustomCall call_func;
    GDExtensionCallableCustomIsValid is_valid_func;
    GDExtensionCallableCustomFree free_func;
    GDExtensionCallableCustomHash hash_func;
    GDExtensionCallableCustomEqual equal_func;
    GDExtensionCallableCustomLessThan less_than_func;
    GDExtensionCallableCustomToString to_string_func;
    GDExtensionCallableCustomGetArgumentCount get_argument_count_func;
}

/* SCRIPT INSTANCE EXTENSION */

alias GDExtensionScriptInstanceDataPtr = void*;  // Pointer to custom ScriptInstance native implementation.

alias GDExtensionScriptInstanceSet = GDExtensionBool function(GDExtensionScriptInstanceDataPtr p_instance, GDExtensionConstStringNamePtr p_name, GDExtensionConstVariantPtr p_value);
alias GDExtensionScriptInstanceGet = GDExtensionBool function(GDExtensionScriptInstanceDataPtr p_instance, GDExtensionConstStringNamePtr p_name, GDExtensionVariantPtr r_ret);
alias GDExtensionScriptInstanceGetPropertyList = const(GDExtensionPropertyInfo) * function(GDExtensionScriptInstanceDataPtr p_instance, uint32_t* r_count);
alias GDExtensionScriptInstanceFreePropertyList = void function(GDExtensionScriptInstanceDataPtr p_instance, const(GDExtensionPropertyInfo)* p_list); // Deprecated. Use GDExtensionScriptInstanceFreePropertyList2 instead.
alias GDExtensionScriptInstanceFreePropertyList2 = void function(GDExtensionScriptInstanceDataPtr p_instance, const(GDExtensionPropertyInfo)* p_list, uint32_t p_count);
alias GDExtensionScriptInstanceGetClassCategory = GDExtensionBool function(GDExtensionScriptInstanceDataPtr p_instance, GDExtensionPropertyInfo* p_class_category);
alias GDExtensionScriptInstanceGetPropertyType = GDExtensionVariantType function(GDExtensionScriptInstanceDataPtr p_instance, GDExtensionConstStringNamePtr p_name, GDExtensionBool* r_is_valid);
alias GDExtensionScriptInstanceValidateProperty = GDExtensionBool function(GDExtensionScriptInstanceDataPtr p_instance, GDExtensionPropertyInfo* p_property);
alias GDExtensionScriptInstancePropertyCanRevert = GDExtensionBool function(GDExtensionScriptInstanceDataPtr p_instance, GDExtensionConstStringNamePtr p_name);
alias GDExtensionScriptInstancePropertyGetRevert = GDExtensionBool function(GDExtensionScriptInstanceDataPtr p_instance, GDExtensionConstStringNamePtr p_name, GDExtensionVariantPtr r_ret);

alias GDExtensionScriptInstanceGetOwner = GDExtensionObjectPtr function(GDExtensionScriptInstanceDataPtr p_instance);
alias GDExtensionScriptInstancePropertyStateAdd = void function(GDExtensionConstStringNamePtr p_name, GDExtensionConstVariantPtr p_value, void* p_userdata);
alias GDExtensionScriptInstanceGetPropertyState = void function(GDExtensionScriptInstanceDataPtr p_instance, GDExtensionScriptInstancePropertyStateAdd p_add_func, void* p_userdata);
alias GDExtensionScriptInstanceGetMethodList = const(GDExtensionMethodInfo) * function(GDExtensionScriptInstanceDataPtr p_instance, uint32_t* r_count);
alias GDExtensionScriptInstanceFreeMethodList = void function(GDExtensionScriptInstanceDataPtr p_instance, const(GDExtensionMethodInfo)* p_list); // Deprecated. Use GDExtensionScriptInstanceFreeMethodList2 instead.
alias GDExtensionScriptInstanceFreeMethodList2 = void function(GDExtensionScriptInstanceDataPtr p_instance, const(GDExtensionMethodInfo)* p_list, uint32_t p_count);

alias GDExtensionScriptInstanceHasMethod = GDExtensionBool function(GDExtensionScriptInstanceDataPtr p_instance, GDExtensionConstStringNamePtr p_name);
alias GDExtensionScriptInstanceGetMethodArgumentCount = GDExtensionInt function(GDExtensionScriptInstanceDataPtr p_instance, GDExtensionConstStringNamePtr p_name, GDExtensionBool* r_is_valid);

alias GDExtensionScriptInstanceCall = void function(GDExtensionScriptInstanceDataPtr p_self, GDExtensionConstStringNamePtr p_method, const(GDExtensionConstVariantPtr)* p_args, GDExtensionInt p_argument_count, GDExtensionVariantPtr r_return, GDExtensionCallError* r_error);
alias GDExtensionScriptInstanceNotification = void function(GDExtensionScriptInstanceDataPtr p_instance, int32_t p_what); // Deprecated. Use GDExtensionScriptInstanceNotification2 instead.
alias GDExtensionScriptInstanceNotification2 = void function(GDExtensionScriptInstanceDataPtr p_instance, int32_t p_what, GDExtensionBool p_reversed);
alias GDExtensionScriptInstanceToString = void function(GDExtensionScriptInstanceDataPtr p_instance, GDExtensionBool* r_is_valid, GDExtensionStringPtr r_out);

alias GDExtensionScriptInstanceRefCountIncremented = void function(GDExtensionScriptInstanceDataPtr p_instance);
alias GDExtensionScriptInstanceRefCountDecremented = GDExtensionBool function(GDExtensionScriptInstanceDataPtr p_instance);

alias GDExtensionScriptInstanceGetScript = GDExtensionObjectPtr function(GDExtensionScriptInstanceDataPtr p_instance);
alias GDExtensionScriptInstanceIsPlaceholder = GDExtensionBool function(GDExtensionScriptInstanceDataPtr p_instance);

alias GDExtensionScriptLanguagePtr = void*;

alias GDExtensionScriptInstanceGetLanguage = GDExtensionScriptLanguagePtr function(GDExtensionScriptInstanceDataPtr p_instance);

alias GDExtensionScriptInstanceFree = void function(GDExtensionScriptInstanceDataPtr p_instance);

alias GDExtensionScriptInstancePtr = void*; // Pointer to ScriptInstance.

struct GDExtensionScriptInstanceInfo
{
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

// Deprecated. Use GDExtensionScriptInstanceInfo3 instead.
struct GDExtensionScriptInstanceInfo2
{
    GDExtensionScriptInstanceSet set_func;
    GDExtensionScriptInstanceGet get_func;
    GDExtensionScriptInstanceGetPropertyList get_property_list_func;
    GDExtensionScriptInstanceFreePropertyList free_property_list_func;
    GDExtensionScriptInstanceGetClassCategory get_class_category_func;
    GDExtensionScriptInstancePropertyCanRevert property_can_revert_func;
    GDExtensionScriptInstancePropertyGetRevert property_get_revert_func;
    GDExtensionScriptInstanceGetOwner get_owner_func;
    GDExtensionScriptInstanceGetPropertyState get_property_state_func;
    GDExtensionScriptInstanceGetMethodList get_method_list_func;
    GDExtensionScriptInstanceFreeMethodList free_method_list_func;
    GDExtensionScriptInstanceGetPropertyType get_property_type_func;
    GDExtensionScriptInstanceValidateProperty validate_property_func;
    GDExtensionScriptInstanceHasMethod has_method_func;
    GDExtensionScriptInstanceCall call_func;
    GDExtensionScriptInstanceNotification2 notification_func;
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

// Deprecated. Use GDExtensionScriptInstanceInfo3 instead.

struct GDExtensionScriptInstanceInfo3
{
    GDExtensionScriptInstanceSet set_func;
    GDExtensionScriptInstanceGet get_func;
    GDExtensionScriptInstanceGetPropertyList get_property_list_func;
    GDExtensionScriptInstanceFreePropertyList2 free_property_list_func;
    GDExtensionScriptInstanceGetClassCategory get_class_category_func;
    GDExtensionScriptInstancePropertyCanRevert property_can_revert_func;
    GDExtensionScriptInstancePropertyGetRevert property_get_revert_func;
    GDExtensionScriptInstanceGetOwner get_owner_func;
    GDExtensionScriptInstanceGetPropertyState get_property_state_func;
    GDExtensionScriptInstanceGetMethodList get_method_list_func;
    GDExtensionScriptInstanceFreeMethodList2 free_method_list_func;
    GDExtensionScriptInstanceGetPropertyType get_property_type_func;
    GDExtensionScriptInstanceValidateProperty validate_property_func;
    GDExtensionScriptInstanceHasMethod has_method_func;
    GDExtensionScriptInstanceGetMethodArgumentCount get_method_argument_count_func;
    GDExtensionScriptInstanceCall call_func;
    GDExtensionScriptInstanceNotification2 notification_func;
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

alias GDExtensionWorkerThreadPoolGroupTask = void function(void *, uint32_t);

alias GDExtensionWorkerThreadPoolTask = void function(void *);

/* INITIALIZATION */
alias GDExtensionInitializationLevel = int;
enum : GDExtensionInitializationLevel
{
    GDEXTENSION_INITIALIZATION_CORE,
    GDEXTENSION_INITIALIZATION_SERVERS,
    GDEXTENSION_INITIALIZATION_SCENE,
    GDEXTENSION_INITIALIZATION_EDITOR,
    GDEXTENSION_MAX_INITIALIZATION_LEVEL,
}

alias GDExtensionInitializeCallback = void function(void* p_userdata, GDExtensionInitializationLevel p_level);

alias GDExtensionDeinitializeCallback = void function(void* p_userdata, GDExtensionInitializationLevel p_level);

struct GDExtensionInitialization
{
    GDExtensionInitializationLevel minimum_initialization_level;
    void* userdata;
    GDExtensionInitializeCallback initialize;
    GDExtensionDeinitializeCallback deinitialize;
}

alias GDExtensionInterfaceFunctionPtr = void function();
alias GDExtensionInterfaceGetProcAddress = GDExtensionInterfaceFunctionPtr function(const(char)* p_function_name);

/*
 * Each GDExtension should define a C function that matches the signature of GDExtensionInitializationFunction,
 * and export it so that it can be loaded via dlopen() or equivalent for the given platform.
 *
 * For example:
 *
 *   GDExtensionBool my_extension_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization);
 *
 * This function's name must be specified as the 'entry_symbol' in the .gdextension file.
 *
 * This makes it the entry point of the GDExtension and will be called on initialization.
 *
 * The GDExtension can then modify the r_initialization structure, setting the minimum initialization level,
 * and providing pointers to functions that will be called at various stages of initialization/shutdown.
 *
 * The rest of the GDExtension's interface to Godot consists of function pointers that can be loaded
 * by calling p_get_proc_address("...") with the name of the function.
 *
 * For example:
 *
 *   GDExtensionInterfaceGetGodotVersion get_godot_version = (GDExtensionInterfaceGetGodotVersion)p_get_proc_address("get_godot_version");
 *
 * (Note that snippet may cause "cast between incompatible function types" on some compilers, you can
 * silence this by adding an intermediary `void*` cast.)
 *
 * You can then call it like a normal function:
 *
 *   GDExtensionGodotVersion godot_version;
 *   get_godot_version(&godot_version);
 *   printf("Godot v%d.%d.%d\n", godot_version.major, godot_version.minor, godot_version.patch);
 *
 * All of these interface functions are described below, together with the name that's used to load it,
 * and the function pointer typedef that shows its signature.
 */
alias GDExtensionInitializationFunction = GDExtensionBool function(GDExtensionInterfaceGetProcAddress p_get_proc_address, GDExtensionClassLibraryPtr p_library, GDExtensionInitialization* r_initialization);

/* INTERFACE */

struct GDExtensionGodotVersion
{
    uint32_t major;
    uint32_t minor;
    uint32_t patch;
    const(char)* string_;
}

struct GDExtensionGodotVersion2
{
    uint32_t major;
    uint32_t minor;
    uint32_t patch;
    uint32_t hex;
    const(char)* status;
    const(char)* build;
    const(char)* hash;
    uint64_t timestamp;
    const(char)* string_;
}

/* Called when starting the main loop. */
alias GDExtensionMainLoopStartupCallback = void function();

/* Called when shutting down the main loop. */
alias GDExtensionMainLoopShutdownCallback = void function();

/* Called for every frame iteration of the main loop. */
alias GDExtensionMainLoopFrameCallback = void function();

struct GDExtensionMainLoopCallbacks
{
    GDExtensionMainLoopStartupCallback startup_func;
    GDExtensionMainLoopShutdownCallback shutdown_func;
    GDExtensionMainLoopFrameCallback frame_func;
}

/**
 * @name get_godot_version
 * @since 4.1
 * @deprecated in Godot 4.5. Use `get_godot_version2` instead.
 *
 * Gets the Godot version that the GDExtension was loaded into.
 *
 * @param r_godot_version A pointer to the structure to write the version information into.
 */
alias GDExtensionInterfaceGetGodotVersion = void function(GDExtensionGodotVersion* r_godot_version);

/**
 * @name get_godot_version2
 * @since 4.5
 *
 * Gets the Godot version that the GDExtension was loaded into.
 *
 * @param r_godot_version A pointer to the structure to write the version information into.
 */
alias GDExtensionInterfaceGetGodotVersion2 = void function(GDExtensionGodotVersion2* r_godot_version);

/* INTERFACE: Memory */

/**
 * @name mem_alloc
 * @since 4.1
 *
 * Allocates memory.
 *
 * @param p_bytes The amount of memory to allocate in bytes.
 *
 * @return A pointer to the allocated memory, or NULL if unsuccessful.
 */
alias GDExtensionInterfaceMemAlloc = void * function(size_t p_bytes);

/**
 * @name mem_realloc
 * @since 4.1
 *
 * Reallocates memory.
 *
 * @param p_ptr A pointer to the previously allocated memory.
 * @param p_bytes The number of bytes to resize the memory block to.
 *
 * @return A pointer to the allocated memory, or NULL if unsuccessful.
 */
alias GDExtensionInterfaceMemRealloc = void * function(void* p_ptr, size_t p_bytes);

/**
 * @name mem_free
 * @since 4.1
 *
 * Frees memory.
 *
 * @param p_ptr A pointer to the previously allocated memory.
 */
alias GDExtensionInterfaceMemFree = void function(void* p_ptr);

/* INTERFACE: Godot Core */

/**
 * @name print_error
 * @since 4.1
 *
 * Logs an error to Godot's built-in debugger and to the OS terminal.
 *
 * @param p_description The code triggering the error.
 * @param p_function The function name where the error occurred.
 * @param p_file The file where the error occurred.
 * @param p_line The line where the error occurred.
 * @param p_editor_notify Whether or not to notify the editor.
 */
alias GDExtensionInterfacePrintError = void function(const(char)* p_description, const(char)* p_function, const(char)* p_file, int32_t p_line, GDExtensionBool p_editor_notify);

/**
 * @name print_error_with_message
 * @since 4.1
 *
 * Logs an error with a message to Godot's built-in debugger and to the OS terminal.
 *
 * @param p_description The code triggering the error.
 * @param p_message The message to show along with the error.
 * @param p_function The function name where the error occurred.
 * @param p_file The file where the error occurred.
 * @param p_line The line where the error occurred.
 * @param p_editor_notify Whether or not to notify the editor.
 */
alias GDExtensionInterfacePrintErrorWithMessage = void function(const(char)* p_description, const(char)* p_message, const(char)* p_function, const(char)* p_file, int32_t p_line, GDExtensionBool p_editor_notify);

/**
 * @name print_warning
 * @since 4.1
 *
 * Logs a warning to Godot's built-in debugger and to the OS terminal.
 *
 * @param p_description The code triggering the warning.
 * @param p_function The function name where the warning occurred.
 * @param p_file The file where the warning occurred.
 * @param p_line The line where the warning occurred.
 * @param p_editor_notify Whether or not to notify the editor.
 */
alias GDExtensionInterfacePrintWarning = void function(const(char)* p_description, const(char)* p_function, const(char)* p_file, int32_t p_line, GDExtensionBool p_editor_notify);

/**
 * @name print_warning_with_message
 * @since 4.1
 *
 * Logs a warning with a message to Godot's built-in debugger and to the OS terminal.
 *
 * @param p_description The code triggering the warning.
 * @param p_message The message to show along with the warning.
 * @param p_function The function name where the warning occurred.
 * @param p_file The file where the warning occurred.
 * @param p_line The line where the warning occurred.
 * @param p_editor_notify Whether or not to notify the editor.
 */
alias GDExtensionInterfacePrintWarningWithMessage = void function(const(char)* p_description, const(char)* p_message, const(char)* p_function, const(char)* p_file, int32_t p_line, GDExtensionBool p_editor_notify);

/**
 * @name print_script_error
 * @since 4.1
 *
 * Logs a script error to Godot's built-in debugger and to the OS terminal.
 *
 * @param p_description The code triggering the error.
 * @param p_function The function name where the error occurred.
 * @param p_file The file where the error occurred.
 * @param p_line The line where the error occurred.
 * @param p_editor_notify Whether or not to notify the editor.
 */
alias GDExtensionInterfacePrintScriptError = void function(const(char)* p_description, const(char)* p_function, const(char)* p_file, int32_t p_line, GDExtensionBool p_editor_notify);

/**
 * @name print_script_error_with_message
 * @since 4.1
 *
 * Logs a script error with a message to Godot's built-in debugger and to the OS terminal.
 *
 * @param p_description The code triggering the error.
 * @param p_message The message to show along with the error.
 * @param p_function The function name where the error occurred.
 * @param p_file The file where the error occurred.
 * @param p_line The line where the error occurred.
 * @param p_editor_notify Whether or not to notify the editor.
 */
alias GDExtensionInterfacePrintScriptErrorWithMessage = void function(const(char)* p_description, const(char)* p_message, const(char)* p_function, const(char)* p_file, int32_t p_line, GDExtensionBool p_editor_notify);

/**
 * @name get_native_struct_size
 * @since 4.1
 *
 * Gets the size of a native struct (ex. ObjectID) in bytes.
 *
 * @param p_name A pointer to a StringName identifying the struct name.
 *
 * @return The size in bytes.
 */
alias GDExtensionInterfaceGetNativeStructSize = uint64_t function(GDExtensionConstStringNamePtr p_name);

/* INTERFACE: Variant */

/**
 * @name variant_new_copy
 * @since 4.1
 *
 * Copies one Variant into a another.
 *
 * @param r_dest A pointer to the destination Variant.
 * @param p_src A pointer to the source Variant.
 */
alias GDExtensionInterfaceVariantNewCopy = void function(GDExtensionUninitializedVariantPtr r_dest, GDExtensionConstVariantPtr p_src);

/**
 * @name variant_new_nil
 * @since 4.1
 *
 * Creates a new Variant containing nil.
 *
 * @param r_dest A pointer to the destination Variant.
 */
alias GDExtensionInterfaceVariantNewNil = void function(GDExtensionUninitializedVariantPtr r_dest);

/**
 * @name variant_destroy
 * @since 4.1
 *
 * Destroys a Variant.
 *
 * @param p_self A pointer to the Variant to destroy.
 */
alias GDExtensionInterfaceVariantDestroy = void function(GDExtensionVariantPtr p_self);

/**
 * @name variant_call
 * @since 4.1
 *
 * Calls a method on a Variant.
 *
 * @param p_self A pointer to the Variant.
 * @param p_method A pointer to a StringName identifying the method.
 * @param p_args A pointer to a C array of Variant.
 * @param p_argument_count The number of arguments.
 * @param r_return A pointer a Variant which will be assigned the return value.
 * @param r_error A pointer the structure which will hold error information.
 *
 * @see Variant::callp()
 */
alias GDExtensionInterfaceVariantCall = void function(GDExtensionVariantPtr p_self, GDExtensionConstStringNamePtr p_method, const(GDExtensionConstVariantPtr)* p_args, GDExtensionInt p_argument_count, GDExtensionUninitializedVariantPtr r_return, GDExtensionCallError* r_error);

/**
 * @name variant_call_static
 * @since 4.1
 *
 * Calls a static method on a Variant.
 *
 * @param p_type The variant type.
 * @param p_method A pointer to a StringName identifying the method.
 * @param p_args A pointer to a C array of Variant.
 * @param p_argument_count The number of arguments.
 * @param r_return A pointer a Variant which will be assigned the return value.
 * @param r_error A pointer the structure which will be updated with error information.
 *
 * @see Variant::call_static()
 */
alias GDExtensionInterfaceVariantCallStatic = void function(GDExtensionVariantType p_type, GDExtensionConstStringNamePtr p_method, const(GDExtensionConstVariantPtr)* p_args, GDExtensionInt p_argument_count, GDExtensionUninitializedVariantPtr r_return, GDExtensionCallError* r_error);

/**
 * @name variant_evaluate
 * @since 4.1
 *
 * Evaluate an operator on two Variants.
 *
 * @param p_op The operator to evaluate.
 * @param p_a The first Variant.
 * @param p_b The second Variant.
 * @param r_return A pointer a Variant which will be assigned the return value.
 * @param r_valid A pointer to a boolean which will be set to false if the operation is invalid.
 *
 * @see Variant::evaluate()
 */
alias GDExtensionInterfaceVariantEvaluate = void function(GDExtensionVariantOperator p_op, GDExtensionConstVariantPtr p_a, GDExtensionConstVariantPtr p_b, GDExtensionUninitializedVariantPtr r_return, GDExtensionBool* r_valid);

/**
 * @name variant_set
 * @since 4.1
 *
 * Sets a key on a Variant to a value.
 *
 * @param p_self A pointer to the Variant.
 * @param p_key A pointer to a Variant representing the key.
 * @param p_value A pointer to a Variant representing the value.
 * @param r_valid A pointer to a boolean which will be set to false if the operation is invalid.
 *
 * @see Variant::set()
 */
alias GDExtensionInterfaceVariantSet = void function(GDExtensionVariantPtr p_self, GDExtensionConstVariantPtr p_key, GDExtensionConstVariantPtr p_value, GDExtensionBool* r_valid);

/**
 * @name variant_set_named
 * @since 4.1
 *
 * Sets a named key on a Variant to a value.
 *
 * @param p_self A pointer to the Variant.
 * @param p_key A pointer to a StringName representing the key.
 * @param p_value A pointer to a Variant representing the value.
 * @param r_valid A pointer to a boolean which will be set to false if the operation is invalid.
 *
 * @see Variant::set_named()
 */
alias GDExtensionInterfaceVariantSetNamed = void function(GDExtensionVariantPtr p_self, GDExtensionConstStringNamePtr p_key, GDExtensionConstVariantPtr p_value, GDExtensionBool* r_valid);

/**
 * @name variant_set_keyed
 * @since 4.1
 *
 * Sets a keyed property on a Variant to a value.
 *
 * @param p_self A pointer to the Variant.
 * @param p_key A pointer to a Variant representing the key.
 * @param p_value A pointer to a Variant representing the value.
 * @param r_valid A pointer to a boolean which will be set to false if the operation is invalid.
 *
 * @see Variant::set_keyed()
 */
alias GDExtensionInterfaceVariantSetKeyed = void function(GDExtensionVariantPtr p_self, GDExtensionConstVariantPtr p_key, GDExtensionConstVariantPtr p_value, GDExtensionBool* r_valid);

/**
 * @name variant_set_indexed
 * @since 4.1
 *
 * Sets an index on a Variant to a value.
 *
 * @param p_self A pointer to the Variant.
 * @param p_index The index.
 * @param p_value A pointer to a Variant representing the value.
 * @param r_valid A pointer to a boolean which will be set to false if the operation is invalid.
 * @param r_oob A pointer to a boolean which will be set to true if the index is out of bounds.
 */
alias GDExtensionInterfaceVariantSetIndexed = void function(GDExtensionVariantPtr p_self, GDExtensionInt p_index, GDExtensionConstVariantPtr p_value, GDExtensionBool* r_valid, GDExtensionBool* r_oob);

/**
 * @name variant_get
 * @since 4.1
 *
 * Gets the value of a key from a Variant.
 *
 * @param p_self A pointer to the Variant.
 * @param p_key A pointer to a Variant representing the key.
 * @param r_ret A pointer to a Variant which will be assigned the value.
 * @param r_valid A pointer to a boolean which will be set to false if the operation is invalid.
 */
alias GDExtensionInterfaceVariantGet = void function(GDExtensionConstVariantPtr p_self, GDExtensionConstVariantPtr p_key, GDExtensionUninitializedVariantPtr r_ret, GDExtensionBool* r_valid);

/**
 * @name variant_get_named
 * @since 4.1
 *
 * Gets the value of a named key from a Variant.
 *
 * @param p_self A pointer to the Variant.
 * @param p_key A pointer to a StringName representing the key.
 * @param r_ret A pointer to a Variant which will be assigned the value.
 * @param r_valid A pointer to a boolean which will be set to false if the operation is invalid.
 */
alias GDExtensionInterfaceVariantGetNamed = void function(GDExtensionConstVariantPtr p_self, GDExtensionConstStringNamePtr p_key, GDExtensionUninitializedVariantPtr r_ret, GDExtensionBool* r_valid);

/**
 * @name variant_get_keyed
 * @since 4.1
 *
 * Gets the value of a keyed property from a Variant.
 *
 * @param p_self A pointer to the Variant.
 * @param p_key A pointer to a Variant representing the key.
 * @param r_ret A pointer to a Variant which will be assigned the value.
 * @param r_valid A pointer to a boolean which will be set to false if the operation is invalid.
 */
alias GDExtensionInterfaceVariantGetKeyed = void function(GDExtensionConstVariantPtr p_self, GDExtensionConstVariantPtr p_key, GDExtensionUninitializedVariantPtr r_ret, GDExtensionBool* r_valid);

/**
 * @name variant_get_indexed
 * @since 4.1
 *
 * Gets the value of an index from a Variant.
 *
 * @param p_self A pointer to the Variant.
 * @param p_index The index.
 * @param r_ret A pointer to a Variant which will be assigned the value.
 * @param r_valid A pointer to a boolean which will be set to false if the operation is invalid.
 * @param r_oob A pointer to a boolean which will be set to true if the index is out of bounds.
 */
alias GDExtensionInterfaceVariantGetIndexed = void function(GDExtensionConstVariantPtr p_self, GDExtensionInt p_index, GDExtensionUninitializedVariantPtr r_ret, GDExtensionBool* r_valid, GDExtensionBool* r_oob);

/**
 * @name variant_iter_init
 * @since 4.1
 *
 * Initializes an iterator over a Variant.
 *
 * @param p_self A pointer to the Variant.
 * @param r_iter A pointer to a Variant which will be assigned the iterator.
 * @param r_valid A pointer to a boolean which will be set to false if the operation is invalid.
 *
 * @return true if the operation is valid; otherwise false.
 *
 * @see Variant::iter_init()
 */
alias GDExtensionInterfaceVariantIterInit = GDExtensionBool function(GDExtensionConstVariantPtr p_self, GDExtensionUninitializedVariantPtr r_iter, GDExtensionBool* r_valid);

/**
 * @name variant_iter_next
 * @since 4.1
 *
 * Gets the next value for an iterator over a Variant.
 *
 * @param p_self A pointer to the Variant.
 * @param r_iter A pointer to a Variant which will be assigned the iterator.
 * @param r_valid A pointer to a boolean which will be set to false if the operation is invalid.
 *
 * @return true if the operation is valid; otherwise false.
 *
 * @see Variant::iter_next()
 */
alias GDExtensionInterfaceVariantIterNext = GDExtensionBool function(GDExtensionConstVariantPtr p_self, GDExtensionVariantPtr r_iter, GDExtensionBool* r_valid);

/**
 * @name variant_iter_get
 * @since 4.1
 *
 * Gets the next value for an iterator over a Variant.
 *
 * @param p_self A pointer to the Variant.
 * @param r_iter A pointer to a Variant which will be assigned the iterator.
 * @param r_ret A pointer to a Variant which will be assigned false if the operation is invalid.
 * @param r_valid A pointer to a boolean which will be set to false if the operation is invalid.
 *
 * @see Variant::iter_get()
 */
alias GDExtensionInterfaceVariantIterGet = void function(GDExtensionConstVariantPtr p_self, GDExtensionVariantPtr r_iter, GDExtensionUninitializedVariantPtr r_ret, GDExtensionBool* r_valid);

/**
 * @name variant_hash
 * @since 4.1
 *
 * Gets the hash of a Variant.
 *
 * @param p_self A pointer to the Variant.
 *
 * @return The hash value.
 *
 * @see Variant::hash()
 */
alias GDExtensionInterfaceVariantHash = GDExtensionInt function(GDExtensionConstVariantPtr p_self);

/**
 * @name variant_recursive_hash
 * @since 4.1
 *
 * Gets the recursive hash of a Variant.
 *
 * @param p_self A pointer to the Variant.
 * @param p_recursion_count The number of recursive loops so far.
 *
 * @return The hash value.
 *
 * @see Variant::recursive_hash()
 */
alias GDExtensionInterfaceVariantRecursiveHash = GDExtensionInt function(GDExtensionConstVariantPtr p_self, GDExtensionInt p_recursion_count);

/**
 * @name variant_hash_compare
 * @since 4.1
 *
 * Compares two Variants by their hash.
 *
 * @param p_self A pointer to the Variant.
 * @param p_other A pointer to the other Variant to compare it to.
 *
 * @return The hash value.
 *
 * @see Variant::hash_compare()
 */
alias GDExtensionInterfaceVariantHashCompare = GDExtensionBool function(GDExtensionConstVariantPtr p_self, GDExtensionConstVariantPtr p_other);

/**
 * @name variant_booleanize
 * @since 4.1
 *
 * Converts a Variant to a boolean.
 *
 * @param p_self A pointer to the Variant.
 *
 * @return The boolean value of the Variant.
 */
alias GDExtensionInterfaceVariantBooleanize = GDExtensionBool function(GDExtensionConstVariantPtr p_self);

/**
 * @name variant_duplicate
 * @since 4.1
 *
 * Duplicates a Variant.
 *
 * @param p_self A pointer to the Variant.
 * @param r_ret A pointer to a Variant to store the duplicated value.
 * @param p_deep Whether or not to duplicate deeply (when supported by the Variant type).
 */
alias GDExtensionInterfaceVariantDuplicate = void function(GDExtensionConstVariantPtr p_self, GDExtensionVariantPtr r_ret, GDExtensionBool p_deep);

/**
 * @name variant_stringify
 * @since 4.1
 *
 * Converts a Variant to a string.
 *
 * @param p_self A pointer to the Variant.
 * @param r_ret A pointer to a String to store the resulting value.
 */
alias GDExtensionInterfaceVariantStringify = void function(GDExtensionConstVariantPtr p_self, GDExtensionStringPtr r_ret);

/**
 * @name variant_get_type
 * @since 4.1
 *
 * Gets the type of a Variant.
 *
 * @param p_self A pointer to the Variant.
 *
 * @return The variant type.
 */
alias GDExtensionInterfaceVariantGetType = GDExtensionVariantType function(GDExtensionConstVariantPtr p_self);

/**
 * @name variant_has_method
 * @since 4.1
 *
 * Checks if a Variant has the given method.
 *
 * @param p_self A pointer to the Variant.
 * @param p_method A pointer to a StringName with the method name.
 *
 * @return true if the variant has the given method; otherwise false.
 */
alias GDExtensionInterfaceVariantHasMethod = GDExtensionBool function(GDExtensionConstVariantPtr p_self, GDExtensionConstStringNamePtr p_method);

/**
 * @name variant_has_member
 * @since 4.1
 *
 * Checks if a type of Variant has the given member.
 *
 * @param p_type The Variant type.
 * @param p_member A pointer to a StringName with the member name.
 *
 * @return true if the variant has the given method; otherwise false.
 */
alias GDExtensionInterfaceVariantHasMember = GDExtensionBool function(GDExtensionVariantType p_type, GDExtensionConstStringNamePtr p_member);

/**
 * @name variant_has_key
 * @since 4.1
 *
 * Checks if a Variant has a key.
 *
 * @param p_self A pointer to the Variant.
 * @param p_key A pointer to a Variant representing the key.
 * @param r_valid A pointer to a boolean which will be set to false if the key doesn't exist.
 *
 * @return true if the key exists; otherwise false.
 */
alias GDExtensionInterfaceVariantHasKey = GDExtensionBool function(GDExtensionConstVariantPtr p_self, GDExtensionConstVariantPtr p_key, GDExtensionBool* r_valid);

/**
 * @name variant_get_object_instance_id
 * @since 4.4
 *
 * Gets the object instance ID from a variant of type GDEXTENSION_VARIANT_TYPE_OBJECT.
 *
 * If the variant isn't of type GDEXTENSION_VARIANT_TYPE_OBJECT, then zero will be returned.
 * The instance ID will be returned even if the object is no longer valid - use `object_get_instance_by_id()` to check if the object is still valid.
 *
 * @param p_self A pointer to the Variant.
 *
 * @return The instance ID for the contained object.
 */
alias GDExtensionInterfaceVariantGetObjectInstanceId = GDObjectInstanceID function(GDExtensionConstVariantPtr p_self);

/**
 * @name variant_get_type_name
 * @since 4.1
 *
 * Gets the name of a Variant type.
 *
 * @param p_type The Variant type.
 * @param r_name A pointer to a String to store the Variant type name.
 */
alias GDExtensionInterfaceVariantGetTypeName = void function(GDExtensionVariantType p_type, GDExtensionUninitializedStringPtr r_name);

/**
 * @name variant_can_convert
 * @since 4.1
 *
 * Checks if Variants can be converted from one type to another.
 *
 * @param p_from The Variant type to convert from.
 * @param p_to The Variant type to convert to.
 *
 * @return true if the conversion is possible; otherwise false.
 */
alias GDExtensionInterfaceVariantCanConvert = GDExtensionBool function(GDExtensionVariantType p_from, GDExtensionVariantType p_to);

/**
 * @name variant_can_convert_strict
 * @since 4.1
 *
 * Checks if Variant can be converted from one type to another using stricter rules.
 *
 * @param p_from The Variant type to convert from.
 * @param p_to The Variant type to convert to.
 *
 * @return true if the conversion is possible; otherwise false.
 */
alias GDExtensionInterfaceVariantCanConvertStrict = GDExtensionBool function(GDExtensionVariantType p_from, GDExtensionVariantType p_to);

/**
 * @name get_variant_from_type_constructor
 * @since 4.1
 *
 * Gets a pointer to a function that can create a Variant of the given type from a raw value.
 *
 * @param p_type The Variant type.
 *
 * @return A pointer to a function that can create a Variant of the given type from a raw value.
 */
alias GDExtensionInterfaceGetVariantFromTypeConstructor = GDExtensionVariantFromTypeConstructorFunc function(GDExtensionVariantType p_type);

/**
 * @name get_variant_to_type_constructor
 * @since 4.1
 *
 * Gets a pointer to a function that can get the raw value from a Variant of the given type.
 *
 * @param p_type The Variant type.
 *
 * @return A pointer to a function that can get the raw value from a Variant of the given type.
 */
alias GDExtensionInterfaceGetVariantToTypeConstructor = GDExtensionTypeFromVariantConstructorFunc function(GDExtensionVariantType p_type);

/**
 * @name variant_get_ptr_internal_getter
 * @since 4.4
 *
 * Provides a function pointer for retrieving a pointer to a variant's internal value.
 * Access to a variant's internal value can be used to modify it in-place, or to retrieve its value without the overhead of variant conversion functions.
 * It is recommended to cache the getter for all variant types in a function table to avoid retrieval overhead upon use.
 *
 * @note Each function assumes the variant's type has already been determined and matches the function.
 * Invoking the function with a variant of a mismatched type has undefined behavior, and may lead to a segmentation fault.
 *
 * @param p_type The Variant type.
 *
 * @return A pointer to a type-specific function that returns a pointer to the internal value of a variant. Check the implementation of this function (gdextension_variant_get_ptr_internal_getter) for pointee type info of each variant type.
 */
alias GDExtensionInterfaceGetVariantGetInternalPtrFunc = GDExtensionVariantGetInternalPtrFunc function(GDExtensionVariantType p_type);

/**
 * @name variant_get_ptr_operator_evaluator
 * @since 4.1
 *
 * Gets a pointer to a function that can evaluate the given Variant operator on the given Variant types.
 *
 * @param p_operator The variant operator.
 * @param p_type_a The type of the first Variant.
 * @param p_type_b The type of the second Variant.
 *
 * @return A pointer to a function that can evaluate the given Variant operator on the given Variant types.
 */
alias GDExtensionInterfaceVariantGetPtrOperatorEvaluator = GDExtensionPtrOperatorEvaluator function(GDExtensionVariantOperator p_operator, GDExtensionVariantType p_type_a, GDExtensionVariantType p_type_b);

/**
 * @name variant_get_ptr_builtin_method
 * @since 4.1
 *
 * Gets a pointer to a function that can call a builtin method on a type of Variant.
 *
 * @param p_type The Variant type.
 * @param p_method A pointer to a StringName with the method name.
 * @param p_hash A hash representing the method signature.
 *
 * @return A pointer to a function that can call a builtin method on a type of Variant.
 */
alias GDExtensionInterfaceVariantGetPtrBuiltinMethod = GDExtensionPtrBuiltInMethod function(GDExtensionVariantType p_type, GDExtensionConstStringNamePtr p_method, GDExtensionInt p_hash);

/**
 * @name variant_get_ptr_constructor
 * @since 4.1
 *
 * Gets a pointer to a function that can call one of the constructors for a type of Variant.
 *
 * @param p_type The Variant type.
 * @param p_constructor The index of the constructor.
 *
 * @return A pointer to a function that can call one of the constructors for a type of Variant.
 */
alias GDExtensionInterfaceVariantGetPtrConstructor = GDExtensionPtrConstructor function(GDExtensionVariantType p_type, int32_t p_constructor);

/**
 * @name variant_get_ptr_destructor
 * @since 4.1
 *
 * Gets a pointer to a function than can call the destructor for a type of Variant.
 *
 * @param p_type The Variant type.
 *
 * @return A pointer to a function than can call the destructor for a type of Variant.
 */
alias GDExtensionInterfaceVariantGetPtrDestructor = GDExtensionPtrDestructor function(GDExtensionVariantType p_type);

/**
 * @name variant_construct
 * @since 4.1
 *
 * Constructs a Variant of the given type, using the first constructor that matches the given arguments.
 *
 * @param p_type The Variant type.
 * @param r_base A pointer to a Variant to store the constructed value.
 * @param p_args A pointer to a C array of Variant pointers representing the arguments for the constructor.
 * @param p_argument_count The number of arguments to pass to the constructor.
 * @param r_error A pointer the structure which will be updated with error information.
 */
alias GDExtensionInterfaceVariantConstruct = void function(GDExtensionVariantType p_type, GDExtensionUninitializedVariantPtr r_base, const(GDExtensionConstVariantPtr)* p_args, int32_t p_argument_count, GDExtensionCallError* r_error);

/**
 * @name variant_get_ptr_setter
 * @since 4.1
 *
 * Gets a pointer to a function that can call a member's setter on the given Variant type.
 *
 * @param p_type The Variant type.
 * @param p_member A pointer to a StringName with the member name.
 *
 * @return A pointer to a function that can call a member's setter on the given Variant type.
 */
alias GDExtensionInterfaceVariantGetPtrSetter = GDExtensionPtrSetter function(GDExtensionVariantType p_type, GDExtensionConstStringNamePtr p_member);

/**
 * @name variant_get_ptr_getter
 * @since 4.1
 *
 * Gets a pointer to a function that can call a member's getter on the given Variant type.
 *
 * @param p_type The Variant type.
 * @param p_member A pointer to a StringName with the member name.
 *
 * @return A pointer to a function that can call a member's getter on the given Variant type.
 */
alias GDExtensionInterfaceVariantGetPtrGetter = GDExtensionPtrGetter function(GDExtensionVariantType p_type, GDExtensionConstStringNamePtr p_member);

/**
 * @name variant_get_ptr_indexed_setter
 * @since 4.1
 *
 * Gets a pointer to a function that can set an index on the given Variant type.
 *
 * @param p_type The Variant type.
 *
 * @return A pointer to a function that can set an index on the given Variant type.
 */
alias GDExtensionInterfaceVariantGetPtrIndexedSetter = GDExtensionPtrIndexedSetter function(GDExtensionVariantType p_type);

/**
 * @name variant_get_ptr_indexed_getter
 * @since 4.1
 *
 * Gets a pointer to a function that can get an index on the given Variant type.
 *
 * @param p_type The Variant type.
 *
 * @return A pointer to a function that can get an index on the given Variant type.
 */
alias GDExtensionInterfaceVariantGetPtrIndexedGetter = GDExtensionPtrIndexedGetter function(GDExtensionVariantType p_type);

/**
 * @name variant_get_ptr_keyed_setter
 * @since 4.1
 *
 * Gets a pointer to a function that can set a key on the given Variant type.
 *
 * @param p_type The Variant type.
 *
 * @return A pointer to a function that can set a key on the given Variant type.
 */
alias GDExtensionInterfaceVariantGetPtrKeyedSetter = GDExtensionPtrKeyedSetter function(GDExtensionVariantType p_type);

/**
 * @name variant_get_ptr_keyed_getter
 * @since 4.1
 *
 * Gets a pointer to a function that can get a key on the given Variant type.
 *
 * @param p_type The Variant type.
 *
 * @return A pointer to a function that can get a key on the given Variant type.
 */
alias GDExtensionInterfaceVariantGetPtrKeyedGetter = GDExtensionPtrKeyedGetter function(GDExtensionVariantType p_type);

/**
 * @name variant_get_ptr_keyed_checker
 * @since 4.1
 *
 * Gets a pointer to a function that can check a key on the given Variant type.
 *
 * @param p_type The Variant type.
 *
 * @return A pointer to a function that can check a key on the given Variant type.
 */
alias GDExtensionInterfaceVariantGetPtrKeyedChecker = GDExtensionPtrKeyedChecker function(GDExtensionVariantType p_type);

/**
 * @name variant_get_constant_value
 * @since 4.1
 *
 * Gets the value of a constant from the given Variant type.
 *
 * @param p_type The Variant type.
 * @param p_constant A pointer to a StringName with the constant name.
 * @param r_ret A pointer to a Variant to store the value.
 */
alias GDExtensionInterfaceVariantGetConstantValue = void function(GDExtensionVariantType p_type, GDExtensionConstStringNamePtr p_constant, GDExtensionUninitializedVariantPtr r_ret);

/**
 * @name variant_get_ptr_utility_function
 * @since 4.1
 *
 * Gets a pointer to a function that can call a Variant utility function.
 *
 * @param p_function A pointer to a StringName with the function name.
 * @param p_hash A hash representing the function signature.
 *
 * @return A pointer to a function that can call a Variant utility function.
 */
alias GDExtensionInterfaceVariantGetPtrUtilityFunction = GDExtensionPtrUtilityFunction function(GDExtensionConstStringNamePtr p_function, GDExtensionInt p_hash);

/* INTERFACE: String Utilities */

/**
 * @name string_new_with_latin1_chars
 * @since 4.1
 *
 * Creates a String from a Latin-1 encoded C string.
 *
 * @param r_dest A pointer to a Variant to hold the newly created String.
 * @param p_contents A pointer to a Latin-1 encoded C string (null terminated).
 */
alias GDExtensionInterfaceStringNewWithLatin1Chars = void function(GDExtensionUninitializedStringPtr r_dest, const(char)* p_contents);

/**
 * @name string_new_with_utf8_chars
 * @since 4.1
 *
 * Creates a String from a UTF-8 encoded C string.
 *
 * @param r_dest A pointer to a Variant to hold the newly created String.
 * @param p_contents A pointer to a UTF-8 encoded C string (null terminated).
 */
alias GDExtensionInterfaceStringNewWithUtf8Chars = void function(GDExtensionUninitializedStringPtr r_dest, const(char)* p_contents);

/**
 * @name string_new_with_utf16_chars
 * @since 4.1
 *
 * Creates a String from a UTF-16 encoded C string.
 *
 * @param r_dest A pointer to a Variant to hold the newly created String.
 * @param p_contents A pointer to a UTF-16 encoded C string (null terminated).
 */
alias GDExtensionInterfaceStringNewWithUtf16Chars = void function(GDExtensionUninitializedStringPtr r_dest, const(char16_t)* p_contents);

/**
 * @name string_new_with_utf32_chars
 * @since 4.1
 *
 * Creates a String from a UTF-32 encoded C string.
 *
 * @param r_dest A pointer to a Variant to hold the newly created String.
 * @param p_contents A pointer to a UTF-32 encoded C string (null terminated).
 */
alias GDExtensionInterfaceStringNewWithUtf32Chars = void function(GDExtensionUninitializedStringPtr r_dest, const(char32_t)* p_contents);

/**
 * @name string_new_with_wide_chars
 * @since 4.1
 *
 * Creates a String from a wide C string.
 *
 * @param r_dest A pointer to a Variant to hold the newly created String.
 * @param p_contents A pointer to a wide C string (null terminated).
 */
alias GDExtensionInterfaceStringNewWithWideChars = void function(GDExtensionUninitializedStringPtr r_dest, const(wchar_t)* p_contents);

/**
 * @name string_new_with_latin1_chars_and_len
 * @since 4.1
 *
 * Creates a String from a Latin-1 encoded C string with the given length.
 *
 * @param r_dest A pointer to a Variant to hold the newly created String.
 * @param p_contents A pointer to a Latin-1 encoded C string.
 * @param p_size The number of characters (= number of bytes).
 */
alias GDExtensionInterfaceStringNewWithLatin1CharsAndLen = void function(GDExtensionUninitializedStringPtr r_dest, const(char)* p_contents, GDExtensionInt p_size);

/**
 * @name string_new_with_utf8_chars_and_len
 * @since 4.1
 * @deprecated in Godot 4.3. Use `string_new_with_utf8_chars_and_len2` instead.
 *
 * Creates a String from a UTF-8 encoded C string with the given length.
 *
 * @param r_dest A pointer to a Variant to hold the newly created String.
 * @param p_contents A pointer to a UTF-8 encoded C string.
 * @param p_size The number of bytes (not code units).
 */
alias GDExtensionInterfaceStringNewWithUtf8CharsAndLen = void function(GDExtensionUninitializedStringPtr r_dest, const(char)* p_contents, GDExtensionInt p_size);

/**
 * @name string_new_with_utf8_chars_and_len2
 * @since 4.3
 *
 * Creates a String from a UTF-8 encoded C string with the given length.
 *
 * @param r_dest A pointer to a Variant to hold the newly created String.
 * @param p_contents A pointer to a UTF-8 encoded C string.
 * @param p_size The number of bytes (not code units).
 *
 * @return Error code signifying if the operation successful.
 */
alias GDExtensionInterfaceStringNewWithUtf8CharsAndLen2 = GDExtensionInt function(GDExtensionUninitializedStringPtr r_dest, const(char)* p_contents, GDExtensionInt p_size);

/**
 * @name string_new_with_utf16_chars_and_len
 * @since 4.1
 * @deprecated in Godot 4.3. Use `string_new_with_utf16_chars_and_len2` instead.
 *
 * Creates a String from a UTF-16 encoded C string with the given length.
 *
 * @param r_dest A pointer to a Variant to hold the newly created String.
 * @param p_contents A pointer to a UTF-16 encoded C string.
 * @param p_char_count The number of characters (not bytes).
 */
alias GDExtensionInterfaceStringNewWithUtf16CharsAndLen = void function(GDExtensionUninitializedStringPtr r_dest, const(char16_t)* p_contents, GDExtensionInt p_char_count);

/**
 * @name string_new_with_utf16_chars_and_len2
 * @since 4.3
 *
 * Creates a String from a UTF-16 encoded C string with the given length.
 *
 * @param r_dest A pointer to a Variant to hold the newly created String.
 * @param p_contents A pointer to a UTF-16 encoded C string.
 * @param p_char_count The number of characters (not bytes).
 * @param p_default_little_endian If true, UTF-16 use little endian.
 *
 * @return Error code signifying if the operation successful.
 */
alias GDExtensionInterfaceStringNewWithUtf16CharsAndLen2 = GDExtensionInt function(GDExtensionUninitializedStringPtr r_dest, const(char16_t)* p_contents, GDExtensionInt p_char_count, GDExtensionBool p_default_little_endian);

/**
 * @name string_new_with_utf32_chars_and_len
 * @since 4.1
 *
 * Creates a String from a UTF-32 encoded C string with the given length.
 *
 * @param r_dest A pointer to a Variant to hold the newly created String.
 * @param p_contents A pointer to a UTF-32 encoded C string.
 * @param p_char_count The number of characters (not bytes).
 */
alias GDExtensionInterfaceStringNewWithUtf32CharsAndLen = void function(GDExtensionUninitializedStringPtr r_dest, const(char32_t)* p_contents, GDExtensionInt p_char_count);

/**
 * @name string_new_with_wide_chars_and_len
 * @since 4.1
 *
 * Creates a String from a wide C string with the given length.
 *
 * @param r_dest A pointer to a Variant to hold the newly created String.
 * @param p_contents A pointer to a wide C string.
 * @param p_char_count The number of characters (not bytes).
 */
alias GDExtensionInterfaceStringNewWithWideCharsAndLen = void function(GDExtensionUninitializedStringPtr r_dest, const(wchar_t)* p_contents, GDExtensionInt p_char_count);

/**
 * @name string_to_latin1_chars
 * @since 4.1
 *
 * Converts a String to a Latin-1 encoded C string.
 *
 * It doesn't write a null terminator.
 *
 * @param p_self A pointer to the String.
 * @param r_text A pointer to the buffer to hold the resulting data. If NULL is passed in, only the length will be computed.
 * @param p_max_write_length The maximum number of characters that can be written to r_text. It has no affect on the return value.
 *
 * @return The resulting encoded string length in characters (not bytes), not including a null terminator.
 */
alias GDExtensionInterfaceStringToLatin1Chars = GDExtensionInt function(GDExtensionConstStringPtr p_self, char* r_text, GDExtensionInt p_max_write_length);

/**
 * @name string_to_utf8_chars
 * @since 4.1
 *
 * Converts a String to a UTF-8 encoded C string.
 *
 * It doesn't write a null terminator.
 *
 * @param p_self A pointer to the String.
 * @param r_text A pointer to the buffer to hold the resulting data. If NULL is passed in, only the length will be computed.
 * @param p_max_write_length The maximum number of characters that can be written to r_text. It has no affect on the return value.
 *
 * @return The resulting encoded string length in characters (not bytes), not including a null terminator.
 */
alias GDExtensionInterfaceStringToUtf8Chars = GDExtensionInt function(GDExtensionConstStringPtr p_self, char* r_text, GDExtensionInt p_max_write_length);

/**
 * @name string_to_utf16_chars
 * @since 4.1
 *
 * Converts a String to a UTF-16 encoded C string.
 *
 * It doesn't write a null terminator.
 *
 * @param p_self A pointer to the String.
 * @param r_text A pointer to the buffer to hold the resulting data. If NULL is passed in, only the length will be computed.
 * @param p_max_write_length The maximum number of characters that can be written to r_text. It has no affect on the return value.
 *
 * @return The resulting encoded string length in characters (not bytes), not including a null terminator.
 */
alias GDExtensionInterfaceStringToUtf16Chars = GDExtensionInt function(GDExtensionConstStringPtr p_self, char16_t* r_text, GDExtensionInt p_max_write_length);

/**
 * @name string_to_utf32_chars
 * @since 4.1
 *
 * Converts a String to a UTF-32 encoded C string.
 *
 * It doesn't write a null terminator.
 *
 * @param p_self A pointer to the String.
 * @param r_text A pointer to the buffer to hold the resulting data. If NULL is passed in, only the length will be computed.
 * @param p_max_write_length The maximum number of characters that can be written to r_text. It has no affect on the return value.
 *
 * @return The resulting encoded string length in characters (not bytes), not including a null terminator.
 */
alias GDExtensionInterfaceStringToUtf32Chars = GDExtensionInt function(GDExtensionConstStringPtr p_self, char32_t* r_text, GDExtensionInt p_max_write_length);

/**
 * @name string_to_wide_chars
 * @since 4.1
 *
 * Converts a String to a wide C string.
 *
 * It doesn't write a null terminator.
 *
 * @param p_self A pointer to the String.
 * @param r_text A pointer to the buffer to hold the resulting data. If NULL is passed in, only the length will be computed.
 * @param p_max_write_length The maximum number of characters that can be written to r_text. It has no affect on the return value.
 *
 * @return The resulting encoded string length in characters (not bytes), not including a null terminator.
 */
alias GDExtensionInterfaceStringToWideChars = GDExtensionInt function(GDExtensionConstStringPtr p_self, wchar_t* r_text, GDExtensionInt p_max_write_length);

/**
 * @name string_operator_index
 * @since 4.1
 *
 * Gets a pointer to the character at the given index from a String.
 *
 * @param p_self A pointer to the String.
 * @param p_index The index.
 *
 * @return A pointer to the requested character.
 */
alias GDExtensionInterfaceStringOperatorIndex = char32_t * function(GDExtensionStringPtr p_self, GDExtensionInt p_index);

/**
 * @name string_operator_index_const
 * @since 4.1
 *
 * Gets a const pointer to the character at the given index from a String.
 *
 * @param p_self A pointer to the String.
 * @param p_index The index.
 *
 * @return A const pointer to the requested character.
 */
alias GDExtensionInterfaceStringOperatorIndexConst = const(char32_t) * function(GDExtensionConstStringPtr p_self, GDExtensionInt p_index);

/**
 * @name string_operator_plus_eq_string
 * @since 4.1
 *
 * Appends another String to a String.
 *
 * @param p_self A pointer to the String.
 * @param p_b A pointer to the other String to append.
 */
alias GDExtensionInterfaceStringOperatorPlusEqString = void function(GDExtensionStringPtr p_self, GDExtensionConstStringPtr p_b);

/**
 * @name string_operator_plus_eq_char
 * @since 4.1
 *
 * Appends a character to a String.
 *
 * @param p_self A pointer to the String.
 * @param p_b A pointer to the character to append.
 */
alias GDExtensionInterfaceStringOperatorPlusEqChar = void function(GDExtensionStringPtr p_self, char32_t p_b);

/**
 * @name string_operator_plus_eq_cstr
 * @since 4.1
 *
 * Appends a Latin-1 encoded C string to a String.
 *
 * @param p_self A pointer to the String.
 * @param p_b A pointer to a Latin-1 encoded C string (null terminated).
 */
alias GDExtensionInterfaceStringOperatorPlusEqCstr = void function(GDExtensionStringPtr p_self, const(char)* p_b);

/**
 * @name string_operator_plus_eq_wcstr
 * @since 4.1
 *
 * Appends a wide C string to a String.
 *
 * @param p_self A pointer to the String.
 * @param p_b A pointer to a wide C string (null terminated).
 */
alias GDExtensionInterfaceStringOperatorPlusEqWcstr = void function(GDExtensionStringPtr p_self, const(wchar_t)* p_b);

/**
 * @name string_operator_plus_eq_c32str
 * @since 4.1
 *
 * Appends a UTF-32 encoded C string to a String.
 *
 * @param p_self A pointer to the String.
 * @param p_b A pointer to a UTF-32 encoded C string (null terminated).
 */
alias GDExtensionInterfaceStringOperatorPlusEqC32str = void function(GDExtensionStringPtr p_self, const(char32_t)* p_b);

/**
 * @name string_resize
 * @since 4.2
 *
 * Resizes the underlying string data to the given number of characters.
 *
 * Space needs to be allocated for the null terminating character ('\0') which
 * also must be added manually, in order for all string functions to work correctly.
 *
 * Warning: This is an error-prone operation - only use it if there's no other
 * efficient way to accomplish your goal.
 *
 * @param p_self A pointer to the String.
 * @param p_resize The new length for the String.
 *
 * @return Error code signifying if the operation successful.
 */
alias GDExtensionInterfaceStringResize = GDExtensionInt function(GDExtensionStringPtr p_self, GDExtensionInt p_resize);

/* INTERFACE: StringName Utilities */

/**
 * @name string_name_new_with_latin1_chars
 * @since 4.2
 *
 * Creates a StringName from a Latin-1 encoded C string.
 *
 * If `p_is_static` is true, then:
 * - The StringName will reuse the `p_contents` buffer instead of copying it.
 *   You must guarantee that the buffer remains valid for the duration of the application (e.g. string literal).
 * - You must not call a destructor for this StringName. Incrementing the initial reference once should achieve this.
 *
 * `p_is_static` is purely an optimization and can easily introduce undefined behavior if used wrong. In case of doubt, set it to false.
 *
 * @param r_dest A pointer to uninitialized storage, into which the newly created StringName is constructed.
 * @param p_contents A pointer to a C string (null terminated and Latin-1 or ASCII encoded).
 * @param p_is_static Whether the StringName reuses the buffer directly (see above).
 */
alias GDExtensionInterfaceStringNameNewWithLatin1Chars = void function(GDExtensionUninitializedStringNamePtr r_dest, const(char)* p_contents, GDExtensionBool p_is_static);

/**
 * @name string_name_new_with_utf8_chars
 * @since 4.2
 *
 * Creates a StringName from a UTF-8 encoded C string.
 *
 * @param r_dest A pointer to uninitialized storage, into which the newly created StringName is constructed.
 * @param p_contents A pointer to a C string (null terminated and UTF-8 encoded).
 */
alias GDExtensionInterfaceStringNameNewWithUtf8Chars = void function(GDExtensionUninitializedStringNamePtr r_dest, const(char)* p_contents);

/**
 * @name string_name_new_with_utf8_chars_and_len
 * @since 4.2
 *
 * Creates a StringName from a UTF-8 encoded string with a given number of characters.
 *
 * @param r_dest A pointer to uninitialized storage, into which the newly created StringName is constructed.
 * @param p_contents A pointer to a C string (null terminated and UTF-8 encoded).
 * @param p_size The number of bytes (not UTF-8 code points).
 */
alias GDExtensionInterfaceStringNameNewWithUtf8CharsAndLen = void function(GDExtensionUninitializedStringNamePtr r_dest, const(char)* p_contents, GDExtensionInt p_size);

/* INTERFACE: XMLParser Utilities */

/**
 * @name xml_parser_open_buffer
 * @since 4.1
 *
 * Opens a raw XML buffer on an XMLParser instance.
 *
 * @param p_instance A pointer to an XMLParser object.
 * @param p_buffer A pointer to the buffer.
 * @param p_size The size of the buffer.
 *
 * @return A Godot error code (ex. OK, ERR_INVALID_DATA, etc).
 *
 * @see XMLParser::open_buffer()
 */
alias GDExtensionInterfaceXmlParserOpenBuffer = GDExtensionInt function(GDExtensionObjectPtr p_instance, const(uint8_t)* p_buffer, size_t p_size);

/* INTERFACE: FileAccess Utilities */

/**
 * @name file_access_store_buffer
 * @since 4.1
 *
 * Stores the given buffer using an instance of FileAccess.
 *
 * @param p_instance A pointer to a FileAccess object.
 * @param p_src A pointer to the buffer.
 * @param p_length The size of the buffer.
 *
 * @see FileAccess::store_buffer()
 */
alias GDExtensionInterfaceFileAccessStoreBuffer = void function(GDExtensionObjectPtr p_instance, const(uint8_t)* p_src, uint64_t p_length);

/**
 * @name file_access_get_buffer
 * @since 4.1
 *
 * Reads the next p_length bytes into the given buffer using an instance of FileAccess.
 *
 * @param p_instance A pointer to a FileAccess object.
 * @param p_dst A pointer to the buffer to store the data.
 * @param p_length The requested number of bytes to read.
 *
 * @return The actual number of bytes read (may be less than requested).
 */
alias GDExtensionInterfaceFileAccessGetBuffer = uint64_t function(GDExtensionConstObjectPtr p_instance, uint8_t* p_dst, uint64_t p_length);

/* INTERFACE: Image Utilities */

/**
 * @name image_ptrw
 * @since 4.3
 *
 * Returns writable pointer to internal Image buffer.
 *
 * @param p_instance A pointer to a Image object.
 *
 * @return Pointer to internal Image buffer.
 *
 * @see Image::ptrw()
 */
alias GDExtensionInterfaceImagePtrw = uint8_t * function(GDExtensionObjectPtr p_instance);

/**
 * @name image_ptr
 * @since 4.3
 *
 * Returns read only pointer to internal Image buffer.
 *
 * @param p_instance A pointer to a Image object.
 *
 * @return Pointer to internal Image buffer.
 *
 * @see Image::ptr()
 */
alias GDExtensionInterfaceImagePtr = const(uint8_t) * function(GDExtensionObjectPtr p_instance);

/* INTERFACE: WorkerThreadPool Utilities */

/**
 * @name worker_thread_pool_add_native_group_task
 * @since 4.1
 *
 * Adds a group task to an instance of WorkerThreadPool.
 *
 * @param p_instance A pointer to a WorkerThreadPool object.
 * @param p_func A pointer to a function to run in the thread pool.
 * @param p_userdata A pointer to arbitrary data which will be passed to p_func.
 * @param p_elements The number of element needed in the group.
 * @param p_tasks The number of tasks needed in the group.
 * @param p_high_priority Whether or not this is a high priority task.
 * @param p_description A pointer to a String with the task description.
 *
 * @return The task group ID.
 *
 * @see WorkerThreadPool::add_group_task()
 */
alias GDExtensionInterfaceWorkerThreadPoolAddNativeGroupTask = int64_t function(GDExtensionObjectPtr p_instance, GDExtensionWorkerThreadPoolGroupTask p_func, void* p_userdata, int p_elements, int p_tasks, GDExtensionBool p_high_priority, GDExtensionConstStringPtr p_description);

/**
 * @name worker_thread_pool_add_native_task
 * @since 4.1
 *
 * Adds a task to an instance of WorkerThreadPool.
 *
 * @param p_instance A pointer to a WorkerThreadPool object.
 * @param p_func A pointer to a function to run in the thread pool.
 * @param p_userdata A pointer to arbitrary data which will be passed to p_func.
 * @param p_high_priority Whether or not this is a high priority task.
 * @param p_description A pointer to a String with the task description.
 *
 * @return The task ID.
 */
alias GDExtensionInterfaceWorkerThreadPoolAddNativeTask = int64_t function(GDExtensionObjectPtr p_instance, GDExtensionWorkerThreadPoolTask p_func, void* p_userdata, GDExtensionBool p_high_priority, GDExtensionConstStringPtr p_description);

/* INTERFACE: Packed Array */

/**
 * @name packed_byte_array_operator_index
 * @since 4.1
 *
 * Gets a pointer to a byte in a PackedByteArray.
 *
 * @param p_self A pointer to a PackedByteArray object.
 * @param p_index The index of the byte to get.
 *
 * @return A pointer to the requested byte.
 */
alias GDExtensionInterfacePackedByteArrayOperatorIndex = uint8_t * function(GDExtensionTypePtr p_self, GDExtensionInt p_index);

/**
 * @name packed_byte_array_operator_index_const
 * @since 4.1
 *
 * Gets a const pointer to a byte in a PackedByteArray.
 *
 * @param p_self A const pointer to a PackedByteArray object.
 * @param p_index The index of the byte to get.
 *
 * @return A const pointer to the requested byte.
 */
alias GDExtensionInterfacePackedByteArrayOperatorIndexConst = const(uint8_t) * function(GDExtensionConstTypePtr p_self, GDExtensionInt p_index);

/**
 * @name packed_float32_array_operator_index
 * @since 4.1
 *
 * Gets a pointer to a 32-bit float in a PackedFloat32Array.
 *
 * @param p_self A pointer to a PackedFloat32Array object.
 * @param p_index The index of the float to get.
 *
 * @return A pointer to the requested 32-bit float.
 */
alias GDExtensionInterfacePackedFloat32ArrayOperatorIndex = float * function(GDExtensionTypePtr p_self, GDExtensionInt p_index);

/**
 * @name packed_float32_array_operator_index_const
 * @since 4.1
 *
 * Gets a const pointer to a 32-bit float in a PackedFloat32Array.
 *
 * @param p_self A const pointer to a PackedFloat32Array object.
 * @param p_index The index of the float to get.
 *
 * @return A const pointer to the requested 32-bit float.
 */
alias GDExtensionInterfacePackedFloat32ArrayOperatorIndexConst = const(float) * function(GDExtensionConstTypePtr p_self, GDExtensionInt p_index);

/**
 * @name packed_float64_array_operator_index
 * @since 4.1
 *
 * Gets a pointer to a 64-bit float in a PackedFloat64Array.
 *
 * @param p_self A pointer to a PackedFloat64Array object.
 * @param p_index The index of the float to get.
 *
 * @return A pointer to the requested 64-bit float.
 */
alias GDExtensionInterfacePackedFloat64ArrayOperatorIndex = double * function(GDExtensionTypePtr p_self, GDExtensionInt p_index);

/**
 * @name packed_float64_array_operator_index_const
 * @since 4.1
 *
 * Gets a const pointer to a 64-bit float in a PackedFloat64Array.
 *
 * @param p_self A const pointer to a PackedFloat64Array object.
 * @param p_index The index of the float to get.
 *
 * @return A const pointer to the requested 64-bit float.
 */
alias GDExtensionInterfacePackedFloat64ArrayOperatorIndexConst = const(double) * function(GDExtensionConstTypePtr p_self, GDExtensionInt p_index);

/**
 * @name packed_int32_array_operator_index
 * @since 4.1
 *
 * Gets a pointer to a 32-bit integer in a PackedInt32Array.
 *
 * @param p_self A pointer to a PackedInt32Array object.
 * @param p_index The index of the integer to get.
 *
 * @return A pointer to the requested 32-bit integer.
 */
alias GDExtensionInterfacePackedInt32ArrayOperatorIndex = int32_t * function(GDExtensionTypePtr p_self, GDExtensionInt p_index);

/**
 * @name packed_int32_array_operator_index_const
 * @since 4.1
 *
 * Gets a const pointer to a 32-bit integer in a PackedInt32Array.
 *
 * @param p_self A const pointer to a PackedInt32Array object.
 * @param p_index The index of the integer to get.
 *
 * @return A const pointer to the requested 32-bit integer.
 */
alias GDExtensionInterfacePackedInt32ArrayOperatorIndexConst = const(int32_t) * function(GDExtensionConstTypePtr p_self, GDExtensionInt p_index);

/**
 * @name packed_int64_array_operator_index
 * @since 4.1
 *
 * Gets a pointer to a 64-bit integer in a PackedInt64Array.
 *
 * @param p_self A pointer to a PackedInt64Array object.
 * @param p_index The index of the integer to get.
 *
 * @return A pointer to the requested 64-bit integer.
 */
alias GDExtensionInterfacePackedInt64ArrayOperatorIndex = int64_t * function(GDExtensionTypePtr p_self, GDExtensionInt p_index);

/**
 * @name packed_int64_array_operator_index_const
 * @since 4.1
 *
 * Gets a const pointer to a 64-bit integer in a PackedInt64Array.
 *
 * @param p_self A const pointer to a PackedInt64Array object.
 * @param p_index The index of the integer to get.
 *
 * @return A const pointer to the requested 64-bit integer.
 */
alias GDExtensionInterfacePackedInt64ArrayOperatorIndexConst = const(int64_t) * function(GDExtensionConstTypePtr p_self, GDExtensionInt p_index);

/**
 * @name packed_string_array_operator_index
 * @since 4.1
 *
 * Gets a pointer to a string in a PackedStringArray.
 *
 * @param p_self A pointer to a PackedStringArray object.
 * @param p_index The index of the String to get.
 *
 * @return A pointer to the requested String.
 */
alias GDExtensionInterfacePackedStringArrayOperatorIndex = GDExtensionStringPtr function(GDExtensionTypePtr p_self, GDExtensionInt p_index);

/**
 * @name packed_string_array_operator_index_const
 * @since 4.1
 *
 * Gets a const pointer to a string in a PackedStringArray.
 *
 * @param p_self A const pointer to a PackedStringArray object.
 * @param p_index The index of the String to get.
 *
 * @return A const pointer to the requested String.
 */
alias GDExtensionInterfacePackedStringArrayOperatorIndexConst = GDExtensionStringPtr function(GDExtensionConstTypePtr p_self, GDExtensionInt p_index);

/**
 * @name packed_vector2_array_operator_index
 * @since 4.1
 *
 * Gets a pointer to a Vector2 in a PackedVector2Array.
 *
 * @param p_self A pointer to a PackedVector2Array object.
 * @param p_index The index of the Vector2 to get.
 *
 * @return A pointer to the requested Vector2.
 */
alias GDExtensionInterfacePackedVector2ArrayOperatorIndex = GDExtensionTypePtr function(GDExtensionTypePtr p_self, GDExtensionInt p_index);

/**
 * @name packed_vector2_array_operator_index_const
 * @since 4.1
 *
 * Gets a const pointer to a Vector2 in a PackedVector2Array.
 *
 * @param p_self A const pointer to a PackedVector2Array object.
 * @param p_index The index of the Vector2 to get.
 *
 * @return A const pointer to the requested Vector2.
 */
alias GDExtensionInterfacePackedVector2ArrayOperatorIndexConst = GDExtensionTypePtr function(GDExtensionConstTypePtr p_self, GDExtensionInt p_index);

/**
 * @name packed_vector3_array_operator_index
 * @since 4.1
 *
 * Gets a pointer to a Vector3 in a PackedVector3Array.
 *
 * @param p_self A pointer to a PackedVector3Array object.
 * @param p_index The index of the Vector3 to get.
 *
 * @return A pointer to the requested Vector3.
 */
alias GDExtensionInterfacePackedVector3ArrayOperatorIndex = GDExtensionTypePtr function(GDExtensionTypePtr p_self, GDExtensionInt p_index);

/**
 * @name packed_vector3_array_operator_index_const
 * @since 4.1
 *
 * Gets a const pointer to a Vector3 in a PackedVector3Array.
 *
 * @param p_self A const pointer to a PackedVector3Array object.
 * @param p_index The index of the Vector3 to get.
 *
 * @return A const pointer to the requested Vector3.
 */
alias GDExtensionInterfacePackedVector3ArrayOperatorIndexConst = GDExtensionTypePtr function(GDExtensionConstTypePtr p_self, GDExtensionInt p_index);


/**
 * @name packed_vector4_array_operator_index
 * @since 4.3
 *
 * Gets a pointer to a Vector4 in a PackedVector4Array.
 *
 * @param p_self A pointer to a PackedVector4Array object.
 * @param p_index The index of the Vector4 to get.
 *
 * @return A pointer to the requested Vector4.
 */
alias GDExtensionInterfacePackedVector4ArrayOperatorIndex = GDExtensionTypePtr function(GDExtensionTypePtr p_self, GDExtensionInt p_index);

/**
 * @name packed_vector4_array_operator_index_const
 * @since 4.3
 *
 * Gets a const pointer to a Vector4 in a PackedVector4Array.
 *
 * @param p_self A const pointer to a PackedVector4Array object.
 * @param p_index The index of the Vector4 to get.
 *
 * @return A const pointer to the requested Vector4.
 */
alias GDExtensionInterfacePackedVector4ArrayOperatorIndexConst = GDExtensionTypePtr function(GDExtensionConstTypePtr p_self, GDExtensionInt p_index);

/**
 * @name packed_color_array_operator_index
 * @since 4.1
 *
 * Gets a pointer to a color in a PackedColorArray.
 *
 * @param p_self A pointer to a PackedColorArray object.
 * @param p_index The index of the Color to get.
 *
 * @return A pointer to the requested Color.
 */
alias GDExtensionInterfacePackedColorArrayOperatorIndex = GDExtensionTypePtr function(GDExtensionTypePtr p_self, GDExtensionInt p_index);

/**
 * @name packed_color_array_operator_index_const
 * @since 4.1
 *
 * Gets a const pointer to a color in a PackedColorArray.
 *
 * @param p_self A const pointer to a PackedColorArray object.
 * @param p_index The index of the Color to get.
 *
 * @return A const pointer to the requested Color.
 */
alias GDExtensionInterfacePackedColorArrayOperatorIndexConst = GDExtensionTypePtr function(GDExtensionConstTypePtr p_self, GDExtensionInt p_index);

/**
 * @name array_operator_index
 * @since 4.1
 *
 * Gets a pointer to a Variant in an Array.
 *
 * @param p_self A pointer to an Array object.
 * @param p_index The index of the Variant to get.
 *
 * @return A pointer to the requested Variant.
 */
alias GDExtensionInterfaceArrayOperatorIndex = GDExtensionVariantPtr function(GDExtensionTypePtr p_self, GDExtensionInt p_index);

/**
 * @name array_operator_index_const
 * @since 4.1
 *
 * Gets a const pointer to a Variant in an Array.
 *
 * @param p_self A const pointer to an Array object.
 * @param p_index The index of the Variant to get.
 *
 * @return A const pointer to the requested Variant.
 */
alias GDExtensionInterfaceArrayOperatorIndexConst = GDExtensionVariantPtr function(GDExtensionConstTypePtr p_self, GDExtensionInt p_index);

/**
 * @name array_ref
 * @since 4.1
 * @deprecated in Godot 4.5. use `Array::operator=` instead.
 *
 * Sets an Array to be a reference to another Array object.
 *
 * @param p_self A pointer to the Array object to update.
 * @param p_from A pointer to the Array object to reference.
 */
alias GDExtensionInterfaceArrayRef = void function(GDExtensionTypePtr p_self, GDExtensionConstTypePtr p_from);

/**
 * @name array_set_typed
 * @since 4.1
 *
 * Makes an Array into a typed Array.
 *
 * @param p_self A pointer to the Array.
 * @param p_type The type of Variant the Array will store.
 * @param p_class_name A pointer to a StringName with the name of the object (if p_type is GDEXTENSION_VARIANT_TYPE_OBJECT).
 * @param p_script A pointer to a Script object (if p_type is GDEXTENSION_VARIANT_TYPE_OBJECT and the base class is extended by a script).
 */
alias GDExtensionInterfaceArraySetTyped = void function(GDExtensionTypePtr p_self, GDExtensionVariantType p_type, GDExtensionConstStringNamePtr p_class_name, GDExtensionConstVariantPtr p_script);

/* INTERFACE: Dictionary */

/**
 * @name dictionary_operator_index
 * @since 4.1
 *
 * Gets a pointer to a Variant in a Dictionary with the given key.
 *
 * @param p_self A pointer to a Dictionary object.
 * @param p_key A pointer to a Variant representing the key.
 *
 * @return A pointer to a Variant representing the value at the given key.
 */
alias GDExtensionInterfaceDictionaryOperatorIndex = GDExtensionVariantPtr function(GDExtensionTypePtr p_self, GDExtensionConstVariantPtr p_key);

/**
 * @name dictionary_operator_index_const
 * @since 4.1
 *
 * Gets a const pointer to a Variant in a Dictionary with the given key.
 *
 * @param p_self A const pointer to a Dictionary object.
 * @param p_key A pointer to a Variant representing the key.
 *
 * @return A const pointer to a Variant representing the value at the given key.
 */
alias GDExtensionInterfaceDictionaryOperatorIndexConst = GDExtensionVariantPtr function(GDExtensionConstTypePtr p_self, GDExtensionConstVariantPtr p_key);

/**
 * @name dictionary_set_typed
 * @since 4.4
 *
 * Makes a Dictionary into a typed Dictionary.
 *
 * @param p_self A pointer to the Dictionary.
 * @param p_key_type The type of Variant the Dictionary key will store.
 * @param p_key_class_name A pointer to a StringName with the name of the object (if p_key_type is GDEXTENSION_VARIANT_TYPE_OBJECT).
 * @param p_key_script A pointer to a Script object (if p_key_type is GDEXTENSION_VARIANT_TYPE_OBJECT and the base class is extended by a script).
 * @param p_value_type The type of Variant the Dictionary value will store.
 * @param p_value_class_name A pointer to a StringName with the name of the object (if p_value_type is GDEXTENSION_VARIANT_TYPE_OBJECT).
 * @param p_value_script A pointer to a Script object (if p_value_type is GDEXTENSION_VARIANT_TYPE_OBJECT and the base class is extended by a script).
 */
alias GDExtensionInterfaceDictionarySetTyped = void function(GDExtensionTypePtr p_self, GDExtensionVariantType p_key_type, GDExtensionConstStringNamePtr p_key_class_name, GDExtensionConstVariantPtr p_key_script, GDExtensionVariantType p_value_type, GDExtensionConstStringNamePtr p_value_class_name, GDExtensionConstVariantPtr p_value_script);

/* INTERFACE: Object */

/**
 * @name object_method_bind_call
 * @since 4.1
 *
 * Calls a method on an Object.
 *
 * @param p_method_bind A pointer to the MethodBind representing the method on the Object's class.
 * @param p_instance A pointer to the Object.
 * @param p_args A pointer to a C array of Variants representing the arguments.
 * @param p_arg_count The number of arguments.
 * @param r_ret A pointer to Variant which will receive the return value.
 * @param r_error A pointer to a GDExtensionCallError struct that will receive error information.
 */
alias GDExtensionInterfaceObjectMethodBindCall = void function(GDExtensionMethodBindPtr p_method_bind, GDExtensionObjectPtr p_instance, const(GDExtensionConstVariantPtr)* p_args, GDExtensionInt p_arg_count, GDExtensionUninitializedVariantPtr r_ret, GDExtensionCallError* r_error);

/**
 * @name object_method_bind_ptrcall
 * @since 4.1
 *
 * Calls a method on an Object (using a "ptrcall").
 *
 * @param p_method_bind A pointer to the MethodBind representing the method on the Object's class.
 * @param p_instance A pointer to the Object.
 * @param p_args A pointer to a C array representing the arguments.
 * @param r_ret A pointer to the Object that will receive the return value.
 */
alias GDExtensionInterfaceObjectMethodBindPtrcall = void function(GDExtensionMethodBindPtr p_method_bind, GDExtensionObjectPtr p_instance, const(GDExtensionConstTypePtr)* p_args, GDExtensionTypePtr r_ret);

/**
 * @name object_destroy
 * @since 4.1
 *
 * Destroys an Object.
 *
 * @param p_o A pointer to the Object.
 */
alias GDExtensionInterfaceObjectDestroy = void function(GDExtensionObjectPtr p_o);

/**
 * @name global_get_singleton
 * @since 4.1
 *
 * Gets a global singleton by name.
 *
 * @param p_name A pointer to a StringName with the singleton name.
 *
 * @return A pointer to the singleton Object.
 */
alias GDExtensionInterfaceGlobalGetSingleton = GDExtensionObjectPtr function(GDExtensionConstStringNamePtr p_name);

/**
 * @name object_get_instance_binding
 * @since 4.1
 *
 * Gets a pointer representing an Object's instance binding.
 *
 * @param p_o A pointer to the Object.
 * @param p_token A token the library received by the GDExtension's entry point function.
 * @param p_callbacks A pointer to a GDExtensionInstanceBindingCallbacks struct.
 *
 * @return A pointer to the instance binding.
 */
alias GDExtensionInterfaceObjectGetInstanceBinding = void * function(GDExtensionObjectPtr p_o, void* p_token, const(GDExtensionInstanceBindingCallbacks)* p_callbacks);

/**
 * @name object_set_instance_binding
 * @since 4.1
 *
 * Sets an Object's instance binding.
 *
 * @param p_o A pointer to the Object.
 * @param p_token A token the library received by the GDExtension's entry point function.
 * @param p_binding A pointer to the instance binding.
 * @param p_callbacks A pointer to a GDExtensionInstanceBindingCallbacks struct.
 */
alias GDExtensionInterfaceObjectSetInstanceBinding = void function(GDExtensionObjectPtr p_o, void* p_token, void* p_binding, const(GDExtensionInstanceBindingCallbacks)* p_callbacks);

/**
 * @name object_free_instance_binding
 * @since 4.2
 *
 * Free an Object's instance binding.
 *
 * @param p_o A pointer to the Object.
 * @param p_token A token the library received by the GDExtension's entry point function.
 */
alias GDExtensionInterfaceObjectFreeInstanceBinding = void function(GDExtensionObjectPtr p_o, void* p_token);

/**
 * @name object_set_instance
 * @since 4.1
 *
 * Sets an extension class instance on a Object.
 *
 * `p_classname` should be a registered extension class and should extend the `p_o` Object's class.
 *
 * @param p_o A pointer to the Object.
 * @param p_classname A pointer to a StringName with the registered extension class's name.
 * @param p_instance A pointer to the extension class instance.
 */
alias GDExtensionInterfaceObjectSetInstance = void function(GDExtensionObjectPtr p_o, GDExtensionConstStringNamePtr p_classname, GDExtensionClassInstancePtr p_instance);

/**
 * @name object_get_class_name
 * @since 4.1
 *
 * Gets the class name of an Object.
 *
 * If the GDExtension wraps the Godot object in an abstraction specific to its class, this is the
 * function that should be used to determine which wrapper to use.
 *
 * @param p_object A pointer to the Object.
 * @param p_library A pointer the library received by the GDExtension's entry point function.
 * @param r_class_name A pointer to a String to receive the class name.
 *
 * @return true if successful in getting the class name; otherwise false.
 */
alias GDExtensionInterfaceObjectGetClassName = GDExtensionBool function(GDExtensionConstObjectPtr p_object, GDExtensionClassLibraryPtr p_library, GDExtensionUninitializedStringNamePtr r_class_name);

/**
 * @name object_cast_to
 * @since 4.1
 *
 * Casts an Object to a different type.
 *
 * @param p_object A pointer to the Object.
 * @param p_class_tag A pointer uniquely identifying a built-in class in the ClassDB.
 *
 * @return Returns a pointer to the Object, or NULL if it can't be cast to the requested type.
 */
alias GDExtensionInterfaceObjectCastTo = GDExtensionObjectPtr function(GDExtensionConstObjectPtr p_object, void* p_class_tag);

/**
 * @name object_get_instance_from_id
 * @since 4.1
 *
 * Gets an Object by its instance ID.
 *
 * @param p_instance_id The instance ID.
 *
 * @return A pointer to the Object.
 */
alias GDExtensionInterfaceObjectGetInstanceFromId = GDExtensionObjectPtr function(GDObjectInstanceID p_instance_id);

/**
 * @name object_get_instance_id
 * @since 4.1
 *
 * Gets the instance ID from an Object.
 *
 * @param p_object A pointer to the Object.
 *
 * @return The instance ID.
 */
alias GDExtensionInterfaceObjectGetInstanceId = GDObjectInstanceID function(GDExtensionConstObjectPtr p_object);

/**
 * @name object_has_script_method
 * @since 4.3
 *
 * Checks if this object has a script with the given method.
 *
 * @param p_object A pointer to the Object.
 * @param p_method A pointer to a StringName identifying the method.
 *
 * @return true if the object has a script and that script has a method with the given name. Returns false if the object has no script.
 */
alias GDExtensionInterfaceObjectHasScriptMethod = GDExtensionBool function(GDExtensionConstObjectPtr p_object, GDExtensionConstStringNamePtr p_method);

/**
 * @name object_call_script_method
 * @since 4.3
 *
 * Call the given script method on this object.
 *
 * @param p_object A pointer to the Object.
 * @param p_method A pointer to a StringName identifying the method.
 * @param p_args A pointer to a C array of Variant.
 * @param p_argument_count The number of arguments.
 * @param r_return A pointer a Variant which will be assigned the return value.
 * @param r_error A pointer the structure which will hold error information.
 */
alias GDExtensionInterfaceObjectCallScriptMethod = void function(GDExtensionObjectPtr p_object, GDExtensionConstStringNamePtr p_method, const(GDExtensionConstVariantPtr)* p_args, GDExtensionInt p_argument_count, GDExtensionUninitializedVariantPtr r_return, GDExtensionCallError* r_error);

/* INTERFACE: Reference */

/**
 * @name ref_get_object
 * @since 4.1
 *
 * Gets the Object from a reference.
 *
 * @param p_ref A pointer to the reference.
 *
 * @return A pointer to the Object from the reference or NULL.
 */
alias GDExtensionInterfaceRefGetObject = GDExtensionObjectPtr function(GDExtensionConstRefPtr p_ref);

/**
 * @name ref_set_object
 * @since 4.1
 *
 * Sets the Object referred to by a reference.
 *
 * @param p_ref A pointer to the reference.
 * @param p_object A pointer to the Object to refer to.
 */
alias GDExtensionInterfaceRefSetObject = void function(GDExtensionRefPtr p_ref, GDExtensionObjectPtr p_object);

/* INTERFACE: Script Instance */

/**
 * @name script_instance_create
 * @since 4.1
 * @deprecated in Godot 4.2. Use `script_instance_create3` instead.
 *
 * Creates a script instance that contains the given info and instance data.
 *
 * @param p_info A pointer to a GDExtensionScriptInstanceInfo struct.
 * @param p_instance_data A pointer to a data representing the script instance in the GDExtension. This will be passed to all the function pointers on p_info.
 *
 * @return A pointer to a ScriptInstanceExtension object.
 */
alias GDExtensionInterfaceScriptInstanceCreate = GDExtensionScriptInstancePtr function(const(GDExtensionScriptInstanceInfo)* p_info, GDExtensionScriptInstanceDataPtr p_instance_data);

/**
 * @name script_instance_create2
 * @since 4.2
 * @deprecated in Godot 4.3. Use `script_instance_create3` instead.
 *
 * Creates a script instance that contains the given info and instance data.
 *
 * @param p_info A pointer to a GDExtensionScriptInstanceInfo2 struct.
 * @param p_instance_data A pointer to a data representing the script instance in the GDExtension. This will be passed to all the function pointers on p_info.
 *
 * @return A pointer to a ScriptInstanceExtension object.
 */
alias GDExtensionInterfaceScriptInstanceCreate2 = GDExtensionScriptInstancePtr function(const(GDExtensionScriptInstanceInfo2)* p_info, GDExtensionScriptInstanceDataPtr p_instance_data);

/**
 * @name script_instance_create3
 * @since 4.3
 *
 * Creates a script instance that contains the given info and instance data.
 *
 * @param p_info A pointer to a GDExtensionScriptInstanceInfo3 struct.
 * @param p_instance_data A pointer to a data representing the script instance in the GDExtension. This will be passed to all the function pointers on p_info.
 *
 * @return A pointer to a ScriptInstanceExtension object.
 */
alias GDExtensionInterfaceScriptInstanceCreate3 = GDExtensionScriptInstancePtr function(const(GDExtensionScriptInstanceInfo3)* p_info, GDExtensionScriptInstanceDataPtr p_instance_data);

/**
 * @name placeholder_script_instance_create
 * @since 4.2
 *
 * Creates a placeholder script instance for a given script and instance.
 *
 * This interface is optional as a custom placeholder could also be created with script_instance_create().
 *
 * @param p_language A pointer to a ScriptLanguage.
 * @param p_script A pointer to a Script.
 * @param p_owner A pointer to an Object.
 *
 * @return A pointer to a PlaceHolderScriptInstance object.
 */
alias GDExtensionInterfacePlaceHolderScriptInstanceCreate = GDExtensionScriptInstancePtr function(GDExtensionObjectPtr p_language, GDExtensionObjectPtr p_script, GDExtensionObjectPtr p_owner);

/**
 * @name placeholder_script_instance_update
 * @since 4.2
 *
 * Updates a placeholder script instance with the given properties and values.
 *
 * The passed in placeholder must be an instance of PlaceHolderScriptInstance
 * such as the one returned by placeholder_script_instance_create().
 *
 * @param p_placeholder A pointer to a PlaceHolderScriptInstance.
 * @param p_properties A pointer to an Array of Dictionary representing PropertyInfo.
 * @param p_values A pointer to a Dictionary mapping StringName to Variant values.
 */
alias GDExtensionInterfacePlaceHolderScriptInstanceUpdate = void function(GDExtensionScriptInstancePtr p_placeholder, GDExtensionConstTypePtr p_properties, GDExtensionConstTypePtr p_values);

/**
 * @name object_get_script_instance
 * @since 4.2
 *
 * Get the script instance data attached to this object.
 *
 * @param p_object A pointer to the Object.
 * @param p_language A pointer to the language expected for this script instance.
 *
 * @return A GDExtensionScriptInstanceDataPtr that was attached to this object as part of script_instance_create.
 */
alias GDExtensionInterfaceObjectGetScriptInstance = GDExtensionScriptInstanceDataPtr function(GDExtensionConstObjectPtr p_object, GDExtensionObjectPtr p_language);

/**
 * @name object_set_script_instance
 * @since 4.5
 *
 * Set the script instance data attached to this object.
 *
 * @param p_object A pointer to the Object.
 * @param p_script_instance A pointer to the script instance data to attach to this object.
 */
alias GDExtensionInterfaceObjectSetScriptInstance = void function(GDExtensionObjectPtr p_object, GDExtensionScriptInstanceDataPtr p_script_instance);

/* INTERFACE: Callable */
/**
 * @name callable_custom_create
 * @since 4.2
 * @deprecated in Godot 4.3. Use `callable_custom_create2` instead.
 *
 * Creates a custom Callable object from a function pointer.
 *
 * Provided struct can be safely freed once the function returns.
 *
 * @param r_callable A pointer that will receive the new Callable.
 * @param p_callable_custom_info The info required to construct a Callable.
 */
alias GDExtensionInterfaceCallableCustomCreate = void function(GDExtensionUninitializedTypePtr r_callable, GDExtensionCallableCustomInfo* p_callable_custom_info);

/**
 * @name callable_custom_create2
 * @since 4.3
 *
 * Creates a custom Callable object from a function pointer.
 *
 * Provided struct can be safely freed once the function returns.
 *
 * @param r_callable A pointer that will receive the new Callable.
 * @param p_callable_custom_info The info required to construct a Callable.
 */
alias GDExtensionInterfaceCallableCustomCreate2 = void function(GDExtensionUninitializedTypePtr r_callable, GDExtensionCallableCustomInfo2* p_callable_custom_info);

/**
 * @name callable_custom_get_userdata
 * @since 4.2
 *
 * Retrieves the userdata pointer from a custom Callable.
 *
 * If the Callable is not a custom Callable or the token does not match the one provided to callable_custom_create() via GDExtensionCallableCustomInfo then NULL will be returned.
 *
 * @param p_callable A pointer to a Callable.
 * @param p_token A pointer to an address that uniquely identifies the GDExtension.
 *
 * @return The userdata pointer given when creating this custom Callable.
 */
alias GDExtensionInterfaceCallableCustomGetUserData = void * function(GDExtensionConstTypePtr p_callable, void* p_token);

/* INTERFACE: ClassDB */

/**
 * @name classdb_construct_object
 * @since 4.1
 * @deprecated in Godot 4.4. Use `classdb_construct_object2` instead.
 *
 * Constructs an Object of the requested class.
 *
 * The passed class must be a built-in godot class, or an already-registered extension class. In both cases, object_set_instance() should be called to fully initialize the object.
 *
 * @param p_classname A pointer to a StringName with the class name.
 *
 * @return A pointer to the newly created Object.
 */
alias GDExtensionInterfaceClassdbConstructObject = GDExtensionObjectPtr function(GDExtensionConstStringNamePtr p_classname);

/**
 * @name classdb_construct_object2
 * @since 4.4
 *
 * Constructs an Object of the requested class.
 *
 * The passed class must be a built-in godot class, or an already-registered extension class. In both cases, object_set_instance() should be called to fully initialize the object.
 *
 * "NOTIFICATION_POSTINITIALIZE" must be sent after construction.
 *
 * @param p_classname A pointer to a StringName with the class name.
 *
 * @return A pointer to the newly created Object.
 */
alias GDExtensionInterfaceClassdbConstructObject2 = GDExtensionObjectPtr function(GDExtensionConstStringNamePtr p_classname);

/**
 * @name classdb_get_method_bind
 * @since 4.1
 *
 * Gets a pointer to the MethodBind in ClassDB for the given class, method and hash.
 *
 * @param p_classname A pointer to a StringName with the class name.
 * @param p_methodname A pointer to a StringName with the method name.
 * @param p_hash A hash representing the function signature.
 *
 * @return A pointer to the MethodBind from ClassDB.
 */
alias GDExtensionInterfaceClassdbGetMethodBind = GDExtensionMethodBindPtr function(GDExtensionConstStringNamePtr p_classname, GDExtensionConstStringNamePtr p_methodname, GDExtensionInt p_hash);

/**
 * @name classdb_get_class_tag
 * @since 4.1
 *
 * Gets a pointer uniquely identifying the given built-in class in the ClassDB.
 *
 * @param p_classname A pointer to a StringName with the class name.
 *
 * @return A pointer uniquely identifying the built-in class in the ClassDB.
 */
alias GDExtensionInterfaceClassdbGetClassTag = void * function(GDExtensionConstStringNamePtr p_classname);

/* INTERFACE: ClassDB Extension */

/**
 * @name classdb_register_extension_class
 * @since 4.1
 * @deprecated in Godot 4.2. Use `classdb_register_extension_class4` instead.
 *
 * Registers an extension class in the ClassDB.
 *
 * Provided struct can be safely freed once the function returns.
 *
 * @param p_library A pointer the library received by the GDExtension's entry point function.
 * @param p_class_name A pointer to a StringName with the class name.
 * @param p_parent_class_name A pointer to a StringName with the parent class name.
 * @param p_extension_funcs A pointer to a GDExtensionClassCreationInfo struct.
 */
alias GDExtensionInterfaceClassdbRegisterExtensionClass = void function(GDExtensionClassLibraryPtr p_library, GDExtensionConstStringNamePtr p_class_name, GDExtensionConstStringNamePtr p_parent_class_name, const(GDExtensionClassCreationInfo)* p_extension_funcs);

/**
 * @name classdb_register_extension_class2
 * @since 4.2
 * @deprecated in Godot 4.3. Use `classdb_register_extension_class4` instead.
 *
 * Registers an extension class in the ClassDB.
 *
 * Provided struct can be safely freed once the function returns.
 *
 * @param p_library A pointer the library received by the GDExtension's entry point function.
 * @param p_class_name A pointer to a StringName with the class name.
 * @param p_parent_class_name A pointer to a StringName with the parent class name.
 * @param p_extension_funcs A pointer to a GDExtensionClassCreationInfo2 struct.
 */
alias GDExtensionInterfaceClassdbRegisterExtensionClass2 = void function(GDExtensionClassLibraryPtr p_library, GDExtensionConstStringNamePtr p_class_name, GDExtensionConstStringNamePtr p_parent_class_name, const(GDExtensionClassCreationInfo2)* p_extension_funcs);

/**
 * @name classdb_register_extension_class3
 * @since 4.3
 * @deprecated in Godot 4.4. Use `classdb_register_extension_class4` instead.
 *
 * Registers an extension class in the ClassDB.
 *
 * Provided struct can be safely freed once the function returns.
 *
 * @param p_library A pointer the library received by the GDExtension's entry point function.
 * @param p_class_name A pointer to a StringName with the class name.
 * @param p_parent_class_name A pointer to a StringName with the parent class name.
 * @param p_extension_funcs A pointer to a GDExtensionClassCreationInfo2 struct.
 */
alias GDExtensionInterfaceClassdbRegisterExtensionClass3 = void function(GDExtensionClassLibraryPtr p_library, GDExtensionConstStringNamePtr p_class_name, GDExtensionConstStringNamePtr p_parent_class_name, const(GDExtensionClassCreationInfo3)* p_extension_funcs);

/**
 * @name classdb_register_extension_class4
 * @since 4.4
 * @deprecated in Godot 4.5. Use `classdb_register_extension_class5` instead.
 *
 * Registers an extension class in the ClassDB.
 *
 * Provided struct can be safely freed once the function returns.
 *
 * @param p_library A pointer the library received by the GDExtension's entry point function.
 * @param p_class_name A pointer to a StringName with the class name.
 * @param p_parent_class_name A pointer to a StringName with the parent class name.
 * @param p_extension_funcs A pointer to a GDExtensionClassCreationInfo2 struct.
 */
alias GDExtensionInterfaceClassdbRegisterExtensionClass4 = void function(GDExtensionClassLibraryPtr p_library, GDExtensionConstStringNamePtr p_class_name, GDExtensionConstStringNamePtr p_parent_class_name, const(GDExtensionClassCreationInfo4)* p_extension_funcs);

/**
 * @name classdb_register_extension_class5
 * @since 4.5
 *
 * Registers an extension class in the ClassDB.
 *
 * Provided struct can be safely freed once the function returns.
 *
 * @param p_library A pointer the library received by the GDExtension's entry point function.
 * @param p_class_name A pointer to a StringName with the class name.
 * @param p_parent_class_name A pointer to a StringName with the parent class name.
 * @param p_extension_funcs A pointer to a GDExtensionClassCreationInfo2 struct.
 */
alias GDExtensionInterfaceClassdbRegisterExtensionClass5 = void function(GDExtensionClassLibraryPtr p_library, GDExtensionConstStringNamePtr p_class_name, GDExtensionConstStringNamePtr p_parent_class_name, const(GDExtensionClassCreationInfo5)* p_extension_funcs);

/**
 * @name classdb_register_extension_class_method
 * @since 4.1
 *
 * Registers a method on an extension class in the ClassDB.
 *
 * Provided struct can be safely freed once the function returns.
 *
 * @param p_library A pointer the library received by the GDExtension's entry point function.
 * @param p_class_name A pointer to a StringName with the class name.
 * @param p_method_info A pointer to a GDExtensionClassMethodInfo struct.
 */
alias GDExtensionInterfaceClassdbRegisterExtensionClassMethod = void function(GDExtensionClassLibraryPtr p_library, GDExtensionConstStringNamePtr p_class_name, const(GDExtensionClassMethodInfo)* p_method_info);

/**
 * @name classdb_register_extension_class_virtual_method
 * @since 4.3
 *
 * Registers a virtual method on an extension class in ClassDB, that can be implemented by scripts or other extensions.
 *
 * Provided struct can be safely freed once the function returns.
 *
 * @param p_library A pointer the library received by the GDExtension's entry point function.
 * @param p_class_name A pointer to a StringName with the class name.
 * @param p_method_info A pointer to a GDExtensionClassMethodInfo struct.
 */
alias GDExtensionInterfaceClassdbRegisterExtensionClassVirtualMethod = void function(GDExtensionClassLibraryPtr p_library, GDExtensionConstStringNamePtr p_class_name, const(GDExtensionClassVirtualMethodInfo)* p_method_info);

/**
 * @name classdb_register_extension_class_integer_constant
 * @since 4.1
 *
 * Registers an integer constant on an extension class in the ClassDB.
 *
 * Note about registering bitfield values (if p_is_bitfield is true): even though p_constant_value is signed, language bindings are
 * advised to treat bitfields as uint64_t, since this is generally clearer and can prevent mistakes like using -1 for setting all bits.
 * Language APIs should thus provide an abstraction that registers bitfields (uint64_t) separately from regular constants (int64_t).
 *
 * @param p_library A pointer the library received by the GDExtension's entry point function.
 * @param p_class_name A pointer to a StringName with the class name.
 * @param p_enum_name A pointer to a StringName with the enum name.
 * @param p_constant_name A pointer to a StringName with the constant name.
 * @param p_constant_value The constant value.
 * @param p_is_bitfield Whether or not this constant is part of a bitfield.
 */
alias GDExtensionInterfaceClassdbRegisterExtensionClassIntegerConstant = void function(GDExtensionClassLibraryPtr p_library, GDExtensionConstStringNamePtr p_class_name, GDExtensionConstStringNamePtr p_enum_name, GDExtensionConstStringNamePtr p_constant_name, GDExtensionInt p_constant_value, GDExtensionBool p_is_bitfield);

/**
 * @name classdb_register_extension_class_property
 * @since 4.1
 *
 * Registers a property on an extension class in the ClassDB.
 *
 * Provided struct can be safely freed once the function returns.
 *
 * @param p_library A pointer the library received by the GDExtension's entry point function.
 * @param p_class_name A pointer to a StringName with the class name.
 * @param p_info A pointer to a GDExtensionPropertyInfo struct.
 * @param p_setter A pointer to a StringName with the name of the setter method.
 * @param p_getter A pointer to a StringName with the name of the getter method.
 */
alias GDExtensionInterfaceClassdbRegisterExtensionClassProperty = void function(GDExtensionClassLibraryPtr p_library, GDExtensionConstStringNamePtr p_class_name, const(GDExtensionPropertyInfo)* p_info, GDExtensionConstStringNamePtr p_setter, GDExtensionConstStringNamePtr p_getter);

/**
 * @name classdb_register_extension_class_property_indexed
 * @since 4.2
 *
 * Registers an indexed property on an extension class in the ClassDB.
 *
 * Provided struct can be safely freed once the function returns.
 *
 * @param p_library A pointer the library received by the GDExtension's entry point function.
 * @param p_class_name A pointer to a StringName with the class name.
 * @param p_info A pointer to a GDExtensionPropertyInfo struct.
 * @param p_setter A pointer to a StringName with the name of the setter method.
 * @param p_getter A pointer to a StringName with the name of the getter method.
 * @param p_index The index to pass as the first argument to the getter and setter methods.
 */
alias GDExtensionInterfaceClassdbRegisterExtensionClassPropertyIndexed = void function(GDExtensionClassLibraryPtr p_library, GDExtensionConstStringNamePtr p_class_name, const(GDExtensionPropertyInfo)* p_info, GDExtensionConstStringNamePtr p_setter, GDExtensionConstStringNamePtr p_getter, GDExtensionInt p_index);

/**
 * @name classdb_register_extension_class_property_group
 * @since 4.1
 *
 * Registers a property group on an extension class in the ClassDB.
 *
 * @param p_library A pointer the library received by the GDExtension's entry point function.
 * @param p_class_name A pointer to a StringName with the class name.
 * @param p_group_name A pointer to a String with the group name.
 * @param p_prefix A pointer to a String with the prefix used by properties in this group.
 */
alias GDExtensionInterfaceClassdbRegisterExtensionClassPropertyGroup = void function(GDExtensionClassLibraryPtr p_library, GDExtensionConstStringNamePtr p_class_name, GDExtensionConstStringPtr p_group_name, GDExtensionConstStringPtr p_prefix);

/**
 * @name classdb_register_extension_class_property_subgroup
 * @since 4.1
 *
 * Registers a property subgroup on an extension class in the ClassDB.
 *
 * @param p_library A pointer the library received by the GDExtension's entry point function.
 * @param p_class_name A pointer to a StringName with the class name.
 * @param p_subgroup_name A pointer to a String with the subgroup name.
 * @param p_prefix A pointer to a String with the prefix used by properties in this subgroup.
 */
alias GDExtensionInterfaceClassdbRegisterExtensionClassPropertySubgroup = void function(GDExtensionClassLibraryPtr p_library, GDExtensionConstStringNamePtr p_class_name, GDExtensionConstStringPtr p_subgroup_name, GDExtensionConstStringPtr p_prefix);

/**
 * @name classdb_register_extension_class_signal
 * @since 4.1
 *
 * Registers a signal on an extension class in the ClassDB.
 *
 * Provided structs can be safely freed once the function returns.
 *
 * @param p_library A pointer the library received by the GDExtension's entry point function.
 * @param p_class_name A pointer to a StringName with the class name.
 * @param p_signal_name A pointer to a StringName with the signal name.
 * @param p_argument_info A pointer to a GDExtensionPropertyInfo struct.
 * @param p_argument_count The number of arguments the signal receives.
 */
alias GDExtensionInterfaceClassdbRegisterExtensionClassSignal = void function(GDExtensionClassLibraryPtr p_library, GDExtensionConstStringNamePtr p_class_name, GDExtensionConstStringNamePtr p_signal_name, const(GDExtensionPropertyInfo)* p_argument_info, GDExtensionInt p_argument_count);

/**
 * @name classdb_unregister_extension_class
 * @since 4.1
 *
 * Unregisters an extension class in the ClassDB.
 *
 * Unregistering a parent class before a class that inherits it will result in failure. Inheritors must be unregistered first.
 *
 * @param p_library A pointer the library received by the GDExtension's entry point function.
 * @param p_class_name A pointer to a StringName with the class name.
 */
alias GDExtensionInterfaceClassdbUnregisterExtensionClass = void function(GDExtensionClassLibraryPtr p_library, GDExtensionConstStringNamePtr p_class_name);

/**
 * @name get_library_path
 * @since 4.1
 *
 * Gets the path to the current GDExtension library.
 *
 * @param p_library A pointer the library received by the GDExtension's entry point function.
 * @param r_path A pointer to a String which will receive the path.
 */
alias GDExtensionInterfaceGetLibraryPath = void function(GDExtensionClassLibraryPtr p_library, GDExtensionUninitializedStringPtr r_path);

/**
 * @name editor_add_plugin
 * @since 4.1
 *
 * Adds an editor plugin.
 *
 * It's safe to call during initialization.
 *
 * @param p_class_name A pointer to a StringName with the name of a class (descending from EditorPlugin) which is already registered with ClassDB.
 */
alias GDExtensionInterfaceEditorAddPlugin = void function(GDExtensionConstStringNamePtr p_class_name);

/**
 * @name editor_remove_plugin
 * @since 4.1
 *
 * Removes an editor plugin.
 *
 * @param p_class_name A pointer to a StringName with the name of a class that was previously added as an editor plugin.
 */
alias GDExtensionInterfaceEditorRemovePlugin = void function(GDExtensionConstStringNamePtr p_class_name);

/**
 * @name editor_help_load_xml_from_utf8_chars
 * @since 4.3
 *
 * Loads new XML-formatted documentation data in the editor.
 *
 * The provided pointer can be immediately freed once the function returns.
 *
 * @param p_data A pointer to a UTF-8 encoded C string (null terminated).
 */
alias GDExtensionsInterfaceEditorHelpLoadXmlFromUtf8Chars = void function(const(char)* p_data);

/**
 * @name editor_help_load_xml_from_utf8_chars_and_len
 * @since 4.3
 *
 * Loads new XML-formatted documentation data in the editor.
 *
 * The provided pointer can be immediately freed once the function returns.
 *
 * @param p_data A pointer to a UTF-8 encoded C string.
 * @param p_size The number of bytes (not code units).
 */
alias GDExtensionsInterfaceEditorHelpLoadXmlFromUtf8CharsAndLen = void function(const(char)* p_data, GDExtensionInt p_size);

/**
 * @name editor_register_get_classes_used_callback
 * @since 4.5
 *
 * Registers a callback that Godot can call to get the list of all classes (from ClassDB) that may be used by the calling GDExtension.
 *
 * This is used by the editor to generate a build profile (in "Tools" > "Engine Compilation Configuration Editor..." > "Detect from project"),
 * in order to recompile Godot with only the classes used.
 * In the provided callback, the GDExtension should provide the list of classes that _may_ be used statically, thus the time of invocation shouldn't matter.
 * If a GDExtension doesn't register a callback, Godot will assume that it could be using any classes.
 *
 * @param p_library A pointer the library received by the GDExtension's entry point function.
 * @param p_callback The callback to retrieve the list of classes used.
 */
alias GDExtensionInterfaceEditorRegisterGetClassesUsedCallback = void function(GDExtensionClassLibraryPtr p_library, GDExtensionEditorGetClassesUsedCallback p_callback);

/**
 * @name register_main_loop_callbacks
 * @since 4.5
 *
 * Registers callbacks to be called at different phases of the main loop.
 *
 * @param p_library A pointer the library received by the GDExtension's entry point function.
 * @param p_callbacks A pointer to the structure that contains the callbacks.
 */
alias GDExtensionInterfaceRegisterMainLoopCallbacks = void function(GDExtensionClassLibraryPtr p_library, const(GDExtensionMainLoopCallbacks)* p_callbacks);


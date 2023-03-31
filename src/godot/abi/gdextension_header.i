# 1 "gdextension_interface.h"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 375 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "gdextension_interface.h" 2
# 38 "gdextension_interface.h"
# 1 "/usr/lib/clang/15.0.7/include/stddef.h" 1 3
# 35 "/usr/lib/clang/15.0.7/include/stddef.h" 3
typedef long int ptrdiff_t;
# 46 "/usr/lib/clang/15.0.7/include/stddef.h" 3
typedef long unsigned int size_t;
# 74 "/usr/lib/clang/15.0.7/include/stddef.h" 3
typedef int wchar_t;
# 102 "/usr/lib/clang/15.0.7/include/stddef.h" 3
# 1 "/usr/lib/clang/15.0.7/include/__stddef_max_align_t.h" 1 3
# 19 "/usr/lib/clang/15.0.7/include/__stddef_max_align_t.h" 3
typedef struct {
  long long __clang_max_align_nonce1
      __attribute__((__aligned__(__alignof__(long long))));
  long double __clang_max_align_nonce2
      __attribute__((__aligned__(__alignof__(long double))));
} max_align_t;
# 103 "/usr/lib/clang/15.0.7/include/stddef.h" 2 3
# 39 "gdextension_interface.h" 2
# 1 "/usr/lib/clang/15.0.7/include/stdint.h" 1 3
# 52 "/usr/lib/clang/15.0.7/include/stdint.h" 3
# 1 "/usr/include/stdint.h" 1 3 4
# 26 "/usr/include/stdint.h" 3 4
# 1 "/usr/include/bits/libc-header-start.h" 1 3 4
# 33 "/usr/include/bits/libc-header-start.h" 3 4
# 1 "/usr/include/features.h" 1 3 4
# 393 "/usr/include/features.h" 3 4
# 1 "/usr/include/features-time64.h" 1 3 4
# 20 "/usr/include/features-time64.h" 3 4
# 1 "/usr/include/bits/wordsize.h" 1 3 4
# 21 "/usr/include/features-time64.h" 2 3 4
# 1 "/usr/include/bits/timesize.h" 1 3 4
# 19 "/usr/include/bits/timesize.h" 3 4
# 1 "/usr/include/bits/wordsize.h" 1 3 4
# 20 "/usr/include/bits/timesize.h" 2 3 4
# 22 "/usr/include/features-time64.h" 2 3 4
# 394 "/usr/include/features.h" 2 3 4
# 469 "/usr/include/features.h" 3 4
# 1 "/usr/include/stdc-predef.h" 1 3 4
# 470 "/usr/include/features.h" 2 3 4
# 491 "/usr/include/features.h" 3 4
# 1 "/usr/include/sys/cdefs.h" 1 3 4
# 559 "/usr/include/sys/cdefs.h" 3 4
# 1 "/usr/include/bits/wordsize.h" 1 3 4
# 560 "/usr/include/sys/cdefs.h" 2 3 4
# 1 "/usr/include/bits/long-double.h" 1 3 4
# 561 "/usr/include/sys/cdefs.h" 2 3 4
# 492 "/usr/include/features.h" 2 3 4
# 515 "/usr/include/features.h" 3 4
# 1 "/usr/include/gnu/stubs.h" 1 3 4
# 10 "/usr/include/gnu/stubs.h" 3 4
# 1 "/usr/include/gnu/stubs-64.h" 1 3 4
# 11 "/usr/include/gnu/stubs.h" 2 3 4
# 516 "/usr/include/features.h" 2 3 4
# 34 "/usr/include/bits/libc-header-start.h" 2 3 4
# 27 "/usr/include/stdint.h" 2 3 4
# 1 "/usr/include/bits/types.h" 1 3 4
# 27 "/usr/include/bits/types.h" 3 4
# 1 "/usr/include/bits/wordsize.h" 1 3 4
# 28 "/usr/include/bits/types.h" 2 3 4
# 1 "/usr/include/bits/timesize.h" 1 3 4
# 19 "/usr/include/bits/timesize.h" 3 4
# 1 "/usr/include/bits/wordsize.h" 1 3 4
# 20 "/usr/include/bits/timesize.h" 2 3 4
# 29 "/usr/include/bits/types.h" 2 3 4


typedef unsigned char __u_char;
typedef unsigned short int __u_short;
typedef unsigned int __u_int;
typedef unsigned long int __u_long;


typedef signed char __int8_t;
typedef unsigned char __uint8_t;
typedef signed short int __int16_t;
typedef unsigned short int __uint16_t;
typedef signed int __int32_t;
typedef unsigned int __uint32_t;

typedef signed long int __int64_t;
typedef unsigned long int __uint64_t;






typedef __int8_t __int_least8_t;
typedef __uint8_t __uint_least8_t;
typedef __int16_t __int_least16_t;
typedef __uint16_t __uint_least16_t;
typedef __int32_t __int_least32_t;
typedef __uint32_t __uint_least32_t;
typedef __int64_t __int_least64_t;
typedef __uint64_t __uint_least64_t;



typedef long int __quad_t;
typedef unsigned long int __u_quad_t;







typedef long int __intmax_t;
typedef unsigned long int __uintmax_t;
# 141 "/usr/include/bits/types.h" 3 4
# 1 "/usr/include/bits/typesizes.h" 1 3 4
# 142 "/usr/include/bits/types.h" 2 3 4
# 1 "/usr/include/bits/time64.h" 1 3 4
# 143 "/usr/include/bits/types.h" 2 3 4


typedef unsigned long int __dev_t;
typedef unsigned int __uid_t;
typedef unsigned int __gid_t;
typedef unsigned long int __ino_t;
typedef unsigned long int __ino64_t;
typedef unsigned int __mode_t;
typedef unsigned long int __nlink_t;
typedef long int __off_t;
typedef long int __off64_t;
typedef int __pid_t;
typedef struct { int __val[2]; } __fsid_t;
typedef long int __clock_t;
typedef unsigned long int __rlim_t;
typedef unsigned long int __rlim64_t;
typedef unsigned int __id_t;
typedef long int __time_t;
typedef unsigned int __useconds_t;
typedef long int __suseconds_t;
typedef long int __suseconds64_t;

typedef int __daddr_t;
typedef int __key_t;


typedef int __clockid_t;


typedef void * __timer_t;


typedef long int __blksize_t;




typedef long int __blkcnt_t;
typedef long int __blkcnt64_t;


typedef unsigned long int __fsblkcnt_t;
typedef unsigned long int __fsblkcnt64_t;


typedef unsigned long int __fsfilcnt_t;
typedef unsigned long int __fsfilcnt64_t;


typedef long int __fsword_t;

typedef long int __ssize_t;


typedef long int __syscall_slong_t;

typedef unsigned long int __syscall_ulong_t;



typedef __off64_t __loff_t;
typedef char *__caddr_t;


typedef long int __intptr_t;


typedef unsigned int __socklen_t;




typedef int __sig_atomic_t;
# 28 "/usr/include/stdint.h" 2 3 4
# 1 "/usr/include/bits/wchar.h" 1 3 4
# 29 "/usr/include/stdint.h" 2 3 4
# 1 "/usr/include/bits/wordsize.h" 1 3 4
# 30 "/usr/include/stdint.h" 2 3 4




# 1 "/usr/include/bits/stdint-intn.h" 1 3 4
# 24 "/usr/include/bits/stdint-intn.h" 3 4
typedef __int8_t int8_t;
typedef __int16_t int16_t;
typedef __int32_t int32_t;
typedef __int64_t int64_t;
# 35 "/usr/include/stdint.h" 2 3 4


# 1 "/usr/include/bits/stdint-uintn.h" 1 3 4
# 24 "/usr/include/bits/stdint-uintn.h" 3 4
typedef __uint8_t uint8_t;
typedef __uint16_t uint16_t;
typedef __uint32_t uint32_t;
typedef __uint64_t uint64_t;
# 38 "/usr/include/stdint.h" 2 3 4





typedef __int_least8_t int_least8_t;
typedef __int_least16_t int_least16_t;
typedef __int_least32_t int_least32_t;
typedef __int_least64_t int_least64_t;


typedef __uint_least8_t uint_least8_t;
typedef __uint_least16_t uint_least16_t;
typedef __uint_least32_t uint_least32_t;
typedef __uint_least64_t uint_least64_t;





typedef signed char int_fast8_t;

typedef long int int_fast16_t;
typedef long int int_fast32_t;
typedef long int int_fast64_t;
# 71 "/usr/include/stdint.h" 3 4
typedef unsigned char uint_fast8_t;

typedef unsigned long int uint_fast16_t;
typedef unsigned long int uint_fast32_t;
typedef unsigned long int uint_fast64_t;
# 87 "/usr/include/stdint.h" 3 4
typedef long int intptr_t;


typedef unsigned long int uintptr_t;
# 101 "/usr/include/stdint.h" 3 4
typedef __intmax_t intmax_t;
typedef __uintmax_t uintmax_t;
# 53 "/usr/lib/clang/15.0.7/include/stdint.h" 2 3
# 40 "gdextension_interface.h" 2


typedef uint32_t char32_t;
typedef uint16_t char16_t;
# 52 "gdextension_interface.h"
typedef enum {
 GDEXTENSION_VARIANT_TYPE_NIL,


 GDEXTENSION_VARIANT_TYPE_BOOL,
 GDEXTENSION_VARIANT_TYPE_INT,
 GDEXTENSION_VARIANT_TYPE_FLOAT,
 GDEXTENSION_VARIANT_TYPE_STRING,


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


 GDEXTENSION_VARIANT_TYPE_COLOR,
 GDEXTENSION_VARIANT_TYPE_STRING_NAME,
 GDEXTENSION_VARIANT_TYPE_NODE_PATH,
 GDEXTENSION_VARIANT_TYPE_RID,
 GDEXTENSION_VARIANT_TYPE_OBJECT,
 GDEXTENSION_VARIANT_TYPE_CALLABLE,
 GDEXTENSION_VARIANT_TYPE_SIGNAL,
 GDEXTENSION_VARIANT_TYPE_DICTIONARY,
 GDEXTENSION_VARIANT_TYPE_ARRAY,


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
} GDExtensionVariantType;

typedef enum {

 GDEXTENSION_VARIANT_OP_EQUAL,
 GDEXTENSION_VARIANT_OP_NOT_EQUAL,
 GDEXTENSION_VARIANT_OP_LESS,
 GDEXTENSION_VARIANT_OP_LESS_EQUAL,
 GDEXTENSION_VARIANT_OP_GREATER,
 GDEXTENSION_VARIANT_OP_GREATER_EQUAL,


 GDEXTENSION_VARIANT_OP_ADD,
 GDEXTENSION_VARIANT_OP_SUBTRACT,
 GDEXTENSION_VARIANT_OP_MULTIPLY,
 GDEXTENSION_VARIANT_OP_DIVIDE,
 GDEXTENSION_VARIANT_OP_NEGATE,
 GDEXTENSION_VARIANT_OP_POSITIVE,
 GDEXTENSION_VARIANT_OP_MODULE,
 GDEXTENSION_VARIANT_OP_POWER,


 GDEXTENSION_VARIANT_OP_SHIFT_LEFT,
 GDEXTENSION_VARIANT_OP_SHIFT_RIGHT,
 GDEXTENSION_VARIANT_OP_BIT_AND,
 GDEXTENSION_VARIANT_OP_BIT_OR,
 GDEXTENSION_VARIANT_OP_BIT_XOR,
 GDEXTENSION_VARIANT_OP_BIT_NEGATE,


 GDEXTENSION_VARIANT_OP_AND,
 GDEXTENSION_VARIANT_OP_OR,
 GDEXTENSION_VARIANT_OP_XOR,
 GDEXTENSION_VARIANT_OP_NOT,


 GDEXTENSION_VARIANT_OP_IN,
 GDEXTENSION_VARIANT_OP_MAX

} GDExtensionVariantOperator;

typedef void *GDExtensionVariantPtr;
typedef const void *GDExtensionConstVariantPtr;
typedef void *GDExtensionStringNamePtr;
typedef const void *GDExtensionConstStringNamePtr;
typedef void *GDExtensionStringPtr;
typedef const void *GDExtensionConstStringPtr;
typedef void *GDExtensionObjectPtr;
typedef const void *GDExtensionConstObjectPtr;
typedef void *GDExtensionTypePtr;
typedef const void *GDExtensionConstTypePtr;
typedef const void *GDExtensionMethodBindPtr;
typedef int64_t GDExtensionInt;
typedef uint8_t GDExtensionBool;
typedef uint64_t GDObjectInstanceID;
typedef void *GDExtensionRefPtr;
typedef const void *GDExtensionConstRefPtr;



typedef enum {
 GDEXTENSION_CALL_OK,
 GDEXTENSION_CALL_ERROR_INVALID_METHOD,
 GDEXTENSION_CALL_ERROR_INVALID_ARGUMENT,
 GDEXTENSION_CALL_ERROR_TOO_MANY_ARGUMENTS,
 GDEXTENSION_CALL_ERROR_TOO_FEW_ARGUMENTS,
 GDEXTENSION_CALL_ERROR_INSTANCE_IS_NULL,
 GDEXTENSION_CALL_ERROR_METHOD_NOT_CONST,
} GDExtensionCallErrorType;

typedef struct {
 GDExtensionCallErrorType error;
 int32_t argument;
 int32_t expected;
} GDExtensionCallError;

typedef void (*GDExtensionVariantFromTypeConstructorFunc)(GDExtensionVariantPtr, GDExtensionTypePtr);
typedef void (*GDExtensionTypeFromVariantConstructorFunc)(GDExtensionTypePtr, GDExtensionVariantPtr);
typedef void (*GDExtensionPtrOperatorEvaluator)(GDExtensionConstTypePtr p_left, GDExtensionConstTypePtr p_right, GDExtensionTypePtr r_result);
typedef void (*GDExtensionPtrBuiltInMethod)(GDExtensionTypePtr p_base, const GDExtensionConstTypePtr *p_args, GDExtensionTypePtr r_return, int p_argument_count);
typedef void (*GDExtensionPtrConstructor)(GDExtensionTypePtr p_base, const GDExtensionConstTypePtr *p_args);
typedef void (*GDExtensionPtrDestructor)(GDExtensionTypePtr p_base);
typedef void (*GDExtensionPtrSetter)(GDExtensionTypePtr p_base, GDExtensionConstTypePtr p_value);
typedef void (*GDExtensionPtrGetter)(GDExtensionConstTypePtr p_base, GDExtensionTypePtr r_value);
typedef void (*GDExtensionPtrIndexedSetter)(GDExtensionTypePtr p_base, GDExtensionInt p_index, GDExtensionConstTypePtr p_value);
typedef void (*GDExtensionPtrIndexedGetter)(GDExtensionConstTypePtr p_base, GDExtensionInt p_index, GDExtensionTypePtr r_value);
typedef void (*GDExtensionPtrKeyedSetter)(GDExtensionTypePtr p_base, GDExtensionConstTypePtr p_key, GDExtensionConstTypePtr p_value);
typedef void (*GDExtensionPtrKeyedGetter)(GDExtensionConstTypePtr p_base, GDExtensionConstTypePtr p_key, GDExtensionTypePtr r_value);
typedef uint32_t (*GDExtensionPtrKeyedChecker)(GDExtensionConstVariantPtr p_base, GDExtensionConstVariantPtr p_key);
typedef void (*GDExtensionPtrUtilityFunction)(GDExtensionTypePtr r_return, const GDExtensionConstTypePtr *p_args, int p_argument_count);

typedef GDExtensionObjectPtr (*GDExtensionClassConstructor)();

typedef void *(*GDExtensionInstanceBindingCreateCallback)(void *p_token, void *p_instance);
typedef void (*GDExtensionInstanceBindingFreeCallback)(void *p_token, void *p_instance, void *p_binding);
typedef GDExtensionBool (*GDExtensionInstanceBindingReferenceCallback)(void *p_token, void *p_binding, GDExtensionBool p_reference);

typedef struct {
 GDExtensionInstanceBindingCreateCallback create_callback;
 GDExtensionInstanceBindingFreeCallback free_callback;
 GDExtensionInstanceBindingReferenceCallback reference_callback;
} GDExtensionInstanceBindingCallbacks;



typedef void *GDExtensionClassInstancePtr;

typedef GDExtensionBool (*GDExtensionClassSet)(GDExtensionClassInstancePtr p_instance, GDExtensionConstStringNamePtr p_name, GDExtensionConstVariantPtr p_value);
typedef GDExtensionBool (*GDExtensionClassGet)(GDExtensionClassInstancePtr p_instance, GDExtensionConstStringNamePtr p_name, GDExtensionVariantPtr r_ret);
typedef uint64_t (*GDExtensionClassGetRID)(GDExtensionClassInstancePtr p_instance);

typedef struct {
 GDExtensionVariantType type;
 GDExtensionStringNamePtr name;
 GDExtensionStringNamePtr class_name;
 uint32_t hint;
 GDExtensionStringPtr hint_string;
 uint32_t usage;
} GDExtensionPropertyInfo;

typedef struct {
 GDExtensionStringNamePtr name;
 GDExtensionPropertyInfo return_value;
 uint32_t flags;
 int32_t id;


 uint32_t argument_count;
 GDExtensionPropertyInfo *arguments;


 uint32_t default_argument_count;
 GDExtensionVariantPtr *default_arguments;
} GDExtensionMethodInfo;

typedef const GDExtensionPropertyInfo *(*GDExtensionClassGetPropertyList)(GDExtensionClassInstancePtr p_instance, uint32_t *r_count);
typedef void (*GDExtensionClassFreePropertyList)(GDExtensionClassInstancePtr p_instance, const GDExtensionPropertyInfo *p_list);
typedef GDExtensionBool (*GDExtensionClassPropertyCanRevert)(GDExtensionClassInstancePtr p_instance, GDExtensionConstStringNamePtr p_name);
typedef GDExtensionBool (*GDExtensionClassPropertyGetRevert)(GDExtensionClassInstancePtr p_instance, GDExtensionConstStringNamePtr p_name, GDExtensionVariantPtr r_ret);
typedef void (*GDExtensionClassNotification)(GDExtensionClassInstancePtr p_instance, int32_t p_what);
typedef void (*GDExtensionClassToString)(GDExtensionClassInstancePtr p_instance, GDExtensionBool *r_is_valid, GDExtensionStringPtr p_out);
typedef void (*GDExtensionClassReference)(GDExtensionClassInstancePtr p_instance);
typedef void (*GDExtensionClassUnreference)(GDExtensionClassInstancePtr p_instance);
typedef void (*GDExtensionClassCallVirtual)(GDExtensionClassInstancePtr p_instance, const GDExtensionConstTypePtr *p_args, GDExtensionTypePtr r_ret);
typedef GDExtensionObjectPtr (*GDExtensionClassCreateInstance)(void *p_userdata);
typedef void (*GDExtensionClassFreeInstance)(void *p_userdata, GDExtensionClassInstancePtr p_instance);
typedef GDExtensionClassCallVirtual (*GDExtensionClassGetVirtual)(void *p_userdata, GDExtensionConstStringNamePtr p_name);

typedef struct {
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
 void *class_userdata;
} GDExtensionClassCreationInfo;

typedef void *GDExtensionClassLibraryPtr;



typedef enum {
 GDEXTENSION_METHOD_FLAG_NORMAL = 1,
 GDEXTENSION_METHOD_FLAG_EDITOR = 2,
 GDEXTENSION_METHOD_FLAG_CONST = 4,
 GDEXTENSION_METHOD_FLAG_VIRTUAL = 8,
 GDEXTENSION_METHOD_FLAG_VARARG = 16,
 GDEXTENSION_METHOD_FLAG_STATIC = 32,
 GDEXTENSION_METHOD_FLAGS_DEFAULT = GDEXTENSION_METHOD_FLAG_NORMAL,
} GDExtensionClassMethodFlags;

typedef enum {
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
} GDExtensionClassMethodArgumentMetadata;

typedef void (*GDExtensionClassMethodCall)(void *method_userdata, GDExtensionClassInstancePtr p_instance, const GDExtensionConstVariantPtr *p_args, GDExtensionInt p_argument_count, GDExtensionVariantPtr r_return, GDExtensionCallError *r_error);
typedef void (*GDExtensionClassMethodPtrCall)(void *method_userdata, GDExtensionClassInstancePtr p_instance, const GDExtensionConstTypePtr *p_args, GDExtensionTypePtr r_ret);

typedef struct {
 GDExtensionStringNamePtr name;
 void *method_userdata;
 GDExtensionClassMethodCall call_func;
 GDExtensionClassMethodPtrCall ptrcall_func;
 uint32_t method_flags;


 GDExtensionBool has_return_value;
 GDExtensionPropertyInfo *return_value_info;
 GDExtensionClassMethodArgumentMetadata return_value_metadata;




 uint32_t argument_count;
 GDExtensionPropertyInfo *arguments_info;
 GDExtensionClassMethodArgumentMetadata *arguments_metadata;


 uint32_t default_argument_count;
 GDExtensionVariantPtr *default_arguments;
} GDExtensionClassMethodInfo;



typedef void *GDExtensionScriptInstanceDataPtr;

typedef GDExtensionBool (*GDExtensionScriptInstanceSet)(GDExtensionScriptInstanceDataPtr p_instance, GDExtensionConstStringNamePtr p_name, GDExtensionConstVariantPtr p_value);
typedef GDExtensionBool (*GDExtensionScriptInstanceGet)(GDExtensionScriptInstanceDataPtr p_instance, GDExtensionConstStringNamePtr p_name, GDExtensionVariantPtr r_ret);
typedef const GDExtensionPropertyInfo *(*GDExtensionScriptInstanceGetPropertyList)(GDExtensionScriptInstanceDataPtr p_instance, uint32_t *r_count);
typedef void (*GDExtensionScriptInstanceFreePropertyList)(GDExtensionScriptInstanceDataPtr p_instance, const GDExtensionPropertyInfo *p_list);
typedef GDExtensionVariantType (*GDExtensionScriptInstanceGetPropertyType)(GDExtensionScriptInstanceDataPtr p_instance, GDExtensionConstStringNamePtr p_name, GDExtensionBool *r_is_valid);

typedef GDExtensionBool (*GDExtensionScriptInstancePropertyCanRevert)(GDExtensionScriptInstanceDataPtr p_instance, GDExtensionConstStringNamePtr p_name);
typedef GDExtensionBool (*GDExtensionScriptInstancePropertyGetRevert)(GDExtensionScriptInstanceDataPtr p_instance, GDExtensionConstStringNamePtr p_name, GDExtensionVariantPtr r_ret);

typedef GDExtensionObjectPtr (*GDExtensionScriptInstanceGetOwner)(GDExtensionScriptInstanceDataPtr p_instance);
typedef void (*GDExtensionScriptInstancePropertyStateAdd)(GDExtensionConstStringNamePtr p_name, GDExtensionConstVariantPtr p_value, void *p_userdata);
typedef void (*GDExtensionScriptInstanceGetPropertyState)(GDExtensionScriptInstanceDataPtr p_instance, GDExtensionScriptInstancePropertyStateAdd p_add_func, void *p_userdata);

typedef const GDExtensionMethodInfo *(*GDExtensionScriptInstanceGetMethodList)(GDExtensionScriptInstanceDataPtr p_instance, uint32_t *r_count);
typedef void (*GDExtensionScriptInstanceFreeMethodList)(GDExtensionScriptInstanceDataPtr p_instance, const GDExtensionMethodInfo *p_list);

typedef GDExtensionBool (*GDExtensionScriptInstanceHasMethod)(GDExtensionScriptInstanceDataPtr p_instance, GDExtensionConstStringNamePtr p_name);

typedef void (*GDExtensionScriptInstanceCall)(GDExtensionScriptInstanceDataPtr p_self, GDExtensionConstStringNamePtr p_method, const GDExtensionConstVariantPtr *p_args, GDExtensionInt p_argument_count, GDExtensionVariantPtr r_return, GDExtensionCallError *r_error);
typedef void (*GDExtensionScriptInstanceNotification)(GDExtensionScriptInstanceDataPtr p_instance, int32_t p_what);
typedef void (*GDExtensionScriptInstanceToString)(GDExtensionScriptInstanceDataPtr p_instance, GDExtensionBool *r_is_valid, GDExtensionStringPtr r_out);

typedef void (*GDExtensionScriptInstanceRefCountIncremented)(GDExtensionScriptInstanceDataPtr p_instance);
typedef GDExtensionBool (*GDExtensionScriptInstanceRefCountDecremented)(GDExtensionScriptInstanceDataPtr p_instance);

typedef GDExtensionObjectPtr (*GDExtensionScriptInstanceGetScript)(GDExtensionScriptInstanceDataPtr p_instance);
typedef GDExtensionBool (*GDExtensionScriptInstanceIsPlaceholder)(GDExtensionScriptInstanceDataPtr p_instance);

typedef void *GDExtensionScriptLanguagePtr;

typedef GDExtensionScriptLanguagePtr (*GDExtensionScriptInstanceGetLanguage)(GDExtensionScriptInstanceDataPtr p_instance);

typedef void (*GDExtensionScriptInstanceFree)(GDExtensionScriptInstanceDataPtr p_instance);

typedef void *GDExtensionScriptInstancePtr;

typedef struct {
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

} GDExtensionScriptInstanceInfo;



typedef struct {
 uint32_t version_major;
 uint32_t version_minor;
 uint32_t version_patch;
 const char *version_string;



 void *(*mem_alloc)(size_t p_bytes);
 void *(*mem_realloc)(void *p_ptr, size_t p_bytes);
 void (*mem_free)(void *p_ptr);

 void (*print_error)(const char *p_description, const char *p_function, const char *p_file, int32_t p_line, GDExtensionBool p_editor_notify);
 void (*print_error_with_message)(const char *p_description, const char *p_message, const char *p_function, const char *p_file, int32_t p_line, GDExtensionBool p_editor_notify);
 void (*print_warning)(const char *p_description, const char *p_function, const char *p_file, int32_t p_line, GDExtensionBool p_editor_notify);
 void (*print_warning_with_message)(const char *p_description, const char *p_message, const char *p_function, const char *p_file, int32_t p_line, GDExtensionBool p_editor_notify);
 void (*print_script_error)(const char *p_description, const char *p_function, const char *p_file, int32_t p_line, GDExtensionBool p_editor_notify);
 void (*print_script_error_with_message)(const char *p_description, const char *p_message, const char *p_function, const char *p_file, int32_t p_line, GDExtensionBool p_editor_notify);

 uint64_t (*get_native_struct_size)(GDExtensionConstStringNamePtr p_name);




 void (*variant_new_copy)(GDExtensionVariantPtr r_dest, GDExtensionConstVariantPtr p_src);
 void (*variant_new_nil)(GDExtensionVariantPtr r_dest);
 void (*variant_destroy)(GDExtensionVariantPtr p_self);


 void (*variant_call)(GDExtensionVariantPtr p_self, GDExtensionConstStringNamePtr p_method, const GDExtensionConstVariantPtr *p_args, GDExtensionInt p_argument_count, GDExtensionVariantPtr r_return, GDExtensionCallError *r_error);
 void (*variant_call_static)(GDExtensionVariantType p_type, GDExtensionConstStringNamePtr p_method, const GDExtensionConstVariantPtr *p_args, GDExtensionInt p_argument_count, GDExtensionVariantPtr r_return, GDExtensionCallError *r_error);
 void (*variant_evaluate)(GDExtensionVariantOperator p_op, GDExtensionConstVariantPtr p_a, GDExtensionConstVariantPtr p_b, GDExtensionVariantPtr r_return, GDExtensionBool *r_valid);
 void (*variant_set)(GDExtensionVariantPtr p_self, GDExtensionConstVariantPtr p_key, GDExtensionConstVariantPtr p_value, GDExtensionBool *r_valid);
 void (*variant_set_named)(GDExtensionVariantPtr p_self, GDExtensionConstStringNamePtr p_key, GDExtensionConstVariantPtr p_value, GDExtensionBool *r_valid);
 void (*variant_set_keyed)(GDExtensionVariantPtr p_self, GDExtensionConstVariantPtr p_key, GDExtensionConstVariantPtr p_value, GDExtensionBool *r_valid);
 void (*variant_set_indexed)(GDExtensionVariantPtr p_self, GDExtensionInt p_index, GDExtensionConstVariantPtr p_value, GDExtensionBool *r_valid, GDExtensionBool *r_oob);
 void (*variant_get)(GDExtensionConstVariantPtr p_self, GDExtensionConstVariantPtr p_key, GDExtensionVariantPtr r_ret, GDExtensionBool *r_valid);
 void (*variant_get_named)(GDExtensionConstVariantPtr p_self, GDExtensionConstStringNamePtr p_key, GDExtensionVariantPtr r_ret, GDExtensionBool *r_valid);
 void (*variant_get_keyed)(GDExtensionConstVariantPtr p_self, GDExtensionConstVariantPtr p_key, GDExtensionVariantPtr r_ret, GDExtensionBool *r_valid);
 void (*variant_get_indexed)(GDExtensionConstVariantPtr p_self, GDExtensionInt p_index, GDExtensionVariantPtr r_ret, GDExtensionBool *r_valid, GDExtensionBool *r_oob);
 GDExtensionBool (*variant_iter_init)(GDExtensionConstVariantPtr p_self, GDExtensionVariantPtr r_iter, GDExtensionBool *r_valid);
 GDExtensionBool (*variant_iter_next)(GDExtensionConstVariantPtr p_self, GDExtensionVariantPtr r_iter, GDExtensionBool *r_valid);
 void (*variant_iter_get)(GDExtensionConstVariantPtr p_self, GDExtensionVariantPtr r_iter, GDExtensionVariantPtr r_ret, GDExtensionBool *r_valid);
 GDExtensionInt (*variant_hash)(GDExtensionConstVariantPtr p_self);
 GDExtensionInt (*variant_recursive_hash)(GDExtensionConstVariantPtr p_self, GDExtensionInt p_recursion_count);
 GDExtensionBool (*variant_hash_compare)(GDExtensionConstVariantPtr p_self, GDExtensionConstVariantPtr p_other);
 GDExtensionBool (*variant_booleanize)(GDExtensionConstVariantPtr p_self);
 void (*variant_duplicate)(GDExtensionConstVariantPtr p_self, GDExtensionVariantPtr r_ret, GDExtensionBool p_deep);
 void (*variant_stringify)(GDExtensionConstVariantPtr p_self, GDExtensionStringPtr r_ret);

 GDExtensionVariantType (*variant_get_type)(GDExtensionConstVariantPtr p_self);
 GDExtensionBool (*variant_has_method)(GDExtensionConstVariantPtr p_self, GDExtensionConstStringNamePtr p_method);
 GDExtensionBool (*variant_has_member)(GDExtensionVariantType p_type, GDExtensionConstStringNamePtr p_member);
 GDExtensionBool (*variant_has_key)(GDExtensionConstVariantPtr p_self, GDExtensionConstVariantPtr p_key, GDExtensionBool *r_valid);
 void (*variant_get_type_name)(GDExtensionVariantType p_type, GDExtensionStringPtr r_name);
 GDExtensionBool (*variant_can_convert)(GDExtensionVariantType p_from, GDExtensionVariantType p_to);
 GDExtensionBool (*variant_can_convert_strict)(GDExtensionVariantType p_from, GDExtensionVariantType p_to);


 GDExtensionVariantFromTypeConstructorFunc (*get_variant_from_type_constructor)(GDExtensionVariantType p_type);
 GDExtensionTypeFromVariantConstructorFunc (*get_variant_to_type_constructor)(GDExtensionVariantType p_type);
 GDExtensionPtrOperatorEvaluator (*variant_get_ptr_operator_evaluator)(GDExtensionVariantOperator p_operator, GDExtensionVariantType p_type_a, GDExtensionVariantType p_type_b);
 GDExtensionPtrBuiltInMethod (*variant_get_ptr_builtin_method)(GDExtensionVariantType p_type, GDExtensionConstStringNamePtr p_method, GDExtensionInt p_hash);
 GDExtensionPtrConstructor (*variant_get_ptr_constructor)(GDExtensionVariantType p_type, int32_t p_constructor);
 GDExtensionPtrDestructor (*variant_get_ptr_destructor)(GDExtensionVariantType p_type);
 void (*variant_construct)(GDExtensionVariantType p_type, GDExtensionVariantPtr p_base, const GDExtensionConstVariantPtr *p_args, int32_t p_argument_count, GDExtensionCallError *r_error);
 GDExtensionPtrSetter (*variant_get_ptr_setter)(GDExtensionVariantType p_type, GDExtensionConstStringNamePtr p_member);
 GDExtensionPtrGetter (*variant_get_ptr_getter)(GDExtensionVariantType p_type, GDExtensionConstStringNamePtr p_member);
 GDExtensionPtrIndexedSetter (*variant_get_ptr_indexed_setter)(GDExtensionVariantType p_type);
 GDExtensionPtrIndexedGetter (*variant_get_ptr_indexed_getter)(GDExtensionVariantType p_type);
 GDExtensionPtrKeyedSetter (*variant_get_ptr_keyed_setter)(GDExtensionVariantType p_type);
 GDExtensionPtrKeyedGetter (*variant_get_ptr_keyed_getter)(GDExtensionVariantType p_type);
 GDExtensionPtrKeyedChecker (*variant_get_ptr_keyed_checker)(GDExtensionVariantType p_type);
 void (*variant_get_constant_value)(GDExtensionVariantType p_type, GDExtensionConstStringNamePtr p_constant, GDExtensionVariantPtr r_ret);
 GDExtensionPtrUtilityFunction (*variant_get_ptr_utility_function)(GDExtensionConstStringNamePtr p_function, GDExtensionInt p_hash);


 void (*string_new_with_latin1_chars)(GDExtensionStringPtr r_dest, const char *p_contents);
 void (*string_new_with_utf8_chars)(GDExtensionStringPtr r_dest, const char *p_contents);
 void (*string_new_with_utf16_chars)(GDExtensionStringPtr r_dest, const char16_t *p_contents);
 void (*string_new_with_utf32_chars)(GDExtensionStringPtr r_dest, const char32_t *p_contents);
 void (*string_new_with_wide_chars)(GDExtensionStringPtr r_dest, const wchar_t *p_contents);
 void (*string_new_with_latin1_chars_and_len)(GDExtensionStringPtr r_dest, const char *p_contents, GDExtensionInt p_size);
 void (*string_new_with_utf8_chars_and_len)(GDExtensionStringPtr r_dest, const char *p_contents, GDExtensionInt p_size);
 void (*string_new_with_utf16_chars_and_len)(GDExtensionStringPtr r_dest, const char16_t *p_contents, GDExtensionInt p_size);
 void (*string_new_with_utf32_chars_and_len)(GDExtensionStringPtr r_dest, const char32_t *p_contents, GDExtensionInt p_size);
 void (*string_new_with_wide_chars_and_len)(GDExtensionStringPtr r_dest, const wchar_t *p_contents, GDExtensionInt p_size);
# 500 "gdextension_interface.h"
 GDExtensionInt (*string_to_latin1_chars)(GDExtensionConstStringPtr p_self, char *r_text, GDExtensionInt p_max_write_length);
 GDExtensionInt (*string_to_utf8_chars)(GDExtensionConstStringPtr p_self, char *r_text, GDExtensionInt p_max_write_length);
 GDExtensionInt (*string_to_utf16_chars)(GDExtensionConstStringPtr p_self, char16_t *r_text, GDExtensionInt p_max_write_length);
 GDExtensionInt (*string_to_utf32_chars)(GDExtensionConstStringPtr p_self, char32_t *r_text, GDExtensionInt p_max_write_length);
 GDExtensionInt (*string_to_wide_chars)(GDExtensionConstStringPtr p_self, wchar_t *r_text, GDExtensionInt p_max_write_length);
 char32_t *(*string_operator_index)(GDExtensionStringPtr p_self, GDExtensionInt p_index);
 const char32_t *(*string_operator_index_const)(GDExtensionConstStringPtr p_self, GDExtensionInt p_index);

 void (*string_operator_plus_eq_string)(GDExtensionStringPtr p_self, GDExtensionConstStringPtr p_b);
 void (*string_operator_plus_eq_char)(GDExtensionStringPtr p_self, char32_t p_b);
 void (*string_operator_plus_eq_cstr)(GDExtensionStringPtr p_self, const char *p_b);
 void (*string_operator_plus_eq_wcstr)(GDExtensionStringPtr p_self, const wchar_t *p_b);
 void (*string_operator_plus_eq_c32str)(GDExtensionStringPtr p_self, const char32_t *p_b);



 GDExtensionInt (*xml_parser_open_buffer)(GDExtensionObjectPtr p_instance, const uint8_t *p_buffer, size_t p_size);



 void (*file_access_store_buffer)(GDExtensionObjectPtr p_instance, const uint8_t *p_src, uint64_t p_length);
 uint64_t (*file_access_get_buffer)(GDExtensionConstObjectPtr p_instance, uint8_t *p_dst, uint64_t p_length);



 int64_t (*worker_thread_pool_add_native_group_task)(GDExtensionObjectPtr p_instance, void (*p_func)(void *, uint32_t), void *p_userdata, int p_elements, int p_tasks, GDExtensionBool p_high_priority, GDExtensionConstStringPtr p_description);
 int64_t (*worker_thread_pool_add_native_task)(GDExtensionObjectPtr p_instance, void (*p_func)(void *), void *p_userdata, GDExtensionBool p_high_priority, GDExtensionConstStringPtr p_description);



 uint8_t *(*packed_byte_array_operator_index)(GDExtensionTypePtr p_self, GDExtensionInt p_index);
 const uint8_t *(*packed_byte_array_operator_index_const)(GDExtensionConstTypePtr p_self, GDExtensionInt p_index);

 GDExtensionTypePtr (*packed_color_array_operator_index)(GDExtensionTypePtr p_self, GDExtensionInt p_index);
 GDExtensionTypePtr (*packed_color_array_operator_index_const)(GDExtensionConstTypePtr p_self, GDExtensionInt p_index);

 float *(*packed_float32_array_operator_index)(GDExtensionTypePtr p_self, GDExtensionInt p_index);
 const float *(*packed_float32_array_operator_index_const)(GDExtensionConstTypePtr p_self, GDExtensionInt p_index);
 double *(*packed_float64_array_operator_index)(GDExtensionTypePtr p_self, GDExtensionInt p_index);
 const double *(*packed_float64_array_operator_index_const)(GDExtensionConstTypePtr p_self, GDExtensionInt p_index);

 int32_t *(*packed_int32_array_operator_index)(GDExtensionTypePtr p_self, GDExtensionInt p_index);
 const int32_t *(*packed_int32_array_operator_index_const)(GDExtensionConstTypePtr p_self, GDExtensionInt p_index);
 int64_t *(*packed_int64_array_operator_index)(GDExtensionTypePtr p_self, GDExtensionInt p_index);
 const int64_t *(*packed_int64_array_operator_index_const)(GDExtensionConstTypePtr p_self, GDExtensionInt p_index);

 GDExtensionStringPtr (*packed_string_array_operator_index)(GDExtensionTypePtr p_self, GDExtensionInt p_index);
 GDExtensionStringPtr (*packed_string_array_operator_index_const)(GDExtensionConstTypePtr p_self, GDExtensionInt p_index);

 GDExtensionTypePtr (*packed_vector2_array_operator_index)(GDExtensionTypePtr p_self, GDExtensionInt p_index);
 GDExtensionTypePtr (*packed_vector2_array_operator_index_const)(GDExtensionConstTypePtr p_self, GDExtensionInt p_index);
 GDExtensionTypePtr (*packed_vector3_array_operator_index)(GDExtensionTypePtr p_self, GDExtensionInt p_index);
 GDExtensionTypePtr (*packed_vector3_array_operator_index_const)(GDExtensionConstTypePtr p_self, GDExtensionInt p_index);

 GDExtensionVariantPtr (*array_operator_index)(GDExtensionTypePtr p_self, GDExtensionInt p_index);
 GDExtensionVariantPtr (*array_operator_index_const)(GDExtensionConstTypePtr p_self, GDExtensionInt p_index);
 void (*array_ref)(GDExtensionTypePtr p_self, GDExtensionConstTypePtr p_from);
 void (*array_set_typed)(GDExtensionTypePtr p_self, GDExtensionVariantType p_type, GDExtensionConstStringNamePtr p_class_name, GDExtensionConstVariantPtr p_script);



 GDExtensionVariantPtr (*dictionary_operator_index)(GDExtensionTypePtr p_self, GDExtensionConstVariantPtr p_key);
 GDExtensionVariantPtr (*dictionary_operator_index_const)(GDExtensionConstTypePtr p_self, GDExtensionConstVariantPtr p_key);



 void (*object_method_bind_call)(GDExtensionMethodBindPtr p_method_bind, GDExtensionObjectPtr p_instance, const GDExtensionConstVariantPtr *p_args, GDExtensionInt p_arg_count, GDExtensionVariantPtr r_ret, GDExtensionCallError *r_error);
 void (*object_method_bind_ptrcall)(GDExtensionMethodBindPtr p_method_bind, GDExtensionObjectPtr p_instance, const GDExtensionConstTypePtr *p_args, GDExtensionTypePtr r_ret);
 void (*object_destroy)(GDExtensionObjectPtr p_o);
 GDExtensionObjectPtr (*global_get_singleton)(GDExtensionConstStringNamePtr p_name);

 void *(*object_get_instance_binding)(GDExtensionObjectPtr p_o, void *p_token, const GDExtensionInstanceBindingCallbacks *p_callbacks);
 void (*object_set_instance_binding)(GDExtensionObjectPtr p_o, void *p_token, void *p_binding, const GDExtensionInstanceBindingCallbacks *p_callbacks);

 void (*object_set_instance)(GDExtensionObjectPtr p_o, GDExtensionConstStringNamePtr p_classname, GDExtensionClassInstancePtr p_instance);

 GDExtensionObjectPtr (*object_cast_to)(GDExtensionConstObjectPtr p_object, void *p_class_tag);
 GDExtensionObjectPtr (*object_get_instance_from_id)(GDObjectInstanceID p_instance_id);
 GDObjectInstanceID (*object_get_instance_id)(GDExtensionConstObjectPtr p_object);



 GDExtensionObjectPtr (*ref_get_object)(GDExtensionConstRefPtr p_ref);
 void (*ref_set_object)(GDExtensionRefPtr p_ref, GDExtensionObjectPtr p_object);



 GDExtensionScriptInstancePtr (*script_instance_create)(const GDExtensionScriptInstanceInfo *p_info, GDExtensionScriptInstanceDataPtr p_instance_data);



 GDExtensionObjectPtr (*classdb_construct_object)(GDExtensionConstStringNamePtr p_classname);
 GDExtensionMethodBindPtr (*classdb_get_method_bind)(GDExtensionConstStringNamePtr p_classname, GDExtensionConstStringNamePtr p_methodname, GDExtensionInt p_hash);
 void *(*classdb_get_class_tag)(GDExtensionConstStringNamePtr p_classname);




 void (*classdb_register_extension_class)(GDExtensionClassLibraryPtr p_library, GDExtensionConstStringNamePtr p_class_name, GDExtensionConstStringNamePtr p_parent_class_name, const GDExtensionClassCreationInfo *p_extension_funcs);
 void (*classdb_register_extension_class_method)(GDExtensionClassLibraryPtr p_library, GDExtensionConstStringNamePtr p_class_name, const GDExtensionClassMethodInfo *p_method_info);
 void (*classdb_register_extension_class_integer_constant)(GDExtensionClassLibraryPtr p_library, GDExtensionConstStringNamePtr p_class_name, GDExtensionConstStringNamePtr p_enum_name, GDExtensionConstStringNamePtr p_constant_name, GDExtensionInt p_constant_value, GDExtensionBool p_is_bitfield);
 void (*classdb_register_extension_class_property)(GDExtensionClassLibraryPtr p_library, GDExtensionConstStringNamePtr p_class_name, const GDExtensionPropertyInfo *p_info, GDExtensionConstStringNamePtr p_setter, GDExtensionConstStringNamePtr p_getter);
 void (*classdb_register_extension_class_property_group)(GDExtensionClassLibraryPtr p_library, GDExtensionConstStringNamePtr p_class_name, GDExtensionConstStringPtr p_group_name, GDExtensionConstStringPtr p_prefix);
 void (*classdb_register_extension_class_property_subgroup)(GDExtensionClassLibraryPtr p_library, GDExtensionConstStringNamePtr p_class_name, GDExtensionConstStringPtr p_subgroup_name, GDExtensionConstStringPtr p_prefix);
 void (*classdb_register_extension_class_signal)(GDExtensionClassLibraryPtr p_library, GDExtensionConstStringNamePtr p_class_name, GDExtensionConstStringNamePtr p_signal_name, const GDExtensionPropertyInfo *p_argument_info, GDExtensionInt p_argument_count);
 void (*classdb_unregister_extension_class)(GDExtensionClassLibraryPtr p_library, GDExtensionConstStringNamePtr p_class_name);

 void (*get_library_path)(GDExtensionClassLibraryPtr p_library, GDExtensionStringPtr r_path);

} GDExtensionInterface;



typedef enum {
 GDEXTENSION_INITIALIZATION_CORE,
 GDEXTENSION_INITIALIZATION_SERVERS,
 GDEXTENSION_INITIALIZATION_SCENE,
 GDEXTENSION_INITIALIZATION_EDITOR,
 GDEXTENSION_MAX_INITIALIZATION_LEVEL,
} GDExtensionInitializationLevel;

typedef struct {


 GDExtensionInitializationLevel minimum_initialization_level;

 void *userdata;

 void (*initialize)(void *userdata, GDExtensionInitializationLevel p_level);
 void (*deinitialize)(void *userdata, GDExtensionInitializationLevel p_level);
} GDExtensionInitialization;






typedef GDExtensionBool (*GDExtensionInitializationFunction)(const GDExtensionInterface *p_interface, GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization);

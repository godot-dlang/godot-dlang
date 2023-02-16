/// Templates for working with Godot's type system
module godot.api.types;

import godot;
import godot.abi.core;
import godot.abi.types;
import godot.api.traits;
import godot.api.reference;
import godot.script, godot.object;

import std.meta;

import std.sumtype;

/// 
struct BuiltInClass {
    String name;
}

/// 
alias TypeCategories = AliasSeq!(VariantType, BuiltInClass, Ref!Script);

/++
A specific Godot type in one of these type categories:
* A built-in class derived from GodotObject
* A Script extending GodotObject (either in D or another Godot scripting language)
* A Godot core type from the `godot` modules or a primitive (represented as a Variant.Type)

These are all the types that can be directly stored in a Godot Variant. D types
that are indirectly compatible with Variant are converted to one of these when
passed to Godot.
+/
alias GodotType = SumType!(TypeCategories);

/// Returns: `type` as a `T` if it is actually in type category `T`,
/// otherwise `defaultValue`
@nogc nothrow
T get(T)(in GodotType type, T defaultValue = T.init) {
    return type.match!((T t) => t, _ => defaultValue);
}

/// Is `type` in type category `T`?
@nogc nothrow
bool isCategory(T)(in GodotType type) {
    return type.match!((T t) => true, _ => false);
}

/// FIXME: GodotType can't currently work with String or Ref!Script at compile
/// time, when they're not yet loaded from Godot. That also breaks DTypeOf

/// GodotType of a compile-time D type.
/// If T is indirectly compatible with Godot, this returns the Godot type T would
/// be converted to when passed to Godot.
template GodotTypeOf(T) {
    version (none) {
        static if (extendsGodotBaseClass!T)
            enum GodotTypeOf = GodotType(NativeScriptTemplate!T.as!Script);
        else static if (isGodotBaseClass!T)
            enum GodotTypeOf = GodotType(BuiltInClass(String(T._GODOT_internal_name)));
    } else
        enum GodotTypeOf = GodotType(Variant.variantTypeOf!T);
}

// TODO: fix me
//static assert(GodotTypeOf!int == GodotType(Variant.Type.int_));
//static assert(GodotTypeOf!(float[]) == GodotType(Variant.Type.array));
//static assert(GodotTypeOf!(int[4]) == GodotType(Variant.Type.array));

/// D type of a compile-time GodotType
template DTypeOf(GodotType t) {
    static if (t.isCategory!(Variant.Type)) {
        alias DTypeOf = Variant.DType[get!(Variant.Type)(t)];
    } else
        static assert(0, "Class types aren't known at compile time because the Godot API is not yet loaded");
}

static foreach (alias C; TypeCategories)
    alias DTypeOf(C t) = DTypeOf!(GodotType(t));

// TODO: fix me
//static assert(is(DTypeOf!(Variant.Type.int_) == long));
//static assert(is(DTypeOf!(Variant.Type.array) == Array));

enum GodotError {
    ok,
    failed,
    unavailable,
    unconfigured,
    unauthorized,
    parameterRangeError,
    outOfMemory,
    fileNotFound,
    fileBadDrive,
    fileBadPath,
    fileNoPermission,
    fileAlreadyInUse,
    fileCantOpen,
    fileCantWrite,
    fileCantRead,
    fileUnrecognized,
    fileCorrupt,
    fileMissingDependencies,
    fileEof,
    cantOpen,
    cantCreate,
    queryFailed,
    alreadyInUse,
    locked,
    timeout,
    cantConnect,
    cantResolve,
    connectionError,
    cantAcquireResource,
    cantFork,
    invalidData,
    invalidParameter,
    alreadyExists,
    doesNotExist,
    databaseCantRead,
    databaseCantWrite,
    compilationFailed,
    methodNotFound,
    linkFailed,
    scriptFailed,
    cyclicLink,
    invalidDeclaration,
    duplicateSymbol,
    parseError,
    busy,
    skip,
    help,
    bug,
    printerOnFire,
    omfgThisIsVeryVeryBad,
    wtf = omfgThisIsVeryVeryBad,
}

alias real_t = float;

enum real_t CMP_EPSILON = 0.00001;
enum real_t CMP_EPSILON2 = (CMP_EPSILON * CMP_EPSILON);

enum real_t _PLANE_EQ_DOT_EPSILON = 0.999;
enum real_t _PLANE_EQ_D_EPSILON = 0.0001;
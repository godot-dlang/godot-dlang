/**
The most important data type in Godot.

Copyright:
Copyright (c) 2007-2022 Juan Linietsky, Ariel Manzur.
Copyright (c) 2014-2022 Godot Engine contributors (cf. AUTHORS.md)
Copyright (c) 2017-2018 Godot-D contributors
Copyright (c) 2022-2022 Godot-DLang contributors

License: $(LINK2 https://opensource.org/licenses/MIT, MIT License)


*/
module godot.variant;

import godot.abi;
import godot;
import godot.object;
import godot.d.traits;
import godot.d.reference;
import godot.script;
import godot.d.type;

import std.meta, std.traits;
import std.conv : text;
import std.range;

// for tests
import godot.node;
import godot.resource;

// FIXME ABI type should probably have its own `version`...
version (X86_64) {
    version (DigitalMars) {
        version (linux) version = GodotSystemV;
        version (OSX) version = GodotSystemV;
        version (Posix) version = GodotSystemV;
    }
}

/// User-defined Variant conversions.
/// For structs and classes, constructors and member functions can also be used.
unittest {
    struct A {
    }

    static assert(!Variant.compatible!A);

    struct B {
    }

    B to(T : B)(Variant v) {
        return B();
    }

    int to(T : Variant)(B b) {
        return 1;
    }

    static assert(Variant.compatible!B);

    struct C {
        this(Variant v) {
        }

        Variant to(T : Variant)() {
            return Variant(1);
        }
    }

    static assert(Variant.compatible!C);

    B b;
    C c;

    Variant vb = b;
    Variant vc = c;

    b = vb.as!B;
    c = vc.as!C;
}

/// 
enum VariantType {
    nil,

    // atomic types
    bool_,
    int_,
    float_,
    string,

    // math types

    vector2, // 5
    vector2i,
    rect2,
    rect2i,
    vector3,
    vector3i, // 10
    transform2d,
    vector4,
    vector4i,
    plane,
    quaternion,
    aabb,
    basis, // 15
    transform3d,
    projection,

    // misc types
    color,
    string_name,
    node_path,
    rid,
    object, // 20
    callable,
    signal,
    dictionary,
    array,

    // arrays
    packed_byte_array, // 25
    packed_int32_array,
    packed_int64_array,
    packed_float32_array,
    packed_float64_array,
    packed_string_array, // 30
    packed_vector2_array,
    packed_vector3_array,
    packed_color_array,
}

/**
Godot's tagged union type.

Primitives, Godot core types, and `GodotObject`-derived classes can be stored in
a Variant. Other user-defined D types can be made compatible with Variant by
defining `to!CustomType(Variant)` and `to!Variant(CustomType)` functions.

Properties and method arguments/returns are passed between Godot and D through
Variant, so these must use Variant-compatible types.
*/
struct Variant {
    package(godot) godot_variant _godot_variant;

    // having it inside variant creates annoying recursive alias issue
    alias Type = VariantType;

    /// GDNative type that gets passed to the C functions
    // NOTE: godot 4 now uses default int as int32 and double precision by default
    // TODO: verify this
    alias InternalType = AliasSeq!(
        typeof(null),

        godot_bool,
        int,
        double,
        godot_string,

        godot_vector2, // 5
        godot_vector2i,
        godot_rect2,
        godot_rect2i,
        godot_vector3,
        godot_vector3i, // 10
        godot_transform2d,
        godot_vector4,
        godot_vector4i,
        godot_plane,
        godot_quaternion,
        godot_aabb,
        godot_basis, // 15
        godot_transform3d,
        godot_projection,

        godot_color,
        godot_string, //godot_string_name
        godot_node_path,
        godot_rid, // 20
        godot_object,
        godot_callable,
        godot_signal,
        godot_dictionary,
        godot_array, // 25

        godot_packed_byte_array,
        godot_packed_int32_array,
        godot_packed_int64_array,
        godot_packed_float32_array,
        godot_packed_float64_array, // 30
        godot_packed_string_array,
        godot_packed_vector2_array,
        godot_packed_vector3_array,
        godot_packed_color_array,
    );

    /// D type that this Variant implementation uses
    alias DType = AliasSeq!(
        typeof(null),

        bool,
        long,
        double,
        String,

        Vector2, // 5
        Vector2i,
        Rect2,
        Rect2i,
        Vector3,
        Vector3i, // 10
        Transform2D,
        Vector4,
        Vector4i,
        Plane,
        Quaternion,
        AABB,
        Basis, // 15
        Transform3D,
        Projection,// misc types
        Color,
        StringName,
        NodePath,
        RID, // 20
        GodotObject,
        GodotCallable,
        GodotSignal,
        Dictionary,
        Array, // 25

        // arrays
        PackedByteArray,
        PackedInt32Array,
        PackedInt64Array,
        PackedFloat32Array,
        PackedFloat64Array, // 30
        PackedStringArray,
        PackedVector2Array,
        PackedVector3Array,
        PackedColorArray,
    );

    /// 
    enum Operator {
        //comparation
        equal,
        notEqual,
        less,
        lessEqual,
        greater,
        greaterEqual,

        //mathematic
        add,
        substract,
        multiply,
        divide,
        negate,
        positive,
        modulus,
        power,
        //stringConcat,

        //bitwise
        shiftLeft,
        shiftRight,
        bitAnd,
        bitOr,
        bitXor,
        bitNegate,

        //logic
        and,
        or,
        xor,
        not,

        //containment
        in_
    }

    private enum bool implicit(Src, Dest) = is(Src : Dest) || isImplicitlyConvertible!(Src, Dest);

    private static GodotObject objectToGodot(T)(T o) {
        return o.getGodotObject;
    }

    // Conversions for non-core types provided by Variant.
    // Lower priority than user-defined `to` functions, to allow overriding
    // default blanket implementations.
    private alias internalAs(T) = (Variant v) => v.as!T;
    private enum bool hasInternalAs(T) = __traits(compiles, internalAs!T);
    private alias internalFrom(T) = (T t) => Variant.from(t);
    private enum bool hasInternalFrom(T) = __traits(compiles, internalFrom!T);

    ///
    T as(T)() const if (isStaticArray!T && compatibleFromGodot!(ElementType!T)) {
        return as!Array.as!T;
    }

    /// 
    T as(T)() const if (is(T : TypedArray!U, U...) && !is(U == Array)) {
        return T(as!Array);
    }

    T as(T : void*)() {
        return cast(T)&_godot_variant;
    }

    /// 
    T as(T)() const 
            if ((isGodotClass!T && !is(T == GodotObject)) || is(T : Ref!U, U)) {
        GodotObject o = cast()(as!GodotObject);
        return o.as!T;
    }

    ///
    static Array from(T)(T t)
            if ((isForwardRange!T || isStaticArray!T) && compatibleToGodot!(ElementType!T)) {
        return Array.from(t);
    }

    ///
    GodotType as(T : GodotType)() const {
        if (type == Type.object) {
            Ref!Script s = as!Script;
            if (s)
                return GodotType(s);
            else
                return GodotType.init;
        } else if (type == Type.string)
            return GodotType(BuiltInClass(as!String));
        else if (type == Type.int_)
            return GodotType(cast(Variant.Type)(as!int));
        else
            return GodotType.init;
    }

    ///
    static Variant from(T : GodotType)(T t) {
        import sumtype : match;

        Variant ret;
        t.match!(
            (Variant.Type t) { ret = cast(int) t; },
            (BuiltInClass c) { ret = c.name; },
            (Ref!Script s) { ret = s; }
        );
        return ret;
    }

    // TODO: fix me
    /*
	static assert(hasInternalAs!Node, internalAs!Node);
	static assert(hasInternalAs!(Ref!Resource), internalAs!(Ref!Resource));
	static assert(!hasInternalAs!Object); // `directlyCompatible` types not handled by internalAs
	static assert(hasInternalAs!(int[4]), internalAs!(int[4]));
	static assert(hasInternalFrom!(int[4]), internalFrom!(int[4]));
	static assert(!hasInternalAs!(int[]));
	static assert(hasInternalFrom!(int[]), internalFrom!(int[]));
	static assert(hasInternalAs!GodotType, internalAs!GodotType);
	static assert(hasInternalFrom!GodotType, internalFrom!GodotType);
	static assert(compatible!GodotType);
	*/

    private template getToVariantFunction(T) {
        mixin("import " ~ moduleName!T ~ ";");
        alias getToVariantFunction = (T t) { Variant v = t.to!Variant; return v; };
    }

    enum bool hasToVariantFunction(T) = __traits(compiles, getToVariantFunction!T);

    private template getVariantConstructor(T) {
        alias getVariantConstructor = (Variant v) => T(v);
    }

    enum bool hasVariantConstructor(T) = __traits(compiles, getVariantConstructor!T);

    template getFromVariantFunction(T) {
        mixin("import " ~ moduleName!T ~ ";");
        alias getFromVariantFunction = (Variant v) { T ret = v.to!T; return ret; };
    }

    enum bool hasFromVariantFunction(T) = __traits(compiles, getFromVariantFunction!T);

    /// function to convert T to an equivalent Godot type
    template conversionToGodot(T) {
        static if (isGodotClass!T)
            alias conversionToGodot = objectToGodot!T;
        else static if (is(T : GodotStringLiteral!s, string s))
            alias conversionToGodot = (T t) => t.str();
        else static if (is(T : Ref!U, U))
            alias conversionToGodot = objectToGodot!U;
        else static if (isIntegral!T)
            alias conversionToGodot = (T t) => cast(long) t;
        else static if (isFloatingPoint!T)
            alias conversionToGodot = (T t) => cast(double) t;
        else static if (implicit!(T, const(char)[]) || implicit!(T, const(char)*))
            alias conversionToGodot = (T t) => String(t);
        else static if (hasToVariantFunction!T) {
            alias conversionToGodot = getToVariantFunction!T;
        } else static if (hasInternalFrom!T)
            alias conversionToGodot = internalFrom!T;
        else
            alias conversionToGodot = void; // none
    }

    enum bool convertsToGodot(T) = isCallable!(conversionToGodot!T);
    alias conversionToGodotType(T) = Unqual!(ReturnType!(conversionToGodot!T));

    /// function to convert a Godot-compatible type to T
    template conversionFromGodot(T) {
        static if (isIntegral!T)
            alias conversionFromGodot = (long v) => cast(T) v;
        else static if (isFloatingPoint!T)
            alias conversionFromGodot = (double v) => cast(T) v;
        else static if (hasVariantConstructor!T) {
            alias conversionFromGodot = getVariantConstructor!T;
        } else static if (hasFromVariantFunction!T) {
            alias conversionFromGodot = getFromVariantFunction!T;
        } else
            alias conversionFromGodot = void;
    }

    enum bool convertsFromGodot(T) = isCallable!(conversionFromGodot!T);
    alias conversionFromGodotType(T) = Unqual!(Parameters!(conversionFromGodot!T)[0]);

    enum bool directlyCompatible(T) = staticIndexOf!(Unqual!T, DType) != -1;
    template compatibleToGodot(T) {
        static if (directlyCompatible!T)
            enum bool compatibleToGodot = true;
        else
            enum bool compatibleToGodot = convertsToGodot!T;
    }

    template compatibleFromGodot(T) {
        static if (directlyCompatible!T)
            enum bool compatibleFromGodot = true;
        else static if (hasInternalAs!T)
            enum bool compatibleFromGodot = true;
        else
            enum bool compatibleFromGodot = convertsFromGodot!T;
    }

    enum bool compatible(R) = compatibleToGodot!(R) && compatibleFromGodot!(R);

    /// All target Variant.Types that T could implicitly convert to, as indices
    private template implicitTargetIndices(T) {
        private enum bool _implicit(size_t di) = implicit!(T, DType[di]);
        alias implicitTargetIndices = Filter!(_implicit, aliasSeqOf!(iota(DType.length)));
    }

    /++
	Get the Variant.Type of a compatible D type. Incompatible types return nil.
	+/
    public template variantTypeOf(T) {
        import std.traits, godot;

        static if (directlyCompatible!T) {
            enum Type variantTypeOf = EnumMembers!Type[staticIndexOf!(Unqual!T, DType)];
        } else static if (convertsToGodot!T) {
            static if (is(conversionToGodotType!T : Variant))
                enum Type variantTypeOf = Type.nil;
            else
                enum Type variantTypeOf = EnumMembers!Type[staticIndexOf!(
                            conversionToGodotType!T, DType)];
        } else
            enum Type variantTypeOf = Type.nil; // so the template always returns a Type
    }

    /// 
    R as(R)() const 
            if (!is(R == Variant) && !is(R == typeof(null)) && (convertsFromGodot!R || directlyCompatible!R)) {
        static if (directlyCompatible!R)
            enum VarType = variantTypeOf!R;
        else static if (is(conversionFromGodotType!R : Variant))
            enum VarType = Type.nil;
        else
            enum VarType = EnumMembers!Type[staticIndexOf!(conversionFromGodotType!R, DType)];

        // HACK workaround for DMD issue #5570
        version (GodotSystemV)
            enum sV = true;
        else
            enum sV = false;
        static if (VarType == Type.vector3 && sV) {
            godot_vector3 ret = void;
            void* _func = cast(void*) _godot_api.variant_as_vector3;
            void* _this = cast(void*)&this;

            asm @nogc nothrow {
                mov RDI, _this;
                call _func;

                mov ret[0], RAX;
                mov ret[8], EDX;
            }
            return *cast(Vector3*)&ret;
        } else static if (VarType == Type.nil) {
            return conversionFromGodot!R(this);
        } else static if (is(Unqual!R == String)) {
            static if (is(Unqual!R == NodePath))
                godot_node_path str;
            else
                godot_string str;
            _godot_api.variant_stringify(&_godot_variant, cast(void*)&str);
            return R(str);
        } else {
            DType[VarType] ret = void;
            //*cast(InternalType[VarType]*)&ret = mixin("_godot_api.variant_as_"~FunctionAs!VarType~"(&_godot_variant)");

            // this gives wrong result, try the other way around
            //auto fn = _godot_api.get_variant_from_type_constructor(VarType);
            //fn(cast(GDNativeVariantPtr) &_godot_variant, &ret);

            // special case such as calling function with null optional parameter
            if (_godot_variant._opaque.ptr is null) {
                return R.init;
            }

            auto fn = _godot_api.get_variant_to_type_constructor(VarType);
            fn(cast(void*)&ret, cast(void*)&_godot_variant);

            static if (directlyCompatible!R)
                return ret;
            else {
                return conversionFromGodot!R(ret);
            }
        }
    }

    this(R)(auto ref R input) if (!is(R : Variant) && !is(R : typeof(null))) {
        static assert(compatibleToGodot!R, R.stringof ~ " isn't compatible with Variant.");
        enum VarType = variantTypeOf!R;

        static if (VarType == Type.nil) {
            this = conversionToGodot!R(input);
        } else {
            //mixin("auto Fn = _godot_api.variant_new_"~FunctionNew!VarType~";");
            auto Fn = _godot_api.get_variant_from_type_constructor(VarType);
            alias PassType = Parameters!Fn[1]; // second param is the value

            alias IT = InternalType[VarType];

            // handle explicit conversions
            static if (directlyCompatible!R)
                alias inputConv = input;
            else
                auto inputConv = conversionToGodot!R(input);

            static if (is(IT == Unqual!PassType))
                Fn(&_godot_variant, cast(IT) inputConv); // value
            else
                Fn(&_godot_variant, cast(IT*)&inputConv); // pointer
        }
    }

    pragma(inline, true)
    void opAssign(T)(in auto ref T input)
            if (!is(T : Variant) && !is(T : typeof(null)) && !is(Unqual!T : void*)) {
        import std.conv : emplace;

        _godot_api.variant_destroy(&_godot_variant);
        static if (is(T : TypedArray!Args, Args...)) {
            // hacky way, for some reasons 'alias this' was ignored
            emplace!(Variant)(&this, input._array);
        } else {
            emplace!(Variant)(&this, input);
        }
    }

    // internal use only, but can be useful for users who knows what they are doing
    // used in few cases only, audioeffect.process() as a buffer is one example
    pragma(inline, true)
    package(godot) void opAssign(const void* input) {
        // can it be messed up by alignment?
        _godot_variant = *cast(godot_variant*) input;
    }

    static assert(allSatisfy!(compatible, DType));
    static assert(!compatible!Object); // D Object

    static assert(directlyCompatible!GodotObject);
    static assert(directlyCompatible!(const(GodotObject)));
    static assert(!directlyCompatible!Node);
    // TODO: fix me
    //static assert(compatibleFromGodot!Node);
    static assert(compatibleToGodot!Node);
    // TODO: fix me
    //static assert(compatibleFromGodot!(const(Node)));
    static assert(compatibleToGodot!(const(Node)));
    static assert(!directlyCompatible!(Ref!Resource));
    // TODO: fix me
    //static assert(compatibleFromGodot!(Ref!Resource));
    static assert(compatibleToGodot!(Ref!Resource));
    // TODO: fix me
    //static assert(compatibleFromGodot!(const(Ref!Resource)));
    static assert(compatibleToGodot!(const(Ref!Resource)));

    private template FunctionAs(Type type) {
        private enum string name_ = text(type);
        private enum string FunctionAs = (name_[$ - 1] == '_') ? (name_[0 .. $ - 1]) : name_;
    }

    private template FunctionNew(Type type) {
        private enum string name_ = text(type);
        private enum string FunctionNew = (name_[$ - 1] == '_') ? (name_[0 .. $ - 1]) : name_;
    }

    //@nogc nothrow:
    this(this) {
        godot_variant other = _godot_variant; // source Variant still owns this
        _godot_api.variant_new_copy(&_godot_variant, &other);
    }

    static Variant nil() {
        Variant v = void;
        _godot_api.variant_new_nil(&v._godot_variant);
        return v;
    }

    this(in ref Variant other) {
        _godot_api.variant_new_copy(&_godot_variant, &other._godot_variant);
    }

    this(T : typeof(null))(in T nil) {
        _godot_api.variant_new_nil(&_godot_variant);
    }

    ~this() {
        // TODO: need to check this, causes broken values after several Variant to variant assignments
        _godot_api.variant_destroy(&_godot_variant);
    }

    Type type() const {
        return cast(Type) _godot_api.variant_get_type(&_godot_variant);
    }

    inout(T) as(T : Variant)() inout {
        return this;
    }

    pragma(inline, true)
    void opAssign(T : typeof(null))(in T nil) {
        _godot_api.variant_destroy(&_godot_variant);
        _godot_api.variant_new_nil(&_godot_variant);
    }

    pragma(inline, true)
    void opAssign(T : Variant)(in T other) {
        _godot_api.variant_destroy(&_godot_variant);
        _godot_api.variant_new_copy(&_godot_variant, &other._godot_variant);
    }

    bool opEquals(in ref Variant other) const {
        Variant ret;
        bool valid;
        evaluate(GDNATIVE_VARIANT_OP_EQUAL, this, other, ret, valid);
        return ret.as!bool;
        //return cast(bool)_godot_api.variant_operator_equal(&_godot_variant, &other._godot_variant);
    }

    private void evaluate(int op, ref const Variant a, ref const Variant b, ref Variant ret, ref bool isValid) const {
        GDNativeBool res;
        _godot_api.variant_evaluate(op, &a._godot_variant, &b._godot_variant, &ret._godot_variant, &res);
        isValid = !!res;
    }

    int opCmp(in ref Variant other) const {
        Variant res;
        bool valid;
        evaluate(GDNATIVE_VARIANT_OP_EQUAL, this, other, res, valid);
        if (res.as!bool)
            return 0;
        evaluate(GDNATIVE_VARIANT_OP_LESS, this, other, res, valid);
        return res.as!bool ? -1 : 1;
        //if(_godot_api.variant_operator_equal(&_godot_variant, &other._godot_variant))
        //	return 0;
        //return _godot_api.variant_operator_less(&_godot_variant, &other._godot_variant)?
        //	-1 : 1;
    }

    bool booleanize() const {
        return cast(bool) _godot_api.variant_booleanize(&_godot_variant);
    }

    auto toString() const {
        String str = as!String;
        return str.data;
    }

    /// Is this Variant of the specified `type` or of a subclass of `type`?
    bool isType(GodotType type) const {
        import sumtype : match;

        return type.match!(
            (Ref!Script script) {
            GodotObject o = this.as!GodotObject;
            if (o == null)
                return false;
            return script.instanceHas(o);
        },
            (BuiltInClass object) {
            GodotObject o = this.as!GodotObject;
            if (o == null)
                return false;
            return o.isClass(object.name);
        },
            (Type vt) => this.type == vt
        );
    }

    /++
	The exact GodotType of the value stored in this Variant.

	To check if a Variant is a specific GodotType, use `isType` instead to
	account for inheritance.
	+/
    GodotType exactType() const {
        if (GodotObject o = this.as!GodotObject) {
            if (Ref!Script s = o.getScript().as!Script)
                return GodotType(s);
            else
                return GodotType(BuiltInClass(o.getClass()));
        } else
            return GodotType(this.type);
    }
}

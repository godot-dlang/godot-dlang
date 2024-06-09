/**
Memory-pool-based dynamic arrays. Optimized for memory usage, can’t fragment the memory.

Copyright:
Copyright (c) 2007 Juan Linietsky, Ariel Manzur.
Copyright (c) 2014 Godot Engine contributors (cf. AUTHORS.md)
Copyright (c) 2017 Godot-D contributors
Copyright (c) 2022 Godot-DLang contributors

License: $(LINK2 https://opensource.org/licenses/MIT, MIT License)


*/
module godot.poolarrays;

import godot.abi;
import godot.array;
import godot.api.types;
import godot.string;
import godot.color;
import godot.vector2;
import godot.vector3;
import godot.vector4;
import godot.builtins;
import extVersion = godot.apiinfo;

import std.range.primitives;
import std.meta, std.traits;

enum isGodot43orNewer = extVersion.VERSION_MINOR > 2;

private alias PackedArrayTypes = AliasSeq!(
    ubyte,
    int,
    long,
    float,
    double,
    // String,
    string,
    Vector2,
    Vector3,
    Vector4,
    Color,
);

// used in GDExtensionInterface.variant_get_ptr_destructor()
private alias PackedArrayVariantType = AliasSeq!(
    GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY,
    GDEXTENSION_VARIANT_TYPE_PACKED_INT32_ARRAY,
    GDEXTENSION_VARIANT_TYPE_PACKED_INT64_ARRAY,
    GDEXTENSION_VARIANT_TYPE_PACKED_FLOAT32_ARRAY,
    GDEXTENSION_VARIANT_TYPE_PACKED_FLOAT64_ARRAY,
    GDEXTENSION_VARIANT_TYPE_PACKED_STRING_ARRAY,
    GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR2_ARRAY,
    GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR3_ARRAY,
    GDEXTENSION_VARIANT_TYPE_PACKED_VECTOR4_ARRAY,
    GDEXTENSION_VARIANT_TYPE_PACKED_COLOR_ARRAY,
);

private enum string nameOverride(T) = AliasSeq!(
        "byte", "int32", "int64", "float32", "float64", "string",
        "vector2", "vector3", "vector4", "color")[staticIndexOf!(T, PackedArrayTypes)];

private enum string bindNameOverride(T) = AliasSeq!(
        "Byte", "Int32", "Int64", "Float32", "Float64", "String",
        "Vector2", "Vector3", "Vector4", "Color")[staticIndexOf!(T, PackedArrayTypes)];

private enum string opaqueName(T) = "godot_packed_" ~ (nameOverride!T) ~ "_array";
private enum string typeName(T) = "packed_" ~ (nameOverride!T) ~ "_array";
private enum string readName(T) = "packed_" ~ (nameOverride!T) ~ "_array_operator_index_const";
private enum string writeName(T) = "packed_" ~ (nameOverride!T) ~ "_array_operator_index";

alias PackedByteArray = PackedArray!ubyte;
alias PackedInt32Array = PackedArray!int;
alias PackedInt64Array = PackedArray!long;
alias PackedFloat32Array = PackedArray!float;
alias PackedFloat64Array = PackedArray!double;
// alias PackedStringArray = PackedArray!String;
alias PackedStringArray = PackedArray!string;
alias PackedVector2Array = PackedArray!Vector2;
//alias PackedVector2iArray = PackedArray!Vector2i;
alias PackedVector3Array = PackedArray!Vector3;
//alias PackedVector3iArray = PackedArray!Vector3i;
alias PackedColorArray = PackedArray!Color;
alias PackedVector4Array = PackedArray!Vector4;

/++
Copy-on-write array for some Godot types, allocated with a memory pool.
+/
struct PackedArray(T) if (!is(T == Vector4) || isGodot43orNewer) {
    //@nogc nothrow:

    // godot type name, e.g. "PackedVector3Array"
    package(godot) enum InternalName = "Packed" ~ bindNameOverride!T ~ "Array";

    static assert(staticIndexOf!(T, PackedArrayTypes) != -1,
        "Cannot make a Godot PackedArray for a non-Godot type");

    // TODO: this is now gone, replace with real array
    //mixin("package(godot) "~(typeName!T)~" _godot_array;");

    package(godot) union _PackedArray {
        OPAQUE_TYPE _godot_array;
        mixin("Packed" ~ bindNameOverride!T ~ "Array_Bind _bind;");
    }

    package(godot) _PackedArray _packed_array;
    alias _packed_array this;

    alias VARIANT_TYPE = PackedArrayVariantType[staticIndexOf!(T, PackedArrayTypes)];
    alias OPAQUE_TYPE = mixin(opaqueName!T);

    this(ref const PackedArray other) {
        auto ctor = gdextension_interface_variant_get_ptr_constructor(VARIANT_TYPE, 1);
        void*[1] args; 
        args[0] = cast(void*) other._godot_array._opaque.ptr;
        ctor(&_godot_array, cast(void**) args.ptr);
    }

    package(godot) this(OPAQUE_TYPE opaque) {
        _godot_array = opaque;
    }

    PackedArray opAssign(in PackedArray other) {
        auto dtor = gdextension_interface_variant_get_ptr_destructor(VARIANT_TYPE);
        auto ctor = gdextension_interface_variant_get_ptr_constructor(VARIANT_TYPE, 1);
        dtor(&_godot_array);

        void*[1] args; 
        args[0] = cast(void*) other._godot_array._opaque.ptr;
        ctor(&_godot_array, cast(void**) args.ptr);
        return this;
    }

    /++
	C API type to pass to/from C functions
	+/
    static if (is(T == Vector2))
        private alias InternalType = godot_vector2;
    else static if (is(T == Vector3))
        private alias InternalType = godot_vector3;
    else static if (is(T == Vector4))
        private alias InternalType = godot_vector4;
    else static if (is(T == Color))
        private alias InternalType = godot_color;
    else
        private alias InternalType = T;

    this(in Array arr) {
        const(Array)*[1] ptr = [ &arr ];
        auto n = gdextension_interface_variant_get_ptr_constructor(VARIANT_TYPE, 2);
        n(&_godot_array, cast(void**)ptr.ptr);
    }

    ///
    void pushBack(PackedArray arr) {
        _bind.appendArray(arr);
        //mixin("auto a = gdextension_interface_"~(typeName!T)~"_append_array;");
        //a(&_godot_array, &arr._godot_array);
    }

    deprecated("Use the concatenation operator ~= instead of append_array.") alias append_array = pushBack;

    void invert() {
        _bind.reverse();
        //mixin("auto i = gdextension_interface_"~(typeName!T)~"_invert;");
        //i(&_godot_array);
    }

    void remove(size_t idx) {
        _bind.removeAt(idx);
        //mixin("auto r = gdextension_interface_"~(typeName!T)~"_remove;");
        //r(&_godot_array, cast(int)idx);
    }

    void resize(size_t size) {
        _bind.resize(size);
        //mixin("auto r = gdextension_interface_"~(typeName!T)~"_resize;");
        //r(&_godot_array, cast(int)size);
    }

    size_t size() const {
        return cast(size_t) _bind.size();
        //mixin("auto s = gdextension_interface_"~(typeName!T)~"_size;");
        //return s(&_godot_array);
    }

    alias length = size; // D-style name for size
    alias opDollar = size;

    /// Returns: true if length is 0.
    bool empty() const {
        return length == 0;
    }

    ~this() {
        //auto d = gdextension_interface_variant_get_ptr_destructor(GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY)
        auto d = gdextension_interface_variant_get_ptr_destructor(VARIANT_TYPE);
        d(&_godot_array);
    }

    // a few functions are different for Strings than for the others:
    //static if(is(T == String))
    //{
    //	void pushBack(in String data)
    //	{
    //		gdextension_interface_packed_string_array_push_back(&_godot_array, &data._godot_string);
    //	}
    //	void insert(size_t idx, in String data)
    //	{
    //		gdextension_interface_packed_string_array_insert(&_godot_array, cast(int)idx, &data._godot_string);
    //	}
    //	void set(size_t idx, in String data)
    //	{
    //		gdextension_interface_packed_string_array_operator_index(&_godot_array, cast(int)idx) = &data._godot_string;
    //	}
    //	void opIndexAssign(in String data, size_t idx)
    //	{
    //		gdextension_interface_packed_string_array_operator_index(&_godot_array, cast(int)idx) = &data._godot_string;
    //	}
    //	String opIndex(size_t idx) const
    //	{
    //		String ret = void;
    //		ret._godot_string = godot_string(cast(size_t)  gdextension_interface_packed_string_array_operator_index_const(&_godot_array, cast(int)idx));
    //		return ret;
    //	}
    //}
    //else
    //{
    void pushBack(in T data) {
        _bind.pushBack(data);
        //mixin("auto p = gdextension_interface_"~(typeName!T)~"_push_back;");
        //static if(is(T==Vector2) || is(T==Vector3) || is(T==Color))
        //	p(&_godot_array, cast(InternalType*)&data);
        //else p(&_godot_array, data);
    }

    void insert(size_t idx, in T data) {
        _bind.insert(idx, data);
        //mixin("auto i = gdextension_interface_"~(typeName!T)~"_insert;");
        //static if(is(T==Vector2) || is(T==Vector3) || is(T==Color))
        //	i(&_godot_array, cast(int)idx, cast(InternalType*)&data);
        //else i(&_godot_array, cast(int)idx, data);
    }

    void set(size_t idx, in T data) {
        _bind.set(idx, data);
        //mixin("auto s = gdextension_interface_"~(typeName!T)~"_set;");
        //static if(is(T==Vector2) || is(T==Vector3) || is(T==Color))
        //	s(&_godot_array, cast(int)idx, cast(InternalType*)&data);
        //else s(&_godot_array, cast(int)idx, data);
    }
    //}

    ///
    alias append = pushBack;
    ///
    template opOpAssign(string op) if (op == "~" || op == "+") {
        alias opOpAssign = pushBack;
    }

    ///
    PackedArray opBinary(string op)(in ref PackedArray other) const 
            if (op == "~" || op == "+") {
        PackedArray ret = this;
        ret ~= other;
        return ret;
    }

    T[] data() return @trusted {
        return (&opIndex(0))[0 .. length];
    }

    const(T)[] data() const return @trusted {
        return (&opIndex(0))[0 .. length];
    }

    ref T opIndex(size_t idx) return @trusted {
        alias fn = mixin("gdextension_interface_", writeName!T);
        return *cast(T*) fn(&_godot_array, cast(int) idx);
    }

    ref const(T) opIndex(size_t idx) const return @trusted {
        alias fn = mixin("gdextension_interface_", readName!T);
        return *cast(const(T)*) fn(&_godot_array, cast(int) idx);
    }
}

struct PackedArray(T) if (is(T == Vector4) && !isGodot43orNewer) {
    // doesn't exist in Godot 4.2 but needed to make it compile
}

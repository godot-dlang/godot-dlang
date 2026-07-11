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
import godot.variant;
import godot.vector2;
import godot.vector3;
import godot.vector4;
import godot.builtins;
import extVersion = godot.apiinfo;

import std.range.primitives;
import std.meta, std.traits;

enum isGodot43orNewer = extVersion.VERSION_MINOR > 2;
enum isGodot44orNewer = extVersion.VERSION_MINOR > 3;
enum isGodot45orNewer = extVersion.VERSION_MINOR > 4;
enum isGodot46orNewer = extVersion.VERSION_MINOR > 5;

private alias PackedArrayTypes = AliasSeq!(
    ubyte,
    int,
    long,
    float,
    double,
    String,
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
alias PackedStringArray = PackedArray!String;
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

    // a helper for D native arrays
    static if(is(T == ubyte))
    this(in int[] arr) {
        this(Array.from(arr));
    }

    ///
    void appendArray(PackedArray arr) {
        _bind.appendArray(arr);
    }

    ///
    deprecated("Old name used in older Godot versions. Use reverse() instead.") alias inverse = reverse;

    ///
    void reverse() {
        _bind.reverse();
    }

    bool erase(in T value) {
        // added in v4.5+
        static if (isGodot45orNewer) {
            return _bind.erase(value);
        } else {
            size_t idx = find(value);
            if (idx != -1) {
                removeAt(idx);
                return true;
            }
		    return false;
        }
    }

    /// 
    deprecated("Use removeAt instead") alias remove = removeAt;

    void removeAt(size_t idx) {
        _bind.removeAt(idx);
    }

    size_t resize(size_t size) {
        return _bind.resize(size);
    }

    size_t size() const {
        return cast(size_t) _bind.size();
    }

    alias length = size; // D-style name for size
    alias opDollar = size;

    ///
    alias isEmpty = empty;

    /// Returns: true if length is 0.
    bool empty() const {
        return length == 0;
    }

    ~this() {
        // this is what it expands to
        //auto d = gdextension_interface_variant_get_ptr_destructor(GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY)
        auto d = gdextension_interface_variant_get_ptr_destructor(VARIANT_TYPE);
        d(&_godot_array);
    }

    // a few helper functions for string/String convenience:
    static if(is(T == String))
    {
        bool append(in string str) {
            return append(String(str));
        }
        size_t bsearch(in string str, bool before = true) const {
            return bsearch(String(str), before);
        }
        size_t count(in string str) const {
            return count(String(str));
        }
        bool erase(in string str) {
            return erase(String(str));
        }
        void fill(in string str) {
            fill(String(str));
        }
        size_t find(in string str, size_t from = 0) const {
            return find(String(str), from);
        }
    	bool pushBack(in string str)
    	{
    		return pushBack(String(str));
    	}
    	size_t insert(size_t idx, in string value)
    	{
    		return insert(idx, String(value));
    	}
    	void set(size_t idx, in string value)
    	{
    		set(idx, String(value));
    	}
        size_t rfind(in string str, size_t from = -1) const {
            return rfind(String(str), from);
        }
        bool has(in string value) const {
            return _bind.has(value);
        }
    	void opIndexAssign(in string value, size_t idx)
    	{
    		set(idx, String(value));
    	}
    }

    bool pushBack(in T data) {
        return _bind.pushBack(data);
    }

    size_t insert(size_t idx, in T data) {
        return _bind.insert(idx, data);
    }

    void set(size_t idx, in T data) {
        _bind.set(idx, data);
    }

    T get(size_t idx) const {
        // added in v4.4
        static if (isGodot44orNewer) {
            static if (is(T == ubyte) || is(T == int))
                return cast(T) _bind.get(idx);
            else
                return _bind.get(idx);
        } else {
            mixin("auto s = gdextension_interface_"~(typeName!T)~"_operator_index_const;");
            auto ptr = s(&_bind, idx);
            if (ptr)
                return *cast(T*) ptr; // cast is needed because String, Vector3 and others simply returns void*
            else
                return T.init;
        }
    }

    bool has(in T value) const {
        return _bind.has(value);
    }

    /// Creates a copy of the array, as the Packed Array internally is a reference type this makes it possible to mutate a copy without affecting other references.
    typeof(this) duplicate() const {
        static if (isGodot46orNewer) {
            return _bind.duplicate();
        } else {
            // before v4.6 duplicate is not const!
            return (cast() _bind).duplicate();
        }
    }

    static if (!is(T == ubyte)) {
        ///
        PackedByteArray toByteArray() const {
            return _bind.toByteArray();
        }
    }

    ///
    bool append(in T value) {
        return _bind.append(value);
    }

    ///
    void clear() {
        _bind.clear();
    }

    void fill(in T value) {
        _bind.fill(value);
    }

    size_t find(in T value, size_t from = 0) const {
        return _bind.find(value, from);
    }

    size_t rfind(in T value, size_t from = -1) const {
        return _bind.rfind(value, from);
    }

    /// Performs binary search looking for the value, expected array to be sorted
    size_t bsearch(in T value, bool before = true) const {
        static if (isGodot46orNewer) {
            return _bind.bsearch(value, before);
        } else {
            // not const before v4.6
            return (cast() _bind).bsearch(value, before);
        }
    }

    PackedArray slice(size_t begin, size_t end = 0x7FFFFFFF) const {
        return _bind.slice(begin, end);
    }

    /// returns number of occurences of value
    long count(in T value) const {
        return _bind.count(value);
    }

    ///
    void sort() {
        _bind.sort();
    }


    // PackedByteArray specific methods
    static if(is(T == ubyte))
    {
        // for available values see FileAccess.CompressionMode
        PackedByteArray compress(int compressionMode = 0) const {
            return _bind.compress(compressionMode);
        }
        double decodeDouble(int byteOffset) const {
            return _bind.decodeDouble(byteOffset);
        }
        double decodeFloat(int byteOffset) const {
            return _bind.decodeFloat(byteOffset);
        }
        double decodeHalf(int byteOffset) const {
            return _bind.decodeHalf(byteOffset);
        }
        long decodeS8(int byteOffset) const {
            return _bind.decodeS8(byteOffset);
        }
        long decodeS16(int byteOffset) const {
            return _bind.decodeS16(byteOffset);
        }
        long decodeS32(int byteOffset) const {
            return _bind.decodeS32(byteOffset);
        }
        long decodeS64(int byteOffset) const {
            return _bind.decodeS64(byteOffset);
        }
        long decodeU8(int byteOffset) const {
            return _bind.decodeU8(byteOffset);
        }
        long decodeU16(int byteOffset) const {
            return _bind.decodeU16(byteOffset);
        }
        long decodeU32(int byteOffset) const {
            return _bind.decodeU32(byteOffset);
        }
        long decodeU64(int byteOffset) const {
            return _bind.decodeU64(byteOffset);
        }
        void encodeDouble(int byteOffset, double value) {
            return _bind.encodeDouble(byteOffset, value);
        }
        void encodeFloat(int byteOffset, double value) {
            return _bind.encodeFloat(byteOffset, value);
        }
        void encodeHalf(int byteOffset, double value) {
            return _bind.encodeHalf(byteOffset, value);
        }
        void encodeS8(int byteOffset, long value) {
            return _bind.encodeS8(byteOffset, value);
        }
        void encodeS16(int byteOffset, long value) {
            return _bind.encodeS16(byteOffset, value);
        }
        void encodeS32(int byteOffset, long value) {
            return _bind.encodeS32(byteOffset, value);
        }
        void encodeS64(int byteOffset, long value) {
            return _bind.encodeS64(byteOffset, value);
        }
        void encodeU8(int byteOffset, long value) {
            return _bind.encodeU8(byteOffset, value);
        }
        void encodeU16(int byteOffset, long value) {
            return _bind.encodeU16(byteOffset, value);
        }
        void encodeU32(int byteOffset, long value) {
            return _bind.encodeU32(byteOffset, value);
        }
        void encodeU64(int byteOffset, long value) {
            return _bind.encodeU64(byteOffset, value);
        }
        Variant decodeVar(int byteOffset, bool allowObjects = false) const {
            return _bind.decodeVar(byteOffset, allowObjects);
        }
        long decodeVarSize(int byteOffset, bool allowObjects = false) const {
            return _bind.decodeVarSize(byteOffset, allowObjects);
        }
        // for available values see FileAccess.CompressionMode
        PackedByteArray decompress(int bufferSize, int compressionMode = 0) const {
            return _bind.decompress(bufferSize, compressionMode);
        }
        // for available values see FileAccess.CompressionMode
        PackedByteArray decompressDynamic(int maxOutputSize, int compressionMode = 0) const {
            return _bind.decompressDynamic(maxOutputSize, compressionMode);
        }
        long encodeVar(int byteOffset, Variant value, bool allowObjects = false) {
            return _bind.encodeVar(byteOffset, value, allowObjects);
        }
        // Returns true if a valid Variant value can be decoded at the byte_offset. Returns false otherwise or when the value is Object-derived and allow_objects is false.
        bool hasEncodedVar(int byteOffset, bool allowObjects = false) const {
            return _bind.hasEncodedVar(byteOffset, allowObjects);
        }
        String hexEncode() const {
            return _bind.hexEncode();
        }
        // see also String.toAsciiBuffer, naively tranlates bytes into ASCII characters, for real input use fromUtf8 variant
        String getStringFromAscii() const {
            return _bind.getStringFromAscii();
        }
        String getStringFromUtf8() const {
            return _bind.getStringFromUtf8();
        }
        String getStringFromUtf16() const {
            return _bind.getStringFromUtf16();
        }
        String getStringFromUtf32() const {
            return _bind.getStringFromUtf32();
        }
        String getStringFromWchar() const {
            return _bind.getStringFromWchar();
        }
        PackedFloat32Array toFloat32Array() const {
            return _bind.toFloat32Array();
        }
        PackedFloat64Array toFloat64Array() const {
            return _bind.toFloat64Array();
        }
        PackedInt32Array toInt32Array() const {
            return _bind.toInt32Array();
        }
        PackedInt64Array toInt64Array() const {
            return _bind.toInt64Array();
        }
      static if (isGodot45orNewer) {
        void bswap16(size_t offset, size_t count = -1) {
            _bind.bswap16(offset, count);
        }
        void bswap32(size_t offset, size_t count = -1) {
            _bind.bswap32(offset, count);
        }
        void bswap64(size_t offset, size_t count = -1) {
            _bind.bswap64(offset, count);
        }
        String getStringFromMultibyteChar(String encoding) const {
            return _bind.getStringFromMultibyteChar(encoding);
        }
        String getStringFromMultibyteChar(string encoding = "") const {
            return getStringFromMultibyteChar(String(encoding));
        }
        PackedColorArray toColorArray() const {
            return _bind.toColorArray();
        }
        PackedVector2Array toVector2Array() const {
            return _bind.toVector2Array();
        }
        PackedVector3Array toVector3Array() const {
            return _bind.toVector3Array();
        }
        static if (isGodot43orNewer) 
        PackedVector4Array toVector4Array() const {
            return _bind.toVector4Array();
        }
      }
    }

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

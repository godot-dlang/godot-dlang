/**
Memory-pool-based dynamic arrays. Optimized for memory usage, can’t fragment the memory.

Copyright:
Copyright (c) 2007-2022 Juan Linietsky, Ariel Manzur.
Copyright (c) 2014-2022 Godot Engine contributors (cf. AUTHORS.md)
Copyright (c) 2017-2018 Godot-D contributors
Copyright (c) 2022-2022 Godot-DLang contributors

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
import godot.builtins;

import std.range.primitives;
import std.meta, std.traits;

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
    Color
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
    GDEXTENSION_VARIANT_TYPE_PACKED_COLOR_ARRAY,
);

private enum string nameOverride(T) = AliasSeq!(
        "byte", "int32", "int64", "float32", "float64", "string",
        "vector2", "vector3", "color")[staticIndexOf!(T, PackedArrayTypes)];

private enum string bindNameOverride(T) = AliasSeq!(
        "Byte", "Int32", "Int64", "Float32", "Float64", "String",
        "Vector2", "Vector3", "Color")[staticIndexOf!(T, PackedArrayTypes)];

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

/++
Copy-on-write array for some Godot types, allocated with a memory pool.
+/
struct PackedArray(T) {
    //@nogc nothrow:

    static assert(staticIndexOf!(T, PackedArrayTypes) != -1,
        "Cannot make a Godot PackedArray for a non-Godot type");

    // TODO: this is now gone, replace with real array
    //mixin("package(godot) "~(typeName!T)~" _godot_array;");

    package(godot) union _PackedArray {
        GDExtensionTypePtr _godot_array;
        mixin("Packed" ~ bindNameOverride!T ~ "Array_Bind _bind;");
    }

    package(godot) _PackedArray _packed_array;
    alias _packed_array this;

    alias VARIANT_TYPE = PackedArrayVariantType[staticIndexOf!(T, PackedArrayTypes)];

    this(this) {
        import std.array;

        //mixin("auto n = _godot_api."~(typeName!T)~"_new_copy;");
        auto ctor = _godot_api.variant_get_ptr_constructor(VARIANT_TYPE, 1);
        const auto args = [_godot_array].staticArray;
        ctor(_godot_array, args.ptr);

        //n(&_godot_array, &tmp);

    }

    package(godot) this(GDExtensionTypePtr opaque) {
        _godot_array = opaque;
    }

    PackedArray opAssign(in PackedArray other) {
        auto dtor = _godot_api.variant_get_ptr_destructor(VARIANT_TYPE);
        auto ctor = _godot_api.variant_get_ptr_constructor(VARIANT_TYPE, 1);
        dtor(&_godot_array);
        ctor(&_godot_array, &other._godot_array);
        return this;
    }

    /++
	C API type to pass to/from C functions
	+/
    static if (is(T == Vector2))
        private alias InternalType = godot_vector2;
    else static if (is(T == Vector3))
        private alias InternalType = godot_vector3;
    else static if (is(T == Color))
        private alias InternalType = godot_color;
    else
        private alias InternalType = T;

    this(Array arr) {
        auto n = _godot_api.variant_get_ptr_constructor(VARIANT_TYPE, 2);
        n(&_godot_array, cast(void**)&arr._godot_array);
    }

    ///
    void pushBack(in ref PackedArray arr) {
        _bind.appendArray(arr);
        //mixin("auto a = _godot_api."~(typeName!T)~"_append_array;");
        //a(&_godot_array, &arr._godot_array);
    }

    deprecated("Use the concatenation operator ~= instead of append_array.") alias append_array = pushBack;

    void invert() {
        _bind.reverse();
        //mixin("auto i = _godot_api."~(typeName!T)~"_invert;");
        //i(&_godot_array);
    }

    void remove(size_t idx) {
        _bind.removeAt(idx);
        //mixin("auto r = _godot_api."~(typeName!T)~"_remove;");
        //r(&_godot_array, cast(int)idx);
    }

    void resize(size_t size) {
        _bind.resize(size);
        //mixin("auto r = _godot_api."~(typeName!T)~"_resize;");
        //r(&_godot_array, cast(int)size);
    }

    size_t size() const {
        return _bind.size();
        //mixin("auto s = _godot_api."~(typeName!T)~"_size;");
        //return s(&_godot_array);
    }

    alias length = size; // D-style name for size
    alias opDollar = size;

    /// Returns: true if length is 0.
    bool empty() const {
        return length == 0;
    }

    ~this() {
        //auto d = _godot_api.variant_get_ptr_destructor(GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY)
        auto d = _godot_api.variant_get_ptr_destructor(VARIANT_TYPE);
        d(&_godot_array);
    }

    // a few functions are different for Strings than for the others:
    //static if(is(T == String))
    //{
    //	void pushBack(in String data)
    //	{
    //		_godot_api.packed_string_array_push_back(&_godot_array, &data._godot_string);
    //	}
    //	void insert(size_t idx, in String data)
    //	{
    //		_godot_api.packed_string_array_insert(&_godot_array, cast(int)idx, &data._godot_string);
    //	}
    //	void set(size_t idx, in String data)
    //	{
    //		_godot_api.packed_string_array_operator_index(&_godot_array, cast(int)idx) = &data._godot_string;
    //	}
    //	void opIndexAssign(in String data, size_t idx)
    //	{
    //		_godot_api.packed_string_array_operator_index(&_godot_array, cast(int)idx) = &data._godot_string;
    //	}
    //	String opIndex(size_t idx) const
    //	{
    //		String ret = void;
    //		ret._godot_string = godot_string(cast(size_t)  _godot_api.packed_string_array_operator_index_const(&_godot_array, cast(int)idx));
    //		return ret;
    //	}
    //}
    //else
    //{
    void pushBack(in T data) {
        _bind.pushBack(data);
        //mixin("auto p = _godot_api."~(typeName!T)~"_push_back;");
        //static if(is(T==Vector2) || is(T==Vector3) || is(T==Color))
        //	p(&_godot_array, cast(InternalType*)&data);
        //else p(&_godot_array, data);
    }

    void insert(size_t idx, in T data) {
        _bind.insert(idx, data);
        //mixin("auto i = _godot_api."~(typeName!T)~"_insert;");
        //static if(is(T==Vector2) || is(T==Vector3) || is(T==Color))
        //	i(&_godot_array, cast(int)idx, cast(InternalType*)&data);
        //else i(&_godot_array, cast(int)idx, data);
    }

    void set(size_t idx, in T data) {
        _bind.set(idx, data);
        //mixin("auto s = _godot_api."~(typeName!T)~"_set;");
        //static if(is(T==Vector2) || is(T==Vector3) || is(T==Color))
        //	s(&_godot_array, cast(int)idx, cast(InternalType*)&data);
        //else s(&_godot_array, cast(int)idx, data);
    }

    void opIndexAssign(in T data, size_t idx) {
        _bind.set(idx, data);
        //mixin("auto s = _godot_api."~(typeName!T)~"_set;");
        //static if(is(T==Vector2) || is(T==Vector3) || is(T==Color))
        //	s(&_godot_array, cast(int)idx, cast(InternalType*)&data);
        //else s(&_godot_array, cast(int)idx, data);
    }

    T opIndex(size_t idx) const {
        mixin("auto g = _godot_api." ~ (typeName!T) ~ "_operator_index_const;");
        static union V {
            T t;
            InternalType r;
        }

        V v;
        v.r = *cast(InternalType*) g(&_godot_array, cast(int) idx);
        return v.t;
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

    static if (is(T == String))
        char* data() inout {
            return cast(char*) _godot_array;
        }
    else
        T* data() inout {
            return cast(T*) _godot_array;
        }

    // Superbelko: PoolVector was replaced by Vector, all PoolTypeArray's was replaced with PackedTypeArray 
    //             which is simply Vector<Type> under the hood plus bells and whistles.
    //             No need to keep this anymore, but ok. use raw pointer instead of Read.
    /// Read/Write access locks with RAII.
    version (none) static struct Access(bool write = false) {
        private enum string rw = write ? "operator_index" : "operator_index_const";
        private enum string RW = write ? "Write" : "Read";
        static if (write)
            private alias access = writeName!T;
        else
            private alias access = readName!T;

        private {
            mixin(access ~ "* _access;");
            T[] _data;
        }

        static if (write) {
            /// 
            inout(T[]) data() inout {
                return _data;
            }
        } else {
            /// 
            const(T[]) data() const {
                return _data;
            }
        }
        // TODO: `scope` for data to ensure it doesn't outlive `this`?
        alias data this;

        this(PackedArray!T p) {
            mixin("_access = _godot_api." ~ typeName!T ~ "_" ~ rw ~ "(&p._godot_array);");
            mixin("void* _ptr = cast(void*)_godot_api." ~ access ~ "_ptr(_access);");
            _data = (cast(T*) _ptr)[0 .. p.length];
        }

        this(this) {
            mixin("_access = _godot_api." ~ access ~ "_copy(_access);");
        }

        void opAssign(const ref typeof(this) other) {
            mixin("_godot_api." ~ access ~ "_destroy(_access);");
            mixin("_access = _godot_api." ~ access ~ "_copy(other._access);");
        }

        ~this() {
            mixin("_godot_api." ~ access ~ "_destroy(_access);");
        }
    }

    version (none) {

        /// 
        alias Read = Access!false;
        /// Lock the array for read-only access to the underlying memory.
        /// This is faster than using opIndex, which locks each time it's called.
        Read read() const {
            return Read(this);
        }
        /// 
        alias Write = Access!true;
        /// Lock the array for write access to the underlying memory.
        /// This is faster than using opIndexAssign, which locks each time it's called.
        Write write() {
            return Write(this);
        }
    }

    /// Slice-like view of the PackedArray.
    static struct Range {
        private {
            PackedArray* arr;
            size_t start, end;
        }

        bool empty() const {
            return start == end;
        }

        size_t length() const {
            return end - start;
        }

        alias opDollar = length;
        T front() {
            return (*arr)[start];
        }

        void popFront() {
            ++start;
        }

        T back() {
            return (*arr)[end - 1];
        }

        void popBack() {
            --end;
        }

        T opIndex(size_t index) {
            return (*arr)[index + start];
        }

        Range save() {
            return this;
        }
    }

    static assert(isRandomAccessRange!Range);

    /// Returns: a slice-like Range view over the array.
    /// Note: Prefer `read()`/`write()`; Range locks the array on each individual access.
    Range opSlice() {
        return Range(&this, 0, length);
    }
    /// ditto
    Range opSlice(size_t start, size_t end) {
        return Range(&this, start, end);
    }
}

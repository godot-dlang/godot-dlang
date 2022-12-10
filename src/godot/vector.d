module godot.vector;

import godot.vector2: Vector2, Vector2i;
import godot.vector3: Vector3, Vector3i;
import godot.vector4: Vector4, Vector4i;

import std.traits;

/// Vector structure with data accesible with `[N]` or swizzling
struct Vector(T, size_t N) if (isNumeric!T && N > 0)  {
    /// Vector data
    public T[N] data = [ 0 ];

    /// Alias to allow easy `data` access
    alias data this;
    /// Alias to data type (e.g. float, int)
    alias dataType = T;
    /** 
    Alias to vector type. Can be used to contruct vectors
    of same type
    ---
    auto rvec7 = Vector!(real, 7)(10);
    auto rvec7s = rvec7.VecType(20);
    ---
    */
    alias VecType = Vector!(T, N);
    /// Alias to vector size
    enum size_t size = N;

    /**
    Constructs Vector from components. If no components present
    vector will be filled with 0
    Example:
    ---
    // Vector can be constructed manually or with aliases
    auto v1 = Vector!(int, 2)(10, 20);
    auto v2 = ivec2(10, 20);
    auto v3 = Vector2i(10, 20);
    auto v4 = Vector2!int(10, 20);
    // Also vector can be given only one value,
    // in that case it'll be filled with that value
    auto v5 = ivec4(13);
    auto v6 = vec4(0.3f);
    // Vector values can be accessed with array slicing,
    // by using color symbols or swizzling
    float v6x = v6.x;
    float v6z = v6.z;
    float[] v6yzx = v6.yzx;
    float v6y = v6[1];
    // Valid vector accessors are:
    // Vector2 - [x, y], [w, h], [u, v]
    // Vector3 - [x, y, z], [w, h, d], [u, v, t], [r, g, b]
    // Vector4 - [x, y, z, w], [r, g, b, a]
    // Other sizes must be accessed with index
    ---
    */
    this(in T val) {
        foreach (i; 0 .. size) { data[i] = val; }
    }
    /// Ditto
    this(in T[N] vals...) {
        data = vals;
    }

    /* -------------------------------------------------------------------------- */
    /*                         UNARY OPERATIONS OVERRIDES                         */
    /* -------------------------------------------------------------------------- */
    
    /// opBinary x [+, -, *, /, %] y
    auto opBinary(string op, R)(in Vector!(R, N) b) const if ( isNumeric!R ) {
        // assert(/* this !is null && */ b !is null, "\nOP::ERROR nullptr Vector!" ~ size.to!string ~ ".");
        VecType ret = VecType();
        foreach (i; 0 .. size) { mixin( "data[i] = data[i] " ~ op ~ " b.data[i];" ); }
        return ret;
    }

    /// Ditto
    auto opBinaryRight(string op, R)(in Vector!(R, N) b) const if ( isNumeric!R ) {
        // assert(/* this !is null && */ b !is null, "\nOP::ERROR nullptr Vector!" ~ size.to!string ~ ".");
        VecType ret = VecType();
        foreach (i; 0 .. size) { mixin( "ret[i] = b.data[i] " ~ op ~ " data[i];" ); }
        return ret;
    }

    /// Ditto
    auto opBinary(string op, R)(in R b) const if ( isNumeric!R ) {
        // assert(this !is null, "\nOP::ERROR nullptr Vector!" ~ size.to!string ~ ".");
        VecType ret = VecType();
        foreach (i; 0 .. size) { mixin( "data[i] = data[i] " ~ op ~ " b;" ); }
        return ret;
    }

    /// Ditto
    auto opBinaryRight(string op, R)(in R b) const if ( isNumeric!R ) {
        // assert(this !is null, "\nOP::ERROR nullptr Vector!" ~ size.to!string ~ ".");
        VecType ret = VecType();
        foreach (i; 0 .. size) { mixin( "ret[i] = b " ~ op ~ " data[i];" ); }
        return ret;
    }

    /// opEquals x == y
    bool opEquals(R)(in Vector!(R, size) b) const if ( isNumeric!R ) {
        // assert(/* this !is null && */ b !is null, "\nOP::ERROR nullptr Vector!" ~ size.to!string ~ ".");
        bool eq = true;
        foreach (i; 0 .. size) { eq = eq && data[i] == b.data[i]; }
        return eq;
    }

    /// opCmp x [< > <= >=] y
    int opCmp(R)(in Vector!(R, N) b) const if ( isNumeric!R ) {
        // assert(/* this !is null && */ b !is null, "\nOP::ERROR nullptr Vector!" ~ size.to!string ~ ".");
        T al = length;
        T bl = b.length;
        if (al == bl) return 0;
        if (al < bl) return -1;
        return 1;
    }

    /// opUnary [-, +, --, ++] x
    auto opUnary(string op)() if(op == "-"){
        // assert(this !is null, "\nOP::ERROR nullptr Vector!" ~ size.to!string ~ ".");
        VecType ret = VecType();
        if (op == "-")
            foreach (i; 0 .. size) { data[i] = -data[i]; }
        return ret;
    }
    
    /// opOpAssign x [+, -, *, /, %]= y
    auto opOpAssign(string op, R)( in Vector!(R, N) b ) if ( isNumeric!R ) { 
        // assert(/* this !is null && */ b !is null, "\nOP::ERROR nullptr Vector!" ~ size.to!string ~ ".");
        foreach (i; 0 .. size) { mixin( "data[i] = data[i] " ~ op ~ " b.data[i];" ); }
        return this;
    }
    
    /// Ditto
    auto opOpAssign(string op, R)( in R b ) if ( isNumeric!R ) { 
        // assert(this !is null, "\nOP::ERROR nullptr Vector!" ~ size.to!string ~ ".");
        foreach (i; 0 .. size) { mixin( "data[i] = data[i] " ~ op ~ " b;" ); }
        return this;
    }

    /// Returns hash 
    size_t toHash() const @safe nothrow {
        return typeid(data).getHash(&data);
    }

    // incredible magic from sily.meta
    // idk how it works but it works awesome
    // and im not going to touch it at all
    static if (N == 2 || N == 3 || N == 4) {
        static if (N == 2) enum AccessString = "x y|w h|u v"; 
        else
        static if (N == 3) enum AccessString = "x y z|w h d|u v t|r g b"; 
        else
        static if (N == 4) enum AccessString = "x y z w|r g b a"; 

        mixin accessByString!(T, N, "data", AccessString); 
    }

    /// Returns copy of vector
    public VecType copyof() {
        return VecType(data);
    }

    /// Returns string representation of vector: `[1.00, 1.00,... , 1.00]`
    public string toString() const {
        import std.conv : to;
        import std.string: format;
        string s;
        s ~= "[";
        foreach (i; 0 .. size) {
            s ~= isFloatingPoint!T ? format("%.2f", data[i]) : format("%d", data[i]);
            if (i != size - 1) s ~= ", ";
        }
        s ~= "]";
        return s;
    }

    /// Returns pointer to data
    T* ptr() return {
        return data.ptr;
    }

    /* ------------------------------ Godot Vectors ----------------------------- */

    static if(N == 2) {
        static if (isFloatingPoint!T) {
            Vector2 godotVector() {
                return Vector2(data);
            }
        } else {
            Vector2i godotVector() {
                return Vector2i(data);
            }
        }
    }

    static if(N == 3) {
        static if (isFloatingPoint!T) {
            Vector3 godotVector() {
                return Vector3(data);
            }
        } else {
            Vector3i godotVector() {
                return Vector3i(data);
            }
        }
    }

    static if(N == 4) {
        static if (isFloatingPoint!T) {
            Vector4 godotVector() {
                return Vector4(data);
            }
        } else {
            Vector4i godotVector() {
                return Vector4i(data);
            }
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                         STATIC GETTERS AND SETTERS                         */
    /* -------------------------------------------------------------------------- */
    
    /// Constructs predefined vector
    static alias zero  = () => VecType(0);
    /// Ditto
    static alias one   = () => VecType(1);

    static if(isFloatingPoint!T) {
        /// Ditto
        static alias inf   = () => VecType(float.infinity);
    }

    static if(N == 2) {
        /// Ditto
        static alias left  = () => VecType(-1, 0);
        /// Ditto
        static alias right = () => VecType(1, 0);
        /// Ditto
        static alias up    = () => VecType(0, -1);
        /// Ditto
        static alias down  = () => VecType(0, 1);
    }

    static if(N == 3) {
        static alias forward = () => VecType(0, 0, -1);
        /// Ditto
        static alias back    = () => VecType(0, 0, 1);
        /// Ditto
        static alias left    = () => VecType(-1, 0, 0);
        /// Ditto
        static alias right   = () => VecType(1, 0, 0);
        /// Ditto
        static alias up      = () => VecType(0, 1, 0);
        /// Ditto
        static alias down    = () => VecType(0, -1, 0);
    }
}
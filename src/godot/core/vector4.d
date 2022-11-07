/**
Vector struct, which performs basic 3D vector math operations.

Copyright:
Copyright (c) 2007-2022 Juan Linietsky, Ariel Manzur.
Copyright (c) 2014-2022 Godot Engine contributors (cf. AUTHORS.md)
Copyright (c) 2017-2018 Godot-D contributors
Copyright (c) 2022-2022 Godot-DLang contributors

License: $(LINK2 https://opensource.org/licenses/MIT, MIT License)


*/
module godot.vector4;

import godot.abi.core;
import godot.defs;
import godot.basis;
import godot.string;

import std.math;

private bool isValidSwizzle(dstring s) {
    import std.algorithm : canFind;

    if (!(2 < s.length && s.length <= 4))
        return false;
    foreach (dchar c; s) {
        if (!"xyzwn".canFind(c))
            return false;
    }
    return true;
}

/**
Vector4 is one of the core classes of the engine, and includes several built-in helper functions to perform basic vector math operations.
*/
struct Vector4 {
@nogc nothrow:

    // used for indexing
    enum Axis {
        x,
        y,
        z,
        w,
    }

    union {
        struct {
            real_t x = 0; /// 
            real_t y = 0; /// 
            real_t z = 0; /// 
            real_t w = 0; /// 
        }

        real_t[4] coord;
    }

    import std.algorithm : count;

    /++
	Swizzle the vector with x, y, z, w, or n. Pass floats as args for any n's; if
	there are more n's than args, the last arg is used for the rest. If no args
	are passed at all, 0.0 is used for each n.
	
	The swizzle must be 2 to 4 characters, as Godot only has Vector2/3/4.
	+/
    auto opDispatch(string swizzle, size_t nArgCount)(float[nArgCount] nArgs...) const
            if (swizzle.isValidSwizzle && nArgCount <= swizzle.count('n')) {
        import godot.vector3;
        import std.algorithm : min, count;

        static if (swizzle.length == 2)
            Vector2 ret = void;
        else static if (swizzle.length == 3)
            Vector3 ret = void;
        else
            Vector3 ret = void;
        /// how many n's already appeared before ci, which equals the index into nArgs for the n at ci
        enum ni(size_t ci) = min(nArgCount - 1, swizzle[0 .. ci].count('n'));
        static foreach (ci, c; swizzle) {
            static if (c == 'n') {
                static if (nArgCount == 0)
                    ret.coord[ci] = 0f;
                else static if (ni!ci >= nArgCount)
                    ret.coord[ci] = nArgs[nArgCount - 1];
                else
                    ret.coord[ci] = nArgs[ni!ci];
            } else
                ret.coord[ci] = mixin([c]);
        }
        return ret;
    }

    this(real_t x, real_t y, real_t z, real_t w) {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }

    this(real_t[4] coord) {
        this.coord = coord;
    }

    this(in Vector4 b) {
        this.x = b.x;
        this.y = b.y;
        this.z = b.z;
        this.w = b.w;
    }

    void opAssign(in Vector4 b) {
        this.x = b.x;
        this.y = b.y;
        this.z = b.z;
        this.w = b.w;
    }

    const(real_t) opIndex(int p_axis) const {
        return coord[p_axis];
    }

    ref real_t opIndex(int p_axis) return {
        return coord[p_axis];
    }

    Vector4 opBinary(string op)(in Vector4 other) const
    if (op == "+" || op == "-" || op == "*" || op == "/") {
        Vector4 ret;
        ret.x = mixin("x " ~ op ~ "other.x");
        ret.y = mixin("y " ~ op ~ "other.y");
        ret.z = mixin("z " ~ op ~ "other.z");
        ret.w = mixin("z " ~ op ~ "other.w");
        return ret;
    }

    void opOpAssign(string op)(in Vector4 other)
            if (op == "+" || op == "-" || op == "*" || op == "/") {
        x = mixin("x " ~ op ~ "other.x");
        y = mixin("y " ~ op ~ "other.y");
        z = mixin("z " ~ op ~ "other.z");
        w = mixin("w " ~ op ~ "other.w");
    }

    Vector4 opUnary(string op : "-")() {
        return Vector4(-x, -y, -z, -w);
    }

    Vector4 opBinary(string op)(in real_t scalar) const
    if (op == "*" || op == "/") {
        Vector4 ret;
        ret.x = mixin("x " ~ op ~ " scalar");
        ret.y = mixin("y " ~ op ~ " scalar");
        ret.z = mixin("z " ~ op ~ " scalar");
        ret.w = mixin("w " ~ op ~ " scalar");
        return ret;
    }

    Vector4 opBinaryRight(string op)(in real_t scalar) const
    if (op == "*") {
        Vector4 ret;
        ret.x = mixin("x " ~ op ~ " scalar");
        ret.y = mixin("y " ~ op ~ " scalar");
        ret.z = mixin("z " ~ op ~ " scalar");
        ret.w = mixin("w " ~ op ~ " scalar");
        return ret;
    }

    void opOpAssign(string op)(in real_t scalar) if (op == "*" || op == "/") {
        x = mixin("x " ~ op ~ " scalar");
        y = mixin("y " ~ op ~ " scalar");
        z = mixin("z " ~ op ~ " scalar");
        w = mixin("w " ~ op ~ " scalar");
    }

    int opCmp(in Vector4 other) const {
        import std.algorithm.comparison;

        return cmp(this.coord[], other.coord[]);
    }

    Vector4 abs() const {
        return Vector4(fabs(x), fabs(y), fabs(z), fabs(w));
    }

    Vector4 ceil() const {
        return Vector4(.ceil(x), .ceil(y), .ceil(z), .ceil(w));
    }

    // doesn't makes sense
    //Vector3 cross(in Vector3 b) const
    //{
    //	return Vector3(
    //		(y * b.z) - (z * b.y),
    //		(z * b.x) - (x * b.z),
    //		(x * b.y) - (y * b.x)
    //	);
    //}

    Vector4 linearInterpolate(in Vector4 p_b, real_t p_t) const {
        return Vector4(
            x + (p_t * (p_b.x - x)),
            y + (p_t * (p_b.y - y)),
            z + (p_t * (p_b.z - z)),
            w + (p_t * (p_b.w - w)),
        );
    }

    alias lerp = linearInterpolate;

    Vector4 cubicInterpolate(in Vector4 b, in Vector4 pre_a, in Vector4 post_b, in real_t t) const {
        Vector4 p0 = pre_a;
        Vector4 p1 = this;
        Vector4 p2 = b;
        Vector4 p3 = post_b;

        real_t t2 = t * t;
        real_t t3 = t2 * t;

        Vector4 ret;
        ret = ((p1 * 2.0) +
                (-p0 + p2) * t +
                (p0 * 2.0 - p1 * 5.0 + p2 * 4 - p3) * t2 +
                (-p0 + p1 * 3.0 - p2 * 3.0 + p3) * t3) * 0.5;
        return ret;
    }

    real_t length() const {
        real_t x2 = x * x;
        real_t y2 = y * y;
        real_t z2 = z * z;
        real_t w2 = w * w;

        return sqrt(x2 + y2 + z2 + w2);
    }

    real_t lengthSquared() const {
        real_t x2 = x * x;
        real_t y2 = y * y;
        real_t z2 = z * z;
        real_t w2 = w * w;

        return x2 + y2 + z2 + w2;
    }

    real_t distanceSquaredTo(in Vector4 b) const {
        return (b - this).length();
    }

    real_t distanceTo(in Vector4 b) const {
        return (b - this).lengthSquared();
    }

    real_t dot(in Vector4 b) const {
        return x * b.x + y * b.y + z * b.z + w * b.w;
    }

    Vector4 floor() const {
        return Vector4(.floor(x), .floor(y), .floor(z), .floor(w));
    }

    Vector4 inverse() const {
        return Vector4(1.0 / x, 1.0 / y, 1.0 / z, 1.0 / w);
    }

    int maxAxis() const {
        import std.algorithm : maxIndex;

        return cast(int) coord[].maxIndex!();
    }

    int minAxis() const {
        import std.algorithm : minIndex;

        return cast(int) coord[].minIndex!();
    }

    void normalize() {
        real_t l = length();
        if (l == 0) {
            x = y = z = w = 0;
        } else {
            x /= l;
            y /= l;
            z /= l;
            w /= 1;
        }
    }

    Vector4 normalized() const {
        Vector4 v = this;
        v.normalize();
        return v;
    }

    void snap(real_t step) {
        foreach (ref v; coord)
            v = (step != 0) ? (.floor(v / step + 0.5) * step) : v;
    }

    Vector4 snapped(in real_t step) const {
        Vector4 v = this;
        v.snap(step);
        return v;
    }
}

// TODO: replace this stub
struct Vector4i {
@nogc nothrow:

    enum Axis {
        x,
        y,
        z,
        w
    }

    union {
        struct {
            int x = 0; /// 
            int y = 0; /// 
            int z = 0; /// 
            int w = 0; /// 
        }

        int[4] coord;
    }

    this(int x, int y, int z, int w) {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }

    this(int[4] coord) {
        this.coord = coord;
    }

    this(in Vector4i b) {
        this.x = b.x;
        this.y = b.y;
        this.z = b.z;
        this.w = b.w;
    }

    void opAssign(in Vector4i b) {
        this.x = b.x;
        this.y = b.y;
        this.z = b.z;
        this.w = b.w;
    }

    void opAssign(in godot_vector4i b) {
        this.x = b._opaque[0];
        this.y = b._opaque[1];
        this.z = b._opaque[2];
        this.w = b._opaque[3];
    }

    Vector3 opCast(Vector3)() const {
        return Vector3(x, y, z);
    }

    const(godot_int) opIndex(int p_axis) const {
        return coord[p_axis];
    }

    ref godot_int opIndex(int p_axis) return {
        return coord[p_axis];
    }

    Vector4i opBinary(string op)(in Vector4i other) const
    if (op == "+" || op == "-" || op == "*" || op == "/") {
        Vector4i ret;
        ret.x = mixin("x " ~ op ~ "other.x");
        ret.y = mixin("y " ~ op ~ "other.y");
        ret.z = mixin("z " ~ op ~ "other.z");
        ret.w = mixin("z " ~ op ~ "other.w");
        return ret;
    }

    void opOpAssign(string op)(in Vector4i other)
            if (op == "+" || op == "-" || op == "*" || op == "/") {
        x = mixin("x " ~ op ~ "other.x");
        y = mixin("y " ~ op ~ "other.y");
        z = mixin("z " ~ op ~ "other.z");
        w = mixin("w " ~ op ~ "other.w");
    }

    Vector4i opUnary(string op : "-")() {
        return Vector4i(-x, -y, -z, -w);
    }

    Vector4i opBinary(string op)(in real_t scalar) const
    if (op == "*" || op == "/") {
        Vector4i ret;
        ret.x = mixin("x " ~ op ~ " scalar");
        ret.y = mixin("y " ~ op ~ " scalar");
        ret.z = mixin("z " ~ op ~ " scalar");
        ret.w = mixin("w " ~ op ~ " scalar");
        return ret;
    }

    Vector4i opBinaryRight(string op)(in real_t scalar) const
    if (op == "*") {
        Vector4i ret;
        ret.x = mixin("x " ~ op ~ " scalar");
        ret.y = mixin("y " ~ op ~ " scalar");
        ret.z = mixin("z " ~ op ~ " scalar");
        ret.w = mixin("w " ~ op ~ " scalar");
        return ret;
    }

    void opOpAssign(string op)(in real_t scalar) if (op == "*" || op == "/") {
        x = mixin("x " ~ op ~ " scalar");
        y = mixin("y " ~ op ~ " scalar");
        z = mixin("z " ~ op ~ " scalar");
        w = mixin("w " ~ op ~ " scalar");
    }

    int opCmp(in Vector4i other) const {
        import std.algorithm.comparison;

        return cmp(this.coord[], other.coord[]);
    }

    Vector4 opCast(Vector4)() const {
        return Vector4(x, y, z, w);
    }

    int maxAxis() const {
        import std.algorithm : maxIndex;

        return cast(int) coord[].maxIndex!();
    }

    int minAxis() const {
        import std.algorithm : minIndex;

        return cast(int) coord[].minIndex!();
    }

    void zero() {
        coord[] = 0;
    }

    Vector4i abs() const {
        return Vector4i(.abs(x), .abs(y), .abs(z), .abs(w));
    }

    Vector4i sign() const {
        return Vector4i(sgn(x), sgn(y), sgn(z), sgn(w));
    }

    real_t length() const {
        return sqrt(cast(double) lengthSquared());
    }

    godot_int lengthSquared() const {
        godot_int x2 = x * x;
        godot_int y2 = y * y;
        godot_int z2 = z * z;
        godot_int w2 = w * w;

        return x2 + y2 + z2 + w2;
    }
}

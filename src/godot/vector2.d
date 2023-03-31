/**
Vector used for 2D Math.

Copyright:
Copyright (c) 2007 Juan Linietsky, Ariel Manzur.
Copyright (c) 2014 Godot Engine contributors (cf. AUTHORS.md)
Copyright (c) 2017 Godot-D contributors
Copyright (c) 2022 Godot-DLang contributors

License: $(LINK2 https://opensource.org/licenses/MIT, MIT License)


*/
module godot.vector2;

import godot.abi.core;
import godot.abi.types;



import std.math;

private bool isValidSwizzle(dstring s) {
    import std.algorithm : canFind;

    if (s.length != 2 && s.length != 3)
        return false;
    foreach (dchar c; s) {
        if (!"xyn".canFind(c))
            return false;
    }
    return true;
}

/**
2-element structure that can be used to represent positions in 2d-space, or any other pair of numeric values.
*/
struct Vector2 {
@nogc nothrow:

    union {
        struct {
            union {
                real_t x = 0.0; /// 
                real_t width; /// 
            }

            union {
                real_t y = 0.0; /// 
                real_t height; /// 
            }
        }

        real_t[2] coord;
    }

    import std.algorithm : count;

    /++
	Swizzle the vector with x, y, or n. Pass floats as args for any n's; if
	there are more n's than args, the last arg is used for the rest. If no args
	are passed at all, 0.0 is used for each n.
	
	The swizzle must be 2 or 3 characters, as Godot only has Vector2/3.
	+/
    auto opDispatch(string swizzle, size_t nArgCount)(float[nArgCount] nArgs...) const
            if (swizzle.isValidSwizzle && nArgCount <= swizzle.count('n')) {
        import godot.vector3;
        import std.algorithm : min, count;

        static if (swizzle.length == 2)
            Vector2 ret = void;
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

    this(real_t x, real_t y) {
        this.x = x;
        this.y = y;
    }

    this(real_t[2] coord) {
        this.coord = coord;
    }

    this(in Vector2 b) {
        this.x = b.x;
        this.y = b.y;
    }

    this(in Vector2i b) {
        this.x = b.x;
        this.y = b.y;
    }

    void opAssign(in Vector2 b) {
        this.x = b.x;
        this.y = b.y;
    }

    // there is cases where this happens in api.json
    void opAssign(in Vector2i b) {
        this.x = b.x;
        this.y = b.y;
    }

    ref real_t opIndex(int axis) return {
        return axis ? y : x;
    }

    const(real_t) opIndex(int axis) const {
        return axis ? y : x;
    }

    Vector2 opBinary(string op)(in Vector2 other) const
    if (op == "+" || op == "-" || op == "*" || op == "/") {
        Vector2 ret;
        ret.x = mixin("x " ~ op ~ "other.x");
        ret.y = mixin("y " ~ op ~ "other.y");
        return ret;
    }

    void opOpAssign(string op)(in Vector2 other)
            if (op == "+" || op == "-" || op == "*" || op == "/") {
        x = mixin("x " ~ op ~ "other.x");
        y = mixin("y " ~ op ~ "other.y");
    }

    Vector2 opUnary(string op : "-")() {
        return Vector2(-x, -y);
    }

    Vector2 opBinary(string op)(in real_t scalar) const
    if (op == "*" || op == "/") {
        Vector2 ret;
        ret.x = mixin("x " ~ op ~ " scalar");
        ret.y = mixin("y " ~ op ~ " scalar");
        return ret;
    }

    Vector2 opBinaryRight(string op)(in real_t scalar) const
    if (op == "*") {
        Vector2 ret;
        ret.x = mixin("x " ~ op ~ " scalar");
        ret.y = mixin("y " ~ op ~ " scalar");
        return ret;
    }

    void opOpAssign(string op)(in real_t scalar) if (op == "*" || op == "/") {
        x = mixin("x " ~ op ~ " scalar");
        y = mixin("y " ~ op ~ " scalar");
    }

    int opCmp(in Vector2 other) const {
        import std.algorithm.comparison;
        import std.range;

        return cmp(only(x, y), only(other.x, other.y));
    }

    real_t aspect() const {
        return width / height;
    }

    void normalize() {
        real_t l = x * x + y * y;
        if (l != 0) {
            l = sqrt(l);
            x /= l;
            y /= l;
        }
    }

    Vector2 normalized() const {
        Vector2 v = this;
        v.normalize();
        return v;
    }

    real_t length() const {
        return sqrt(x * x + y * y);
    }

    real_t lengthSquared() const {
        return x * x + y * y;
    }

    real_t distanceTo(in Vector2 p_vector2) const {
        return sqrt((x - p_vector2.x) * (x - p_vector2.x) + (y - p_vector2.y) * (y - p_vector2.y));
    }

    real_t distanceSquaredTo(in Vector2 p_vector2) const {
        return (x - p_vector2.x) * (x - p_vector2.x) + (y - p_vector2.y) * (y - p_vector2.y);
    }

    real_t angleTo(in Vector2 p_vector2) const {
        return atan2(cross(p_vector2), dot(p_vector2));
    }

    real_t angleToPoint(in Vector2 p_vector2) const {
        return atan2(y - p_vector2.y, x - p_vector2.x);
    }

    real_t dot(in Vector2 p_other) const {
        return x * p_other.x + y * p_other.y;
    }

    real_t cross(in Vector2 p_other) const {
        return x * p_other.y - y * p_other.x;
    }

    Vector2 cross(real_t p_other) const {
        return Vector2(p_other * y, -p_other * x);
    }

    Vector2 project(in Vector2 p_vec) const {
        Vector2 v1 = p_vec;
        Vector2 v2 = this;
        return v2 * (v1.dot(v2) / v2.dot(v2));
    }

    Vector2 planeProject(real_t p_d, in Vector2 p_vec) const {
        return p_vec - this * (dot(p_vec) - p_d);
    }

    Vector2 clamped(real_t p_len) const {
        real_t l = length();
        Vector2 v = this;
        if (l > 0 && p_len < l) {
            v /= l;
            v *= p_len;
        }
        return v;
    }

    static Vector2 linearInterpolate(in Vector2 p_a, in Vector2 p_b, real_t p_t) {
        Vector2 res = p_a;
        res.x += (p_t * (p_b.x - p_a.x));
        res.y += (p_t * (p_b.y - p_a.y));
        return res;
    }

    Vector2 linearInterpolate(in Vector2 p_b, real_t p_t) const {
        Vector2 res = this;
        res.x += (p_t * (p_b.x - x));
        res.y += (p_t * (p_b.y - y));
        return res;

    }

    alias lerp = linearInterpolate;

    Vector2 cubicInterpolate(in Vector2 p_b, in Vector2 p_pre_a, in Vector2 p_post_b, real_t p_t) const {
        Vector2 p0 = p_pre_a;
        Vector2 p1 = this;
        Vector2 p2 = p_b;
        Vector2 p3 = p_post_b;

        real_t t = p_t;
        real_t t2 = t * t;
        real_t t3 = t2 * t;

        Vector2 ret;
        ret = ((p1 * 2.0) +
                (-p0 + p2) * t +
                (p0 * 2.0 - p1 * 5.0 + p2 * 4 - p3) * t2 +
                (-p0 + p1 * 3.0 - p2 * 3.0 + p3) * t3) * 0.5;

        return ret;
    }

    Vector2 slide(in Vector2 p_vec) const {
        return p_vec - this * this.dot(p_vec);
    }

    Vector2 reflect(in Vector2 p_vec) const {
        return p_vec - this * this.dot(p_vec) * 2.0;
    }

    real_t angle() const {
        return atan2(y, x);
    }

    void setRotation(real_t p_radians) {
        x = cos(p_radians);
        y = sin(p_radians);
    }

    Vector2 abs() const {
        return Vector2(fabs(x), fabs(y));
    }

    Vector2 rotated(real_t p_by) const {
        Vector2 v = void;
        v.setRotation(angle() + p_by);
        v *= length();
        return v;
    }

    Vector2 tangent() const {
        return Vector2(y, -x);
    }

    Vector2 floor() const {
        return Vector2(.floor(x), .floor(y));
    }

    Vector2 snapped(in Vector2 p_by) const {
        return Vector2(
            p_by.x != 0 ? .floor(x / p_by.x + 0.5) * p_by.x : x,
            p_by.y != 0 ? .floor(y / p_by.y + 0.5) * p_by.y : y
        );
    }
}

// TODO: replace this stub
struct Vector2i {
@nogc nothrow:

    union {
        struct {
            union {
                godot_int x = 0; /// 
                godot_int width; /// 
            }

            union {
                godot_int y = 0; /// 
                godot_int height; /// 
            }
        }

        godot_int[2] coord;
    }

    this(godot_int x, godot_int y) {
        this.x = x;
        this.y = y;
    }

    this(int[2] coord) {
        this.coord = cast(godot_int[]) coord;
    }

    this(in Vector2i b) {
        this.x = b.x;
        this.y = b.y;
    }

    this(in godot_vector2i b) {
        this.x = b._opaque[0];
        this.y = b._opaque[1];
    }

    void opAssign(in Vector2i b) {
        this.x = b.x;
        this.y = b.y;
    }

    void opAssign(in godot_vector2i b) {
        this.x = b._opaque[0];
        this.y = b._opaque[1];
    }

    ref godot_int opIndex(int axis) return {
        return axis ? y : x;
    }

    const(godot_int) opIndex(int axis) const {
        return axis ? y : x;
    }

    Vector2i opBinary(string op)(in Vector2i other) const
    if (op == "+" || op == "-" || op == "*" || op == "/") {
        Vector2i ret;
        ret.x = mixin("x " ~ op ~ "other.x");
        ret.y = mixin("y " ~ op ~ "other.y");
        return ret;
    }

    void opOpAssign(string op)(in Vector2i other)
            if (op == "+" || op == "-" || op == "*" || op == "/") {
        x = mixin("x " ~ op ~ "other.x");
        y = mixin("y " ~ op ~ "other.y");
    }

    Vector2i opUnary(string op : "-")() {
        return Vector2i(-x, -y);
    }

    Vector2i opBinary(string op)(in godot_int scalar) const
    if (op == "*" || op == "/") {
        Vector2 ret;
        ret.x = mixin("x " ~ op ~ " scalar");
        ret.y = mixin("y " ~ op ~ " scalar");
        return ret;
    }

    Vector2i opBinaryRight(string op)(in godot_int scalar) const
    if (op == "*") {
        Vector2i ret;
        ret.x = mixin("x " ~ op ~ " scalar");
        ret.y = mixin("y " ~ op ~ " scalar");
        return ret;
    }

    void opOpAssign(string op)(in godot_int scalar) if (op == "*" || op == "/") {
        x = mixin("x " ~ op ~ " scalar");
        y = mixin("y " ~ op ~ " scalar");
    }

    int opCmp(in Vector2 other) const {
        import std.algorithm.comparison;
        import std.range;

        return cmp(only(x, y), only(other.x, other.y));
    }

    Vector2 opCast(Vector2)() const {
        return Vector2(x, y);
    }

    real_t aspect() const {
        return width / cast(real_t) height;
    }

    real_t length() const {
        return cast(real_t) sqrt(cast(double) lengthSquared());
    }

    int64_t lengthSquared() const {
        return (x * cast(int64_t) x) + (y * cast(int64_t) y);
    }

    Vector2i abs() const {
        import std.math : abs;

        return Vector2i(.abs(x), .abs(y));
    }

    Vector2i clamp(in Vector2i p_min, in Vector2i p_max) const {
        import std.algorithm.comparison : _clamp = clamp; // template looses priority to local symbol
        return Vector2i(_clamp(x, p_min.x, p_max.x), _clamp(y, p_min.y, p_max.y));
    }
}

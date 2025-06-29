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
import godot.math;
import godot.api.types;

alias Size2 = Vector2;
alias Point2 = Vector2;
alias Size2i = Vector2i;
alias Point2i = Vector2i;

import std.algorithm.comparison;

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
/*@nogc nothrow:*/

    enum Axis {
        x,
        y
    }

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

    Vector2.Axis minAxisIndex() const {
		return x < y ? Axis.x : Axis.y;
	}

	Vector2.Axis maxAxisIndex() const {
		return x < y ? Axis.y : Axis.x;
	}

    int opCmp(in Vector2 other) const {
        import std.algorithm.comparison;
        import std.range;

        return cmp(only(x, y), only(other.x, other.y));
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

    bool opEquals(in Vector2 other) const {
        return x == other.x && y == other.y;
    }

    bool isEqualApprox(in Vector2 v) const {
        return isClose(x, v.x) && isClose(y, v.y);
    }

    bool isZeroApprox() const {
        return isClose(x, 0) && isClose(y, 0);
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

    bool isNormalized() const {
        // use length_squared() instead of length() to avoid sqrt(), makes it more stringent.
        return isClose(lengthSquared(), 1, UNIT_EPSILON);
    }

    real_t length() const {
        return sqrt(x * x + y * y);
    }

    real_t lengthSquared() const {
        return x * x + y * y;
    }

    Vector2 limitLength(in real_t p_len = 1.0) const {
        const real_t l = length();
        Vector2 v = this;
        if (l > 0 && p_len < l) {
            v /= l;
            v *= p_len;
        }

        return v;
    }

    Vector2 min(in Vector2 p_vector2) const {
        return Vector2(.min(x, p_vector2.x), .min(y, p_vector2.y));
    }

    Vector2 max(in Vector2 p_vector2) const {
        return Vector2(.max(x, p_vector2.x), .max(y, p_vector2.y));
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
        return (p_vector2 - this).angle();
    }

    Vector2 directionTo(in Vector2 p_to) const {
        Vector2 ret = Vector2(p_to.x - x, p_to.y - y);
        ret.normalize();
        return ret;
    }

    real_t dot(in Vector2 p_other) const {
        return x * p_other.x + y * p_other.y;
    }

    real_t cross(in Vector2 p_other) const {
        return x * p_other.y - y * p_other.x;
    }

    Vector2 posmod(in real_t p_mod) const {
        return Vector2(fposmod(x, p_mod), fposmod(y, p_mod));
    }

	Vector2 posmodv(in Vector2 p_modv) const {
        return Vector2(fposmod(x, p_modv.x), fposmod(y, p_modv.y));
    }

	Vector2 project(in Vector2 p_to) const {
        return p_to * (dot(p_to) / p_to.lengthSquared());
    }

    Vector2 planeProject(in real_t d, in Vector2 vec) const {
        return vec - this * (dot(vec) - d);
    }

    deprecated
    Vector2 cross(real_t p_other) const {
        return Vector2(p_other * y, -p_other * x);
    }

    Vector2 sign() const {
        return Vector2(sgn(x), sgn(y));
    }

    deprecated("use limitLength()")
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

    // Superbelko: godot 4 uses lerp now, not sure if it is worth to keep old name
    alias lerp = linearInterpolate;

    Vector2 slerp(in Vector2 p_to, const real_t p_weight) const {
        real_t start_length_sq = lengthSquared();
        real_t end_length_sq = p_to.lengthSquared();
        if (start_length_sq == 0.0f || end_length_sq == 0.0f) {
            // Zero length vectors have no angle, so the best we can do is either lerp or throw an error.
            return lerp(p_to, p_weight);
        }
        real_t start_length = sqrt(start_length_sq);
        real_t result_length = .lerp(start_length, sqrt(end_length_sq), p_weight);
        real_t angle = angleTo(p_to);
        return rotated(angle * p_weight) * (result_length / start_length);
    }

    Vector2 cubicInterpolate(in Vector2 p_b, in Vector2 p_pre_a, in Vector2 p_post_b, real_t p_t) const {
        Vector2 res = this;
        res.x = .cubicInterpolate(res.x, p_b.x, p_pre_a.x, p_post_b.x, p_t);
        res.y = .cubicInterpolate(res.y, p_b.y, p_pre_a.y, p_post_b.y, p_t);
        return res;
    }

    Vector2 cubicInterpolateInTime(in Vector2 p_b, in Vector2 p_pre_a, in Vector2 p_post_b, in real_t p_weight, in real_t p_b_t, in real_t p_pre_a_t, in real_t p_post_b_t) const {
        Vector2 res = this;
        res.x = .cubicInterpolateInTime(res.x, p_b.x, p_pre_a.x, p_post_b.x, p_weight, p_b_t, p_pre_a_t, p_post_b_t);
        res.y = .cubicInterpolateInTime(res.y, p_b.y, p_pre_a.y, p_post_b.y, p_weight, p_b_t, p_pre_a_t, p_post_b_t);
        return res;
    }

    Vector2 bezierInterpolate(in Vector2 p_control_1, in Vector2 p_control_2, in Vector2 p_end, in real_t p_t) const {
        Vector2 res = this;

        /* Formula from Wikipedia article on Bezier curves. */
        real_t omt = (1.0 - p_t);
        real_t omt2 = omt * omt;
        real_t omt3 = omt2 * omt;
        real_t t2 = p_t * p_t;
        real_t t3 = t2 * p_t;

        return res * omt3 + p_control_1 * omt2 * p_t * 3.0 + p_control_2 * omt * t2 * 3.0 + p_end * t3;
    }

    Vector2 moveToward(in Vector2 p_to, in real_t p_delta) const {
        Vector2 v = this;
        Vector2 vd = p_to - v;
        real_t len = vd.length();
        if (len <= p_delta || len < CMP_EPSILON)
            return p_to;
        return (v + vd / len * p_delta);
    }

    Vector2 slide(in Vector2 normal) const {
        return this - normal * this.dot(normal);
    }

    Vector2 bounce(in Vector2 normal) const {
        return -reflect(normal);
    }

    Vector2 reflect(in Vector2 normal) const {
        return 2.0f * normal * dot(normal) - this;
    }

    real_t angle() const {
        return atan2(y, x);
    }

    static Vector2 fromAngle(in real_t angle) {
        return Vector2(cos(angle), sin(angle));
    }

    deprecated("use Vector2.fromAngle()")
    void setRotation(real_t p_radians) {
        x = cos(p_radians);
        y = sin(p_radians);
    }

    Vector2 abs() const {
        return Vector2(fabs(x), fabs(y));
    }

    Vector2 rotated(real_t by) const {
        real_t sine = sin(by);
        real_t cosi = cos(by);
        return Vector2(
                x * cosi - y * sine,
                x * sine + y * cosi);
    }

    Vector2 orthogonal() const {
		return Vector2(y, -x);
	}

    Vector2 tangent() const {
        return Vector2(y, -x);
    }

    Vector2 floor() const {
        return Vector2(.floor(x), .floor(y));
    }

    Vector2 ceil() const {
        return Vector2(.ceil(x), .ceil(y));
    }

    Vector2 round() const {
        return Vector2(.round(x), .round(y));
    }

    Vector2 snapped(in Vector2 p_by) const {
        return Vector2(
            p_by.x != 0 ? .floor(x / p_by.x + 0.5) * p_by.x : x,
            p_by.y != 0 ? .floor(y / p_by.y + 0.5) * p_by.y : y
        );
    }

    bool isEqualApprox(Vector2 other) const {
        return isClose(x, other.x) && isClose(y, other.y);
    }

    Vector2 clamp(in Vector2 p_min, in Vector2 p_max) const {
        return Vector2(.clamp(x, p_min.x, p_max.x), .clamp(y, p_min.y, p_max.y));
    }
}


// ################## Vector2i ################################################ 


struct Vector2i {
/*@nogc nothrow:*/

    enum Axis {
		x,
		y,
	}

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

    this(long x, long y) {
        this.x = cast(typeof(this.x)) x;
        this.y = cast(typeof(this.y)) y;
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

    ref godot_int opIndex(int idx) return {
        return coord[idx];
    }

    const(godot_int) opIndex(int idx) const {
        return coord[idx];
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
        Vector2i ret;
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

    int opCmp(in Vector2i other) const {
        import std.algorithm.comparison;
        import std.range;

        return cmp(only(x, y), only(other.x, other.y));
    }

    Vector2 opCast(Vector2)() const {
        return Vector2(x, y);
    }

    Vector2i.Axis minAxisIndex() const {
		return x < y ? Axis.x : Axis.y;
	}

	Vector2i.Axis maxAxisIndex() const {
		return x < y ? Axis.y : Axis.x;
	}

	Vector2i min(in Vector2i p_vector2i) const {
		return Vector2i(.min(x, p_vector2i.x), .min(y, p_vector2i.y));
	}

	Vector2i max(in Vector2i p_vector2i) const {
		return Vector2i(.max(x, p_vector2i.x), .max(y, p_vector2i.y));
	}

    real_t length() const {
        return cast(real_t) sqrt(cast(double) lengthSquared());
    }

    int64_t lengthSquared() const {
        return (x * cast(int64_t) x) + (y * cast(int64_t) y);
    }

    int64_t distanceSquaredTo(in Vector2i to) const {
        return (to - this).lengthSquared();
    }

	double distanceTo(in Vector2i to) const {
        return (to - this).length();
    }

    real_t aspect() const {
        return width / cast(real_t) height;
    }

    Vector2i sign() const {
        return Vector2i(sgn(x), sgn(y));
    }

    Vector2i abs() const {
        return Vector2i(.abs(x), .abs(y));
    }

    Vector2i clamp(in Vector2i p_min, in Vector2i p_max) const {
        return Vector2i(.clamp(x, p_min.x, p_max.x), .clamp(y, p_min.y, p_max.y));
    }
}

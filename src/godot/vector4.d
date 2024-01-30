/**
Vector struct, which performs basic 3D vector math operations.

Copyright:
Copyright (c) 2007 Juan Linietsky, Ariel Manzur.
Copyright (c) 2014 Godot Engine contributors (cf. AUTHORS.md)
Copyright (c) 2017 Godot-D contributors
Copyright (c) 2022 Godot-DLang contributors

License: $(LINK2 https://opensource.org/licenses/MIT, MIT License)


*/
module godot.vector4;

// import godot.abi.core;
import godot.abi.types;
import godot.basis;
import godot.string;
import godot.math;
import godot.api.types; // CMP_EPSILON

import std.math;
import std.algorithm; // min, max, minIndex, maxIndex

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
        axisX = 0,
        axisY = 1,
        axisZ = 2,
        axisW = 3
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

    const(real_t) opIndex(int axis) const {
        return coord[axis];
    }

    ref real_t opIndex(int axis) return {
        return coord[axis];
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

    bool opEquals(in Vector4 other) const {
        return coord[] == other.coord[];
    }

    bool isEqualApprox(in Vector4 other) const {
        return isClose(x, other.x) 
            && isClose(y, other.y)
            && isClose(z, other.z)
            && isClose(w, other.w);
    }

    bool isZeroApprox(in Vector4 other) const {
        return isClose(x, 0) 
            && isClose(y, 0)
            && isClose(z, 0)
            && isClose(w, 0);
    }

    Vector4.Axis minAxisIndex() const {
        return cast(Axis) coord[].minIndex!();
    }

    Vector4.Axis maxAxisIndex() const {
        return cast(Axis) coord[].maxIndex!();
    }
    
    deprecated("use maxAxisIndex")
    alias maxAxis = maxAxisIndex;

    deprecated("use minAxisIndex")
    alias minAxis = minAxisIndex;

    Vector4 min(in Vector4 other) const {
		return Vector4(.min(x, other.x), .min(y, other.y), .min(z, other.z), .min(w, other.w));
	}

	Vector4 max(in Vector4 other) const {
		return Vector4(.max(x, other.x), .max(y, other.y), .max(z, other.z), .max(w, other.w));
	}

    Vector4 abs() const {
        return Vector4(fabs(x), fabs(y), fabs(z), fabs(w));
    }

    Vector4 sign() const {
        return Vector4(sgn(x), sgn(y), sgn(z), sgn(w));
    }

    Vector4 ceil() const {
        return Vector4(.ceil(x), .ceil(y), .ceil(z), .ceil(w));
    }

    Vector4 floor() const {
        return Vector4(.floor(x), .floor(y), .floor(z), .floor(w));
    }

    Vector4 round() const {
        return Vector4(.round(x), .round(y), .round(z), .round(w));
    }

    Vector4 linearInterpolate(in Vector4 b, real_t weight) const {
        return Vector4(
            x + (weight * (b.x - x)),
            y + (weight * (b.y - y)),
            z + (weight * (b.z - z)),
            w + (weight * (b.w - w)),
        );
    }

    alias lerp = linearInterpolate;

    Vector4 cubicInterpolate(in Vector4 b, in Vector4 pre_a, in Vector4 post_b, in real_t weight) const {
        Vector4 res = this;
        res.x = .cubicInterpolate(res.x, b.x, pre_a.x, post_b.x, weight);
        res.y = .cubicInterpolate(res.y, b.y, pre_a.y, post_b.y, weight);
        res.z = .cubicInterpolate(res.z, b.z, pre_a.z, post_b.z, weight);
        res.w = .cubicInterpolate(res.w, b.w, pre_a.w, post_b.w, weight);
        return res;
    }

    Vector4 cubicInterpolateInTime(in Vector4 b, in Vector4 pre_a, in Vector4 post_b, const real_t weight, const real_t b_t, const real_t pre_a_t, const real_t post_b_t) const {
        Vector4 res = this;
        res.x = .cubicInterpolateInTime(res.x, b.x, pre_a.x, post_b.x, weight, b_t, pre_a_t, post_b_t);
        res.y = .cubicInterpolateInTime(res.y, b.y, pre_a.y, post_b.y, weight, b_t, pre_a_t, post_b_t);
        res.z = .cubicInterpolateInTime(res.z, b.z, pre_a.z, post_b.z, weight, b_t, pre_a_t, post_b_t);
        res.w = .cubicInterpolateInTime(res.w, b.w, pre_a.w, post_b.w, weight, b_t, pre_a_t, post_b_t);
        return res;
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

    Vector4 directionTo(in Vector4 to) const {
        Vector4 ret = Vector4(to.x - x, to.y - y, to.z - z, to.w - w);
        ret.normalize();
        return ret;
    }

    real_t dot(in Vector4 b) const {
        return x * b.x + y * b.y + z * b.z + w * b.w;
    }

    Vector4 inverse() const {
        return Vector4(1.0 / x, 1.0 / y, 1.0 / z, 1.0 / w);
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

    bool isNormalized() const {
        return isClose(lengthSquared(), 1, UNIT_EPSILON);
    }

    Vector4 posmod(const real_t mod) const {
        return Vector4(fposmod(x, mod), fposmod(y, mod), fposmod(z, mod), fposmod(w, mod));
    }

	Vector4 posmodv(in Vector4 modv) const {
        return Vector4(fposmod(x, modv.x), fposmod(y, modv.y), fposmod(z, modv.z), fposmod(w, modv.w));
    }

    // deprecated, but keep for convenience
    void snap(real_t step) {
        x = .snapped(x, step);
        y = .snapped(y, step);
        z = .snapped(z, step);
        w = .snapped(w, step);
    }

    void snap(Vector4 step) {
        x = .snapped(x, step.x);
        y = .snapped(y, step.y);
        z = .snapped(z, step.z);
        w = .snapped(w, step.w);
    }

    Vector4 snapped(in real_t step) const {
        Vector4 v = this;
        v.snap(step);
        return v;
    }

    Vector4 clamp(in Vector4 min, in Vector4 max) const {
        return Vector4(
            .clamp(x, min.x, max.x),
            .clamp(y, min.y, max.y),
            .clamp(z, min.z, max.z),
            .clamp(w, min.w, max.w));
    }
}


// ################ Vector4i ##################################################

struct Vector4i {
@nogc nothrow:

    enum Axis {
        x,
        y,
        z,
        w,
        axisX = 0,
        axisY = 1,
        axisZ = 2,
        axisW = 3
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

    this(in Vector4 b) {
        this.x = cast(godot_int) b.x;
        this.y = cast(godot_int) b.y;
        this.z = cast(godot_int) b.z;
        this.w = cast(godot_int) b.w;
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

    Vector4 opCast(Vector4)() const {
        return Vector4(x, y, z, w);
    }

    const(godot_int) opIndex(int axis) const {
        return coord[axis];
    }

    ref godot_int opIndex(int axis) return {
        return coord[axis];
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

    deprecated("use maxAxisIndex")
    alias maxAxis = maxAxisIndex; 

    int maxAxisIndex() const {
        import std.algorithm : maxIndex;

        return cast(int) coord[].maxIndex!();
    }

    deprecated("use minAxisIndex")
    alias minAxis = minAxisIndex;

    int minAxisIndex() const {
        import std.algorithm : minIndex;

        return cast(int) coord[].minIndex!();
    }

    Vector4i min(in Vector4i other) const {
		return Vector4i(.min(x, other.x), .min(y, other.y), .min(z, other.z), .min(w, other.w));
	}

	Vector4i max(in Vector4i other) const {
		return Vector4i(.max(x, other.x), .max(y, other.y), .max(z, other.z), .max(w, other.w));
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

    Vector4i clamp(in Vector4i min, in Vector4i max) const {
        return Vector4i(
			.clamp(x, min.x, max.x),
			.clamp(y, min.y, max.y),
			.clamp(z, min.z, max.z),
			.clamp(w, min.w, max.w));
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

    int64_t distanceSquaredTo(in Vector4i to) const {
        return (to - this).lengthSquared();
    }

    double distanceTo(in Vector4i to) const {
        return (to - this).length();
    }
}

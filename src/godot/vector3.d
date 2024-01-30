/**
Vector struct, which performs basic 3D vector math operations.

Copyright:
Copyright (c) 2007 Juan Linietsky, Ariel Manzur.
Copyright (c) 2014 Godot Engine contributors (cf. AUTHORS.md)
Copyright (c) 2017 Godot-D contributors
Copyright (c) 2022 Godot-DLang contributors

License: $(LINK2 https://opensource.org/licenses/MIT, MIT License)


*/
module godot.vector3;

import godot.abi.core;
import godot.abi.types;
import godot.api.types;
import godot.basis;
import godot.string;
import godot.math;
import godot.vector2;


import std.algorithm.comparison; // min, max
import std.math;

private bool isValidSwizzle(dstring s) {
    import std.algorithm : canFind;

    if (s.length != 2 && s.length != 3)
        return false;
    foreach (dchar c; s) {
        if (!"xyzn".canFind(c))
            return false;
    }
    return true;
}

/**
Vector3 is one of the core classes of the engine, and includes several built-in helper functions to perform basic vector math operations.
*/
struct Vector3 {
@nogc nothrow:

    enum Axis {
        x = 0,
        y = 1,
        z = 3,
        axisX = 0,
        axisY = 1,
        axisZ = 2
    }

    union {
        struct {
            real_t x = 0; /// 
            real_t y = 0; /// 
            real_t z = 0; /// 
        }

        real_t[3] coord;
    }

    import std.algorithm : count;

    /++
	Swizzle the vector with x, y, z, or n. Pass floats as args for any n's; if
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

    this(real_t x, real_t y, real_t z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    this(real_t[3] coord) {
        this.coord = coord;
    }

    this(in Vector3 b) {
        this.x = b.x;
        this.y = b.y;
        this.z = b.z;
    }

    void opAssign(in Vector3 b) {
        this.x = b.x;
        this.y = b.y;
        this.z = b.z;
    }

    const(real_t) opIndex(int axis) const {
        return coord[axis];
    }

    ref real_t opIndex(int axis) return {
        return coord[axis];
    }

    Vector3 opBinary(string op)(in Vector3 other) const
    if (op == "+" || op == "-" || op == "*" || op == "/") {
        Vector3 ret;
        ret.x = mixin("x " ~ op ~ "other.x");
        ret.y = mixin("y " ~ op ~ "other.y");
        ret.z = mixin("z " ~ op ~ "other.z");
        return ret;
    }

    void opOpAssign(string op)(in Vector3 other)
            if (op == "+" || op == "-" || op == "*" || op == "/") {
        x = mixin("x " ~ op ~ "other.x");
        y = mixin("y " ~ op ~ "other.y");
        z = mixin("z " ~ op ~ "other.z");
    }

    Vector3 opUnary(string op : "-")() const {
        return Vector3(-x, -y, -z);
    }

    Vector3 opBinary(string op)(in real_t scalar) const
    if (op == "*" || op == "/") {
        Vector3 ret;
        ret.x = mixin("x " ~ op ~ " scalar");
        ret.y = mixin("y " ~ op ~ " scalar");
        ret.z = mixin("z " ~ op ~ " scalar");
        return ret;
    }

    Vector3 opBinaryRight(string op)(in real_t scalar) const
    if (op == "*") {
        Vector3 ret;
        ret.x = mixin("x " ~ op ~ " scalar");
        ret.y = mixin("y " ~ op ~ " scalar");
        ret.z = mixin("z " ~ op ~ " scalar");
        return ret;
    }

    void opOpAssign(string op)(in real_t scalar) if (op == "*" || op == "/") {
        x = mixin("x " ~ op ~ " scalar");
        y = mixin("y " ~ op ~ " scalar");
        z = mixin("z " ~ op ~ " scalar");
    }

    Vector3i opCast(Vector3i)() const {
        return Vector3i(x, y, z);
    }

    int opCmp(in Vector3 other) const {
        import std.algorithm.comparison;

        return cmp(this.coord[], other.coord[]);
    }

    bool opEquals(in Vector3 other) const {
        return x == other.x && y == other.y && z == other.z;
    }

    Vector3.Axis minAxisIndex() const {
		return x < y ? (x < z ? Axis.x : Axis.z) : (y < z ? Axis.y : Axis.z);
	}

	Vector3.Axis maxAxisIndex() const {
		return x < y ? (y < z ? Axis.z : Axis.y) : (x < z ? Axis.z : Axis.x);
	}

	Vector3 min(in Vector3 other) const {
		return Vector3(.min(x, other.x), .min(y, other.y), .min(z, other.z));
	}

	Vector3 max(in Vector3 other) const {
		return Vector3(.max(x, other.x), .max(y, other.y), .max(z, other.z));
	}

    void zero() { 
        coord[] = 0;
    }

    Vector3 abs() const {
        return Vector3(fabs(x), fabs(y), fabs(z));
    }

    Vector3 ceil() const {
        return Vector3(.ceil(x), .ceil(y), .ceil(z));
    }

    Vector3 floor() const {
        return Vector3(.floor(x), .floor(y), .floor(z));
    }

    Vector3 sign() const {
        return Vector3(.sgn(x), .sgn(y), .sgn(z));
    }

    Vector3 round() const {
        return Vector3(.round(x), .round(y), .round(z));
    }

    Vector3 clamp(in Vector3 min, in Vector3 max) const {
        return Vector3(
            .clamp(x, min.x, max.x),
            .clamp(y, min.y, max.y),
            .clamp(z, min.z, max.z),
        );
    }

    Vector3 posmod(const real_t mod) const {
        return Vector3(.fposmod(x, mod), .fposmod(y, mod), .fposmod(z, mod));
    }

    Vector3 posmodv(in Vector3 modv) const {
        return Vector3(.fposmod(x, modv.x), .fposmod(y, modv.y), .fposmod(z, modv.z));
    }

    Vector3 project(in Vector3 to) const {
        return to * (dot(to) / to.lengthSquared());
    }

    real_t angleTo(in Vector3 to) const {
        return atan2(cross(to).length(), dot(to));
    }

    real_t signedAngleTo(in Vector3 to, in Vector3 axis) const {
        Vector3 cross_to = cross(to);
        real_t unsigned_angle = atan2(cross_to.length(), dot(to));
        real_t sign = cross_to.dot(axis);
        return (sign < 0) ? -unsigned_angle : unsigned_angle;
    }

    Vector3 directionTo(in Vector3 to) const {
        Vector3 ret = Vector3(to.x - x, to.y - y, to.z - z);
        ret.normalize();
        return ret;
    }

    Vector3 cross(in Vector3 b) const {
        return Vector3(
            (y * b.z) - (z * b.y),
            (z * b.x) - (x * b.z),
            (x * b.y) - (y * b.x)
        );
    }

    Vector3 linearInterpolate(in Vector3 b, const real_t t) const {
        return Vector3(
            x + (t * (b.x - x)),
            y + (t * (b.y - y)),
            z + (t * (b.z - z))
        );
    }

    alias lerp = linearInterpolate;

    Vector3 slerp(in Vector3 to, const real_t weight) const {
        // This method seems more complicated than it really is, since we write out
        // the internals of some methods for efficiency (mainly, checking length).
        real_t start_length_sq = lengthSquared();
        real_t end_length_sq = to.lengthSquared();
        if (start_length_sq == 0.0f || end_length_sq == 0.0f) {
            // Zero length vectors have no angle, so the best we can do is either lerp or throw an error.
            return lerp(to, weight);
        }
        Vector3 axis = cross(to);
        real_t axis_length_sq = axis.lengthSquared();
        if (axis_length_sq == 0.0f) {
            // Colinear vectors have no rotation axis or angle between them, so the best we can do is lerp.
            return lerp(to, weight);
        }
        axis /= sqrt(axis_length_sq);
        real_t start_length = sqrt(start_length_sq);
        real_t result_length = .lerp(start_length, .sqrt(end_length_sq), weight);
        real_t angle = angleTo(to);
        return rotated(axis, angle * weight) * (result_length / start_length);
    }

    Vector3 cubicInterpolate(in Vector3 b, in Vector3 pre_a, in Vector3 post_b, const real_t weight) const {
        Vector3 res = this;
        res.x = .cubicInterpolate(res.x, b.x, pre_a.x, post_b.x, weight);
        res.y = .cubicInterpolate(res.y, b.y, pre_a.y, post_b.y, weight);
        res.z = .cubicInterpolate(res.z, b.z, pre_a.z, post_b.z, weight);
        return res;
    }

    Vector3 cubicInterpolateInTime(in Vector3 b, in Vector3 pre_a, in Vector3 post_b, const real_t weight, const real_t b_t, const real_t pre_a_t, const real_t post_b_t) const {
        Vector3 res = this;
        res.x = .cubicInterpolateInTime(res.x, b.x, pre_a.x, post_b.x, weight, b_t, pre_a_t, post_b_t);
        res.y = .cubicInterpolateInTime(res.y, b.y, pre_a.y, post_b.y, weight, b_t, pre_a_t, post_b_t);
        res.z = .cubicInterpolateInTime(res.z, b.z, pre_a.z, post_b.z, weight, b_t, pre_a_t, post_b_t);
        return res;
    }

    Vector3 bezierInterpolate(in Vector3 control_1, in Vector3 control_2, in Vector3 end, const real_t t) const {
        Vector3 res = this;

        /* Formula from Wikipedia article on Bezier curves. */
        real_t omt = (1.0 - t);
        real_t omt2 = omt * omt;
        real_t omt3 = omt2 * omt;
        real_t t2 = t * t;
        real_t t3 = t2 * t;

        return res * omt3 + control_1 * omt2 * t * 3.0 + control_2 * omt * t2 * 3.0 + end * t3;
    }

    Vector3 moveToward(in Vector3 to, const real_t delta) const {
        Vector3 v = this;
        Vector3 vd = to - v;
        real_t len = vd.length();
        if (len <= delta || len < CMP_EPSILON)
            return to;
        return (v + vd / len * delta);
    }

    Vector2 octahedronEncode() const {
        Vector3 n = this;
        n /= .abs(n.x) + .abs(n.y) + .abs(n.z);
        Vector2 o;
        if (n.z >= 0.0f) {
            o.x = n.x;
            o.y = n.y;
        } else {
            o.x = (1.0f - .abs(n.y)) * (n.x >= 0.0f ? 1.0f : -1.0f);
            o.y = (1.0f - .abs(n.x)) * (n.y >= 0.0f ? 1.0f : -1.0f);
        }
        o.x = o.x * 0.5f + 0.5f;
        o.y = o.y * 0.5f + 0.5f;
        return o;
    }

    static Vector3 octahedronDecode(in Vector2 oct) {
        Vector2 f = Vector2(oct.x * 2.0f - 1.0f, oct.y * 2.0f - 1.0f);
        Vector3 n = Vector3(f.x, f.y, 1.0f - .abs(f.x) - .abs(f.y));
        float t = .clamp(-n.z, 0.0f, 1.0f);
        n.x += n.x >= 0 ? -t : t;
        n.y += n.y >= 0 ? -t : t;
        return n.normalized();
    }

    Vector2 octahedronTangentEncode(const float sign) const {
        Vector2 res = octahedronEncode();
        res.y = res.y * 0.5f + 0.5f;
        res.y = sign >= 0.0f ? res.y : 1 - res.y;
        return res;
    }

	static Vector3 octahedronTangentDecode(in Vector2 oct, float *sign) {
        Vector2 oct_compressed = oct;
        oct_compressed.y = oct_compressed.y * 2 - 1;
        *sign = oct_compressed.y >= 0.0f ? 1.0f : -1.0f;
        oct_compressed.y = .abs(oct_compressed.y);
        Vector3 res = Vector3.octahedronDecode(oct_compressed);
        return res;
    }

    real_t length() const {
        real_t x2 = x * x;
        real_t y2 = y * y;
        real_t z2 = z * z;

        return sqrt(x2 + y2 + z2);
    }

    real_t lengthSquared() const {
        real_t x2 = x * x;
        real_t y2 = y * y;
        real_t z2 = z * z;

        return x2 + y2 + z2;
    }

    real_t distanceSquaredTo(in Vector3 other) const {
        return (other - this).length();
    }

    real_t distanceTo(in Vector3 other) const {
        return (other - this).lengthSquared();
    }

    real_t dot(in Vector3 other) const {
        return x * other.x + y * other.y + z * other.z;
    }

    Basis outer(in Vector3 other) const {
        Basis basis;
        basis.rows[0] = Vector3(x * other.x, x * other.y, x * other.z);
        basis.rows[1] = Vector3(y * other.x, y * other.y, y * other.z);
        basis.rows[2] = Vector3(z * other.x, z * other.y, z * other.z);
        return basis;
    }

    Vector3 inverse() const {
        return Vector3(1.0 / x, 1.0 / y, 1.0 / z);
    }

    int maxAxis() const {
        return (x < y) ? (y < z ? 2 : 1) : (x < z ? 2 : 0);
    }

    int minAxis() const {
        return (x < y) ? (x < z ? 0 : 2) : (y < z ? 1 : 2);
    }

    void normalize() {
        real_t lensq = lengthSquared();
        if (lensq == 0) {
            x = y = z = 0;
        } else {
            real_t l = sqrt(lensq);
            x /= l;
            y /= l;
            z /= l;
        }
    }

    Vector3 normalized() const {
        Vector3 v = this;
        v.normalize();
        return v;
    }

    bool isNormalized() const {
        // use length_squared() instead of length() to avoid sqrt(), makes it more stringent.
        return isClose(lengthSquared(), 1, UNIT_EPSILON);
    }

    Vector3 limitLength(in real_t newLength = 1.0) const {
        const real_t curLength = length();
        Vector3 v = this;
        if (curLength > 0 && newLength < curLength) {
            v /= curLength;
            v *= newLength;
        }

        return v;
    }

    Vector3 rotated(in Vector3 axis, in real_t angle) const {
        Vector3 v = this;
        v.rotate(axis, angle);
        return v;
    }

    void rotate(in Vector3 axis, in real_t angle) {
        this = Basis(axis, angle).xform(this);
    }

    // slide returns the component of the vector along the given plane, specified by its normal vector.
    Vector3 slide(in Vector3 normal) const {
        return this - normal * this.dot(normal);
    }

    Vector3 bounce(in Vector3 normal) const {
        return -reflect(normal);
    }

	Vector3 reflect(in Vector3 normal) const {
        return 2.0 * normal * this.dot(normal) - this;
    }

    // Superbelko: should we keep it for convenience?
    deprecated("use snap(Vector3)")
    void snap(real_t step) {
        snap(Vector3(step, step, step));
    }

    void snap(Vector3 step) {
        static foreach (i; 0..coord.length)
            coord[i] = .snapped(coord[i], step[i]);
    }

    deprecated("use snapped(Vector3)")
    Vector3 snapped(in real_t step) const {
        Vector3 v = this;
        v.snap(Vector3(step, step, step));
        return v;
    }

    Vector3 snapped(in Vector3 step) const {
        Vector3 v = this;
        v.snap(step);
        return v;
    }

    bool isEqualApprox(in Vector3 other) const {
        import std.math : isClose;
        return isClose(x, other.x) && isClose(y, other.y) && isClose(z, other.z);
    }

    bool isZeroApprox() const {
        import std.math : isClose;
        return isClose(x, 0) && isClose(y, 0) && isClose(z, 0);
    }
}

struct Vector3i {
@nogc nothrow:

    enum Axis {
        x,
        y,
        z,
        axisX = 0,
        axisY = 1,
        axisZ = 2
    }

    union {
        struct {
            int x = 0; /// 
            int y = 0; /// 
            int z = 0; /// 
        }

        int[3] coord;
    }

    this(int x, int y, int z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    this(int[3] coord) {
        this.coord = coord;
    }

    this(in Vector3i b) {
        this.x = b.x;
        this.y = b.y;
        this.z = b.z;
    }

    void opAssign(in Vector3i b) {
        this.x = b.x;
        this.y = b.y;
        this.z = b.z;
    }

    void opAssign(in godot_vector3i b) {
        this.x = b._opaque[0];
        this.y = b._opaque[1];
        this.z = b._opaque[2];
    }

    const(godot_int) opIndex(int axis) const {
        return coord[axis];
    }

    ref godot_int opIndex(int axis) return {
        return coord[axis];
    }

    Vector3i opBinary(string op)(in Vector3i other) const
    if (op == "+" || op == "-" || op == "*" || op == "/") {
        Vector3i ret;
        ret.x = mixin("x " ~ op ~ "other.x");
        ret.y = mixin("y " ~ op ~ "other.y");
        ret.z = mixin("z " ~ op ~ "other.z");
        return ret;
    }

    void opOpAssign(string op)(in Vector3i other)
            if (op == "+" || op == "-" || op == "*" || op == "/") {
        x = mixin("x " ~ op ~ "other.x");
        y = mixin("y " ~ op ~ "other.y");
        z = mixin("z " ~ op ~ "other.z");
    }

    Vector3i opUnary(string op : "-")() {
        return Vector3i(-x, -y, -z);
    }

    Vector3i opBinary(string op)(in godot_int scalar) const
    if (op == "*" || op == "/") {
        Vector3i ret;
        ret.x = mixin("x " ~ op ~ " scalar");
        ret.y = mixin("y " ~ op ~ " scalar");
        ret.z = mixin("z " ~ op ~ " scalar");
        return ret;
    }

    Vector3i opBinaryRight(string op)(in godot_int scalar) const
    if (op == "*") {
        Vector3i ret;
        ret.x = mixin("x " ~ op ~ " scalar");
        ret.y = mixin("y " ~ op ~ " scalar");
        ret.z = mixin("z " ~ op ~ " scalar");
        return ret;
    }

    void opOpAssign(string op)(in godot_int scalar) if (op == "*" || op == "/") {
        x = mixin("x " ~ op ~ " scalar");
        y = mixin("y " ~ op ~ " scalar");
        z = mixin("z " ~ op ~ " scalar");
    }

    int opCmp(in Vector3i other) const {
        import std.algorithm.comparison;

        return cmp(this.coord[], other.coord[]);
    }

    bool opEquals(in Vector3i other) const {
        return coord[] == other.coord[];
    }

    int maxAxis() const {
        return (x < y) ? (y < z ? 2 : 1) : (x < z ? 2 : 0);
    }

    int minAxis() const {
        return (x < y) ? (x < z ? 0 : 2) : (y < z ? 1 : 2);
    }

    Vector3i.Axis minAxisIndex() const {
		return x < y ? (x < z ? Axis.x : Axis.z) : (y < z ? Axis.y : Axis.z);
	}

	Vector3i.Axis maxAxisIndex() const {
		return x < y ? (y < z ? Axis.z : Axis.y) : (x < z ? Axis.z : Axis.x);
	}

    Vector3i min(in Vector3i other) const {
        return Vector3i(.min(x, other.x), .min(y, other.y), .min(z, other.z));
    }

    Vector3i max(in Vector3i other) const {
		return Vector3i(.max(x, other.x), .max(y, other.y), .max(z, other.z));
	}

    void zero() {
        coord[] = 0;
    }

    int64_t lengthSquared() const {
        return (x * cast(int64_t) x) + (y * cast(int64_t) y) + (z * cast(int64_t) z);
    }

    double length() const {
        return sqrt(cast(double) lengthSquared());
    }

    Vector3i abs() const {
        return Vector3i(.abs(x), .abs(y), .abs(z));
    }

    Vector3i sign() const {
        //static int isign(int i) { return i == 0 ? 0 : (i < 0 ? -1 : 1); }
        return Vector3i(sgn(x), sgn(y), sgn(z));
    }

    Vector3i clamp(in Vector3i min, in Vector3i max) const {
        return Vector3i(.clamp(x, min.x, max.x), .clamp(y, min.y, max.y), .clamp(z, min.z, max.z));
    }

    Vector3 opCast(Vector3)() const {
        return Vector3(x, y, z);
    }
}

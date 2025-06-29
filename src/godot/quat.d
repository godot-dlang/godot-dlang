/**
Quaternion.

Copyright:
Copyright (c) 2007 Juan Linietsky, Ariel Manzur.
Copyright (c) 2014 Godot Engine contributors (cf. AUTHORS.md)
Copyright (c) 2017 Godot-D contributors
Copyright (c) 2022 Godot-DLang contributors

License: $(LINK2 https://opensource.org/licenses/MIT, MIT License)


*/
module godot.quat;

import godot.api.types;
import godot.vector3;
import godot.basis;
import godot.math;
import godot.globalenums : EulerOrder;

import std.algorithm.comparison : clamp;

/**
A 4-dimensional vector representing a rotation.

The vector represents a 4 dimensional complex number where multiplication of the basis elements is not commutative (multiplying i with j gives a different result than multiplying j with i).

Multiplying quaternions reproduces rotation sequences. However quaternions need to be often renormalized, or else they suffer from precision issues.

It can be used to perform SLERP (spherical-linear interpolation) between two rotations.
*/
struct Quaternion {
/*@nogc nothrow:*/

    union { 
        struct {
            real_t x = 0;
            real_t y = 0;
            real_t z = 0;
            real_t w = 1;
        }
        real_t[4] components;
    }

    void set(real_t x, real_t y, real_t z, real_t w) {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }

    this(real_t x, real_t y, real_t z, real_t w) {
        set(x,y,z,w);
    }

    real_t length() const {
        return sqrt(lengthSquared());
    }

    bool isEqualApprox(in Quaternion quaternion) const {
	    return isClose(x, quaternion.x) && isClose(y, quaternion.y) && isClose(z, quaternion.z) && isClose(w, quaternion.w);
    }

    void normalize() {
        this /= length();
    }

    Quaternion normalized() const {
        return this / length();
    }

    bool isNormalized() const {
        return isClose(lengthSquared(), 1.0f, UNIT_EPSILON); //use less epsilon
    }

    Quaternion inverse() const {
        return Quaternion(-x, -y, -z, w);
    }

    Quaternion log() const {
        Quaternion src = this;
        Vector3 src_v = src.getAxis() * src.getAngle();
        return Quaternion(src_v.x, src_v.y, src_v.z, 0);
    }

    Quaternion exp() const {
        Quaternion src = this;
        Vector3 src_v = Vector3(src.x, src.y, src.z);
        real_t theta = src_v.length();
        src_v = src_v.normalized();
        if (theta < CMP_EPSILON || !src_v.isNormalized()) {
            return Quaternion(0, 0, 0, 1);
        }
        return Quaternion(src_v, theta);
    }

    real_t angleTo(in Quaternion to) const {
        real_t d = dot(to);
        return acos(clamp(d * d * 2 - 1, -1, 1));
    }

    void setEuler(in Vector3 euler) {
        real_t half_a1 = euler.x * 0.5;
        real_t half_a2 = euler.y * 0.5;
        real_t half_a3 = euler.z * 0.5;

        // R = X(a1).Y(a2).Z(a3) convention for Euler angles.
        // Conversion to quaternion as listed in https://ntrs.nasa.gov/archive/nasa/casi.ntrs.nasa.gov/19770024290.pdf (page A-2)
        // a3 is the angle of the first rotation, following the notation in this reference.

        real_t cos_a1 = cos(half_a1);
        real_t sin_a1 = sin(half_a1);
        real_t cos_a2 = cos(half_a2);
        real_t sin_a2 = sin(half_a2);
        real_t cos_a3 = cos(half_a3);
        real_t sin_a3 = sin(half_a3);

        set(sin_a1 * cos_a2 * cos_a3 + sin_a2 * sin_a3 * cos_a1,
            -sin_a1 * sin_a3 * cos_a2 + sin_a2 * cos_a1 * cos_a3,
            sin_a1 * sin_a2 * cos_a3 + sin_a3 * cos_a1 * cos_a2,
            -sin_a1 * sin_a2 * sin_a3 + cos_a1 * cos_a2 * cos_a3);
    }

    Quaternion slerp(in Quaternion to, in real_t weight) const {
        Quaternion to1;
        real_t omega, cosom, sinom, scale0, scale1;
        // calc cosine
        cosom = dot(to);

        // adjust signs (if necessary)
        if (cosom < 0.0) {
            cosom = -cosom;
            to1 = -to;
        } else {
            to1 = to;
        }
        // calculate coefficients
        if ((1.0 - cosom) > CMP_EPSILON) {
            // standard case (slerp)
            omega = acos(cosom);
            sinom = sin(omega);
            scale0 = sin((1.0 - weight) * omega) / sinom;
            scale1 = sin(weight * omega) / sinom;
        } else {
            // "from" and "to" quaternions are very close
            //  ... so we can do a linear interpolation
            scale0 = 1.0 - weight;
            scale1 = weight;
        }
        // calculate final values
        return Quaternion(
            scale0 * x + scale1 * to1.x,
            scale0 * y + scale1 * to1.y,
            scale0 * z + scale1 * to1.z,
            scale0 * w + scale1 * to1.w
        );
    }

    Quaternion slerpni(in Quaternion to, in real_t weight) const {
        Quaternion from = this;

        real_t dot = from.dot(to);

        if (fabs(dot) > 0.9999)
            return from;

        real_t theta = acos(dot),
        sinT = 1.0 / sin(theta),
        newFactor = sin(weight * theta) * sinT,
        invFactor = sin((1.0 - weight) * theta) * sinT;

        return Quaternion(invFactor * from.x + newFactor * to.x,
            invFactor * from.y + newFactor * to.y,
            invFactor * from.z + newFactor * to.z,
            invFactor * from.w + newFactor * to.w);
    }

    alias sphericalCubicInterpolate = cubicSlerp;
    Quaternion cubicSlerp(in Quaternion b, in Quaternion preA, in Quaternion postB, in real_t weight) const {
        // assert(isNormalized(), "start quaternion must be normalized");
        // assert(b.isNormalized(), "end quaternion must be normalized");
        Quaternion from_q = this;
        Quaternion pre_q = preA;
        Quaternion to_q = b;
        Quaternion post_q = postB;

        // Align flip phases.
        from_q = Basis(from_q).getRotationQuaternion();
        pre_q = Basis(pre_q).getRotationQuaternion();
        to_q = Basis(to_q).getRotationQuaternion();
        post_q = Basis(post_q).getRotationQuaternion();

        // Flip quaternions to shortest path if necessary.
        bool flip1 = sgn(from_q.dot(pre_q)) > 0;
        pre_q = flip1 ? -pre_q : pre_q;
        bool flip2 = sgn(from_q.dot(to_q)) > 0;
        to_q = flip2 ? -to_q : to_q;
        bool flip3 = flip2 ? to_q.dot(post_q) <= 0 : sgn(to_q.dot(post_q)) > 0;
        post_q = flip3 ? -post_q : post_q;

        // Calc by Expmap in from_q space.
        Quaternion ln_from = Quaternion(0, 0, 0, 0);
        Quaternion ln_to = (from_q.inverse() * to_q).log();
        Quaternion ln_pre = (from_q.inverse() * pre_q).log();
        Quaternion ln_post = (from_q.inverse() * post_q).log();
        Quaternion ln = Quaternion(0, 0, 0, 0);
        ln.x = cubicInterpolate(ln_from.x, ln_to.x, ln_pre.x, ln_post.x, weight);
        ln.y = cubicInterpolate(ln_from.y, ln_to.y, ln_pre.y, ln_post.y, weight);
        ln.z = cubicInterpolate(ln_from.z, ln_to.z, ln_pre.z, ln_post.z, weight);
        Quaternion q1 = from_q * ln.exp();

        // Calc by Expmap in to_q space.
        ln_from = (to_q.inverse() * from_q).log();
        ln_to = Quaternion(0, 0, 0, 0);
        ln_pre = (to_q.inverse() * pre_q).log();
        ln_post = (to_q.inverse() * post_q).log();
        ln = Quaternion(0, 0, 0, 0);
        ln.x = cubicInterpolate(ln_from.x, ln_to.x, ln_pre.x, ln_post.x, weight);
        ln.y = cubicInterpolate(ln_from.y, ln_to.y, ln_pre.y, ln_post.y, weight);
        ln.z = cubicInterpolate(ln_from.z, ln_to.z, ln_pre.z, ln_post.z, weight);
        Quaternion q2 = to_q * ln.exp();

        // To cancel error made by Expmap ambiguity, do blends.
        return q1.slerp(q2, weight);
    }

     Quaternion sphericalCubicInterpolateInTime(in Quaternion b, in Quaternion preA, in Quaternion postB, in real_t weight,
            in real_t bT, in real_t preAT, in real_t postBT) const {
        // assert(isNormalized(), "start quaternion must be normalized");
        // assert(b.isNormalized(), "end quaternion must be normalized");
        Quaternion from_q = this;
        Quaternion pre_q = preA;
        Quaternion to_q = b;
        Quaternion post_q = postB;

        // Align flip phases.
        from_q = Basis(from_q).getRotationQuaternion();
        pre_q = Basis(pre_q).getRotationQuaternion();
        to_q = Basis(to_q).getRotationQuaternion();
        post_q = Basis(post_q).getRotationQuaternion();

        // Flip quaternions to shortest path if necessary.
        bool flip1 = sgn(from_q.dot(pre_q)) > 0;
        pre_q = flip1 ? -pre_q : pre_q;
        bool flip2 = sgn(from_q.dot(to_q)) > 0;
        to_q = flip2 ? -to_q : to_q;
        bool flip3 = flip2 ? to_q.dot(post_q) <= 0 : sgn(to_q.dot(post_q)) > 0;
        post_q = flip3 ? -post_q : post_q;

        // Calc by Expmap in from_q space.
        Quaternion ln_from = Quaternion(0, 0, 0, 0);
        Quaternion ln_to = (from_q.inverse() * to_q).log();
        Quaternion ln_pre = (from_q.inverse() * pre_q).log();
        Quaternion ln_post = (from_q.inverse() * post_q).log();
        Quaternion ln = Quaternion(0, 0, 0, 0);
        ln.x = cubicInterpolateInTime(ln_from.x, ln_to.x, ln_pre.x, ln_post.x, weight, bT, preAT, postBT);
        ln.y = cubicInterpolateInTime(ln_from.y, ln_to.y, ln_pre.y, ln_post.y, weight, bT, preAT, postBT);
        ln.z = cubicInterpolateInTime(ln_from.z, ln_to.z, ln_pre.z, ln_post.z, weight, bT, preAT, postBT);
        Quaternion q1 = from_q * ln.exp();

        // Calc by Expmap in to_q space.
        ln_from = (to_q.inverse() * from_q).log();
        ln_to = Quaternion(0, 0, 0, 0);
        ln_pre = (to_q.inverse() * pre_q).log();
        ln_post = (to_q.inverse() * post_q).log();
        ln = Quaternion(0, 0, 0, 0);
        ln.x = cubicInterpolateInTime(ln_from.x, ln_to.x, ln_pre.x, ln_post.x, weight, bT, preAT, postBT);
        ln.y = cubicInterpolateInTime(ln_from.y, ln_to.y, ln_pre.y, ln_post.y, weight, bT, preAT, postBT);
        ln.z = cubicInterpolateInTime(ln_from.z, ln_to.z, ln_pre.z, ln_post.z, weight, bT, preAT, postBT);
        Quaternion q2 = to_q * ln.exp();

        // To cancel error made by Expmap ambiguity, do blends.
        return q1.slerp(q2, weight);
    }

    Vector3 getAxis() const {
        if (fabs(w) > 1 - CMP_EPSILON) {
            return Vector3(x, y, z);
        }
        real_t r = (cast(real_t)1) / sqrt(1 - w * w);
        return Vector3(x * r, y * r, z * r);
    }

    real_t getAngle() const {
        return 2 * acos(w);
    }

    void getAxisAndAngle(out Vector3 axis, out real_t angle) const {
        angle = 2 * acos(w);
        axis.x = x / sqrt(1.0 - w * w);
        axis.y = y / sqrt(1.0 - w * w);
        axis.z = z / sqrt(1.0 - w * w);
    }

    Quaternion opBinary(string op : "*")(in Vector3 v) const {
        return Quaternion(w * v.x + y * v.z - z * v.y,
            w * v.y + z * v.x - x * v.z,
            w * v.z + x * v.y - y * v.x,
            -x * v.x - y * v.y - z * v.z);
    }

    ref real_t opIndex(size_t index) {
        return components[index];
    }

    real_t opIndex(size_t index) const {
        return components[index];
    }

    Vector3 xform(in Vector3 v) const {
        Vector3 u = Vector3(x, y, z);
		Vector3 uv = u.cross(v);
		return v + ((uv * w) + u.cross(uv)) * 2.0;
    }

    Vector3 xformInv(in Vector3 v) const {
		return inverse().xform(v);
	}

    this(in Vector3 axis, in real_t angle) {
        real_t d = axis.length();
        if (d == 0)
            set(0, 0, 0, 0);
        else {
            real_t sin_angle = sin(angle * 0.5);
            real_t cos_angle = cos(angle * 0.5);
            real_t s = sin_angle / d;
            set(axis.x * s, axis.y * s, axis.z * s,
                cos_angle);
        }
    }

    this(in Vector3 v0, in Vector3 v1) // shortest arc
    {
        Vector3 c = v0.cross(v1);
        real_t d = v0.dot(v1);

        if (d < -1.0 + CMP_EPSILON) {
            x = 0;
            y = 1;
            z = 0;
            w = 0;
        } else {
            real_t s = sqrt((1.0 + d) * 2.0);
            real_t rs = 1.0 / s;

            x = c.x * rs;
            y = c.y * rs;
            z = c.z * rs;
            w = s * 0.5;
        }
    }

    // same as Quaternion.fromEuler
    this(in Vector3 eulerYXZ) {
        real_t half_a1 = eulerYXZ.y * 0.5f;
        real_t half_a2 = eulerYXZ.x * 0.5f;
        real_t half_a3 = eulerYXZ.z * 0.5f;

        // R = Y(a1).X(a2).Z(a3) convention for Euler angles.
        // Conversion to quaternion as listed in https://ntrs.nasa.gov/archive/nasa/casi.ntrs.nasa.gov/19770024290.pdf (page A-6)
        // a3 is the angle of the first rotation, following the notation in this reference.

        real_t cos_a1 = cos(half_a1);
        real_t sin_a1 = sin(half_a1);
        real_t cos_a2 = cos(half_a2);
        real_t sin_a2 = sin(half_a2);
        real_t cos_a3 = cos(half_a3);
        real_t sin_a3 = sin(half_a3);

        x = sin_a1 * cos_a2 * sin_a3 + cos_a1 * sin_a2 * cos_a3;
        y = sin_a1 * cos_a2 * cos_a3 - cos_a1 * sin_a2 * sin_a3;
        z = -sin_a1 * sin_a2 * cos_a3 + cos_a1 * cos_a2 * sin_a3;
        w = sin_a1 * sin_a2 * sin_a3 + cos_a1 * cos_a2 * cos_a3;
    }

    real_t dot(in Quaternion q) const {
        return x * q.x + y * q.y + z * q.z + w * q.w;
    }

    real_t lengthSquared() const {
        return dot(this);
    }

    void opOpAssign(string op : "+")(in Quaternion q) {
        x += q.x;
        y += q.y;
        z += q.z;
        w += q.w;
    }

    void opOpAssign(string op : "-")(in Quaternion q) {
        x -= q.x;
        y -= q.y;
        z -= q.z;
        w -= q.w;
    }

    void opOpAssign(string op : "*")(in Quaternion q) {
        x *= q.x;
        y *= q.y;
        z *= q.z;
        w *= q.w;
    }

    void opOpAssign(string op : "*")(in real_t s) {
        x *= s;
        y *= s;
        z *= s;
        w *= s;
    }

    void opOpAssign(string op : "/")(in real_t s) {
        this *= 1.0 / s;
    }

    Quaternion opBinary(string op : "+")(in Quaternion q2) const {
        Quaternion q1 = this;
        return Quaternion(q1.x + q2.x, q1.y + q2.y, q1.z + q2.z, q1.w + q2.w);
    }

    Quaternion opBinary(string op : "-")(in Quaternion q2) const {
        Quaternion q1 = this;
        return Quaternion(q1.x - q2.x, q1.y - q2.y, q1.z - q2.z, q1.w - q2.w);
    }

    Quaternion opBinary(string op : "*")(in Quaternion q2) const {
        Quaternion q1 = this;
        q1 *= q2;
        return q1;
    }

    Quaternion opUnary(string op : "-")() const {
        return Quaternion(-x, -y, -z, -w);
    }

    Quaternion opBinary(string op : "*")(in real_t s) const {
        return Quaternion(x * s, y * s, z * s, w * s);
    }

    Quaternion opBinary(string op : "/")(in real_t s) const {
        return this * (1.0 / s);
    }

    Vector3 getEuler() const {
        return getEulerYxz();
    }

    Vector3 getEulerXyz() const {
        Basis m = Basis(this);
	    return m.getEuler(EulerOrder.eulerOrderXyz);
    }

	Vector3 getEulerYxz() const {
        Basis m = Basis(this);
	    return m.getEuler(EulerOrder.eulerOrderYxz);
    }

}

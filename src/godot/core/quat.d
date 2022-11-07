/**
Quaternion.

Copyright:
Copyright (c) 2007-2022 Juan Linietsky, Ariel Manzur.
Copyright (c) 2014-2022 Godot Engine contributors (cf. AUTHORS.md)
Copyright (c) 2017-2018 Godot-D contributors
Copyright (c) 2022-2022 Godot-DLang contributors

License: $(LINK2 https://opensource.org/licenses/MIT, MIT License)


*/
module godot.quat;

import godot.defs;
import godot.vector3;
import godot.basis;

import std.math;

/**
A 4-dimensional vector representing a rotation.

The vector represents a 4 dimensional complex number where multiplication of the basis elements is not commutative (multiplying i with j gives a different result than multiplying j with i).

Multiplying quaternions reproduces rotation sequences. However quaternions need to be often renormalized, or else they suffer from precision issues.

It can be used to perform SLERP (spherical-linear interpolation) between two rotations.
*/
struct Quaternion {
@nogc nothrow:

    real_t x = 0;
    real_t y = 0;
    real_t z = 0;
    real_t w = 1;

    void set(real_t p_x, real_t p_y, real_t p_z, real_t p_w) {
        x = p_x;
        y = p_y;
        z = p_z;
        w = p_w;
    }

    this(real_t p_x, real_t p_y, real_t p_z, real_t p_w) {
        x = p_x;
        y = p_y;
        z = p_z;
        w = p_w;
    }

    real_t length() const {
        return sqrt(lengthSquared());
    }

    void normalize() {
        this /= length();
    }

    Quaternion normalized() const {
        return this / length();
    }

    Quaternion inverse() const {
        return Quaternion(-x, -y, -z, w);
    }

    void setEuler(in Vector3 p_euler) {
        real_t half_a1 = p_euler.x * 0.5;
        real_t half_a2 = p_euler.y * 0.5;
        real_t half_a3 = p_euler.z * 0.5;

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

    Quaternion slerp(in Quaternion q, in real_t t) const {
        Quaternion to1;
        real_t omega, cosom, sinom, scale0, scale1;
        // calc cosine
        cosom = dot(q);

        // adjust signs (if necessary)
        if (cosom < 0.0) {
            cosom = -cosom;
            to1.x = -q.x;
            to1.y = -q.y;
            to1.z = -q.z;
            to1.w = -q.w;
        } else {
            to1.x = q.x;
            to1.y = q.y;
            to1.z = q.z;
            to1.w = q.w;
        }
        // calculate coefficients
        if ((1.0 - cosom) > CMP_EPSILON) {
            // standard case (slerp)
            omega = acos(cosom);
            sinom = sin(omega);
            scale0 = sin((1.0 - t) * omega) / sinom;
            scale1 = sin(t * omega) / sinom;
        } else {
            // "from" and "to" quaternions are very close
            //  ... so we can do a linear interpolation
            scale0 = 1.0 - t;
            scale1 = t;
        }
        // calculate final values
        return Quaternion(
            scale0 * x + scale1 * to1.x,
            scale0 * y + scale1 * to1.y,
            scale0 * z + scale1 * to1.z,
            scale0 * w + scale1 * to1.w
        );
    }

    Quaternion slerpni(in Quaternion q, in real_t t) const {
        Quaternion from = this;

        real_t dot = from.dot(q);

        if (fabs(dot) > 0.9999)
            return from;

        real_t theta = acos(dot),
        sinT = 1.0 / sin(theta),
        newFactor = sin(t * theta) * sinT,
        invFactor = sin((1.0 - t) * theta) * sinT;

        return Quaternion(invFactor * from.x + newFactor * q.x,
            invFactor * from.y + newFactor * q.y,
            invFactor * from.z + newFactor * q.z,
            invFactor * from.w + newFactor * q.w);
    }

    Quaternion cubicSlerp(in Quaternion q, in Quaternion prep, in Quaternion postq, in real_t t) const {
        //the only way to do slerp :|
        real_t t2 = (1.0 - t) * t * 2;
        Quaternion sp = this.slerp(q, t);
        Quaternion sq = prep.slerpni(postq, t);
        return sp.slerpni(sq, t2);
    }

    void getAxisAndAngle(out Vector3 r_axis, out real_t r_angle) const {
        r_angle = 2 * acos(w);
        r_axis.x = x / sqrt(1 - w * w);
        r_axis.y = y / sqrt(1 - w * w);
        r_axis.z = z / sqrt(1 - w * w);
    }

    Quaternion opBinary(string op : "*")(in Vector3 v) const {
        return Quaternion(w * v.x + y * v.z - z * v.y,
            w * v.y + z * v.x - x * v.z,
            w * v.z + x * v.y - y * v.x,
            -x * v.x - y * v.y - z * v.z);
    }

    Vector3 xform(in Vector3 v) const {
        Quaternion q = this * v;
        q *= this.inverse();
        return Vector3(q.x, q.y, q.z);
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
        Basis m = Basis(this);
        return m.getEuler();
    }
}

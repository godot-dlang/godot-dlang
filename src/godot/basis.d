/**
3x3 matrix datatype.

Copyright:
Copyright (c) 2007 Juan Linietsky, Ariel Manzur.
Copyright (c) 2014 Godot Engine contributors (cf. AUTHORS.md)
Copyright (c) 2017 Godot-D contributors
Copyright (c) 2022 Godot-DLang contributors

License: $(LINK2 https://opensource.org/licenses/MIT, MIT License)


*/
module godot.basis;

import godot.api.types;
import godot.vector3;
import godot.quat;
import godot.globalenums : EulerOrder;
import godot.math;

import std.algorithm.comparison : clamp;
import std.algorithm.mutation : swap;

/**
3x3 matrix used for 3D rotation and scale. Contains 3 vector fields x, y, and z as its columns, which can be interpreted as the local basis vectors of a transformation. Can also be accessed as array of 3D vectors. These vectors are orthogonal to each other, but are not necessarily normalized. Almost always used as orthogonal basis for a $(D Transform).

For such use, it is composed of a scaling and a rotation matrix, in that order (M = R.S).
*/
struct Basis {
/*@nogc nothrow:*/

    Vector3[3] elements =
        [
            Vector3(1.0, 0.0, 0.0),
            Vector3(0.0, 1.0, 0.0),
            Vector3(0.0, 0.0, 1.0),
        ];
    alias rows = elements;

    this(in Vector3 x, in Vector3 y, in Vector3 z) {
        setColumns(x, y, z);
    }

    this(real_t xx, real_t xy, real_t xz, real_t yx, real_t yy, real_t yz, real_t zx, real_t zy, real_t zz) {
        set(xx, xy, xz, yx, yy, yz, zx, zy, zz);
    }

    const(Vector3) opIndex(int axis) const {
        return elements[axis];
    }

    ref Vector3 opIndex(int axis) return {
        return elements[axis];
    }

    private pragma(inline, true)
    real_t cofac(int row1, int col1, int row2, int col2) const {
        return (
            elements[row1][col1] * elements[row2][col2] -
                elements[row1][col2] * elements[row2][col1]);
    }

    void invert() {
        real_t[3] co = [
            cofac(1, 1, 2, 2), cofac(1, 2, 2, 0), cofac(1, 0, 2, 1)
        ];
        real_t det = elements[0][0] * co[0] +
            elements[0][1] * co[1] +
            elements[0][2] * co[2];

        /// ERR_FAIL_COND(det != 0);
        /// TODO: implement errors; D assert/exceptions won't work!

        real_t s = 1.0 / det;

        set(co[0] * s, cofac(0, 2, 2, 1) * s, cofac(0, 1, 1, 2) * s,
            co[1] * s, cofac(0, 0, 2, 2) * s, cofac(0, 2, 1, 0) * s,
            co[2] * s, cofac(0, 1, 2, 0) * s, cofac(0, 0, 1, 1) * s);
    }

    bool isEqualApprox(in Basis basis) const {
        return rows[0].isEqualApprox(basis.rows[0]) && rows[1].isEqualApprox(basis.rows[1]) && rows[2].isEqualApprox(basis.rows[2]);
    }

    bool isOrthogonal() const {
        Basis id;
        Basis m = (this) * transposed();

        return m.isEqualApprox(id);
    }

    bool isDiagonal() const {
        return (
			isClose(rows[0][1], 0) && isClose(rows[0][2], 0) &&
			isClose(rows[1][0], 0) && isClose(rows[1][2], 0) &&
			isClose(rows[2][0], 0) && isClose(rows[2][1], 0));
    }

    bool isRotation() const {
        return fabs(determinant() - 1) < CMP_EPSILON && isOrthogonal();
    }

    Basis lerp(in Basis to, in real_t weight) const {
        Basis b;
        b.rows[0] = rows[0].lerp(to.rows[0], weight);
        b.rows[1] = rows[1].lerp(to.rows[1], weight);
        b.rows[2] = rows[2].lerp(to.rows[2], weight);

        return b;
    }

    Basis slerp(in Basis to, in real_t weight) const {
        //consider scale
        Quaternion from = this.quat;
        Quaternion qto = to.quat;

        Basis b = Basis(from.slerp(qto, weight));
        b.rows[0] *= .lerp(rows[0].length(), to.rows[0].length(), weight);
        b.rows[1] *= .lerp(rows[1].length(), to.rows[1].length(), weight);
        b.rows[2] *= .lerp(rows[2].length(), to.rows[2].length(), weight);

        return b;
    }


    void rotateSh(ref real_t[] values) {
        // code by John Hable
        // http://filmicworlds.com/blog/simple-and-fast-spherical-harmonic-rotation/
        // this code is Public Domain

        const static real_t s_c3 = 0.94617469575; // (3*sqrt(5))/(4*sqrt(pi))
        const static real_t s_c4 = -0.31539156525; // (-sqrt(5))/(4*sqrt(pi))
        const static real_t s_c5 = 0.54627421529; // (sqrt(15))/(4*sqrt(pi))

        const static real_t s_c_scale = 1.0 / 0.91529123286551084;
        const static real_t s_c_scale_inv = 0.91529123286551084;

        const static real_t s_rc2 = 1.5853309190550713 * s_c_scale;
        const static real_t s_c4_div_c3 = s_c4 / s_c3;
        const static real_t s_c4_div_c3_x2 = (s_c4 / s_c3) * 2.0;

        const static real_t s_scale_dst2 = s_c3 * s_c_scale_inv;
        const static real_t s_scale_dst4 = s_c5 * s_c_scale_inv;

        const real_t[9] src = values[0..9];

        real_t m00 = rows[0][0];
        real_t m01 = rows[0][1];
        real_t m02 = rows[0][2];
        real_t m10 = rows[1][0];
        real_t m11 = rows[1][1];
        real_t m12 = rows[1][2];
        real_t m20 = rows[2][0];
        real_t m21 = rows[2][1];
        real_t m22 = rows[2][2];

        values[0] = src[0];
        values[1] = m11 * src[1] - m12 * src[2] + m10 * src[3];
        values[2] = -m21 * src[1] + m22 * src[2] - m20 * src[3];
        values[3] = m01 * src[1] - m02 * src[2] + m00 * src[3];

        real_t sh0 = src[7] + src[8] + src[8] - src[5];
        real_t sh1 = src[4] + s_rc2 * src[6] + src[7] + src[8];
        real_t sh2 = src[4];
        real_t sh3 = -src[7];
        real_t sh4 = -src[5];

        // Rotations.  R0 and R1 just use the raw matrix columns
        real_t r2x = m00 + m01;
        real_t r2y = m10 + m11;
        real_t r2z = m20 + m21;

        real_t r3x = m00 + m02;
        real_t r3y = m10 + m12;
        real_t r3z = m20 + m22;

        real_t r4x = m01 + m02;
        real_t r4y = m11 + m12;
        real_t r4z = m21 + m22;

        // dense matrix multiplication one column at a time

        // column 0
        real_t sh0_x = sh0 * m00;
        real_t sh0_y = sh0 * m10;
        real_t d0 = sh0_x * m10;
        real_t d1 = sh0_y * m20;
        real_t d2 = sh0 * (m20 * m20 + s_c4_div_c3);
        real_t d3 = sh0_x * m20;
        real_t d4 = sh0_x * m00 - sh0_y * m10;

        // column 1
        real_t sh1_x = sh1 * m02;
        real_t sh1_y = sh1 * m12;
        d0 += sh1_x * m12;
        d1 += sh1_y * m22;
        d2 += sh1 * (m22 * m22 + s_c4_div_c3);
        d3 += sh1_x * m22;
        d4 += sh1_x * m02 - sh1_y * m12;

        // column 2
        real_t sh2_x = sh2 * r2x;
        real_t sh2_y = sh2 * r2y;
        d0 += sh2_x * r2y;
        d1 += sh2_y * r2z;
        d2 += sh2 * (r2z * r2z + s_c4_div_c3_x2);
        d3 += sh2_x * r2z;
        d4 += sh2_x * r2x - sh2_y * r2y;

        // column 3
        real_t sh3_x = sh3 * r3x;
        real_t sh3_y = sh3 * r3y;
        d0 += sh3_x * r3y;
        d1 += sh3_y * r3z;
        d2 += sh3 * (r3z * r3z + s_c4_div_c3_x2);
        d3 += sh3_x * r3z;
        d4 += sh3_x * r3x - sh3_y * r3y;

        // column 4
        real_t sh4_x = sh4 * r4x;
        real_t sh4_y = sh4 * r4y;
        d0 += sh4_x * r4y;
        d1 += sh4_y * r4z;
        d2 += sh4 * (r4z * r4z + s_c4_div_c3_x2);
        d3 += sh4_x * r4z;
        d4 += sh4_x * r4x - sh4_y * r4y;

        // extra multipliers
        values[4] = d0;
        values[5] = -d1;
        values[6] = d2 * s_scale_dst2;
        values[7] = -d3;
        values[8] = d4 * s_scale_dst4;
    }

    void transpose() {
        swap(elements[0][1], elements[1][0]);
        swap(elements[0][2], elements[2][0]);
        swap(elements[1][2], elements[2][1]);
    }

    Basis inverse() const {
        Basis b = this;
        b.invert();
        return b;
    }

    Basis transposed() const {
        Basis b = this;
        b.transpose();
        return b;
    }

    real_t determinant() const {
        return elements[0][0] * (elements[1][1] * elements[2][2] - elements[2][1] * elements[1][2]) -
            elements[1][0] * (
                elements[0][1] * elements[2][2] - elements[2][1] * elements[0][2]) +
            elements[2][0] * (
                elements[0][1] * elements[1][2] - elements[1][1] * elements[0][2]);
    }

    deprecated("use getColumn instead")
    Vector3 getAxis(int axis) const {
        // get actual basis axis (elements is transposed for performance)
        return Vector3(elements[0][axis], elements[1][axis], elements[2][axis]);
    }

    deprecated("use setColumn instead")
    void setAxis(int axis, in Vector3 value) {
        // get actual basis axis (elements is transposed for performance)
        elements[0][axis] = value.x;
        elements[1][axis] = value.y;
        elements[2][axis] = value.z;
    }

    void rotate(in Vector3 axis, real_t angle) {
        this = rotated(axis, angle);
    }

    Basis rotated(in Vector3 axis, real_t angle) const {
        return Basis(axis, angle) * (this);
    }

    void rotate_local(in Vector3 axis, real_t angle) {
        // performs a rotation in object-local coordinate system:
        // M -> (M.R.Minv).M = M.R.
        this = rotatedLocal(axis, angle);
    }

    Basis rotatedLocal(in Vector3 axis, real_t angle) const {
	    return this * Basis(axis, angle);
    }

    void rotate(in Vector3 euler, EulerOrder order = EulerOrder.eulerOrderYxz) {
        this = rotated(euler, order);
    }

    Basis rotated(in Vector3 euler, EulerOrder order = EulerOrder.eulerOrderYxz) const {
        return Basis.fromEuler(euler, order) * this;
    }

    void rotate(in Quaternion quaternion) {
        this = rotated(quaternion);
    }

    Basis rotated(in Quaternion quaternion) const {
        return Basis(quaternion) * this;
    }

    Vector3 getEulerNormalized(EulerOrder order = EulerOrder.eulerOrderYxz) const {
        // Assumes that the matrix can be decomposed into a proper rotation and scaling matrix as M = R.S,
        // and returns the Euler angles corresponding to the rotation part, complementing get_scale().
        // See the comment in get_scale() for further information.
        Basis m = orthonormalized();
        real_t det = m.determinant();
        if (det < 0) {
            // Ensure that the determinant is 1, such that result is a proper rotation matrix which can be represented by Euler angles.
            m.scale(Vector3(-1, -1, -1));
        }

        return m.getEuler(order);
    }

    void getRotationAxisAngle(out Vector3 axis, out real_t angle) const {
        // Assumes that the matrix can be decomposed into a proper rotation and scaling matrix as M = R.S,
        // and returns the Euler angles corresponding to the rotation part, complementing get_scale().
        // See the comment in get_scale() for further information.
        Basis m = orthonormalized();
        real_t det = m.determinant();
        if (det < 0) {
            // Ensure that the determinant is 1, such that result is a proper rotation matrix which can be represented by Euler angles.
            m.scale(Vector3(-1, -1, -1));
        }

        m.getAxisAngle(axis, angle);
    }

    void getRotationAxisAngleLocal(out Vector3 axis, out real_t angle) const {
        // Assumes that the matrix can be decomposed into a proper rotation and scaling matrix as M = R.S,
        // and returns the Euler angles corresponding to the rotation part, complementing get_scale().
        // See the comment in get_scale() for further information.
        Basis m = transposed();
        m.orthonormalize();
        real_t det = m.determinant();
        if (det < 0) {
            // Ensure that the determinant is 1, such that result is a proper rotation matrix which can be represented by Euler angles.
            m.scale(Vector3(-1, -1, -1));
        }

        m.getAxisAngle(axis, angle);
        angle = -angle;
    }

    Quaternion getRotationQuaternion() const {
        // Assumes that the matrix can be decomposed into a proper rotation and scaling matrix as M = R.S,
        // and returns the Euler angles corresponding to the rotation part, complementing get_scale().
        // See the comment in get_scale() for further information.
        Basis m = orthonormalized();
        real_t det = m.determinant();
        if (det < 0) {
            // Ensure that the determinant is 1, such that result is a proper rotation matrix which can be represented by Euler angles.
            m.scale(Vector3(-1, -1, -1));
        }

        return m.getQuaternion();
    }

    void rotateToAlign(Vector3 start_direction, Vector3 end_direction) {
        // Takes two vectors and rotates the basis from the first vector to the second vector.
        // Adopted from: https://gist.github.com/kevinmoran/b45980723e53edeb8a5a43c49f134724
        const Vector3 axis = start_direction.cross(end_direction).normalized();
        if (axis.lengthSquared() != 0) {
            real_t dot = start_direction.dot(end_direction);
            dot = clamp(dot, -1.0f, 1.0f);
            const real_t angle_rads = acos(dot);
            setAxisAngle(axis, angle_rads);
        }
    }

    // Decomposes a Basis into a rotation-reflection matrix (an element of the group O(3)) and a positive scaling matrix as B = O.S.
    // Returns the rotation-reflection matrix via reference argument, and scaling information is returned as a Vector3.
    // This (internal) function is too specific and named too ugly to expose to users, and probably there's no need to do so.
    Vector3 rotrefPosscaleDecomposition(out Basis rotref) const {
        Vector3 scale = getScale();
        Basis inv_scale = Basis().scaled(scale.inverse()); // this will also absorb the sign of scale
        rotref = this * inv_scale;
        return scale.abs();
    }

    void scale(in Vector3 scale) {
        elements[0][0] *= scale.x;
        elements[0][1] *= scale.x;
        elements[0][2] *= scale.x;
        elements[1][0] *= scale.y;
        elements[1][1] *= scale.y;
        elements[1][2] *= scale.y;
        elements[2][0] *= scale.z;
        elements[2][1] *= scale.z;
        elements[2][2] *= scale.z;
    }

    Basis scaled(in Vector3 scale) const {
        Basis b = this;
        b.scale(scale);
        return b;
    }

    void scaleLocal(in Vector3 scale) {
        // performs a scaling in object-local coordinate system:
        // M -> (M.S.Minv).M = M.S.
        this = scaledLocal(scale);
    }

    Basis scaledLocal(in Vector3 scale) const {
        return this * Basis.fromScale(scale);
    }

    void scaleOrthogonal(in Vector3 scale) {
        this = scaledOrthogonal(scale);
    }

    Basis scaledOrthogonal(in Vector3 scale) const {
        Basis m = this;
        Vector3 s = Vector3(-1, -1, -1) + scale;
        Vector3 dots;
        Basis b;
        for (int i = 0; i < 3; i++) {
            for (int j = 0; j < 3; j++) {
                dots[j] += s[i] * abs(m.getColumn(i).normalized().dot(b.getColumn(j)));
            }
        }
        m.scaleLocal(Vector3(1, 1, 1) + dots);
        return m;
    }

    void makeScaleUniform() {
        float l = (rows[0].length() + rows[1].length() + rows[2].length()) / 3.0f;
        for (int i = 0; i < 3; i++) {
            rows[i].normalize();
            rows[i] *= l;
        }
    }

    float getUniformScale() const {
        return (rows[0].length() + rows[1].length() + rows[2].length()) / 3.0f;
    }

    /// getScale works with getRotation, use getScaleAbs if you need to enforce positive signature.
    Vector3 getScale() const {
        // FIXME: We are assuming M = R.S (R is rotation and S is scaling), and use polar decomposition to extract R and S.
        // A polar decomposition is M = O.P, where O is an orthogonal matrix (meaning rotation and reflection) and
        // P is a positive semi-definite matrix (meaning it contains absolute values of scaling along its diagonal).
        //
        // Despite being different from what we want to achieve, we can nevertheless make use of polar decomposition
        // here as follows. We can split O into a rotation and a reflection as O = R.Q, and obtain M = R.S where
        // we defined S = Q.P. Now, R is a proper rotation matrix and S is a (signed) scaling matrix,
        // which can involve negative scalings. However, there is a catch: unlike the polar decomposition of M = O.P,
        // the decomposition of O into a rotation and reflection matrix as O = R.Q is not unique.
        // Therefore, we are going to do this decomposition by sticking to a particular convention.
        // This may lead to confusion for some users though.
        //
        // The convention we use here is to absorb the sign flip into the scaling matrix.
        // The same convention is also used in other similar functions such as get_rotation_axis_angle, get_rotation, ...
        //
        // A proper way to get rid of this issue would be to store the scaling values (or at least their signs)
        // as a part of Basis. However, if we go that path, we need to disable direct (write) access to the
        // matrix elements.
        //
        // The rotation part of this decomposition is returned by get_rotation* functions.
        real_t det_sign = sgn(determinant());
        return det_sign * getScaleAbs();
    }

    Vector3 getScaleAbs() const {
        return Vector3(
            Vector3(rows[0][0], rows[1][0], rows[2][0]).length(),
            Vector3(rows[0][1], rows[1][1], rows[2][1]).length(),
            Vector3(rows[0][2], rows[1][2], rows[2][2]).length()
        );
    }

    Vector3 getScaleLocal() const {
        real_t det_sign = sgn(determinant());
        return det_sign * Vector3(rows[0].length(), rows[1].length(), rows[2].length());
    }

    Vector3 getEuler(EulerOrder order = EulerOrder.eulerOrderYxz) const {
        switch (order) {
            case EulerOrder.eulerOrderXyz: {
                // Euler angles in XYZ convention.
                // See https://en.wikipedia.org/wiki/Euler_angles#Rotation_matrix
                //
                // rot =  cy*cz          -cy*sz           sy
                //        cz*sx*sy+cx*sz  cx*cz-sx*sy*sz -cy*sx
                //       -cx*cz*sy+sx*sz  cz*sx+cx*sy*sz  cx*cy

                Vector3 euler;
                real_t sy = rows[0][2];
                if (sy < (1.0f - cast(real_t)CMP_EPSILON)) {
                    if (sy > -(1.0f - cast(real_t)CMP_EPSILON)) {
                        // is this a pure Y rotation?
                        if (rows[1][0] == 0 && rows[0][1] == 0 && rows[1][2] == 0 && rows[2][1] == 0 && rows[1][1] == 1) {
                            // return the simplest form (human friendlier in editor and scripts)
                            euler.x = 0;
                            euler.y = atan2(rows[0][2], rows[0][0]);
                            euler.z = 0;
                        } else {
                            euler.x = atan2(-rows[1][2], rows[2][2]);
                            euler.y = asin(sy);
                            euler.z = atan2(-rows[0][1], rows[0][0]);
                        }
                    } else {
                        euler.x = atan2(rows[2][1], rows[1][1]);
                        euler.y = -PI_2; // -PI / 2
                        euler.z = 0.0f;
                    }
                } else {
                    euler.x = atan2(rows[2][1], rows[1][1]);
                    euler.y = PI_2; // PI / 2
                    euler.z = 0.0f;
                }
                return euler;
            }
            case EulerOrder.eulerOrderXzy: {
                // Euler angles in XZY convention.
                // See https://en.wikipedia.org/wiki/Euler_angles#Rotation_matrix
                //
                // rot =  cz*cy             -sz             cz*sy
                //        sx*sy+cx*cy*sz    cx*cz           cx*sz*sy-cy*sx
                //        cy*sx*sz          cz*sx           cx*cy+sx*sz*sy

                Vector3 euler;
                real_t sz = rows[0][1];
                if (sz < (1.0f - cast(real_t)CMP_EPSILON)) {
                    if (sz > -(1.0f - cast(real_t)CMP_EPSILON)) {
                        euler.x = atan2(rows[2][1], rows[1][1]);
                        euler.y = atan2(rows[0][2], rows[0][0]);
                        euler.z = asin(-sz);
                    } else {
                        // It's -1
                        euler.x = -atan2(rows[1][2], rows[2][2]);
                        euler.y = 0.0f;
                        euler.z = PI_2; // PI / 2
                    }
                } else {
                    // It's 1
                    euler.x = -atan2(rows[1][2], rows[2][2]);
                    euler.y = 0.0f;
                    euler.z = -PI_2; // -PI / 2
                }
                return euler;
            }
            case EulerOrder.eulerOrderYxz: {
                // Euler angles in YXZ convention.
                // See https://en.wikipedia.org/wiki/Euler_angles#Rotation_matrix
                //
                // rot =  cy*cz+sy*sx*sz    cz*sy*sx-cy*sz        cx*sy
                //        cx*sz             cx*cz                 -sx
                //        cy*sx*sz-cz*sy    cy*cz*sx+sy*sz        cy*cx

                Vector3 euler;

                real_t m12 = rows[1][2];

                if (m12 < (1 - cast(real_t)CMP_EPSILON)) {
                    if (m12 > -(1 - cast(real_t)CMP_EPSILON)) {
                        // is this a pure X rotation?
                        if (rows[1][0] == 0 && rows[0][1] == 0 && rows[0][2] == 0 && rows[2][0] == 0 && rows[0][0] == 1) {
                            // return the simplest form (human friendlier in editor and scripts)
                            euler.x = atan2(-m12, rows[1][1]);
                            euler.y = 0;
                            euler.z = 0;
                        } else {
                            euler.x = asin(-m12);
                            euler.y = atan2(rows[0][2], rows[2][2]);
                            euler.z = atan2(rows[1][0], rows[1][1]);
                        }
                    } else { // m12 == -1
                        euler.x = PI_2;
                        euler.y = atan2(rows[0][1], rows[0][0]);
                        euler.z = 0;
                    }
                } else { // m12 == 1
                    euler.x = -PI_2;
                    euler.y = -atan2(rows[0][1], rows[0][0]);
                    euler.z = 0;
                }

                return euler;
            }
            case EulerOrder.eulerOrderYzx: {
                // Euler angles in YZX convention.
                // See https://en.wikipedia.org/wiki/Euler_angles#Rotation_matrix
                //
                // rot =  cy*cz             sy*sx-cy*cx*sz     cx*sy+cy*sz*sx
                //        sz                cz*cx              -cz*sx
                //        -cz*sy            cy*sx+cx*sy*sz     cy*cx-sy*sz*sx

                Vector3 euler;
                real_t sz = rows[1][0];
                if (sz < (1.0f - cast(real_t)CMP_EPSILON)) {
                    if (sz > -(1.0f - cast(real_t)CMP_EPSILON)) {
                        euler.x = atan2(-rows[1][2], rows[1][1]);
                        euler.y = atan2(-rows[2][0], rows[0][0]);
                        euler.z = asin(sz);
                    } else {
                        // It's -1
                        euler.x = atan2(rows[2][1], rows[2][2]);
                        euler.y = 0.0f;
                        euler.z = -PI_2;
                    }
                } else {
                    // It's 1
                    euler.x = atan2(rows[2][1], rows[2][2]);
                    euler.y = 0.0f;
                    euler.z = PI_2;
                }
                return euler;
            }
            case EulerOrder.eulerOrderZxy: {
                // Euler angles in ZXY convention.
                // See https://en.wikipedia.org/wiki/Euler_angles#Rotation_matrix
                //
                // rot =  cz*cy-sz*sx*sy    -cx*sz                cz*sy+cy*sz*sx
                //        cy*sz+cz*sx*sy    cz*cx                 sz*sy-cz*cy*sx
                //        -cx*sy            sx                    cx*cy
                Vector3 euler;
                real_t sx = rows[2][1];
                if (sx < (1.0f - cast(real_t)CMP_EPSILON)) {
                    if (sx > -(1.0f - cast(real_t)CMP_EPSILON)) {
                        euler.x = asin(sx);
                        euler.y = atan2(-rows[2][0], rows[2][2]);
                        euler.z = atan2(-rows[0][1], rows[1][1]);
                    } else {
                        // It's -1
                        euler.x = -PI_2;
                        euler.y = atan2(rows[0][2], rows[0][0]);
                        euler.z = 0;
                    }
                } else {
                    // It's 1
                    euler.x = PI_2;
                    euler.y = atan2(rows[0][2], rows[0][0]);
                    euler.z = 0;
                }
                return euler;
            }
            case EulerOrder.eulerOrderZyx: {
                // Euler angles in ZYX convention.
                // See https://en.wikipedia.org/wiki/Euler_angles#Rotation_matrix
                //
                // rot =  cz*cy             cz*sy*sx-cx*sz        sz*sx+cz*cx*cy
                //        cy*sz             cz*cx+sz*sy*sx        cx*sz*sy-cz*sx
                //        -sy               cy*sx                 cy*cx
                Vector3 euler;
                real_t sy = rows[2][0];
                if (sy < (1.0f - cast(real_t)CMP_EPSILON)) {
                    if (sy > -(1.0f - cast(real_t)CMP_EPSILON)) {
                        euler.x = atan2(rows[2][1], rows[2][2]);
                        euler.y = asin(-sy);
                        euler.z = atan2(rows[1][0], rows[0][0]);
                    } else {
                        // It's -1
                        euler.x = 0;
                        euler.y = PI_2;
                        euler.z = -atan2(rows[0][1], rows[1][1]);
                    }
                } else {
                    // It's 1
                    euler.x = 0;
                    euler.y = -PI_2;
                    euler.z = -atan2(rows[0][1], rows[1][1]);
                }
                return euler;
            }
            default: {
                assert(0); // should never happen
            }
        }
        // unreachable
        //return Vector3();
    }

    void setEuler(in Vector3 euler, EulerOrder order = EulerOrder.eulerOrderYxz) {
        real_t c, s;

        c = cos(euler.x);
        s = sin(euler.x);
        Basis xmat = Basis(1.0, 0.0, 0.0, 0.0, c, -s, 0.0, s, c);

        c = cos(euler.y);
        s = sin(euler.y);
        Basis ymat = Basis(c, 0.0, s, 0.0, 1.0, 0.0, -s, 0.0, c);

        c = cos(euler.z);
        s = sin(euler.z);
        Basis zmat = Basis(c, -s, 0.0, s, c, 0.0, 0.0, 0.0, 1.0);

        switch (order) {
            case EulerOrder.eulerOrderXyz: {
                this = xmat * (ymat * zmat);
            } break;
            case EulerOrder.eulerOrderXzy: {
                this = xmat * zmat * ymat;
            } break;
            case EulerOrder.eulerOrderYxz: {
                this = ymat * xmat * zmat;
            } break;
            case EulerOrder.eulerOrderYzx: {
                this = ymat * zmat * xmat;
            } break;
            case EulerOrder.eulerOrderZxy: {
                this = zmat * xmat * ymat;
            } break;
            case EulerOrder.eulerOrderZyx: {
                this = zmat * ymat * xmat;
            } break;
            default: {
                assert(0, "Invalid order parameter for setEuler(vec3,order)");
            }
        }
    }

    static Basis fromEuler(in Vector3 euler, EulerOrder order = EulerOrder.eulerOrderYxz) {
		Basis b;
		b.setEuler(euler, order);
		return b;
    }

    Quaternion getQuaternion() const {
        /* Allow getting a quaternion from an unnormalized transform */
        Basis m = this;
        real_t trace = m.rows[0][0] + m.rows[1][1] + m.rows[2][2];
        real_t[4] temp;

        if (trace > 0.0f) {
            real_t s = sqrt(trace + 1.0f);
            temp[3] = (s * 0.5f);
            s = 0.5f / s;

            temp[0] = ((m.rows[2][1] - m.rows[1][2]) * s);
            temp[1] = ((m.rows[0][2] - m.rows[2][0]) * s);
            temp[2] = ((m.rows[1][0] - m.rows[0][1]) * s);
        } else {
            int i = m.rows[0][0] < m.rows[1][1]
                    ? (m.rows[1][1] < m.rows[2][2] ? 2 : 1)
                    : (m.rows[0][0] < m.rows[2][2] ? 2 : 0);
            int j = (i + 1) % 3;
            int k = (i + 2) % 3;

            real_t s = sqrt(m.rows[i][i] - m.rows[j][j] - m.rows[k][k] + 1.0f);
            temp[i] = s * 0.5f;
            s = 0.5f / s;

            temp[3] = (m.rows[k][j] - m.rows[j][k]) * s;
            temp[j] = (m.rows[j][i] + m.rows[i][j]) * s;
            temp[k] = (m.rows[k][i] + m.rows[i][k]) * s;
        }

        return Quaternion(temp[0], temp[1], temp[2], temp[3]);
    }

    void setQuaternion(in Quaternion quaternion) {
        real_t d = quaternion.lengthSquared();
        real_t s = 2.0f / d;
        real_t xs = quaternion.x * s, ys = quaternion.y * s, zs = quaternion.z * s;
        real_t wx = quaternion.w * xs, wy = quaternion.w * ys, wz = quaternion.w * zs;
        real_t xx = quaternion.x * xs, xy = quaternion.x * ys, xz = quaternion.x * zs;
        real_t yy = quaternion.y * ys, yz = quaternion.y * zs, zz = quaternion.z * zs;
        set(1.0f - (yy + zz), xy - wz, xz + wy,
                xy + wz, 1.0f - (xx + zz), yz - wx,
                xz - wy, yz + wx, 1.0f - (xx + yy));
    }

    void fromZ(in Vector3 z) {
        if (abs(z.z) > cast(real_t)SQRT1_2) {
            // choose p in y-z plane
            real_t a = z[1] * z[1] + z[2] * z[2];
            real_t k = 1.0f / sqrt(a);
            rows[0] = Vector3(0, -z[2] * k, z[1] * k);
            rows[1] = Vector3(a * k, -z[0] * rows[0][2], z[0] * rows[0][1]);
        } else {
            // choose p in x-y plane
            real_t a = z.x * z.x + z.y * z.y;
            real_t k = 1.0f / sqrt(a);
            rows[0] = Vector3(-z.y * k, z.x * k, 0);
            rows[1] = Vector3(-z.z * rows[0].y, z.z * rows[0].x, a * k);
        }
        rows[2] = z;
    }


    void getAxisAngle(out Vector3 axis, out real_t angle) const {
        // https://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToAngle/index.htm
        real_t x, y, z; // Variables for result.
        if (isClose(rows[0][1] - rows[1][0], 0) && isClose(rows[0][2] - rows[2][0], 0) && isClose(rows[1][2] - rows[2][1], 0)) {
            // Singularity found.
            // First check for identity matrix which must have +1 for all terms in leading diagonal and zero in other terms.
            if (isDiagonal() && (abs(rows[0][0] + rows[1][1] + rows[2][2] - 3) < 3 * CMP_EPSILON)) {
                // This singularity is identity matrix so angle = 0.
                axis = Vector3(0, 1, 0);
                angle = 0;
                return;
            }
            // Otherwise this singularity is angle = 180.
            real_t xx = (rows[0][0] + 1) / 2;
            real_t yy = (rows[1][1] + 1) / 2;
            real_t zz = (rows[2][2] + 1) / 2;
            real_t xy = (rows[0][1] + rows[1][0]) / 4;
            real_t xz = (rows[0][2] + rows[2][0]) / 4;
            real_t yz = (rows[1][2] + rows[2][1]) / 4;

            if ((xx > yy) && (xx > zz)) { // rows[0][0] is the largest diagonal term.
                if (xx < CMP_EPSILON) {
                    x = 0;
                    y = SQRT1_2;
                    z = SQRT1_2;
                } else {
                    x = sqrt(xx);
                    y = xy / x;
                    z = xz / x;
                }
            } else if (yy > zz) { // rows[1][1] is the largest diagonal term.
                if (yy < CMP_EPSILON) {
                    x = SQRT1_2;
                    y = 0;
                    z = SQRT1_2;
                } else {
                    y = sqrt(yy);
                    x = xy / y;
                    z = yz / y;
                }
            } else { // rows[2][2] is the largest diagonal term so base result on this.
                if (zz < CMP_EPSILON) {
                    x = SQRT1_2;
                    y = SQRT1_2;
                    z = 0;
                } else {
                    z = sqrt(zz);
                    x = xz / z;
                    y = yz / z;
                }
            }
            axis = Vector3(x, y, z);
            angle = PI;
            return;
        }
        // As we have reached here there are no singularities so we can handle normally.
        double s = sqrt((rows[2][1] - rows[1][2]) * (rows[2][1] - rows[1][2]) + (rows[0][2] - rows[2][0]) * (rows[0][2] - rows[2][0]) + (rows[1][0] - rows[0][1]) * (rows[1][0] - rows[0][1])); // Used to normalise.

        if (abs(s) < CMP_EPSILON) {
            // Prevent divide by zero, should not happen if matrix is orthogonal and should be caught by singularity test above.
            s = 1;
        }

        x = (rows[2][1] - rows[1][2]) / s;
        y = (rows[0][2] - rows[2][0]) / s;
        z = (rows[1][0] - rows[0][1]) / s;

        axis = Vector3(x, y, z);
        // CLAMP to avoid NaN if the value passed to acos is not in [0,1].
        angle = acos(clamp((rows[0][0] + rows[1][1] + rows[2][2] - 1) / 2, cast(real_t)0.0, cast(real_t)1.0));
    }


    void setAxisAngle(in Vector3 axis, real_t angle) {
        // Rotation matrix from axis and angle, see https://en.wikipedia.org/wiki/Rotation_matrix#Rotation_matrix_from_axis_angle
        Vector3 axis_sq = Vector3(axis.x * axis.x, axis.y * axis.y, axis.z * axis.z);
        real_t cosine = cos(angle);
        rows[0][0] = axis_sq.x + cosine * (1.0f - axis_sq.x);
        rows[1][1] = axis_sq.y + cosine * (1.0f - axis_sq.y);
        rows[2][2] = axis_sq.z + cosine * (1.0f - axis_sq.z);

        real_t sine = sin(angle);
        real_t t = 1 - cosine;

        real_t xyzt = axis.x * axis.y * t;
        real_t zyxs = axis.z * sine;
        rows[0][1] = xyzt - zyxs;
        rows[1][0] = xyzt + zyxs;

        xyzt = axis.x * axis.z * t;
        zyxs = axis.y * sine;
        rows[0][2] = xyzt + zyxs;
        rows[2][0] = xyzt - zyxs;

        xyzt = axis.y * axis.z * t;
        zyxs = axis.x * sine;
        rows[1][2] = xyzt - zyxs;
        rows[2][1] = xyzt + zyxs;
    }

    void setAxisAngleScale(in Vector3 axis, real_t angle, in Vector3 scale) {
        _setDiagonal(scale);
        rotate(axis, angle);
    }

    void setEulerScale(in Vector3 euler, in Vector3 scale, EulerOrder order = EulerOrder.eulerOrderYxz) {
        _setDiagonal(scale);
        rotate(euler, order);
    }

    void setQuaternionScale(in Quaternion quaternion, in Vector3 scale) {
        _setDiagonal(scale);
        rotate(quaternion);
    }

    // transposed dot products
    real_t tdotx(in Vector3 v) const {
        return elements[0][0] * v[0] + elements[1][0] * v[1] + elements[2][0] * v[2];
    }

    real_t tdoty(in Vector3 v) const {
        return elements[0][1] * v[0] + elements[1][1] * v[1] + elements[2][1] * v[2];
    }

    real_t tdotz(in Vector3 v) const {
        return elements[0][2] * v[0] + elements[1][2] * v[1] + elements[2][2] * v[2];
    }

    int opCmp(in Basis other) const {
        for (int i = 0; i < 3; i++) {
            for (int j = 0; j < 3; j++) {
                if (elements[i][j] != other.elements[i][j])
                    return (elements[i][j] > other.elements[i][j]) ? 1 : -1;
            }
        }
        return 0;
    }

    Vector3 xform(in Vector3 vector) const {
        return Vector3(
            elements[0].dot(vector),
            elements[1].dot(vector),
            elements[2].dot(vector)
        );
    }

    Vector3 xformInv(in Vector3 vector) const {
        return Vector3(
            (elements[0][0] * vector.x) + (elements[1][0] * vector.y) + (
                elements[2][0] * vector.z),
            (elements[0][1] * vector.x) + (elements[1][1] * vector.y) + (
                elements[2][1] * vector.z),
            (elements[0][2] * vector.x) + (elements[1][2] * vector.y) + (
                elements[2][2] * vector.z)
        );
    }

    void opOpAssign(string op : "*")(in Basis matrix) {
        set(
            matrix.tdotx(elements[0]), matrix.tdoty(elements[0]), matrix.tdotz(elements[0]),
            matrix.tdotx(elements[1]), matrix.tdoty(elements[1]), matrix.tdotz(elements[1]),
            matrix.tdotx(elements[2]), matrix.tdoty(elements[2]), matrix.tdotz(elements[2]));

    }

    Basis opBinary(string op : "*")(in Basis matrix) const {
        return Basis(
            matrix.tdotx(elements[0]), matrix.tdoty(elements[0]), matrix.tdotz(elements[0]),
            matrix.tdotx(elements[1]), matrix.tdoty(elements[1]), matrix.tdotz(elements[1]),
            matrix.tdotx(elements[2]), matrix.tdoty(elements[2]), matrix.tdotz(elements[2]));

    }

    void opOpAssign(string op : "+")(in Basis matrix) {
        elements[0] += matrix.elements[0];
        elements[1] += matrix.elements[1];
        elements[2] += matrix.elements[2];
    }

    Basis opBinary(string op : "+")(in Basis matrix) const {
        Basis ret = this;
        ret += matrix;
        return ret;
    }

    void opOpAssign(string op : "-")(in Basis matrix) {
        elements[0] -= matrix.elements[0];
        elements[1] -= matrix.elements[1];
        elements[2] -= matrix.elements[2];
    }

    Basis opBinary(string op : "-")(in Basis matrix) const {
        Basis ret = this;
        ret -= matrix;
        return ret;
    }

    void opOpAssign(string op : "*")(real_t val) {

        elements[0] *= val;
        elements[1] *= val;
        elements[2] *= val;
    }

    Basis opBinary(string op : "*")(real_t val) const {

        Basis ret = this;
        ret *= val;
        return ret;
    }

    /++String opCast(T : String)() const
	{
		String s;
		// @Todo
		return s;
	}+/

    /* create / set */

    void set(real_t xx, real_t xy, real_t xz, real_t yx, real_t yy, real_t yz, real_t zx, real_t zy, real_t zz) {
        elements[0][0] = xx;
        elements[0][1] = xy;
        elements[0][2] = xz;
        elements[1][0] = yx;
        elements[1][1] = yy;
        elements[1][2] = yz;
        elements[2][0] = zx;
        elements[2][1] = zy;
        elements[2][2] = zz;
    }

    void setColumns(in Vector3 x, in Vector3 y, in Vector3 z) {
		setColumn(0, x);
		setColumn(1, y);
		setColumn(2, z);
	}

    Vector3 getColumn(int i) const {
        return Vector3(elements[0][i], elements[1][i], elements[2][i]);
    }

    void setColumn(int index, in Vector3 value) {
		// Set actual basis axis column (we store transposed as rows for performance).
		rows[0][index] = value.x;
		rows[1][index] = value.y;
		rows[2][index] = value.z;
	}

    Vector3 getRow(int i) const {
        return Vector3(elements[i][0], elements[i][1], elements[i][2]);
    }

    Vector3 getMainDiagonal() const {
        return Vector3(elements[0][0], elements[1][1], elements[2][2]);
    }

    void setRow(int i, in Vector3 row) {
        elements[i][0] = row.x;
        elements[i][1] = row.y;
        elements[i][2] = row.z;
    }

    void setZero() {
		rows[0].zero();
		rows[1].zero();
		rows[2].zero();
	}

    Basis transposeXform(in Basis m) const {
        return Basis(
            elements[0].x * m[0].x + elements[1].x * m[1].x + elements[2].x * m[2].x,
            elements[0].x * m[0].y + elements[1].x * m[1].y + elements[2].x * m[2].y,
            elements[0].x * m[0].z + elements[1].x * m[1].z + elements[2].x * m[2].z,
            elements[0].y * m[0].x + elements[1].y * m[1].x + elements[2].y * m[2].x,
            elements[0].y * m[0].y + elements[1].y * m[1].y + elements[2].y * m[2].y,
            elements[0].y * m[0].z + elements[1].y * m[1].z + elements[2].y * m[2].z,
            elements[0].z * m[0].x + elements[1].z * m[1].x + elements[2].z * m[2].x,
            elements[0].z * m[0].y + elements[1].z * m[1].y + elements[2].z * m[2].y,
            elements[0].z * m[0].z + elements[1].z * m[1].z + elements[2].z * m[2].z);
    }

    void orthonormalize() {
        ///ERR_FAIL_COND(determinant() != 0);

        // Gram-Schmidt Process

        Vector3 x = getColumn(0);
        Vector3 y = getColumn(1);
        Vector3 z = getColumn(2);

        x.normalize();
        y = (y - x * (x.dot(y)));
        y.normalize();
        z = (z - x * (x.dot(z)) - y * (y.dot(z)));
        z.normalize();

        setColumn(0, x);
        setColumn(1, y);
        setColumn(2, z);
    }

    Basis orthonormalized() const {
        Basis b = this;
        b.orthonormalize();
        return b;
    }

    void orthogonalize() {
        Vector3 scl = getScale();
	    orthonormalize();
	    scaleLocal(scl);
    }

    Basis orthogonalized() const {
        Basis c = this;
        c.orthogonalize();
        return c;
    }

    bool isSymmetric() const {
        if (fabs(elements[0][1] - elements[1][0]) > CMP_EPSILON)
            return false;
        if (fabs(elements[0][2] - elements[2][0]) > CMP_EPSILON)
            return false;
        if (fabs(elements[1][2] - elements[2][1]) > CMP_EPSILON)
            return false;

        return true;
    }

    Basis diagonalize() {
        // much copy paste, WOW
        if (!isSymmetric())
            return Basis();

        const int ite_max = 1024;

        real_t off_matrix_norm_2 = elements[0][1] * elements[0][1] + elements[0][2] * elements[0][2] + elements[1][2] * elements[1][2];

        int ite = 0;
        Basis acc_rot;
        while (off_matrix_norm_2 > CMP_EPSILON2 && ite++ < ite_max) {
            real_t el01_2 = elements[0][1] * elements[0][1];
            real_t el02_2 = elements[0][2] * elements[0][2];
            real_t el12_2 = elements[1][2] * elements[1][2];
            // Find the pivot element
            int i, j;
            if (el01_2 > el02_2) {
                if (el12_2 > el01_2) {
                    i = 1;
                    j = 2;
                } else {
                    i = 0;
                    j = 1;
                }
            } else {
                if (el12_2 > el02_2) {
                    i = 1;
                    j = 2;
                } else {
                    i = 0;
                    j = 2;
                }
            }

            // Compute the rotation angle
            real_t angle;
            if (fabs(elements[j][j] - elements[i][i]) < CMP_EPSILON) {
                angle = PI / 4;
            } else {
                angle = 0.5 * atan(2 * elements[i][j] / (elements[j][j] - elements[i][i]));
            }

            // Compute the rotation matrix
            Basis rot;
            rot.elements[i][i] = rot.elements[j][j] = cos(angle);
            rot.elements[i][j] = -(rot.elements[j][i] = sin(angle));

            // Update the off matrix norm
            off_matrix_norm_2 -= elements[i][j] * elements[i][j];

            // Apply the rotation
            this = rot * this * rot.transposed();
            acc_rot = rot * acc_rot;
        }

        return acc_rot;
    }

    static immutable Basis[24] _ortho_bases =
        [
            Basis(1, 0, 0, 0, 1, 0, 0, 0, 1),
            Basis(0, -1, 0, 1, 0, 0, 0, 0, 1),
            Basis(-1, 0, 0, 0, -1, 0, 0, 0, 1),
            Basis(0, 1, 0, -1, 0, 0, 0, 0, 1),
            Basis(1, 0, 0, 0, 0, -1, 0, 1, 0),
            Basis(0, 0, 1, 1, 0, 0, 0, 1, 0),
            Basis(-1, 0, 0, 0, 0, 1, 0, 1, 0),
            Basis(0, 0, -1, -1, 0, 0, 0, 1, 0),
            Basis(1, 0, 0, 0, -1, 0, 0, 0, -1),
            Basis(0, 1, 0, 1, 0, 0, 0, 0, -1),
            Basis(-1, 0, 0, 0, 1, 0, 0, 0, -1),
            Basis(0, -1, 0, -1, 0, 0, 0, 0, -1),
            Basis(1, 0, 0, 0, 0, 1, 0, -1, 0),
            Basis(0, 0, -1, 1, 0, 0, 0, -1, 0),
            Basis(-1, 0, 0, 0, 0, -1, 0, -1, 0),
            Basis(0, 0, 1, -1, 0, 0, 0, -1, 0),
            Basis(0, 0, 1, 0, 1, 0, -1, 0, 0),
            Basis(0, -1, 0, 0, 0, 1, -1, 0, 0),
            Basis(0, 0, -1, 0, -1, 0, -1, 0, 0),
            Basis(0, 1, 0, 0, 0, -1, -1, 0, 0),
            Basis(0, 0, 1, 0, -1, 0, 1, 0, 0),
            Basis(0, 1, 0, 0, 0, 1, 1, 0, 0),
            Basis(0, 0, -1, 0, 1, 0, 1, 0, 0),
            Basis(0, -1, 0, 0, 0, -1, 1, 0, 0)
        ];

    int getOrthogonalIndex() const {
        //could be sped up if i come up with a way
        Basis orth = this;
        for (int i = 0; i < 3; i++) {
            for (int j = 0; j < 3; j++) {

                real_t v = orth[i][j];
                if (v > 0.5)
                    v = 1.0;
                else if (v < -0.5)
                    v = -1.0;
                else
                    v = 0;

                orth[i][j] = v;
            }
        }

        for (int i = 0; i < 24; i++) {

            if (_ortho_bases[i] == orth)
                return i;

        }

        return 0;
    }

    void setOrthogonalIndex(int index) {
        //there only exist 24 orthogonal bases in r3
        ///ERR_FAIL_COND(index >= 24);
        this = _ortho_bases[index];
    }

    static Basis lookingAt(in Vector3 target, in Vector3 up = Vector3(0, 1, 0)) {
        Vector3 v_z = -target.normalized();
        Vector3 v_x = up.cross(v_z);
        v_x.normalize();
        Vector3 v_y = v_z.cross(v_x);

        Basis basis;
        basis.setColumns(v_x, v_y, v_z);
        return basis;
    }

    static Basis fromScale(in Vector3 scale) {
        return Basis(scale.x, 0, 0, 0, scale.y, 0, 0, 0, scale.z);
    }

    deprecated("use Basis.fromEuler()")
    this(in Vector3 euler) {
        setEuler(euler);
    }

    this(in Quaternion quaternion) {
        setQuaternion(quaternion);
    }

    this(in Quaternion quaternion, in Vector3 scale) { 
        setQuaternionScale(quaternion, scale); 
    }

    this(in Vector3 axis, real_t angle) {
        setAxisAngle(axis, angle);
    }

    this(in Vector3 axis, real_t angle, in Vector3 scale) { 
        setAxisAngleScale(axis, angle, scale); 
    }

    Quaternion quat() const {
        ///ERR_FAIL_COND_V(is_rotation() == false, Quaternion());

        real_t trace = elements[0][0] + elements[1][1] + elements[2][2];
        real_t[4] temp;

        if (trace > 0.0) {
            real_t s = sqrt(trace + 1.0);
            temp[3] = (s * 0.5);
            s = 0.5 / s;

            temp[0] = ((elements[2][1] - elements[1][2]) * s);
            temp[1] = ((elements[0][2] - elements[2][0]) * s);
            temp[2] = ((elements[1][0] - elements[0][1]) * s);
        } else {
            int i = elements[0][0] < elements[1][1] ?
                (elements[1][1] < elements[2][2] ? 2 : 1) : (elements[0][0] < elements[2][2] ? 2 : 0);
            int j = (i + 1) % 3;
            int k = (i + 2) % 3;

            real_t s = sqrt(elements[i][i] - elements[j][j] - elements[k][k] + 1.0);
            temp[i] = s * 0.5;
            s = 0.5 / s;

            temp[3] = (elements[k][j] - elements[j][k]) * s;
            temp[j] = (elements[j][i] + elements[i][j]) * s;
            temp[k] = (elements[k][i] + elements[i][k]) * s;
        }
        return Quaternion(temp[0], temp[1], temp[2], temp[3]);
    }

    Quaternion opCast(T : Quaternion)() const {
        return quat();
    }

    private void _setDiagonal(in Vector3 diag) {
        rows[0][0] = diag.x;
        rows[0][1] = 0;
        rows[0][2] = 0;

        rows[1][0] = 0;
        rows[1][1] = diag.y;
        rows[1][2] = 0;

        rows[2][0] = 0;
        rows[2][1] = 0;
        rows[2][2] = diag.z;
    }
}

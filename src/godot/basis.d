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

import std.math;
import std.algorithm.mutation : swap;

/**
3x3 matrix used for 3D rotation and scale. Contains 3 vector fields x, y, and z as its columns, which can be interpreted as the local basis vectors of a transformation. Can also be accessed as array of 3D vectors. These vectors are orthogonal to each other, but are not necessarily normalized. Almost always used as orthogonal basis for a $(D Transform).

For such use, it is composed of a scaling and a rotation matrix, in that order (M = R.S).
*/
struct Basis {
@nogc nothrow:

    Vector3[3] elements =
        [
            Vector3(1.0, 0.0, 0.0),
            Vector3(0.0, 1.0, 0.0),
            Vector3(0.0, 0.0, 1.0),
        ];
    alias rows = elements;

    this(in Vector3 row0, in Vector3 row1, in Vector3 row2) {
        elements[0] = row0;
        elements[1] = row1;
        elements[2] = row2;
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

    bool isEqualApprox(in Basis a, in Basis b) const {
        for (int i = 0; i < 3; i++) {
            for (int j = 0; j < 3; j++) {
                if ((fabs(a.elements[i][j] - b.elements[i][j]) < CMP_EPSILON) == false)
                    return false;
            }
        }

        return true;
    }

    bool isOrthogonal() const {
        Basis id;
        Basis m = (this) * transposed();

        return isEqualApprox(id, m);
    }

    bool isRotation() const {
        return fabs(determinant() - 1) < CMP_EPSILON && isOrthogonal();
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

    Vector3 getAxis(int p_axis) const {
        // get actual basis axis (elements is transposed for performance)
        return Vector3(elements[0][p_axis], elements[1][p_axis], elements[2][p_axis]);
    }

    void setAxis(int p_axis, in Vector3 p_value) {
        // get actual basis axis (elements is transposed for performance)
        elements[0][p_axis] = p_value.x;
        elements[1][p_axis] = p_value.y;
        elements[2][p_axis] = p_value.z;
    }

    void rotate(in Vector3 p_axis, real_t p_phi) {
        this = rotated(p_axis, p_phi);
    }

    Basis rotated(in Vector3 p_axis, real_t p_phi) const {
        return Basis(p_axis, p_phi) * (this);
    }

    void scale(in Vector3 p_scale) {
        elements[0][0] *= p_scale.x;
        elements[0][1] *= p_scale.x;
        elements[0][2] *= p_scale.x;
        elements[1][0] *= p_scale.y;
        elements[1][1] *= p_scale.y;
        elements[1][2] *= p_scale.y;
        elements[2][0] *= p_scale.z;
        elements[2][1] *= p_scale.z;
        elements[2][2] *= p_scale.z;
    }

    Basis scaled(in Vector3 p_scale) const {
        Basis b = this;
        b.scale(p_scale);
        return b;
    }

    Vector3 getScale() const {
        // We are assuming M = R.S, and performing a polar decomposition to extract R and S.
        // FIXME: We eventually need a proper polar decomposition.
        // As a cheap workaround until then, to ensure that R is a proper rotation matrix with determinant +1
        // (such that it can be represented by a Quaternion or Euler angles), we absorb the sign flip into the scaling matrix.
        // As such, it works in conjuction with get_rotation().
        real_t det_sign = determinant() > 0 ? 1 : -1;
        return det_sign * Vector3(
            Vector3(elements[0][0], elements[1][0], elements[2][0]).length,
            Vector3(elements[0][1], elements[1][1], elements[2][1]).length,
            Vector3(elements[0][2], elements[1][2], elements[2][2]).length
        );
    }

    Vector3 getEuler() const {
        // Euler angles in XYZ convention.
        // See https://en.wikipedia.org/wiki/Euler_angles#Rotation_matrix
        //
        // rot =  cy*cz		  -cy*sz		   sy
        //		cz*sx*sy+cx*sz  cx*cz-sx*sy*sz -cy*sx
        //	   -cx*cz*sy+sx*sz  cz*sx+cx*sy*sz  cx*cy

        Vector3 euler;

        if (isRotation() == false)
            return euler;

        euler.y = asin(elements[0][2]);
        if (euler.y < PI * 0.5) {
            if (euler.y > -PI * 0.5) {
                euler.x = atan2(-elements[1][2], elements[2][2]);
                euler.z = atan2(-elements[0][1], elements[0][0]);
            } else {
                real_t r = atan2(elements[1][0], elements[1][1]);
                euler.z = 0.0;
                euler.x = euler.z - r;
            }
        } else {
            real_t r = atan2(elements[0][1], elements[1][1]);
            euler.z = 0;
            euler.x = r - euler.z;
        }
        return euler;
    }

    void setEuler(in Vector3 p_euler) {
        real_t c, s;

        c = cos(p_euler.x);
        s = sin(p_euler.x);
        Basis xmat = Basis(1.0, 0.0, 0.0, 0.0, c, -s, 0.0, s, c);

        c = cos(p_euler.y);
        s = sin(p_euler.y);
        Basis ymat = Basis(c, 0.0, s, 0.0, 1.0, 0.0, -s, 0.0, c);

        c = cos(p_euler.z);
        s = sin(p_euler.z);
        Basis zmat = Basis(c, -s, 0.0, s, c, 0.0, 0.0, 0.0, 1.0);

        //optimizer will optimize away all this anyway
        this = xmat * (ymat * zmat);
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

    Vector3 xform(in Vector3 p_vector) const {
        return Vector3(
            elements[0].dot(p_vector),
            elements[1].dot(p_vector),
            elements[2].dot(p_vector)
        );
    }

    Vector3 xformInv(in Vector3 p_vector) const {
        return Vector3(
            (elements[0][0] * p_vector.x) + (elements[1][0] * p_vector.y) + (
                elements[2][0] * p_vector.z),
            (elements[0][1] * p_vector.x) + (elements[1][1] * p_vector.y) + (
                elements[2][1] * p_vector.z),
            (elements[0][2] * p_vector.x) + (elements[1][2] * p_vector.y) + (
                elements[2][2] * p_vector.z)
        );
    }

    void opOpAssign(string op : "*")(in Basis p_matrix) {
        set(
            p_matrix.tdotx(elements[0]), p_matrix.tdoty(elements[0]), p_matrix.tdotz(elements[0]),
            p_matrix.tdotx(elements[1]), p_matrix.tdoty(elements[1]), p_matrix.tdotz(elements[1]),
            p_matrix.tdotx(elements[2]), p_matrix.tdoty(elements[2]), p_matrix.tdotz(elements[2]));

    }

    Basis opBinary(string op : "*")(in Basis p_matrix) const {
        return Basis(
            p_matrix.tdotx(elements[0]), p_matrix.tdoty(elements[0]), p_matrix.tdotz(elements[0]),
            p_matrix.tdotx(elements[1]), p_matrix.tdoty(elements[1]), p_matrix.tdotz(elements[1]),
            p_matrix.tdotx(elements[2]), p_matrix.tdoty(elements[2]), p_matrix.tdotz(elements[2]));

    }

    void opOpAssign(string op : "+")(in Basis p_matrix) {
        elements[0] += p_matrix.elements[0];
        elements[1] += p_matrix.elements[1];
        elements[2] += p_matrix.elements[2];
    }

    Basis opBinary(string op : "+")(in Basis p_matrix) const {
        Basis ret = this;
        ret += p_matrix;
        return ret;
    }

    void opOpAssign(string op : "-")(in Basis p_matrix) {
        elements[0] -= p_matrix.elements[0];
        elements[1] -= p_matrix.elements[1];
        elements[2] -= p_matrix.elements[2];
    }

    Basis opBinary(string op : "-")(in Basis p_matrix) const {
        Basis ret = this;
        ret -= p_matrix;
        return ret;
    }

    void opOpAssign(string op : "*")(real_t p_val) {

        elements[0] *= p_val;
        elements[1] *= p_val;
        elements[2] *= p_val;
    }

    Basis opBinary(string op : "*")(real_t p_val) const {

        Basis ret = this;
        ret *= p_val;
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

    Vector3 getColumn(int i) const {
        return Vector3(elements[0][i], elements[1][i], elements[2][i]);
    }

    Vector3 getRow(int i) const {
        return Vector3(elements[i][0], elements[i][1], elements[i][2]);
    }

    Vector3 getMainDiagonal() const {
        return Vector3(elements[0][0], elements[1][1], elements[2][2]);
    }

    void setRow(int i, in Vector3 p_row) {
        elements[i][0] = p_row.x;
        elements[i][1] = p_row.y;
        elements[i][2] = p_row.z;
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

        Vector3 x = getAxis(0);
        Vector3 y = getAxis(1);
        Vector3 z = getAxis(2);

        x.normalize();
        y = (y - x * (x.dot(y)));
        y.normalize();
        z = (z - x * (x.dot(z)) - y * (y.dot(z)));
        z.normalize();

        setAxis(0, x);
        setAxis(1, y);
        setAxis(2, z);
    }

    Basis orthonormalized() const {
        Basis b = this;
        b.orthonormalize();
        return b;
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

    void setOrthogonalIndex(int p_index) {
        //there only exist 24 orthogonal bases in r3
        ///ERR_FAIL_COND(p_index >= 24);
        this = _ortho_bases[p_index];
    }

    this(in Vector3 p_euler) {
        setEuler(p_euler);
    }

    this(in Quaternion p_quat) {

        real_t d = p_quat.lengthSquared();
        real_t s = 2.0 / d;
        real_t xs = p_quat.x * s, ys = p_quat.y * s, zs = p_quat.z * s;
        real_t wx = p_quat.w * xs, wy = p_quat.w * ys, wz = p_quat.w * zs;
        real_t xx = p_quat.x * xs, xy = p_quat.x * ys, xz = p_quat.x * zs;
        real_t yy = p_quat.y * ys, yz = p_quat.y * zs, zz = p_quat.z * zs;
        set(1.0 - (yy + zz), xy - wz, xz + wy,
            xy + wz, 1.0 - (xx + zz), yz - wx,
            xz - wy, yz + wx, 1.0 - (xx + yy));

    }

    this(in Vector3 p_axis, real_t p_phi) {
        // Rotation matrix from axis and angle, see https://en.wikipedia.org/wiki/Rotation_matrix#Rotation_matrix_from_axis_and_angle

        Vector3 axis_sq = Vector3(p_axis.x * p_axis.x, p_axis.y * p_axis.y, p_axis.z * p_axis.z);

        real_t cosine = cos(p_phi);
        real_t sine = sin(p_phi);

        elements[0][0] = axis_sq.x + cosine * (1.0 - axis_sq.x);
        elements[0][1] = p_axis.x * p_axis.y * (1.0 - cosine) - p_axis.z * sine;
        elements[0][2] = p_axis.z * p_axis.x * (1.0 - cosine) + p_axis.y * sine;

        elements[1][0] = p_axis.x * p_axis.y * (1.0 - cosine) + p_axis.z * sine;
        elements[1][1] = axis_sq.y + cosine * (1.0 - axis_sq.y);
        elements[1][2] = p_axis.y * p_axis.z * (1.0 - cosine) - p_axis.x * sine;

        elements[2][0] = p_axis.z * p_axis.x * (1.0 - cosine) - p_axis.y * sine;
        elements[2][1] = p_axis.y * p_axis.z * (1.0 - cosine) + p_axis.x * sine;
        elements[2][2] = axis_sq.z + cosine * (1.0 - axis_sq.z);

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
}

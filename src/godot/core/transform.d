/**
3D Transformation. 3x4 matrix.

Copyright:
Copyright (c) 2007-2022 Juan Linietsky, Ariel Manzur.
Copyright (c) 2014-2022 Godot Engine contributors (cf. AUTHORS.md)
Copyright (c) 2017-2018 Godot-D contributors
Copyright (c) 2022-2022 Godot-DLang contributors

License: $(LINK2 https://opensource.org/licenses/MIT, MIT License)


*/
module godot.transform;

import godot.defs;
import godot.vector3;
import godot.quat;
import godot.basis;
import godot.aabb;
import godot.plane;

/**
Represents one or many transformations in 3D space such as translation, rotation, or scaling. It is similar to a 3x4 matrix.
*/
struct Transform3D {
@nogc nothrow:

    Basis basis; /// 
    Vector3 origin; /// 

    this(real_t xx, real_t xy, real_t xz, real_t yx, real_t yy, real_t yz,
        real_t zx, real_t zy, real_t zz, real_t tx, real_t ty, real_t tz) {
        set(xx, xy, xz, yx, yy, yz, zx, zy, zz, tx, ty, tz);
    }

    this(in Basis basis, in Vector3 origin) {
        this.basis = basis;
        this.origin = origin;
    }

    Transform3D inverseXform(in Transform3D t) const {
        Vector3 v = t.origin - origin;
        return Transform3D(basis.transposeXform(t.basis),
            basis.xform(v));
    }

    void set(real_t xx, real_t xy, real_t xz, real_t yx, real_t yy, real_t yz, real_t zx, real_t zy, real_t zz, real_t tx, real_t ty, real_t tz) {
        basis.elements[0][0] = xx;
        basis.elements[0][1] = xy;
        basis.elements[0][2] = xz;
        basis.elements[1][0] = yx;
        basis.elements[1][1] = yy;
        basis.elements[1][2] = yz;
        basis.elements[2][0] = zx;
        basis.elements[2][1] = zy;
        basis.elements[2][2] = zz;
        origin.x = tx;
        origin.y = ty;
        origin.z = tz;
    }

    Vector3 xform(in Vector3 p_vector) const {
        return Vector3(
            basis[0].dot(p_vector) + origin.x,
            basis[1].dot(p_vector) + origin.y,
            basis[2].dot(p_vector) + origin.z
        );
    }

    Vector3 xformInv(in Vector3 p_vector) const {
        Vector3 v = p_vector - origin;

        return Vector3(
            (basis.elements[0][0] * v.x) + (basis.elements[1][0] * v.y) + (
                basis.elements[2][0] * v.z),
            (basis.elements[0][1] * v.x) + (basis.elements[1][1] * v.y) + (
                basis.elements[2][1] * v.z),
            (basis.elements[0][2] * v.x) + (basis.elements[1][2] * v.y) + (
                basis.elements[2][2] * v.z)
        );
    }

    Plane xform(in Plane p_plane) const {
        Vector3 point = p_plane.normal * p_plane.d;
        Vector3 point_dir = point + p_plane.normal;
        point = xform(point);
        point_dir = xform(point_dir);

        Vector3 normal = point_dir - point;
        normal.normalize();
        real_t d = normal.dot(point);

        return Plane(normal, d);

    }

    Plane xformInv(in Plane p_plane) const {
        Vector3 point = p_plane.normal * p_plane.d;
        Vector3 point_dir = point + p_plane.normal;
        point = xformInv(point);
        point_dir = xformInv(point_dir);

        Vector3 normal = point_dir - point;
        normal.normalize();
        real_t d = normal.dot(point);

        return Plane(normal, d);

    }

    AABB xform(in AABB p_aabb) const {
        /* define vertices */
        Vector3 x = basis.getAxis(0) * p_aabb.size.x;
        Vector3 y = basis.getAxis(1) * p_aabb.size.y;
        Vector3 z = basis.getAxis(2) * p_aabb.size.z;
        Vector3 pos = xform(p_aabb.position);
        //could be even further optimized
        AABB new_aabb;
        new_aabb.position = pos;
        new_aabb.expandTo(pos + x);
        new_aabb.expandTo(pos + y);
        new_aabb.expandTo(pos + z);
        new_aabb.expandTo(pos + x + y);
        new_aabb.expandTo(pos + x + z);
        new_aabb.expandTo(pos + y + z);
        new_aabb.expandTo(pos + x + y + z);
        return new_aabb;
    }

    AABB xformInv(in AABB p_aabb) const {
        /* define vertices */
        Vector3[8] vertices = [
            Vector3(p_aabb.position.x + p_aabb.size.x, p_aabb.position.y + p_aabb.size.y, p_aabb.position.z + p_aabb
                    .size.z),
            Vector3(p_aabb.position.x + p_aabb.size.x, p_aabb.position.y + p_aabb.size.y, p_aabb
                    .position.z),
            Vector3(p_aabb.position.x + p_aabb.size.x, p_aabb.position.y, p_aabb.position.z + p_aabb
                    .size.z),
            Vector3(p_aabb.position.x + p_aabb.size.x, p_aabb.position.y, p_aabb.position.z),
            Vector3(p_aabb.position.x, p_aabb.position.y + p_aabb.size.y, p_aabb.position.z + p_aabb
                    .size.z),
            Vector3(p_aabb.position.x, p_aabb.position.y + p_aabb.size.y, p_aabb.position.z),
            Vector3(p_aabb.position.x, p_aabb.position.y, p_aabb.position.z + p_aabb.size.z),
            Vector3(p_aabb.position.x, p_aabb.position.y, p_aabb.position.z)
        ];
        AABB ret;
        ret.position = xformInv(vertices[0]);
        for (int i = 1; i < 8; i++) {
            ret.expandTo(xformInv(vertices[i]));
        }
        return ret;

    }

    void affineInvert() {
        basis.invert();
        origin = basis.xform(-origin);
    }

    Transform3D affineInverse() const {
        Transform3D ret = this;
        ret.affineInvert();
        return ret;

    }

    void invert() {
        basis.transpose();
        origin = basis.xform(-origin);
    }

    Transform3D inverse() const {
        // FIXME: this function assumes the basis is a rotation matrix, with no scaling.
        // affine_inverse can handle matrices with scaling, so GDScript should eventually use that.
        Transform3D ret = this;
        ret.invert();
        return ret;
    }

    void rotate(in Vector3 p_axis, real_t p_phi) {
        this = rotated(p_axis, p_phi);
    }

    Transform3D rotated(in Vector3 p_axis, real_t p_phi) const {
        return Transform3D(Basis(p_axis, p_phi), Vector3()) * (this);
    }

    void rotateBasis(in Vector3 p_axis, real_t p_phi) {
        basis.rotate(p_axis, p_phi);
    }

    Transform3D lookingAt(in Vector3 p_target, in Vector3 p_up) const {
        Transform3D t = this;
        t.setLookAt(origin, p_target, p_up);
        return t;
    }

    void setLookAt(in Vector3 p_eye, in Vector3 p_target, in Vector3 p_up) {
        // Reference: MESA source code
        Vector3 v_x, v_y, v_z;
        /* Make rotation matrix */

        /* Z vector */
        v_z = p_eye - p_target;

        v_z.normalize();

        v_y = p_up;

        v_x = v_y.cross(v_z);

        /* Recompute Y = Z cross X */
        v_y = v_z.cross(v_x);

        v_x.normalize();
        v_y.normalize();

        basis.setAxis(0, v_x);
        basis.setAxis(1, v_y);
        basis.setAxis(2, v_z);
        origin = p_eye;
    }

    Transform3D interpolateWith(in Transform3D p_transform, real_t p_c) const {
        /* not sure if very "efficient" but good enough? */
        Vector3 src_scale = basis.getScale();
        Quaternion src_rot = basis.quat;
        Vector3 src_loc = origin;

        Vector3 dst_scale = p_transform.basis.getScale();
        Quaternion dst_rot = p_transform.basis.quat;
        Vector3 dst_loc = p_transform.origin;

        Transform3D dst;
        dst.basis = Basis(src_rot.slerp(dst_rot, p_c));
        dst.basis.scale(src_scale.linearInterpolate(dst_scale, p_c));
        dst.origin = src_loc.linearInterpolate(dst_loc, p_c);

        return dst;
    }

    void scale(in Vector3 p_scale) {
        basis.scale(p_scale);
        origin *= p_scale;
    }

    Transform3D scaled(in Vector3 p_scale) const {
        Transform3D t = this;
        t.scale(p_scale);
        return t;
    }

    void scaleBasis(in Vector3 p_scale) {
        basis.scale(p_scale);
    }

    void translate(real_t p_tx, real_t p_ty, real_t p_tz) {
        translate(Vector3(p_tx, p_ty, p_tz));
    }

    void translate(in Vector3 p_translation) {
        for (int i = 0; i < 3; i++) {
            origin[i] += basis[i].dot(p_translation);
        }
    }

    Transform3D translated(in Vector3 p_translation) const {
        Transform3D t = this;
        t.translate(p_translation);
        return t;
    }

    void orthonormalize() {
        basis.orthonormalize();
    }

    Transform3D orthonormalized() const {
        Transform3D _copy = this;
        _copy.orthonormalize();
        return _copy;
    }

    void opOpAssign(string op : "*")(in Transform3D p_transform) {
        origin = xform(p_transform.origin);
        basis *= p_transform.basis;
    }

    Transform3D opBinary(string op : "*")(in Transform3D p_transform) const {
        Transform3D t = this;
        t *= p_transform;
        return t;
    }
}

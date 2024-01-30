/**
3D Transformation. 3x4 matrix.

Copyright:
Copyright (c) 2007 Juan Linietsky, Ariel Manzur.
Copyright (c) 2014 Godot Engine contributors (cf. AUTHORS.md)
Copyright (c) 2017 Godot-D contributors
Copyright (c) 2022 Godot-DLang contributors

License: $(LINK2 https://opensource.org/licenses/MIT, MIT License)


*/
module godot.transform;

import godot.api.types;
import godot.vector3;
import godot.quat;
import godot.basis;
import godot.aabb;
import godot.plane;
import godot.poolarrays;

/**
Represents one or many transformations in 3D space such as translation, rotation, or scaling. It is similar to a 3x4 matrix.
*/
struct Transform3D {
@nogc nothrow:

    Basis basis; /// 
    Vector3 origin; /// 

    this(real_t xx, real_t xy, real_t xz, real_t yx, real_t yy, real_t yz,
            real_t zx, real_t zy, real_t zz, real_t ox, real_t oy, real_t oz) {
        basis = Basis(xx, xy, xz, yx, yy, yz, zx, zy, zz);
	    origin = Vector3(ox, oy, oz);
    }

    this(in Basis basis, in Vector3 origin = Vector3()) {
        this.basis = basis;
        this.origin = origin;
    }

    this(in Vector3 x, in Vector3 y, in Vector3 z, in Vector3 origin) {
        this.origin = origin;
        this.basis.setColumn(0, x);
        this.basis.setColumn(1, y);
        this.basis.setColumn(2, z);
    }

    Transform3D inverseXform(in Transform3D t) const {
        Vector3 v = t.origin - origin;
        return Transform3D(basis.transposeXform(t.basis),
            basis.xform(v));
    }

    void set(real_t xx, real_t xy, real_t xz, real_t yx, real_t yy, real_t yz, real_t zx, real_t zy, real_t zz, real_t tx, real_t ty, real_t tz) {
        basis.set(xx, xy, xz, yx, yy, yz, zx, zy, zz);
        origin.x = tx;
		origin.y = ty;
		origin.z = tz;
    }

    Vector3 xform(in Vector3 vector) const {
        return Vector3(
            basis[0].dot(vector) + origin.x,
            basis[1].dot(vector) + origin.y,
            basis[2].dot(vector) + origin.z
        );
    }

    Vector3 xformInv(in Vector3 vector) const {
        Vector3 v = vector - origin;

        return Vector3(
            (basis.rows[0][0] * v.x) + (basis.rows[1][0] * v.y) + (basis.rows[2][0] * v.z),
            (basis.rows[0][1] * v.x) + (basis.rows[1][1] * v.y) + (basis.rows[2][1] * v.z),
            (basis.rows[0][2] * v.x) + (basis.rows[1][2] * v.y) + (basis.rows[2][2] * v.z)
        );
    }

    // Safe with non-uniform scaling (uses affine_inverse).
    //
    // Neither the plane regular xform or xform_inv are particularly efficient,
    // as they do a basis inverse. For xforming a large number
    // of planes it is better to pre-calculate the inverse transpose basis once
    // and reuse it for each plane, by using the 'fast' version of the functions.
    Plane xform(in Plane plane) const {
        Basis b = basis.inverse();
        b.transpose();
        return xformFast(plane, b);
    }

    Plane xformInv(in Plane plane) const {
        Transform3D inv = affineInverse();
        Basis basis_transpose = basis.transposed();
        return xformInvFast(plane, inv, basis_transpose);
    }

    AABB xform(in AABB aabb) const {
        /* https://dev.theomader.com/transform-bounding-boxes/ */
        Vector3 min = aabb.position;
        Vector3 max = aabb.position + aabb.size;
        Vector3 tmin, tmax;
        for (int i = 0; i < 3; i++) {
            tmin[i] = tmax[i] = origin[i];
            for (int j = 0; j < 3; j++) {
                real_t e = basis[i][j] * min[j];
                real_t f = basis[i][j] * max[j];
                if (e < f) {
                    tmin[i] += e;
                    tmax[i] += f;
                } else {
                    tmin[i] += f;
                    tmax[i] += e;
                }
            }
        }
        AABB r_aabb;
        r_aabb.position = tmin;
        r_aabb.size = tmax - tmin;
        return r_aabb;
    }

    AABB xformInv(in AABB aabb) const {
        /* define vertices */
        Vector3[8] vertices = [
            Vector3(aabb.position.x + aabb.size.x, aabb.position.y + aabb.size.y, aabb.position.z + aabb
                    .size.z),
            Vector3(aabb.position.x + aabb.size.x, aabb.position.y + aabb.size.y, aabb
                    .position.z),
            Vector3(aabb.position.x + aabb.size.x, aabb.position.y, aabb.position.z + aabb
                    .size.z),
            Vector3(aabb.position.x + aabb.size.x, aabb.position.y, aabb.position.z),
            Vector3(aabb.position.x, aabb.position.y + aabb.size.y, aabb.position.z + aabb
                    .size.z),
            Vector3(aabb.position.x, aabb.position.y + aabb.size.y, aabb.position.z),
            Vector3(aabb.position.x, aabb.position.y, aabb.position.z + aabb.size.z),
            Vector3(aabb.position.x, aabb.position.y, aabb.position.z)
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

    void rotate(in Vector3 axis, real_t angle) {
        this = rotated(axis, angle);
    }

    Transform3D rotated(in Vector3 axis, real_t angle) const {
        // Equivalent to left multiplication
        Basis p_basis = Basis(axis, angle);
        return Transform3D(p_basis * basis, p_basis.xform(origin));
    }


    Transform3D rotatedLocal(in Vector3 axis, real_t angle) const {
        // Equivalent to right multiplication
        Basis p_basis = Basis(axis, angle);
        return Transform3D(basis * p_basis, origin);
    }

    void rotateBasis(in Vector3 axis, real_t angle) {
        basis.rotate(axis, angle);
    }

    Transform3D lookingAt(in Vector3 target, in Vector3 up = Vector3(0,1,0)) const {
        Transform3D t = this;
        t.basis = Basis.lookingAt(target - origin, up);
        return t;
    }

    void setLookAt(in Vector3 eye, in Vector3 target, in Vector3 up = Vector3(0,1,0)) {
        basis = Basis.lookingAt(target - eye, up);
        origin = eye;
    }

    Transform3D interpolateWith(in Transform3D transform, real_t c) const {
        Transform3D interp;

        Vector3 src_scale = basis.getScale();
        Quaternion src_rot = basis.getRotationQuaternion();
        Vector3 src_loc = origin;

        Vector3 dst_scale = transform.basis.getScale();
        Quaternion dst_rot = transform.basis.getRotationQuaternion();
        Vector3 dst_loc = transform.origin;

        interp.basis.setQuaternionScale(src_rot.slerp(dst_rot, c).normalized(), src_scale.lerp(dst_scale, c));
        interp.origin = src_loc.lerp(dst_loc, c);

        return interp;
    }

    void scale(in Vector3 scale) {
        basis.scale(scale);
        origin *= scale;
    }

    Transform3D scaled(in Vector3 scale) const {
        // Equivalent to left multiplication
        return Transform3D(basis.scaled(scale), origin * scale);
    }

    Transform3D scaledLocal(in Vector3 scale) const {
        // Equivalent to right multiplication
        return Transform3D(basis.scaledLocal(scale), origin);
    }

    void scaleBasis(in Vector3 scale) {
        basis.scale(scale);
    }

    deprecated("use translateLocal")
    alias translate = translateLocal;

    void translateLocal(real_t tx, real_t ty, real_t tz) {
        translateLocal(Vector3(tx, ty, tz));
    }

    void translateLocal(in Vector3 translation) {
        for (int i = 0; i < 3; i++) {
            origin[i] += basis[i].dot(translation);
        }
    }

    Transform3D translated(in Vector3 translation) const {
        // Equivalent to left multiplication
	    return Transform3D(basis, origin + translation);
    }

    Transform3D translatedLocal(in Vector3 translation) const {
        // Equivalent to right multiplication
        return Transform3D(basis, origin + basis.xform(translation));
    }

    void orthonormalize() {
        basis.orthonormalize();
    }

    Transform3D orthonormalized() const {
        Transform3D _copy = this;
        _copy.orthonormalize();
        return _copy;
    }

    void orthogonalize() {
        basis.orthogonalize();
    }

    Transform3D orthogonalized() const {
        Transform3D _copy = this;
        _copy.orthogonalize();
        return _copy;
    }

    bool isEqualApprox(in Transform3D other) const {
        return basis.isEqualApprox(other.basis) && origin.isEqualApprox(other.origin);
    }

    bool opEquals(in Transform3D other) const {
        return (basis == other.basis && origin == other.origin);
    }

    void opOpAssign(string op : "*")(in Transform3D transform) {
        origin = xform(transform.origin);
        basis *= transform.basis;
    }

    Transform3D opBinary(string op : "*")(in Transform3D transform) const {
        Transform3D t = this;
        t *= transform;
        return t;
    }

    void opOpAssign(string op : "*")(in real_t value) {
        origin *= value;
	    basis *= value;
    }

    Transform3D opBinary(string op : "*")(in real_t value) const {
        Transform3D ret = this;
        ret *= value;
        return ret;
    }

// TODO: enable when PackedArray supports @nogc
version(none) {
    PackedVector3Array xform(in PackedVector3Array array) const {
        PackedVector3Array ret;
        ret.resize(array.size());

        foreach (int i; 0..array.size()) {
            ret[i] = xform(array[i]);
        }
        return array;
    }

    PackedVector3Array xformInv(in PackedVector3Array array) const {
        PackedVector3Array ret;
        ret.resize(array.size());

        foreach (int i; 0..array.size()) {
            ret[i] = xformInv(array[i]);
        }
        return array;
    }
}
    Plane xformFast(in Plane plane, in Basis basisInverseTranspose) const {
        // Transform a single point on the plane.
        Vector3 point = plane.normal * plane.d;
        point = xform(point);

        // Use inverse transpose for correct normals with non-uniform scaling.
        Vector3 normal = basisInverseTranspose.xform(plane.normal);
        normal.normalize();

        real_t d = normal.dot(point);
        return Plane(normal, d);
    }

    Plane xformInvFast(in Plane plane, in Transform3D inverse, in Basis basisTranspose) const {
        // Transform a single point on the plane.
        Vector3 point = plane.normal * plane.d;
        point = inverse.xform(point);

        // Note that instead of precalculating the transpose, an alternative
        // would be to use the transpose for the basis transform.
        // However that would be less SIMD friendly (requiring a swizzle).
        // So the cost is one extra precalced value in the calling code.
        // This is probably worth it, as this could be used in bottleneck areas. And
        // where it is not a bottleneck, the non-fast method is fine.

        // Use transpose for correct normals with non-uniform scaling.
        Vector3 normal = basisTranspose.xform(plane.normal);
        normal.normalize();

        real_t d = normal.dot(point);
        return Plane(normal, d);
    }
}

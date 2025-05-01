/**
2D Transformation. 3x2 matrix.

Copyright:
Copyright (c) 2007 Juan Linietsky, Ariel Manzur.
Copyright (c) 2014 Godot Engine contributors (cf. AUTHORS.md)
Copyright (c) 2017 Godot-D contributors
Copyright (c) 2022 Godot-DLang contributors

License: $(LINK2 https://opensource.org/licenses/MIT, MIT License)


*/
module godot.transform2d;

import godot.api.types;
import godot.vector2;
import godot.rect2;
import godot.poolarrays;
import godot.math;

import std.algorithm.comparison;
import std.algorithm.mutation : swap;

/**
Represents one or many transformations in 2D space such as translation, rotation, or scaling. It is similar to a 3x2 matrix.
*/
struct Transform2D {
//@nogc nothrow:
    // Warning #1: basis of Transform2D is stored differently from Basis. In terms of columns array, the basis matrix looks like "on paper":
	// M = (columns[0][0] columns[1][0])
	//     (columns[0][1] columns[1][1])
	// This is such that the columns, which can be interpreted as basis vectors of the coordinate system "painted" on the object, can be accessed as columns[i].
	// Note that this is the opposite of the indices in mathematical texts, meaning: $M_{12}$ in a math book corresponds to columns[1][0] here.
	// This requires additional care when working with explicit indices.
	// See https://en.wikipedia.org/wiki/Row-_and_column-major_order for further reading.

	// Warning #2: 2D be aware that unlike 3D code, 2D code uses a left-handed coordinate system: Y-axis points down,
	// and angle is measure from +X to +Y in a clockwise-fashion.

    union {
        Vector2[3] columns = [Vector2(1, 0), Vector2(0, 1), Vector2(0, 0)];
        struct {
            Vector2 x_axis; /// 
            Vector2 y_axis; /// 
            Vector2 origin; /// 
        }
    }

    real_t tdotx(in Vector2 v) const /*@nogc nothrow*/ {
        return columns[0][0] * v.x + columns[1][0] * v.y;
    }

    real_t tdoty(in Vector2 v) const /*@nogc nothrow*/ {
        return columns[0][1] * v.x + columns[1][1] * v.y;
    }

    this(real_t xx, real_t xy, real_t yx, real_t yy, real_t ox, real_t oy) {
        columns[0][0] = xx;
        columns[0][1] = xy;
        columns[1][0] = yx;
        columns[1][1] = yy;
        columns[2][0] = ox;
        columns[2][1] = oy;
    }

    this(in Vector2 x, in Vector2 y, in Vector2 origin) {
        columns[0] = x;
        columns[1] = y;
        columns[2] = origin;
    }

    this(real_t rot, in Vector2 pos) {
        real_t cr = cos(rot);
        real_t sr = sin(rot);
        columns[0][0] = cr;
        columns[0][1] = sr;
        columns[1][0] = -sr;
        columns[1][1] = cr;
        columns[2] = pos;
    }

    this(in real_t rot, in Vector2 scale, in real_t skew, in Vector2 pos) {
        columns[0][0] = cos(rot) * scale.x;
        columns[1][1] = cos(rot + skew) * scale.y;
        columns[1][0] = -sin(rot + skew) * scale.y;
        columns[0][1] = sin(rot) * scale.x;
        columns[2] = pos;
    }

    const(Vector2) opIndex(int col) const {
        return columns[col];
    }

    ref Vector2 opIndex(int col) return {
        return columns[col];
    }

    Vector2 basisXform(in Vector2 v) const {
        return Vector2(
            tdotx(v),
            tdoty(v)
        );
    }

    Vector2 basisXformInv(in Vector2 v) const {
        return Vector2(
            columns[0].dot(v),
            columns[1].dot(v)
        );
    }

    Vector2 xform(in Vector2 v) const /*@nogc nothrow*/ {
        return Vector2(
            tdotx(v),
            tdoty(v)
        ) + columns[2];
    }

    Vector2 xformInv(in Vector2 vec) const {
        Vector2 v = vec - columns[2];

        return Vector2(
            columns[0].dot(v),
            columns[1].dot(v)
        );
    }

    Rect2 xform(in Rect2 rect) const {
        Vector2 x = columns[0] * rect.size.x;
        Vector2 y = columns[1] * rect.size.y;
        Vector2 pos = xform(rect.position);

        Rect2 new_rect;
        new_rect.position = pos;
        new_rect.expandTo(pos + x);
        new_rect.expandTo(pos + y);
        new_rect.expandTo(pos + x + y);
        return new_rect;
    }

    PackedVector2Array xform(ref const(PackedVector2Array) array) const {
        PackedVector2Array newArray;
        newArray.resize(array.size());

        for (int i = 0; i < array.size(); ++i) {
            newArray[i] = xform(array[i]);
        }
        return newArray;
    }

    PackedVector2Array xformInv(ref const (PackedVector2Array) array) const {
        PackedVector2Array newArray;
        newArray.resize(array.size());

        for (int i = 0; i < array.size(); ++i) {
            newArray[i] = xformInv(array[i]);
        }
        return newArray;
    }

    void setRotationAndScale(real_t rot, in Vector2 scale) {
        columns[0][0] = cos(rot) * scale.x;
        columns[1][1] = cos(rot) * scale.y;
        columns[1][0] = -sin(rot) * scale.y;
        columns[0][1] = sin(rot) * scale.x;
    }

    void setRotationScaleAndSkew(in real_t rot, in Vector2 scale, in real_t skew) {
        columns[0][0] = cos(rot) * scale.x;
        columns[1][1] = cos(rot + skew) * scale.y;
        columns[1][0] = -sin(rot + skew) * scale.y;
        columns[0][1] = sin(rot) * scale.x;
    }

    Rect2 xformInv(in Rect2 rect) const {
        Vector2[4] ends = [
            xformInv(rect.position),
            xformInv(Vector2(rect.position.x, rect.position.y + rect.size.y)),
            xformInv(Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y)),
            xformInv(Vector2(rect.position.x + rect.size.x, rect.position.y))
        ];

        Rect2 new_rect;
        new_rect.position = ends[0];
        new_rect.expandTo(ends[1]);
        new_rect.expandTo(ends[2]);
        new_rect.expandTo(ends[3]);

        return new_rect;
    }

    void invert() {
        // FIXME: this function assumes the basis is a rotation matrix, with no scaling.
        // affine_inverse can handle matrices with scaling, so GDScript should eventually use that.
        swap(columns[0][1], columns[1][0]);
        columns[2] = basisXform(-columns[2]);
    }

    Transform2D inverse() const {
        Transform2D inv = this;
        inv.invert();
        return inv;

    }

    void affineInvert() {
        real_t det = basisDeterminant();
        ///ERR_FAIL_COND(det==0);
        real_t idet = 1.0 / det;

        swap(columns[0][0], columns[1][1]);
        columns[0] *= Vector2(idet, -idet);
        columns[1] *= Vector2(-idet, idet);

        columns[2] = basisXform(-columns[2]);

    }

    Transform2D affineInverse() const {
        Transform2D inv = this;
        inv.affineInvert();
        return inv;
    }

    real_t getSkew() const {
        real_t det = basisDeterminant();
	    return acos(columns[0].normalized().dot(sgn(det) * columns[1].normalized())) - PI * 0.5f;
    }

    void setSkew(in real_t angle) {
        real_t det = basisDeterminant();
        columns[1] = sgn(det) * columns[0].rotated((PI * 0.5f + angle)).normalized() * columns[1].length();
    }

    void rotate(in real_t angle) {
        this = Transform2D(angle, Vector2()) * (this);
    }

    real_t getRotation() const {
        real_t det = basisDeterminant();
        Transform2D m = orthonormalized();
        if (det < 0) {
            m.scaleBasis(Vector2(-1, -1));
        }
        return atan2(m[0].y, m[0].x);
    }

    void setRotation(real_t rot) {
        real_t cr = cos(rot);
        real_t sr = sin(rot);
        columns[0][0] = cr;
        columns[0][1] = sr;
        columns[1][0] = -sr;
        columns[1][1] = cr;
    }

    Vector2 getScale() const {
        real_t det_sign = basisDeterminant() > 0 ? 1 : -1;
        return det_sign * Vector2(columns[0].length(), columns[1].length());
    }

    void setScale(in Vector2 scale) {
        columns[0].normalize();
        columns[1].normalize();
        columns[0] *= scale.x;
        columns[1] *= scale.y;
    }

    void scale(in Vector2 scale) {
        scaleBasis(scale);
        columns[2] *= scale;
    }

    void scaleBasis(in Vector2 scale) {
        columns[0][0] *= scale.x;
        columns[0][1] *= scale.y;
        columns[1][0] *= scale.x;
        columns[1][1] *= scale.y;

    }

    Vector2 getOrigin() const { 
        return columns[2]; 
    }

    void setOrigin(in Vector2 origin) {
        columns[2] = origin;
    }

    void orthonormalize() {
        // Gram-Schmidt Process

        Vector2 x = columns[0];
        Vector2 y = columns[1];

        x.normalize();
        y = (y - x * (x.dot(y)));
        y.normalize();

        columns[0] = x;
        columns[1] = y;
    }

    Transform2D orthonormalized() const {
        Transform2D on = this;
        on.orthonormalize();
        return on;
    }

    bool isEqualApprox(in Transform2D transform) const {
        return columns[0].isEqualApprox(transform.columns[0]) 
            && columns[1].isEqualApprox(transform.columns[1]) 
            && columns[2].isEqualApprox(transform.columns[2]);
    }

    Transform2D lookingAt(in Vector2 target) const {
        Transform2D return_trans = Transform2D(getRotation(), getOrigin());
        Vector2 target_position = affineInverse().xform(target);
        return_trans.setRotation(return_trans.getRotation() + (target_position * getScale()).angle());
        return return_trans;       
    }

    bool opEquals(in Transform2D transform) const {
        foreach (i; 0..columns.length) {
            if (columns[i] != transform.columns[i]) {
                return false;
            }
        }

	    return true;
    }

    void opOpAssign(string op : "*")(in Transform2D transform) {
        columns[2] = xform(transform.columns[2]);

        real_t x0, x1, y0, y1;

        x0 = tdotx(transform.columns[0]);
        x1 = tdoty(transform.columns[0]);
        y0 = tdotx(transform.columns[1]);
        y1 = tdoty(transform.columns[1]);

        columns[0][0] = x0;
        columns[0][1] = x1;
        columns[1][0] = y0;
        columns[1][1] = y1;
    }

    Transform2D opBinary(string op : "*")(in Transform2D transform) const {
        Transform2D t = this;
        t *= transform;
        return t;

    }

    void opOpAssign(string op : "*")(in real_t value) {
        columns[0] *= value;
        columns[1] *= value;
        columns[2] *= value;
    }

    Transform2D opBinary(string op : "*")(in real_t value) const {
        Transform2D ret = Transform2D(this);
        ret *= value;
        return ret;
    }

    Transform2D scaled(in Vector2 scale) const {
        Transform2D copy = this;
        copy.scale(scale);
        return copy;
    }

    Transform2D scaledLocal(in Vector2 scale) const {
        // Equivalent to right multiplication
        return Transform2D(columns[0] * scale.x, columns[1] * scale.y, columns[2]);
    }

    Transform2D basisScaled(in Vector2 scale) const {
        Transform2D copy = this;
        copy.scaleBasis(scale);
        return copy;
    }

    Transform2D untranslated() const {
        Transform2D copy = this;
        copy.columns[2] = Vector2();
        return copy;
    }

    Transform2D translated(in Vector2 offset) const {
        // Equivalent to left multiplication
	    return Transform2D(columns[0], columns[1], columns[2] + offset);
    }

    Transform2D translatedLocal(in Vector2 offset) const {
        // Equivalent to right multiplication
        return Transform2D(columns[0], columns[1], columns[2] + basisXform(offset));
    }

    deprecated("use translateLocal")
    alias translate = translateLocal;

    void translateLocal(real_t tx, real_t ty) {
        translateLocal(Vector2(tx, ty));
    }

    void translateLocal(in Vector2 translation) {
        columns[2] += basisXform(translation);
    }

    Transform2D rotated(real_t angle) const {
        // Equivalent to left multiplication
        return Transform2D(angle, Vector2()) * (this);
    }

    Transform2D rotatedLocal(const real_t angle) const {
        // Equivalent to right multiplication
        return (this) * Transform2D(angle, Vector2()); // Could be optimized, because origin transform can be skipped.
    }

    real_t basisDeterminant() const {
        return columns[0].x * columns[1].y - columns[0].y * columns[1].x;
    }

    Transform2D interpolateWith(in Transform2D transform, real_t c) const {
        //extract parameters
        Vector2 p1 = origin;
        Vector2 p2 = transform.origin;

        real_t r1 = getRotation();
        real_t r2 = transform.getRotation();

        Vector2 s1 = getScale();
        Vector2 s2 = transform.getScale();

        //slerp rotation
        Vector2 v1 = Vector2(cos(r1), sin(r1));
        Vector2 v2 = Vector2(cos(r2), sin(r2));

        real_t dot = v1.dot(v2);

        dot = clamp(dot, -1.0, 1.0);

        Vector2 v;

        if (dot > 0.9995) {
            v = v1.linearInterpolate(v2, c).normalized(); //linearly interpolate to avoid numerical precision issues
        } else {
            real_t angle = c * acos(dot);
            Vector2 v3 = (v2 - v1 * dot).normalized();
            v = v1 * cos(angle) + v3 * sin(angle);
        }

        //construct matrix
        Transform2D res = Transform2D(v.angle, p1.linearInterpolate(p2, c));
        res.scaleBasis(s1.linearInterpolate(s2, c));
        return res;
    }
}

/**
Axis-Aligned Bounding Box.

Copyright:
Copyright (c) 2007 Juan Linietsky, Ariel Manzur.
Copyright (c) 2014 Godot Engine contributors (cf. AUTHORS.md)
Copyright (c) 2017 Godot-D contributors
Copyright (c) 2022 Godot-DLang contributors

License: $(LINK2 https://opensource.org/licenses/MIT, MIT License)


*/
module godot.aabb;

import godot.api.types;
import godot.vector3;
import godot.plane;
import godot.math;

import std.algorithm.mutation : swap;

/**
AABB consists of a position, a size, and several utility functions. It is typically used for fast overlap tests.
*/
struct AABB {
@nogc nothrow:

    Vector3 position;
    Vector3 size;

    // some aliases for property-like access
    alias volume = getVolume;
    alias center = getCenter;
    alias end = getEnd;
    alias end = setEnd;

    deprecated("pos has been renamed to position, please use position instead")
    alias pos = position;

    deprecated("getArea has been renamed to getVolume, use getVolume() instead")
    alias getArea = getVolume;

    deprecated("will be removed after Q1 2024, use !hasVolume() instead")
    bool hasNoArea() const { return !hasVolume(); }

    bool hasVolume() const {
        return size.x > 0.0f && size.y > 0.0f && size.z > 0.0f;
    }

    deprecated("will be removed after Q1 2024, use !hasSurface instead")
    bool hasNoSurface() const { return !hasSurface(); }

    bool hasSurface() const {
        return size.x > 0.0f || size.y > 0.0f || size.z > 0.0f;
    }

    bool isEqualApprox(in AABB aabb) const {
        return position.isEqualApprox(aabb.position) && size.isEqualApprox(aabb.size);
    }

    bool intersects(in AABB aabb) const {
        if (position.x >= (aabb.position.x + aabb.size.x))
            return false;
        if ((position.x + size.x) <= aabb.position.x)
            return false;
        if (position.y >= (aabb.position.y + aabb.size.y))
            return false;
        if ((position.y + size.y) <= aabb.position.y)
            return false;
        if (position.z >= (aabb.position.z + aabb.size.z))
            return false;
        if ((position.z + size.z) <= aabb.position.z)
            return false;
        return true;
    }

    bool intersectsInclusive(in AABB aabb) const {
        if (position.x > (aabb.position.x + aabb.size.x))
            return false;
        if ((position.x + size.x) < aabb.position.x)
            return false;
        if (position.y > (aabb.position.y + aabb.size.y))
            return false;
        if ((position.y + size.y) < aabb.position.y)
            return false;
        if (position.z > (aabb.position.z + aabb.size.z))
            return false;
        if ((position.z + size.z) < aabb.position.z)
            return false;
        return true;
    }

    bool encloses(in AABB aabb) const {
        Vector3 src_min = position;
        Vector3 src_max = position + size;
        Vector3 dst_min = aabb.position;
        Vector3 dst_max = aabb.position + aabb.size;

        return (
            (src_min.x <= dst_min.x) &&
                (src_max.x >= dst_max.x) &&
                (src_min.y <= dst_min.y) &&
                (src_max.y >= dst_max.y) &&
                (src_min.z <= dst_min.z) &&
                (src_max.z >= dst_max.z));

    }

    Vector3 getSupport(in Vector3 normal) const {
        Vector3 half_extents = size * 0.5;
        Vector3 ofs = position + half_extents;

        return Vector3(
            (normal.x > 0) ? -half_extents.x : half_extents.x,
            (normal.y > 0) ? -half_extents.y : half_extents.y,
            (normal.z > 0) ? -half_extents.z : half_extents.z
        ) + ofs;
    }

    Vector3 getEndpoint(int point) const {
        switch (point) {
        case 0:
            return Vector3(position.x, position.y, position.z);
        case 1:
            return Vector3(position.x, position.y, position.z + size.z);
        case 2:
            return Vector3(position.x, position.y + size.y, position.z);
        case 3:
            return Vector3(position.x, position.y + size.y, position.z + size.z);
        case 4:
            return Vector3(position.x + size.x, position.y, position.z);
        case 5:
            return Vector3(position.x + size.x, position.y, position.z + size.z);
        case 6:
            return Vector3(position.x + size.x, position.y + size.y, position.z);
        case 7:
            return Vector3(position.x + size.x, position.y + size.y, position.z + size.z);
        default:
            assert(0); ///ERR_FAIL_V(Vector3())
        }
    }

    bool intersectsConvexShape(in Plane[] planes, in Vector3[] points) const {
        Vector3 half_extents = size * 0.5;
        Vector3 ofs = position + half_extents;

        foreach (const ref p; planes) {
            Vector3 point = Vector3(
                (p.normal.x > 0) ? -half_extents.x : half_extents.x,
                (p.normal.y > 0) ? -half_extents.y : half_extents.y,
                (p.normal.z > 0) ? -half_extents.z : half_extents.z
            );
            point += ofs;
            if (p.isPointOver(point))
                return false;
        }

        // Make sure all points in the shape aren't fully separated from the AABB on
        // each axis.
        int[3] bad_point_counts_positive = 0;
        int[3] bad_point_counts_negative = 0;

        for (int k = 0; k < 3; k++) {
            for (int i = 0; i < points.length; i++) {
                if (points[i].coord[k] > ofs.coord[k] + half_extents.coord[k]) {
                    bad_point_counts_positive[k]++;
                }
                if (points[i].coord[k] < ofs.coord[k] - half_extents.coord[k]) {
                    bad_point_counts_negative[k]++;
                }
            }

            if (bad_point_counts_negative[k] == points.length) {
                return false;
            }
            if (bad_point_counts_positive[k] == points.length) {
                return false;
            }
        }

        return true;
    }

    bool insideConvexShape(in Plane[] planes) const {
        Vector3 half_extents = size * 0.5;
        Vector3 ofs = position + half_extents;

        foreach (const ref p; planes) {
            Vector3 point = Vector3(
                (p.normal.x < 0) ? -half_extents.x : half_extents.x,
                (p.normal.y < 0) ? -half_extents.y : half_extents.y,
                (p.normal.z < 0) ? -half_extents.z : half_extents.z
            );
            point += ofs;
            if (p.isPointOver(point))
                return false;
        }

        return true;
    }

    bool hasPoint(in Vector3 point) const {
        if (point.x < position.x)
            return false;
        if (point.y < position.y)
            return false;
        if (point.z < position.z)
            return false;
        if (point.x > position.x + size.x)
            return false;
        if (point.y > position.y + size.y)
            return false;
        if (point.z > position.z + size.z)
            return false;

        return true;
    }

    void expandTo(in Vector3 vector) {
        Vector3 begin = position;
        Vector3 end = position + size;

        if (vector.x < begin.x)
            begin.x = vector.x;
        if (vector.y < begin.y)
            begin.y = vector.y;
        if (vector.z < begin.z)
            begin.z = vector.z;

        if (vector.x > end.x)
            end.x = vector.x;
        if (vector.y > end.y)
            end.y = vector.y;
        if (vector.z > end.z)
            end.z = vector.z;

        position = begin;
        size = end - begin;
    }

    void projectRangeInPlane(in Plane plane, out real_t min, out real_t max) const {
        Vector3 half_extents = Vector3(size.x * 0.5, size.y * 0.5, size.z * 0.5);
        Vector3 center = Vector3(position.x + half_extents.x, position.y + half_extents.y, position.z + half_extents.z);

        real_t length = plane.normal.abs().dot(half_extents);
        real_t distance = plane.distanceTo(center);
        min = distance - length;
        max = distance + length;
    }

    real_t getLongestAxisSize() const {
        real_t max_size = size.x;

        if (size.y > max_size) {
            max_size = size.y;
        }

        if (size.z > max_size) {
            max_size = size.z;
        }

        return max_size;
    }

    real_t getShortestAxisSize() const {
        real_t max_size = size.x;

        if (size.y < max_size) {
            max_size = size.y;
        }

        if (size.z < max_size) {
            max_size = size.z;
        }

        return max_size;
    }

    bool smitsIntersectRay(in Vector3 from, in Vector3 dir, real_t t0, real_t t1) const {
        real_t divx = 1.0 / dir.x;
        real_t divy = 1.0 / dir.y;
        real_t divz = 1.0 / dir.z;

        Vector3 upbound = position + size;
        real_t tmin, tmax, tymin, tymax, tzmin, tzmax;
        if (dir.x >= 0) {
            tmin = (position.x - from.x) * divx;
            tmax = (upbound.x - from.x) * divx;
        } else {
            tmin = (upbound.x - from.x) * divx;
            tmax = (position.x - from.x) * divx;
        }
        if (dir.y >= 0) {
            tymin = (position.y - from.y) * divy;
            tymax = (upbound.y - from.y) * divy;
        } else {
            tymin = (upbound.y - from.y) * divy;
            tymax = (position.y - from.y) * divy;
        }
        if ((tmin > tymax) || (tymin > tmax))
            return false;
        if (tymin > tmin)
            tmin = tymin;
        if (tymax < tmax)
            tmax = tymax;
        if (dir.z >= 0) {
            tzmin = (position.z - from.z) * divz;
            tzmax = (upbound.z - from.z) * divz;
        } else {
            tzmin = (upbound.z - from.z) * divz;
            tzmax = (position.z - from.z) * divz;
        }
        if ((tmin > tzmax) || (tzmin > tmax))
            return false;
        if (tzmin > tmin)
            tmin = tzmin;
        if (tzmax < tmax)
            tmax = tzmax;
        return ((tmin < t1) && (tmax > t0));
    }

    void growBy(real_t amount) {
        position.x -= amount;
        position.y -= amount;
        position.z -= amount;
        size.x += 2.0 * amount;
        size.y += 2.0 * amount;
        size.z += 2.0 * amount;
    }

    real_t getVolume() const {
        return size.x * size.y * size.z;
    }

    Vector3 getCenter() const {
        return position + (size * 0.5f);
    }

    Vector3 getEnd() const {
        return position + size;
    }

    void setEnd(in Vector3 end) {
        size = end - position;
    }

    void quantize(real_t unit) {
        size += position;

        position.x -= fposmodp(position.x, unit);
        position.y -= fposmodp(position.y, unit);
        position.z -= fposmodp(position.z, unit);

        size.x -= fposmodp(size.x, unit);
        size.y -= fposmodp(size.y, unit);
        size.z -= fposmodp(size.z, unit);

        size.x += unit;
        size.y += unit;
        size.z += unit;

        size -= position;
    }

    AABB quantized(real_t unit) const {
        AABB ret = this;
        ret.quantize(unit);
        return ret;
    }

    void mergeWith(in AABB aabb) {
        Vector3 beg_1, beg_2;
        Vector3 end_1, end_2;
        Vector3 min, max;

        beg_1 = position;
        beg_2 = aabb.position;
        end_1 = Vector3(size.x, size.y, size.z) + beg_1;
        end_2 = Vector3(aabb.size.x, aabb.size.y, aabb.size.z) + beg_2;

        min.x = (beg_1.x < beg_2.x) ? beg_1.x : beg_2.x;
        min.y = (beg_1.y < beg_2.y) ? beg_1.y : beg_2.y;
        min.z = (beg_1.z < beg_2.z) ? beg_1.z : beg_2.z;

        max.x = (end_1.x > end_2.x) ? end_1.x : end_2.x;
        max.y = (end_1.y > end_2.y) ? end_1.y : end_2.y;
        max.z = (end_1.z > end_2.z) ? end_1.z : end_2.z;

        position = min;
        size = max - min;
    }

    AABB intersection(in AABB aabb) const {
        Vector3 src_min = position;
        Vector3 src_max = position + size;
        Vector3 dst_min = aabb.position;
        Vector3 dst_max = aabb.position + aabb.size;

        Vector3 min, max;

        if (src_min.x > dst_max.x || src_max.x < dst_min.x)
            return AABB();
        else {
            min.x = (src_min.x > dst_min.x) ? src_min.x : dst_min.x;
            max.x = (src_max.x < dst_max.x) ? src_max.x : dst_max.x;
        }

        if (src_min.y > dst_max.y || src_max.y < dst_min.y)
            return AABB();
        else {
            min.y = (src_min.y > dst_min.y) ? src_min.y : dst_min.y;
            max.y = (src_max.y < dst_max.y) ? src_max.y : dst_max.y;
        }

        if (src_min.z > dst_max.z || src_max.z < dst_min.z)
            return AABB();
        else {
            min.z = (src_min.z > dst_min.z) ? src_min.z : dst_min.z;
            max.z = (src_max.z < dst_max.z) ? src_max.z : dst_max.z;
        }

        return AABB(min, max - min);
    }

    bool intersectsRay(in Vector3 from, in Vector3 dir, Vector3* clip = null, Vector3* normal = null) const {
        Vector3 c1, c2;
        Vector3 end = position + size;
        real_t near = -1e20;
        real_t far = 1e20;
        int axis = 0;

        for (int i = 0; i < 3; i++) {
            if (dir[i] == 0) {
                if ((from[i] < position[i]) || (from[i] > end[i])) {
                    return false;
                }
            } else { // ray not parallel to planes in this direction
                c1[i] = (position[i] - from[i]) / dir[i];
                c2[i] = (end[i] - from[i]) / dir[i];

                if (c1[i] > c2[i]) {
                    swap(c1, c2);
                }
                if (c1[i] > near) {
                    near = c1[i];
                    axis = i;
                }
                if (c2[i] < far) {
                    far = c2[i];
                }
                if ((near > far) || (far < 0)) {
                    return false;
                }
            }
        }
        if (clip)
            *clip = c1;
        if (normal) {
            *normal = Vector3();
            (*normal)[axis] = dir[axis] ? -1 : 1;
        }
        return true;
    }

    bool intersectsSegment(in Vector3 from, in Vector3 to, Vector3* clip = null, Vector3* normal = null) const {
        real_t min = 0, max = 1;
        int axis = 0;
        real_t sign = 0;

        for (int i = 0; i < 3; i++) {
            real_t seg_from = from[i];
            real_t seg_to = to[i];
            real_t box_begin = position[i];
            real_t box_end = box_begin + size[i];
            real_t cmin, cmax;
            real_t csign;

            if (seg_from < seg_to) {
                if (seg_from > box_end || seg_to < box_begin)
                    return false;
                real_t length = seg_to - seg_from;
                cmin = (seg_from < box_begin) ? ((box_begin - seg_from) / length) : 0;
                cmax = (seg_to > box_end) ? ((box_end - seg_from) / length) : 1;
                csign = -1.0;
            } else {
                if (seg_to > box_end || seg_from < box_begin)
                    return false;
                real_t length = seg_to - seg_from;
                cmin = (seg_from > box_end) ? (box_end - seg_from) / length : 0;
                cmax = (seg_to < box_begin) ? (box_begin - seg_from) / length : 1;
                csign = 1.0;
            }

            if (cmin > min) {
                min = cmin;
                axis = i;
                sign = csign;
            }
            if (cmax < max)
                max = cmax;
            if (max < min)
                return false;
        }

        Vector3 rel = to - from;

        if (normal) {
            Vector3 normal_;
            normal_[axis] = sign;
            *normal = normal_;
        }

        if (clip)
            *clip = from + rel * min;

        return true;
    }

    bool intersectsPlane(in Plane plane) const {
        Vector3[8] points = [
            Vector3(position.x, position.y, position.z),
            Vector3(position.x, position.y, position.z + size.z),
            Vector3(position.x, position.y + size.y, position.z),
            Vector3(position.x, position.y + size.y, position.z + size.z),
            Vector3(position.x + size.x, position.y, position.z),
            Vector3(position.x + size.x, position.y, position.z + size.z),
            Vector3(position.x + size.x, position.y + size.y, position.z),
            Vector3(position.x + size.x, position.y + size.y, position.z + size.z),
        ];

        bool over = false;
        bool under = false;

        for (int i = 0; i < 8; i++) {
            if (plane.distanceTo(points[i]) > 0)
                over = true;
            else
                under = true;
        }
        return under && over;
    }

    Vector3 getLongestAxis() const {
        Vector3 axis = Vector3(1, 0, 0);
        real_t max_size = size.x;

        if (size.y > max_size) {
            axis = Vector3(0, 1, 0);
            max_size = size.y;
        }

        if (size.z > max_size) {
            axis = Vector3(0, 0, 1);
            max_size = size.z;
        }

        return axis;
    }

    int getLongestAxisIndex() const {
        int axis = 0;
        real_t max_size = size.x;

        if (size.y > max_size) {
            axis = 1;
            max_size = size.y;
        }

        if (size.z > max_size) {
            axis = 2;
            max_size = size.z;
        }

        return axis;
    }

    Vector3 getShortestAxis() const {
        Vector3 axis = Vector3(1, 0, 0);
        real_t max_size = size.x;

        if (size.y < max_size) {
            axis = Vector3(0, 1, 0);
            max_size = size.y;
        }

        if (size.z < max_size) {
            axis = Vector3(0, 0, 1);
            max_size = size.z;
        }

        return axis;
    }

    int getShortestAxisIndex() const {
        int axis = 0;
        real_t max_size = size.x;

        if (size.y < max_size) {
            axis = 1;
            max_size = size.y;
        }

        if (size.z < max_size) {
            axis = 2;
            max_size = size.z;
        }

        return axis;
    }

    AABB merge(in AABB with_) const {
        AABB aabb = this;
        aabb.mergeWith(with_);
        return aabb;
    }

    AABB expand(in Vector3 vector) const {
        AABB aabb = this;
        aabb.expandTo(vector);
        return aabb;
    }

    AABB grow(real_t by) const {
        AABB aabb = this;
        aabb.growBy(by);
        return aabb;
    }

    void getEdge(int edge, out Vector3 from, out Vector3 to) const {
        ///ERR_FAIL_INDEX(edge,12);
        switch (edge) {
        case 0: {
                from = Vector3(position.x + size.x, position.y, position.z);
                to = Vector3(position.x, position.y, position.z);
            }
            break;
        case 1: {
                from = Vector3(position.x + size.x, position.y, position.z + size.z);
                to = Vector3(position.x + size.x, position.y, position.z);
            }
            break;
        case 2: {
                from = Vector3(position.x, position.y, position.z + size.z);
                to = Vector3(position.x + size.x, position.y, position.z + size.z);
            }
            break;
        case 3: {
                from = Vector3(position.x, position.y, position.z);
                to = Vector3(position.x, position.y, position.z + size.z);
            }
            break;
        case 4: {
                from = Vector3(position.x, position.y + size.y, position.z);
                to = Vector3(position.x + size.x, position.y + size.y, position.z);
            }
            break;
        case 5: {
                from = Vector3(position.x + size.x, position.y + size.y, position.z);
                to = Vector3(position.x + size.x, position.y + size.y, position.z + size.z);
            }
            break;
        case 6: {
                from = Vector3(position.x + size.x, position.y + size.y, position.z + size.z);
                to = Vector3(position.x, position.y + size.y, position.z + size.z);
            }
            break;
        case 7: {
                from = Vector3(position.x, position.y + size.y, position.z + size.z);
                to = Vector3(position.x, position.y + size.y, position.z);
            }
            break;
        case 8: {
                from = Vector3(position.x, position.y, position.z + size.z);
                to = Vector3(position.x, position.y + size.y, position.z + size.z);
            }
            break;
        case 9: {
                from = Vector3(position.x, position.y, position.z);
                to = Vector3(position.x, position.y + size.y, position.z);
            }
            break;
        case 10: {
                from = Vector3(position.x + size.x, position.y, position.z);
                to = Vector3(position.x + size.x, position.y + size.y, position.z);
            }
            break;
        case 11: {
                from = Vector3(position.x + size.x, position.y, position.z + size.z);
                to = Vector3(position.x + size.x, position.y + size.y, position.z + size.z);
            }
            break;
        default:
            assert(0);
        }
    }
}

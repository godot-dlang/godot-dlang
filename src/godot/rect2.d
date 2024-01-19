/**
2D Axis-aligned bounding box.

Copyright:
Copyright (c) 2007 Juan Linietsky, Ariel Manzur.
Copyright (c) 2014 Godot Engine contributors (cf. AUTHORS.md)
Copyright (c) 2017 Godot-D contributors
Copyright (c) 2022 Godot-DLang contributors

License: $(LINK2 https://opensource.org/licenses/MIT, MIT License)


*/
module godot.rect2;

import godot.abi.core;
import godot.abi.types;
import godot.vector2, godot.transform2d;

public import godot.globalenums : Side;  // enum Side, but tbh it is bad idea to rely on this

import std.algorithm.comparison;
import std.algorithm.mutation : swap;

/**
Rect2 consists of a position, a size, and several utility functions. It is typically used for fast overlap tests.
*/
struct Rect2 {
@nogc nothrow:

    Vector2 position;
    Vector2 size;

    deprecated("pos has been renamed to position, please use position instead")
    alias pos = position;

    alias end = getEnd;
    alias area = getArea;

    this(real_t x, real_t y, real_t width, real_t height) {
        position = Vector2(x, y);
        size = Vector2(width, height);
    }

    this(in Vector2 pos, in Vector2 size) {
        this.position = pos;
        this.size = size;
    }

    this(in Rect2i b) {
        position = b.position;
        size = b.size;
    }

    real_t getArea() const {
        return size.width * size.height;
    }

    Vector2 getCenter() const {
        return position + (size * 0.5f);
    }

    Vector2 end() const {
        return getEnd();
    }

    void end(in Vector2 p_end) {
        setEnd(p_end);
    }

    bool intersects(in Rect2 rect, in bool includeBorders = false) const {
        if (includeBorders) {
            if (position.x > (rect.position.x + rect.size.width))
				return false;
			if ((position.x + size.width) < rect.position.x)
				return false;
			if (position.y > (rect.position.y + rect.size.height))
				return false;
			if ((position.y + size.height) < rect.position.y)
				return false;
        } else {
            if (position.x >= (rect.position.x + rect.size.width))
                return false;
            if ((position.x + size.width) <= rect.position.x)
                return false;
            if (position.y >= (rect.position.y + rect.size.height))
                return false;
            if ((position.y + size.height) <= rect.position.y)
                return false;
        }

        return true;
    }

    bool encloses(in Rect2 rect) const {
        return (rect.position.x >= position.x) && (rect.position.y >= position.y) &&
            ((rect.position.x + rect.size.x) < (position.x + size.x)) &&
            ((rect.position.y + rect.size.y) < (position.y + size.y));
    }

    deprecated("use !hasArea()")
    bool hasNoArea() const {
        return !hasArea();
    }

    bool hasArea() const {
        return size.x > 0 && size.y > 0;
    }

	// Returns the instersection between two Rect2s or an empty Rect2 if there is no intersection
	Rect2 intersection(in Rect2 rect) const {
		Rect2 new_rect = rect;

		if (!intersects(new_rect)) {
			return Rect2();
		}

		new_rect.position.x = max(rect.position.x, position.x);
		new_rect.position.y = max(rect.position.y, position.y);

		Vector2 p_rect_end = rect.position + rect.size;
		Vector2 end = position + size;

		new_rect.size.x = min(p_rect_end.x, end.x) - new_rect.position.x;
		new_rect.size.y = min(p_rect_end.y, end.y) - new_rect.position.y;

		return new_rect;
	}

	Rect2 merge(in Rect2 rect) const { ///< return a merged rect
		Rect2 new_rect;

		new_rect.position.x = min(rect.position.x, position.x);
		new_rect.position.y = min(rect.position.y, position.y);

		new_rect.size.x = max(rect.position.x + rect.size.x, position.x + size.x);
		new_rect.size.y = max(rect.position.y + rect.size.y, position.y + size.y);

		new_rect.size = new_rect.size - new_rect.position; // Make relative again.

		return new_rect;
	}

    bool hasPoint(in Vector2 point) const {
        if (point.x < position.x)
            return false;
        if (point.y < position.y)
            return false;

        if (point.x >= (position.x + size.x))
            return false;
        if (point.y >= (position.y + size.y))
            return false;

        return true;
    }

    bool isEqualApprox(in Rect2 rect) {
        return position.isEqualApprox(rect.position) && size.isEqualApprox(rect.size);
    }



    Rect2 grow(real_t amount) const {
        Rect2 g = this;
        g.growBy(amount);
        return g;
    }

    void growBy(real_t amount) {
        position.x -= amount;
        position.y -= amount;
        size.width += amount * 2;
        size.height += amount * 2;
    }

    Rect2 growSide(Side side, real_t amount) const {
		Rect2 g = this;
		g = g.growIndividual((Side.sideLeft == side) ? amount : 0,
				(Side.sideTop == side) ? amount : 0,
				(Side.sideRight == side) ? amount : 0,
				(Side.sideBottom == side) ? amount : 0);
		return g;
	}

    Rect2 growIndividual(real_t left, real_t top, real_t right, real_t bottom) const {
		Rect2 g = this;
		g.position.x -= left;
		g.position.y -= top;
		g.size.width += left + right;
		g.size.height += top + bottom;

		return g;
	}

    Rect2 expand(in Vector2 vector) const {
        Rect2 r = this;
        r.expandTo(vector);
        return r;
    }

    void expandTo(in Vector2 vector) {
        Vector2 begin = position;
        Vector2 end = position + size;

        if (vector.x < begin.x)
            begin.x = vector.x;
        if (vector.y < begin.y)
            begin.y = vector.y;

        if (vector.x > end.x)
            end.x = vector.x;
        if (vector.y > end.y)
            end.y = vector.y;

        position = begin;
        size = end - begin;
    }

    Rect2 abs() const {
		return Rect2(Vector2(position.x + min(size.x, cast(real_t) 0), position.y + min(size.y, cast(real_t) 0)), size.abs());
	}

    Vector2 getSupport(in Vector2 normal) const {
		Vector2 half_extents = size * 0.5f;
		Vector2 ofs = position + half_extents;
		return Vector2(
					   (normal.x > 0) ? -half_extents.x : half_extents.x,
					   (normal.y > 0) ? -half_extents.y : half_extents.y
                ) + ofs;
	}

    bool intersectsFilledPolygon(in Vector2[] points) const {
		Vector2 center = getCenter();
		int side_plus = 0;
		int side_minus = 0;
		Vector2 end = position + size;

		int i_f = cast(int)(points.length - 1);
		for (int i = 0; i < points.length; i++) {
			const Vector2 a = points[i_f];
			const Vector2 b = points[i];
			i_f = i;

			Vector2 r = (b - a);
			float l = r.length();
			if (l == 0.0f) {
				continue;
			}

			// Check inside.
			Vector2 tg = r.orthogonal();
			float s = tg.dot(center) - tg.dot(a);
			if (s < 0.0f) {
				side_plus++;
			} else {
				side_minus++;
			}

			// Check ray box.
			r /= l;
			Vector2 ir = Vector2(1.0f / r.x, 1.0f / r.y);

			// lb is the corner of AABB with minimal coordinates - left bottom, rt is maximal corner
			// r.org is origin of ray
			Vector2 t13 = (position - a) * ir;
			Vector2 t24 = (end - a) * ir;

			float tmin = max(min(t13.x, t24.x), min(t13.y, t24.y));
			float tmax = min(max(t13.x, t24.x), max(t13.y, t24.y));

			// if tmax < 0, ray (line) is intersecting AABB, but the whole AABB is behind us
			if (tmax < 0 || tmin > tmax || tmin >= l) {
				continue;
			}

			return true;
		}

		if (side_plus * side_minus == 0) {
			return true; // All inside.
		} else {
			return false;
		}
	}

    real_t distanceTo(in Vector2 point) const {
        real_t dist = 0.0;
		bool inside = true;

		if (point.x < position.x) {
			real_t d = position.x - point.x;
			dist = d;
			inside = false;
		}
		if (point.y < position.y) {
			real_t d = position.y - point.y;
			dist = inside ? d : min(dist, d);
			inside = false;
		}
		if (point.x >= (position.x + size.x)) {
			real_t d = point.x - (position.x + size.x);
			dist = inside ? d : min(dist, d);
			inside = false;
		}
		if (point.y >= (position.y + size.y)) {
			real_t d = point.y - (position.y + size.y);
			dist = inside ? d : min(dist, d);
			inside = false;
		}

		if (inside) {
			return 0;
		} else {
			return dist;
		}
    }

    deprecated("use intersection()")
    alias clip = intersection;

    bool intersectsSegment(in Vector2 from, in Vector2 to, Vector2* pos = null, Vector2* normal = null) const {
        real_t min = 0, max = 1;
        int axis = 0;
        real_t sign = 0;

        for (int i = 0; i < 2; i++) {
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

        Vector2 rel = to - from;

        if (normal) {
            Vector2 normal_;
            normal_[axis] = sign;
            *normal = normal_;
        }

        if (pos)
            *pos = from + rel * min;

        return true;
    }

    bool intersectsTransformed(in Transform2D xform, in Rect2 rect) const {
        //SAT intersection between local and transformed rect2

        Vector2[4] xf_points = [
            xform.xform(rect.position),
            xform.xform(Vector2(rect.position.x + rect.size.x, rect.position.y)),
            xform.xform(Vector2(rect.position.x, rect.position.y + rect.size.y)),
            xform.xform(Vector2(rect.position.x + rect.size.x, rect.position.y + rect
                    .size.y)),
        ];

        real_t low_limit;

        //base rect2 first (faster)

        if (xf_points[0].y > position.y)
            goto next1;
        if (xf_points[1].y > position.y)
            goto next1;
        if (xf_points[2].y > position.y)
            goto next1;
        if (xf_points[3].y > position.y)
            goto next1;

        return false;

    next1:

        low_limit = position.y + size.y;

        if (xf_points[0].y < low_limit)
            goto next2;
        if (xf_points[1].y < low_limit)
            goto next2;
        if (xf_points[2].y < low_limit)
            goto next2;
        if (xf_points[3].y < low_limit)
            goto next2;

        return false;

    next2:

        if (xf_points[0].x > position.x)
            goto next3;
        if (xf_points[1].x > position.x)
            goto next3;
        if (xf_points[2].x > position.x)
            goto next3;
        if (xf_points[3].x > position.x)
            goto next3;

        return false;

    next3:

        low_limit = position.x + size.x;

        if (xf_points[0].x < low_limit)
            goto next4;
        if (xf_points[1].x < low_limit)
            goto next4;
        if (xf_points[2].x < low_limit)
            goto next4;
        if (xf_points[3].x < low_limit)
            goto next4;

        return false;

    next4:

        Vector2[4] xf_points2 = [
            position,
            Vector2(position.x + size.x, position.y),
            Vector2(position.x, position.y + size.y),
            Vector2(position.x + size.x, position.y + size.y),
        ];

        real_t maxa = xform.columns[0].dot(xf_points2[0]);
        real_t mina = maxa;

        real_t dp = xform.columns[0].dot(xf_points2[1]);
        maxa = max(dp, maxa);
        mina = min(dp, mina);

        dp = xform.columns[0].dot(xf_points2[2]);
        maxa = max(dp, maxa);
        mina = min(dp, mina);

        dp = xform.columns[0].dot(xf_points2[3]);
        maxa = max(dp, maxa);
        mina = min(dp, mina);

        real_t maxb = xform.columns[0].dot(xf_points[0]);
        real_t minb = maxb;

        dp = xform.columns[0].dot(xf_points[1]);
        maxb = max(dp, maxb);
        minb = min(dp, minb);

        dp = xform.columns[0].dot(xf_points[2]);
        maxb = max(dp, maxb);
        minb = min(dp, minb);

        dp = xform.columns[0].dot(xf_points[3]);
        maxb = max(dp, maxb);
        minb = min(dp, minb);

        if (mina > maxb)
            return false;
        if (minb > maxa)
            return false;

        maxa = xform.columns[1].dot(xf_points2[0]);
        mina = maxa;

        dp = xform.columns[1].dot(xf_points2[1]);
        maxa = max(dp, maxa);
        mina = min(dp, mina);

        dp = xform.columns[1].dot(xf_points2[2]);
        maxa = max(dp, maxa);
        mina = min(dp, mina);

        dp = xform.columns[1].dot(xf_points2[3]);
        maxa = max(dp, maxa);
        mina = min(dp, mina);

        maxb = xform.columns[1].dot(xf_points[0]);
        minb = maxb;

        dp = xform.columns[1].dot(xf_points[1]);
        maxb = max(dp, maxb);
        minb = min(dp, minb);

        dp = xform.columns[1].dot(xf_points[2]);
        maxb = max(dp, maxb);
        minb = min(dp, minb);

        dp = xform.columns[1].dot(xf_points[3]);
        maxb = max(dp, maxb);
        minb = min(dp, minb);

        if (mina > maxb)
            return false;
        if (minb > maxa)
            return false;

        return true;

    }

    void setEnd(in Vector2 end) {
        size = end - position;
    }

    Vector2 getEnd() const {
        return position + size;
    }

    Rect2i opCast(Rect2i)() const {
        return Rect2i(position, size);
    }

    bool opEquals(in Rect2 rect) const {
        return position == rect.position && size == rect.size;
    }

}

// ###### Rect2i ##############################################################

struct Rect2i {
@nogc nothrow:

    Vector2i position;
    Vector2i size;


    Vector2i end() const {
        return getEnd();
    }

    void end(in Vector2i p_end) {
        setEnd(p_end);
    }

    this(godot_int x, godot_int y, godot_int width, godot_int height) {
        this.position = Vector2i(x, y);
        this.size = Vector2i(width, height);
    }

    this(in Vector2i pos, in Vector2i size) {
        this.position = pos;
        this.size = size;
    }

    int getArea() const {
        return size.width * size.height;
    }

    Vector2i getCenter() const { 
        return position + (size / 2);
    }

    bool intersects(in Rect2i rect) const {
        if (position.x > (rect.position.x + rect.size.width)) {
            return false;
        }
        if ((position.x + size.width) < rect.position.x) {
            return false;
        }
        if (position.y > (rect.position.y + rect.size.height)) {
            return false;
        }
        if ((position.y + size.height) < rect.position.y) {
            return false;
        }

        return true;
    }

    bool encloses(in Rect2i rect) const {
        return (rect.position.x >= position.x) && (rect.position.y >= position.y) &&
            ((rect.position.x + rect.size.x) < (position.x + size.x)) &&
            ((rect.position.y + rect.size.y) < (position.y + size.y));
    }

    deprecated("Scheduled for removal after Q1 2024, use !hasArea() instead")
    bool hasNoArea() const { return hasArea(); }

    bool hasArea() const {
        return size.x > 0 && size.y > 0;
    }

    // Returns the instersection between two Rect2is or an empty Rect2i if there is no intersection
    Rect2i intersection(in Rect2i rect) const {
        Rect2i new_rect = rect;

        if (!intersects(new_rect)) {
            return Rect2i();
        }

        new_rect.position.x = max(rect.position.x, position.x);
        new_rect.position.y = max(rect.position.y, position.y);

        Vector2i p_rect_end = rect.position + rect.size;
        Vector2i end = position + size;

        new_rect.size.x = cast(godot_int)(min(p_rect_end.x, end.x) - new_rect.position.x);
        new_rect.size.y = cast(godot_int)(min(p_rect_end.y, end.y) - new_rect.position.y);

        return new_rect;
    }

    Rect2i merge(in Rect2i rect) const  ///< return a merged rect
    {

        Rect2i new_rect;

        new_rect.position.x = min(rect.position.x, position.x);
        new_rect.position.y = min(rect.position.y, position.y);

        new_rect.size.x = max(rect.position.x + rect.size.x, position.x + size.x);
        new_rect.size.y = max(rect.position.y + rect.size.y, position.y + size.y);

        new_rect.size = new_rect.size - new_rect.position; // make relative again

        return new_rect;
    }

    bool hasPoint(in Vector2i point) const {
        if (point.x < position.x) {
            return false;
        }
        if (point.y < position.y) {
            return false;
        }

        if (point.x >= (position.x + size.x)) {
            return false;
        }
        if (point.y >= (position.y + size.y)) {
            return false;
        }

        return true;
    }

    bool opEquals(in Rect2i rect) const {
        return position == rect.position && size == rect.size;
    }

    void growBy(int amount) {
        position.x -= amount;
        position.y -= amount;
        size.width += amount * 2;
        size.height += amount * 2;
    }

    Rect2i grow(int amount) const {
        Rect2i g = this;
        g.growBy(amount);
        return g;
    }

    Rect2i growSide(Side side, int amount) const {
        Rect2i g = this;
        g = g.growIndividual((Side.sideLeft == side) ? amount : 0,
                (Side.sideTop == side) ? amount : 0,
                (Side.sideRight == side) ? amount : 0,
                (Side.sideBottom == side) ? amount : 0);
        return g;
    }

    Rect2i growIndividual(int left, int top, int right, int bottom) const {
        Rect2i g = this;
        g.position.x -= left;
        g.position.y -= top;
        g.size.width += left + right;
        g.size.height += top + bottom;

        return g;
    }

    Rect2i expand(in Vector2i vector) const {
        Rect2i r = this;
        r.expandTo(vector);
        return r;
    }

    void expandTo(in Vector2i vector) {
        Vector2i begin = position;
        Vector2i end = position + size;

        if (vector.x < begin.x) {
            begin.x = vector.x;
        }
        if (vector.y < begin.y) {
            begin.y = vector.y;
        }

        if (vector.x > end.x) {
            end.x = vector.x;
        }
        if (vector.y > end.y) {
            end.y = vector.y;
        }

        position = begin;
        size = end - begin;
    }

    Rect2i abs() const {
        return Rect2i(Vector2i(position.x + min(size.x, 0), position.y + min(size.y, 0)), size.abs());
    }

    void setEnd(in Vector2i end) {
        size = end - position;
    }

    Vector2i getEnd() const {
        return position + size;
    }

    Rect2 opCast(Rect2)() const {
        return Rect2(cast(Vector2) position, cast(Vector2) size);
    }
}

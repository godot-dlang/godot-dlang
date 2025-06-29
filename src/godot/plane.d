/**
Plane in hessian form.

Copyright:
Copyright (c) 2007 Juan Linietsky, Ariel Manzur.
Copyright (c) 2014 Godot Engine contributors (cf. AUTHORS.md)
Copyright (c) 2017 Godot-D contributors
Copyright (c) 2022 Godot-DLang contributors

License: $(LINK2 https://opensource.org/licenses/MIT, MIT License)


*/
module godot.plane;

import godot.api.types;
import godot.vector3;
import godot.math;

public import godot.globalenums : ClockDirection;

/**
Plane represents a normalized plane equation. Basically, “normal” is the normal of the plane (a,b,c normalized), and “d” is the distance from the origin to the plane (in the direction of “normal”). “Over” or “Above” the plane is considered the side of the plane towards where the normal is pointing.
*/
struct Plane {
/*@nogc nothrow:*/

    Vector3 normal = Vector3(0, 0, 0);
    real_t d = 0;

    Vector3 center() const {
        return normal * d;
    }

    Plane opUnary(string op : "-")() const {
        return Plane(-normal, -d);
    }

    Vector3 project(in Vector3 point) const {
        return point - normal * distanceTo(point);
    }

    void normalize() {
        real_t l = normal.length();
        if (l == 0) {
            this = Plane(Vector3(0, 0, 0), 0);
            return;
        }
        normal /= l;
        d /= l;
    }

    Plane normalized() const {
        Plane p = this;
        p.normalize();
        return p;
    }

    Vector3 getAnyPerpendicularNormal() const {
        enum Vector3 p1 = Vector3(1, 0, 0);
        enum Vector3 p2 = Vector3(0, 1, 0);
        Vector3 p;

        if (fabs(normal.dot(p1)) > 0.99) // if too similar to p1
            p = p2; // use p2
        else
            p = p1; // use p1

        p -= normal * normal.dot(p);
        p.normalize();

        return p;
    }

    pragma(inline, true)
    bool isPointOver(in Vector3 point) const {
        return (normal.dot(point) > d);
    }

    pragma(inline, true)
    real_t distance_to(in Vector3 point) const {
        return (normal.dot(point) - d);
    }

    pragma(inline, true)
    bool hasPoint(in Vector3 point, real_t tolerance = UNIT_EPSILON) const {
        real_t dist = normal.dot(point) - d;
        dist = abs(dist);
        return (dist <= tolerance);
    }

    /* intersections */

    bool intersect3(in Plane plane1, in Plane plane2, Vector3* result = null) const {
        const Plane plane0 = this;
        Vector3 normal0 = plane0.normal;
        Vector3 normal1 = plane1.normal;
        Vector3 normal2 = plane2.normal;

        real_t denom = normal0.cross(normal1).dot(normal2);

        if (fabs(denom) <= CMP_EPSILON)
            return false;

        if (result) {
            *result = ( (normal1.cross(normal2) * plane0.d) +
                        (normal2.cross(normal0) * plane1.d) +
                        (normal0.cross(normal1) * plane2.d) ) 
                      / denom;
        }
        return true;
    }

    bool intersectsRay(in Vector3 from, in Vector3 dir, Vector3* intersection) const {
        Vector3 segment = dir;
        real_t den = normal.dot(segment);

        //printf("den is %i\n",den);
        if (fabs(den) <= CMP_EPSILON) {
            return false;
        }

        real_t dist = (normal.dot(from) - d) / den;
        //printf("dist is %i\n",dist);

        if (dist > CMP_EPSILON) { //this is a ray, before the emiting pos (p_from) doesnt exist
            return false;
        }

        dist = -dist;
        if (intersection)
            *intersection = from + segment * dist;

        return true;
    }

    bool intersectsSegment(in Vector3 begin, in Vector3 end, Vector3* intersection) const {
        Vector3 segment = begin - end;
        real_t den = normal.dot(segment);

        //printf("den is %i\n",den);
        if (fabs(den) <= CMP_EPSILON)
            return false;

        real_t dist = (normal.dot(begin) - d) / den;
        //printf("dist is %i\n",dist);

        if (dist < -CMP_EPSILON || dist > (1.0 + CMP_EPSILON))
            return false;

        dist = -dist;
        if (intersection)
            *intersection = begin + segment * dist;

        return true;
    }

    /* misc */

    deprecated("will be removed after Q1 2024, use isEqualApprox instead")
    alias isAlmostLike = isEqualApprox;

    bool isEqualApprox(in Plane plane) const {
	    return normal.isEqualApprox(plane.normal) && isClose(d, plane.d);
    }

    bool isEqualApproxAnySide(in Plane plane) const {
        return (normal.isEqualApprox(plane.normal) && isClose(d, plane.d)) 
            || (normal.isEqualApprox(-plane.normal) && isClose(d, -plane.d));
    }

    /+String opCast(T : String)() const
	{
		// return normal.operator String() + ", " + rtos(d);
		return String(); // @Todo
	}+/

    real_t distanceTo(in Vector3 point) const {
        return (normal.dot(point) - d);
    }

    this(in Vector3 normal, real_t d = 0.0) {
        this.normal = normal;
        this.d = d;
    }

    this(real_t a, real_t b, real_t c, real_t d) {
        this.normal = Vector3(a, b, c);
        this.d = d;
    }

    this(in Vector3 normal, in Vector3 point) {
        this.normal = normal;
        this.d = normal.dot(point);
    }

    this(in Vector3 point1, in Vector3 point2, in Vector3 point3, ClockDirection dir = ClockDirection.clockwise) {
        if (dir == ClockDirection.clockwise)
            normal = (point1 - point3).cross(point1 - point2);
        else
            normal = (point1 - point2).cross(point1 - point3);
        normal.normalize();
        d = normal.dot(point1);
    }

    Plane opUnary(string op : "-")() const { 
        return Plane(-normal, -d); 
    }

    bool opEquals(R)(in Plane other) const {
        return normal == other.normal && d == other.d;
    }
}

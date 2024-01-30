/// Contains godot math functions that is not tied to any other types
module godot.math;

public import godot.api.types : real_t;

import std.math;
import std.traits;

@nogc nothrow:


enum real_t CMP_EPSILON = 0.00001;
enum real_t CMP_EPSILON2 = (CMP_EPSILON * CMP_EPSILON);

enum real_t _PLANE_EQ_DOT_EPSILON = 0.999;
enum real_t _PLANE_EQ_D_EPSILON = 0.0001;

// tolerate some more floating point error normally
enum real_t UNIT_EPSILON = 0.001;


pragma(inline, true)
inout(T) fposmodp(T)(inout(T) x, inout(T) y) if (isFloatingPoint!T) {
    T value = fmod(x, y);
    if (value < 0) {
        value += y;
    }
    value += 0.0f;
    return value;
}

pragma(inline, true)
inout(T) fposmod(T)(inout(T) x, inout(T) y) if (isFloatingPoint!T) {
    T value = fmod(x, y);
    if (((value < 0) && (y > 0)) || ((value > 0) && (y < 0))) {
        value += y;
    }
    value += 0.0;
    return value;
}

pragma(inline, true)
T posmod(T)(T x, T y) if (isIntegral!T) {
    assert(y != 0, "Division by zero in posmod is undefined.");
    Unqual!T value = x % y;
    if (((value < 0) && (y > 0)) || ((value > 0) && (y < 0))) {
        value += y;
    }
    return value;
}

pragma(inline, true)
T lerp(T)(T from, T to, T weight) if (isFloatingPoint!T) { 
    return from + (to - from) * weight; 
}

pragma(inline, true)
T cubicInterpolate(T)(T from, T to, T pre, T post, T weight) if (isFloatingPoint!T) {
    return 0.5 *
            ((from * 2.0) +
                    (-pre + to) * weight +
                    (2.0 * pre - 5.0 * from + 4.0 * to - post) * (weight * weight) +
                    (-pre + 3.0 * from - 3.0 * to + post) * (weight * weight * weight));
}

pragma(inline, true)
static T cubicInterpolateInTime(T)(T from, T to, T pre, T post, T weight,
            T toT, T preT, T postT) if (isFloatingPoint!T) {
        /* Barry-Goldman method */
        T t = lerp(0.0, toT, weight);
        T a1 = lerp(pre, from, preT == 0 ? 0.0 : (t - preT) / -preT); // ignore linter warning, arguments intended
        T a2 = lerp(from, to, toT == 0 ? 0.5 : t / toT);
        T a3 = lerp(to, post, postT - toT == 0 ? 1.0 : (t - toT) / (postT - toT)); // ignore linter warning
        T b1 = lerp(a1, a2, toT - preT == 0 ? 0.0 : (t - preT) / (toT - preT));
        T b2 = lerp(a2, a3, postT == 0 ? 1.0 : t / postT);
        return lerp(b1, b2, toT == 0 ? 0.5 : t / toT);
    }

double deg2rad(double y) @nogc nothrow {
    return y * PI / 180.0;
}

double rad2deg(double y) @nogc nothrow {
    return y * 180.0 / PI;
}

double snapped(double value, double step) {
    if (step != 0) {
        value = floor(value / step + 0.5) * step;
    }
    return value;
}

T smoothstep(T)(T from, T to, T s) if (isFloatingPoint!T) {
    if (isClose(from, to)) {
        return from;
    }
    T s = clamp((s - from) / (to - from), 0.0, 1.0);
    return s * s * (3.0 - 2.0 * s);
}

T wrapf(T)(T value, T min, T max) if (isFloatingPoint!T) {
    float range = max - min;
    if (isClose(range, 0)) {
        return min;
    }
    float result = value - (range * floor((value - min) / range));
    if (isClose(result, max)) {
        return min;
    }
    return result;
}

double ease(double x, double c) {
    if (x < 0) {
        x = 0;
    } else if (x > 1.0) {
        x = 1.0;
    }
    if (c > 0) {
        if (c < 1.0) {
            return 1.0 - pow(1.0 - x, 1.0 / c);
        } else {
            return pow(x, c);
        }
    } else if (c < 0) {
        //inout ease
        if (x < 0.5) {
            return pow(x * 2.0, -c) * 0.5;
        } else {
            return (1.0 - pow(1.0 - (x - 0.5) * 2.0, -c)) * 0.5 + 0.5;
        }
    } else {
        return 0; // no ease (raw)
    }
}

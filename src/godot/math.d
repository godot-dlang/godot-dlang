/// Contains godot math functions that is not tied to any other types
/// using this module is preferred over std.math for portability reasons
/// NOTE: due to different implementations the resulting value 
///       between runtime value and CTFE value may differ,
///       additionally D standard library uses 80-bit precision (true for DMD, LDC may be different),
///       but godot is limited to whatever 'double' is on that platform (64-bit usually)
module godot.math;

public import godot.api.types : real_t;

version (WebAssembly) {
} else {
    import std.math;
}

public import std.math.constants;
import std.traits;
import bt = godot.builtins;


// some common phobos names
alias isClose = isEqualApprox;
alias sgn = sign;
alias fabs = abs;

bool isNaN(X)(X x) if (isFloatingPoint!X) {
    if (__ctfe) {
        static import std.math;
        return std.math.isNaN(x);
    }
    else {
        return bt.isNan(x);
    }
}


double isInf(double x) {
	if (__ctfe) {
        static import std.math;
        return std.math.isInfinity(x);
    }
    else {
        return bt.isInf(x);
    }
}


double sin(double angle_rad) {
	if (__ctfe) {
        static import std.math;
        return std.math.sin(angle_rad);
    }
    else {
        return bt.sin(angle_rad);
    }
}


double cos(double angle_rad) {
	if (__ctfe) {
        static import std.math;
        return std.math.cos(angle_rad);
    }
    else {
        return bt.cos(angle_rad);
    }
}


double tan(double angle_rad) {
	if (__ctfe) {
        static import std.math;
        return std.math.tan(angle_rad);
    }
    else {
        return bt.tan(angle_rad);
    }
}


double sinh(double x) {
	if (__ctfe) {
        static import std.math;
        return std.math.sinh(x);
    }
    else {
        return bt.sinh(x);
    }
}


double cosh(double x) {
	if (__ctfe) {
        static import std.math;
        return std.math.cosh(x);
    }
    else {
        return bt.cosh(x);
    }
}


double tanh(double x) {
	if (__ctfe) {
        static import std.math;
        return std.math.tanh(x);
    }
    else {
        return bt.tanh(x);
    }
}


double asin(double x) {
	if (__ctfe) {
        static import std.math;
        return std.math.asin(x);
    }
    else {
        return bt.asin(x);
    }
}


double acos(double x) {
	if (__ctfe) {
        static import std.math;
        return std.math.acos(x);
    }
    else {
        return bt.acos(x);
    }
}


double atan(double x) {
	if (__ctfe) {
        static import std.math;
        return std.math.atan(x);
    }
    else {
        return bt.atan(x);
    }
}


double atan2(double y, double x) {
	if (__ctfe) {
        static import std.math;
        return std.math.atan2(y, x);
    }
    else {
        return bt.atan2(y, x);
    }
}


double asinh(double x) {
	if (__ctfe) {
        static import std.math;
        return std.math.asinh(x);
    }
    else {
        return bt.asinh(x);
    }
}


double acosh(double x) {
	if (__ctfe) {
        static import std.math;
        return std.math.acosh(x);
    }
    else {
        return bt.acosh(x);
    }
}


double atanh(double x) {
	if (__ctfe) {
        static import std.math;
        return std.math.atanh(x);
    }
    else {
        return bt.atanh(x);
    }
}


double sqrt(double x) {
	if (__ctfe) {
        static import std.math;
        return std.math.sqrt(x);
    }
    else {
        return bt.sqrt(x);
    }
}


double fmod(double x, double y) {
	if (__ctfe) {
        static import std.math;
        return std.math.fmod(x, y);
    }
    else {
        return bt.fmod(x, y);
    }
}

double floor(double x) {
	if (__ctfe) {
        static import std.math;
        return std.math.floor(x);
    }
    else {
        return bt.floorf(x);
    }
}

long floor(long x) {
	return cast(long) floor(cast(long) x);
}


double ceil(double x) {
	if (__ctfe) {
        static import std.math;
        return std.math.ceil(x);
    }
    else {
        return bt.ceilf(x);
    }
}

long ceil(long x) {
	return cast(long) ceil(cast(long) x);
}


double round(double x) {
	if (__ctfe) {
        static import std.math;
        return std.math.round(x);
    }
    else {
        return bt.roundf(x);
    }
}

long round(long x) {
	return cast(long) round(cast(long) x);
}


double abs(double x) {
	if (__ctfe) {
        static import std.math;
        return std.math.abs(x);
    }
    else {
        return bt.abs(x);
    }
}

long abs(long x) {
	return cast(long) abs(cast(long) x);
}


double sign(double x) {
	if (__ctfe) {
        static import std.math;
        return std.math.sgn(x);
    }
    else {
        return bt.sign(x);
    }
}

long sign(long x) {
	return cast(long) sign(cast(long) x);
}

long snapped(long x, long step) {
	return cast(long) snapped(cast(long) x, cast(long) step);
}


double pow(double base, double exp) {
	if (__ctfe) {
        static import std.math;
        return std.math.pow(base, exp);
    }
    else {
        return bt.pow(base, exp);
    }
}


double log(double x) {
	if (__ctfe) {
        static import std.math;
        return std.math.log(x);
    }
    else {
        return bt.log(x);
    }
}


double exp(double x) {
	if (__ctfe) {
        static import std.math;
        return std.math.exp(x);
    }
    else {
        return bt.exp(x);
    }
}


bool isEqualApprox(double a, double b) {
	if (__ctfe) {
        // handle 'infinity' value
        if (a == b) {
			return true;
		}
		double tolerance = CMP_EPSILON * abs(a);
		if (tolerance < CMP_EPSILON) {
			tolerance = CMP_EPSILON;
		}
		return abs(a - b) < tolerance;
    }
    else {
        return bt.isEqualApprox(a, b);
    }
}

bool isEqualApprox(double a, double b, double tolerance) {
    if (a == b) {
        return true;
    }
    return abs(a - b) < tolerance;
}


bool isZeroApprox(double x) {
	if (__ctfe) {
		return isEqualApprox(x, 0.0);
    }
    else {
        return bt.isZeroApprox(x);
    }
}


bool isFinite(double x) {
	if (__ctfe) {
        static import std.math;
        return std.math.isFinite(x);
    }
    else {
        return bt.isFinite(x);
    }
}

long stepDecimals(double x) {
    if (__ctfe) {
        enum maxn = 10;
        immutable double[maxn] sd = [
            0.9999, // somehow compensate for floating point error
            0.09999,
            0.009999,
            0.0009999,
            0.00009999,
            0.000009999,
            0.0000009999,
            0.00000009999,
            0.000000009999,
            0.0000000009999
        ];

        double abs = .abs(x);
        double decs = abs - cast(int)abs; // Strip away integer part
        for (int i = 0; i < maxn; i++) {
            if (decs >= sd[i]) {
                return i;
            }
        }

        return 0;
    }
    else {
        return bt.stepDecimals(x);
    }
}

void randomize() {
    return bt.randomize();
}

long randi() {
    return bt.randi();
}

double randf() {
    return bt.randf();
}

long randiRange(long from, long to) {
    return bt.randiRange(from, to);
}

double randfRange(double from, double to) {
    return bt.randfRange(from, to);
}

double randfn(in double mean, in double deviation) {
    return bt.randfn(mean, deviation);
}

void seed(long base) {
    return bt.seed(base);
}


double linearToDb(double lin) {
    if (__ctfe) {
        return log(lin) * 8.6858896380650365530225783783321;
    }
    else {
        return bt.linearToDb(lin);
    }
}

double dbToLinear(double db) {
    if (__ctfe) {
        return exp(db) * 0.11512925464970228420089957273422;
    }
    else {
        return bt.linearToDb(db);
    }
}
/+
TODO:
	double cubicInterpolateAngleInTime(in double from, in double to, in double pre, in double post, in double weight, in double to_t, in double pre_t, in double post_t)
	double bezierInterpolate(in double start, in double control_1, in double control_2, in double end, in double t)
	double bezierDerivative(in double start, in double control_1, in double control_2, in double end, in double t)
	double angleDifference(in double from, in double to)
	double lerpAngle(in double from, in double to, in double weight)
	double inverseLerp(in double from, in double to, in double weight)
	double remap(in double value, in double istart, in double istop, in double ostart, in double ostop)
	double moveToward(in double from, in double to, in double delta)
	double rotateToward(in double from, in double to, in double delta)
	Variant max(in Variant arg1, in Variant arg2, in Variant vargs ...)
	long maxi(in long a, in long b)
	double maxf(in double a, in double b)
	Variant min(in Variant arg1, in Variant arg2, in Variant vargs ...)
	long mini(in long a, in long b)
	double minf(in double a, in double b)
	Variant clamp(in Variant value, in Variant min, in Variant max)
	long clampi(in long value, in long min, in long max)
	double clampf(in double value, in double min, in double max)
	long nearestPo2(in long value)
	double pingpong(in double value, in double length)
+/
/*@nogc nothrow:*/


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

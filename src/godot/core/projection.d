/**
2D Transformation. 3x2 matrix.

Copyright:
Copyright (c) 2007-2022 Juan Linietsky, Ariel Manzur.
Copyright (c) 2014-2022 Godot Engine contributors (cf. AUTHORS.md)
Copyright (c) 2017-2018 Godot-D contributors
Copyright (c) 2022-2022 Godot-DLang contributors

License: $(LINK2 https://opensource.org/licenses/MIT, MIT License)


*/
module godot.core.projection;

import godot.core.defs;
import godot.core.vector4;
import godot.core.vector2;
import godot.core.vector3;
import godot.core.rect2;
import godot.core.plane;
import godot.core.aabb;
import godot.core.array;
import godot.core.transform;
import godot.c.core;

import std.math;
import std.algorithm.comparison;
import std.algorithm.mutation : swap;


double deg2rad(double p_y) @nogc nothrow {
	return p_y * PI / 180.0;
}

double rad2deg(double p_y) @nogc nothrow {
	return p_y * 180.0 / PI;
}

/**
Represents projection transformation. It is similar to a 4x4 matrix.
*/
struct Projection
{
	// Array prohibits this, comment for now
	//@nogc nothrow:

	enum Planes 
	{
		near,
		far,
		left,
		top,
		right,
		bottom
	}
	// Convenience aliases
	alias PLANE_NEAR = Planes.near;
	alias PLANE_FAR = Planes.far;
	alias PLANE_LEFT = Planes.left;
	alias PLANE_TOP = Planes.top;
	alias PLANE_RIGHT = Planes.right;
	alias PLANE_BOTTOM = Planes.bottom;
	
	union
	{
		Vector4[4] matrix = [ Vector4(1,0,0,0), Vector4(0,1,0,0), Vector4(0,0,1,0), Vector4(0,0,0,1) ];
		struct
		{
			Vector4 x_axis; /// 
			Vector4 y_axis; /// 
			Vector4 z_axis; /// 
			Vector4 w_axis; /// 
		}
		real_t[16] elements;
	}
	private alias m = elements;
	
	this(Vector4 x, Vector4 y, Vector4 z, Vector4 w)
	{
		matrix[0] = x;
		matrix[1] = y;
		matrix[2] = z;
		matrix[3] = w;
	}

	this(real_t[16] mat)
	{
		elements = mat;
	}

	this(in Transform3D p_transform)
	{
		alias tr = p_transform;

		m[0] = tr.basis.rows[0][0];
		m[1] = tr.basis.rows[1][0];
		m[2] = tr.basis.rows[2][0];
		m[3] = 0.0;
		m[4] = tr.basis.rows[0][1];
		m[5] = tr.basis.rows[1][1];
		m[6] = tr.basis.rows[2][1];
		m[7] = 0.0;
		m[8] = tr.basis.rows[0][2];
		m[9] = tr.basis.rows[1][2];
		m[10] = tr.basis.rows[2][2];
		m[11] = 0.0;
		m[12] = tr.origin.x;
		m[13] = tr.origin.y;
		m[14] = tr.origin.z;
		m[15] = 1.0;
	}
	
	const(Vector4) opIndex(int axis) const { return matrix[axis]; }
	ref Vector4 opIndex(int axis) return { return matrix[axis]; }
	
	float determinant() const
	{
		return matrix[0][3] * matrix[1][2] * matrix[2][1] * matrix[3][0] - matrix[0][2] * matrix[1][3] * matrix[2][1] * matrix[3][0] -
		   matrix[0][3] * matrix[1][1] * matrix[2][2] * matrix[3][0] + matrix[0][1] * matrix[1][3] * matrix[2][2] * matrix[3][0] +
		   matrix[0][2] * matrix[1][1] * matrix[2][3] * matrix[3][0] - matrix[0][1] * matrix[1][2] * matrix[2][3] * matrix[3][0] -
		   matrix[0][3] * matrix[1][2] * matrix[2][0] * matrix[3][1] + matrix[0][2] * matrix[1][3] * matrix[2][0] * matrix[3][1] +
		   matrix[0][3] * matrix[1][0] * matrix[2][2] * matrix[3][1] - matrix[0][0] * matrix[1][3] * matrix[2][2] * matrix[3][1] -
		   matrix[0][2] * matrix[1][0] * matrix[2][3] * matrix[3][1] + matrix[0][0] * matrix[1][2] * matrix[2][3] * matrix[3][1] +
		   matrix[0][3] * matrix[1][1] * matrix[2][0] * matrix[3][2] - matrix[0][1] * matrix[1][3] * matrix[2][0] * matrix[3][2] -
		   matrix[0][3] * matrix[1][0] * matrix[2][1] * matrix[3][2] + matrix[0][0] * matrix[1][3] * matrix[2][1] * matrix[3][2] +
		   matrix[0][1] * matrix[1][0] * matrix[2][3] * matrix[3][2] - matrix[0][0] * matrix[1][1] * matrix[2][3] * matrix[3][2] -
		   matrix[0][2] * matrix[1][1] * matrix[2][0] * matrix[3][3] + matrix[0][1] * matrix[1][2] * matrix[2][0] * matrix[3][3] +
		   matrix[0][2] * matrix[1][0] * matrix[2][1] * matrix[3][3] - matrix[0][0] * matrix[1][2] * matrix[2][1] * matrix[3][3] -
		   matrix[0][1] * matrix[1][0] * matrix[2][2] * matrix[3][3] + matrix[0][0] * matrix[1][1] * matrix[2][2] * matrix[3][3];
	}

	void setIdentity()
	{
		matrix = [ Vector4(1,0,0,0), Vector4(0,1,0,0), Vector4(0,0,1,0), Vector4(0,0,0,1) ];
	}

	void setZero()
	{
		elements[] = 0;
	}

	void setLightBias()
	{
		m[0] = 0.5;
		m[1] = 0.0;
		m[2] = 0.0;
		m[3] = 0.0;
		m[4] = 0.0;
		m[5] = 0.5;
		m[6] = 0.0;
		m[7] = 0.0;
		m[8] = 0.0;
		m[9] = 0.0;
		m[10] = 0.5;
		m[11] = 0.0;
		m[12] = 0.5;
		m[13] = 0.5;
		m[14] = 0.5;
		m[15] = 1.0;
	}

	void setDepthCorrection(bool p_flip_y = true)
	{
		m[0] = 1;
		m[1] = 0.0;
		m[2] = 0.0;
		m[3] = 0.0;
		m[4] = 0.0;
		m[5] = p_flip_y ? -1 : 1;
		m[6] = 0.0;
		m[7] = 0.0;
		m[8] = 0.0;
		m[9] = 0.0;
		m[10] = 0.5;
		m[11] = 0.0;
		m[12] = 0.0;
		m[13] = 0.0;
		m[14] = 0.5;
		m[15] = 1.0;
	}

	
	void setLightAtlasRect(in Rect2 p_rect)
	{
		m[0] = p_rect.size.width;
		m[1] = 0.0;
		m[2] = 0.0;
		m[3] = 0.0;
		m[4] = 0.0;
		m[5] = p_rect.size.height;
		m[6] = 0.0;
		m[7] = 0.0;
		m[8] = 0.0;
		m[9] = 0.0;
		m[10] = 1.0;
		m[11] = 0.0;
		m[12] = p_rect.position.x;
		m[13] = p_rect.position.y;
		m[14] = 0.0;
		m[15] = 1.0;
	}

	void setPerspective(real_t p_fovy_degrees, real_t p_aspect, real_t p_z_near, real_t p_z_far, bool p_flip_fov = false)
	{
		if (p_flip_fov) {
			p_fovy_degrees = getFovY(p_fovy_degrees, 1.0 / p_aspect);
		}

		real_t sine, cotangent, deltaZ;
		real_t radians = deg2rad(p_fovy_degrees / 2.0);

		deltaZ = p_z_far - p_z_near;
		sine = sin(radians);

		if ((deltaZ == 0) || (sine == 0) || (p_aspect == 0)) {
			return;
		}
		cotangent = cos(radians) / sine;

		setIdentity();

		matrix[0][0] = cotangent / p_aspect;
		matrix[1][1] = cotangent;
		matrix[2][2] = -(p_z_far + p_z_near) / deltaZ;
		matrix[2][3] = -1;
		matrix[3][2] = -2 * p_z_near * p_z_far / deltaZ;
		matrix[3][3] = 0;
	}

	void setPerspective(real_t p_fovy_degrees, real_t p_aspect, real_t p_z_near, real_t p_z_far, bool p_flip_fov, int p_eye, real_t p_intraocular_dist, real_t p_convergence_dist)
	{
		if (p_flip_fov) {
			p_fovy_degrees = getFovY(p_fovy_degrees, 1.0 / p_aspect);
		}

		real_t left, right, modeltranslation, ymax, xmax, frustumshift;

		ymax = p_z_near * tan(deg2rad(p_fovy_degrees / 2.0));
		xmax = ymax * p_aspect;
		frustumshift = (p_intraocular_dist / 2.0) * p_z_near / p_convergence_dist;

		switch (p_eye) {
			case 1: { // left eye
				left = -xmax + frustumshift;
				right = xmax + frustumshift;
				modeltranslation = p_intraocular_dist / 2.0;
			} break;
			case 2: { // right eye
				left = -xmax - frustumshift;
				right = xmax - frustumshift;
				modeltranslation = -p_intraocular_dist / 2.0;
			} break;
			default: { // mono, should give the same result as set_perspective(p_fovy_degrees,p_aspect,p_z_near,p_z_far,p_flip_fov)
				left = -xmax;
				right = xmax;
				modeltranslation = 0.0;
			} break;
		}

		setFrustum(left, right, -ymax, ymax, p_z_near, p_z_far);

		// translate matrix by (modeltranslation, 0.0, 0.0)
		Projection cm;
		cm.setIdentity();
		cm.matrix[3][0] = modeltranslation;
		this = (this * cm);
	}

	void setForHMD(int p_eye, real_t p_aspect, real_t p_intraocular_dist, real_t p_display_width, real_t p_display_to_lens, real_t p_oversample, real_t p_z_near, real_t p_z_far)
	{
		// we first calculate our base frustum on our values without taking our lens magnification into account.
		real_t f1 = (p_intraocular_dist * 0.5) / p_display_to_lens;
		real_t f2 = ((p_display_width - p_intraocular_dist) * 0.5) / p_display_to_lens;
		real_t f3 = (p_display_width / 4.0) / p_display_to_lens;

		// now we apply our oversample factor to increase our FOV. how much we oversample is always a balance we strike between performance and how much
		// we're willing to sacrifice in FOV.
		real_t add = ((f1 + f2) * (p_oversample - 1.0)) / 2.0;
		f1 += add;
		f2 += add;
		f3 *= p_oversample;

		// always apply KEEP_WIDTH aspect ratio
		f3 /= p_aspect;

		switch (p_eye) {
			case 1: { // left eye
				setFrustum(-f2 * p_z_near, f1 * p_z_near, -f3 * p_z_near, f3 * p_z_near, p_z_near, p_z_far);
			} break;
			case 2: { // right eye
				setFrustum(-f1 * p_z_near, f2 * p_z_near, -f3 * p_z_near, f3 * p_z_near, p_z_near, p_z_far);
			} break;
			default: { // mono, does not apply here!
			} break;
		}
	}

	void setOrthogonal(real_t p_left, real_t p_right, real_t p_bottom, real_t p_top, real_t p_znear, real_t p_zfar)
	{
		setIdentity();

		matrix[0][0] = 2.0 / (p_right - p_left);
		matrix[3][0] = -((p_right + p_left) / (p_right - p_left));
		matrix[1][1] = 2.0 / (p_top - p_bottom);
		matrix[3][1] = -((p_top + p_bottom) / (p_top - p_bottom));
		matrix[2][2] = -2.0 / (p_zfar - p_znear);
		matrix[3][2] = -((p_zfar + p_znear) / (p_zfar - p_znear));
		matrix[3][3] = 1.0;
	}

	void setOrthogonal(real_t p_size, real_t p_aspect, real_t p_znear, real_t p_zfar, bool p_flip_fov = false)
	{
		if (!p_flip_fov) {
			p_size *= p_aspect;
		}

		setOrthogonal(-p_size / 2, +p_size / 2, -p_size / p_aspect / 2, +p_size / p_aspect / 2, p_znear, p_zfar);
	}

	void setFrustum(real_t p_left, real_t p_right, real_t p_bottom, real_t p_top, real_t p_near, real_t p_far)
	{
		assert(p_right <= p_left);
		assert(p_top <= p_bottom);
		assert(p_far <= p_near);

		real_t x = 2 * p_near / (p_right - p_left);
		real_t y = 2 * p_near / (p_top - p_bottom);

		real_t a = (p_right + p_left) / (p_right - p_left);
		real_t b = (p_top + p_bottom) / (p_top - p_bottom);
		real_t c = -(p_far + p_near) / (p_far - p_near);
		real_t d = -2 * p_far * p_near / (p_far - p_near);

		m[0] = x;
		m[1] = 0;
		m[2] = 0;
		m[3] = 0;
		m[4] = 0;
		m[5] = y;
		m[6] = 0;
		m[7] = 0;
		m[8] = a;
		m[9] = b;
		m[10] = c;
		m[11] = -1;
		m[12] = 0;
		m[13] = 0;
		m[14] = d;
		m[15] = 0;
	}

	void setFrustum(real_t p_size, real_t p_aspect, Vector2 p_offset, real_t p_near, real_t p_far, bool p_flip_fov = false)
	{
		if (!p_flip_fov) {
			p_size *= p_aspect;
		}

		setFrustum(-p_size / 2 + p_offset.x, +p_size / 2 + p_offset.x, -p_size / p_aspect / 2 + p_offset.y, +p_size / p_aspect / 2 + p_offset.y, p_near, p_far);
	}

	void adjustPerspectiveZNear(real_t p_new_znear)
	{
		real_t zfar = getZFar();
		real_t znear = p_new_znear;

		real_t deltaZ = zfar - znear;
		matrix[2][2] = -(zfar + znear) / deltaZ;
		matrix[3][2] = -2 * znear * zfar / deltaZ;
	}

	static Projection createDepthCorrection(bool p_flip_y)
	{
		Projection proj;
		proj.setDepthCorrection(p_flip_y);
		return proj;
	}

	static Projection createLightAtlasRect(in Rect2 p_rect)
	{
		Projection proj;
		proj.setLightAtlasRect(p_rect);
		return proj;
	}

	static Projection createPerspective(real_t p_fovy_degrees, real_t p_aspect, real_t p_z_near, real_t p_z_far, bool p_flip_fov = false)
	{
		Projection proj;
		proj.setPerspective(p_fovy_degrees, p_aspect, p_z_near, p_z_far, p_flip_fov);
		return proj;
	}

	static Projection createPerspectiveHMD(real_t p_fovy_degrees, real_t p_aspect, real_t p_z_near, real_t p_z_far, bool p_flip_fov, int p_eye, real_t p_intraocular_dist, real_t p_convergence_dist)
	{
		Projection proj;
		proj.setPerspective(p_fovy_degrees, p_aspect, p_z_near, p_z_far, p_flip_fov, p_eye, p_intraocular_dist, p_convergence_dist);
		return proj;
	}

	static Projection createForHMD(int p_eye, real_t p_aspect, real_t p_intraocular_dist, real_t p_display_width, real_t p_display_to_lens, real_t p_oversample, real_t p_z_near, real_t p_z_far)
	{
		Projection proj;
		proj.setForHMD(p_eye, p_aspect, p_intraocular_dist, p_display_width, p_display_to_lens, p_oversample, p_z_near, p_z_far);
		return proj;
	}

	static Projection createOrthogonal(real_t p_left, real_t p_right, real_t p_bottom, real_t p_top, real_t p_znear, real_t p_zfar)
	{
		Projection proj;
		proj.setOrthogonal(p_left, p_right, p_bottom, p_top, p_zfar, p_zfar);
		return proj;
	}

	static Projection createOrthogonalAspect(real_t p_size, real_t p_aspect, real_t p_znear, real_t p_zfar, bool p_flip_fov = false)
	{
		Projection proj;
		proj.setOrthogonal(p_size, p_aspect, p_znear, p_zfar, p_flip_fov);
		return proj;
	}

	static Projection createFrustum(real_t p_left, real_t p_right, real_t p_bottom, real_t p_top, real_t p_near, real_t p_far)
	{
		Projection proj;
		proj.setFrustum(p_left, p_right, p_bottom, p_top, p_near, p_far);
		return proj;
	}

	static Projection createFrustumAspect(real_t p_size, real_t p_aspect, Vector2 p_offset, real_t p_near, real_t p_far, bool p_flip_fov = false)
	{
		Projection proj;
		proj.setFrustum(p_size, p_aspect, p_offset, p_near, p_far, p_flip_fov);
		return proj;
	}

	static Projection createFitAABB(in AABB p_aabb)
	{
		Projection proj;
		proj.scaleTranslateToFit(p_aabb);
		return proj;
	}

	Projection perspective_znear_adjusted(real_t p_new_znear) const
	{
		Projection proj = this;
		proj.adjustPerspectiveZNear(p_new_znear);
		return proj;
	}

	Plane getProjectionPlane(Planes p_plane) const
	{
		const real_t* matrix = m.ptr;

		switch (p_plane) {
			case Planes.near: {
				Plane new_plane = Plane(matrix[3] + matrix[2],
						matrix[7] + matrix[6],
						matrix[11] + matrix[10],
						matrix[15] + matrix[14]);

				new_plane.normal = -new_plane.normal;
				new_plane.normalize();
				return new_plane;
			}
			case Planes.far: {
				Plane new_plane = Plane(matrix[3] - matrix[2],
						matrix[7] - matrix[6],
						matrix[11] - matrix[10],
						matrix[15] - matrix[14]);

				new_plane.normal = -new_plane.normal;
				new_plane.normalize();
				return new_plane;
			}
			case Planes.left: {
				Plane new_plane = Plane(matrix[3] + matrix[0],
						matrix[7] + matrix[4],
						matrix[11] + matrix[8],
						matrix[15] + matrix[12]);

				new_plane.normal = -new_plane.normal;
				new_plane.normalize();
				return new_plane;
			}
			case Planes.top: {
				Plane new_plane = Plane(matrix[3] - matrix[1],
						matrix[7] - matrix[5],
						matrix[11] - matrix[9],
						matrix[15] - matrix[13]);

				new_plane.normal = -new_plane.normal;
				new_plane.normalize();
				return new_plane;
			}
			case Planes.right: {
				Plane new_plane = Plane(matrix[3] - matrix[0],
						matrix[7] - matrix[4],
						matrix[11] - matrix[8],
						matrix[15] - matrix[12]);

				new_plane.normal = -new_plane.normal;
				new_plane.normalize();
				return new_plane;
			}
			case Planes.bottom: {
				Plane new_plane = Plane(matrix[3] + matrix[1],
						matrix[7] + matrix[5],
						matrix[11] + matrix[9],
						matrix[15] + matrix[13]);

				new_plane.normal = -new_plane.normal;
				new_plane.normalize();
				return new_plane;
			}
			default:
				break;
		}

		return Plane();
	}

	Projection flippedY() const
	{
		Projection proj = this;
		proj.flipY();
		return proj;
	}

	Projection jitter_offseted(in Vector2 p_offset) const
	{
		Projection proj = this;
		proj.addJitterOffset(p_offset);
		return proj;
	}

	static real_t getFovY(real_t p_fovx, real_t p_aspect) 
	{
		return rad2deg(atan(p_aspect * tan(deg2rad(p_fovx) * 0.5)) * 2.0);
	}

	real_t getZFar() const
	{
		const real_t* matrix = m.ptr;
		Plane new_plane = Plane(matrix[3] - matrix[2],
				matrix[7] - matrix[6],
				matrix[11] - matrix[10],
				matrix[15] - matrix[14]);

		new_plane.normal = -new_plane.normal;
		new_plane.normalize();

		return new_plane.d;
	}

	real_t getZNear() const
	{
		const real_t* matrix = m.ptr;
		Plane new_plane = Plane(matrix[3] + matrix[2],
				matrix[7] + matrix[6],
				matrix[11] + matrix[10],
				-matrix[15] - matrix[14]);

		new_plane.normalize();
		return new_plane.d;
	}

	real_t getAspect() const
	{
		Vector2 vp_he = getViewportHalfExtents();
		return vp_he.x / vp_he.y;
	}

	real_t getFov() const
	{
		const real_t* matrix = m.ptr;

		Plane right_plane = Plane(matrix[3] - matrix[0],
				matrix[7] - matrix[4],
				matrix[11] - matrix[8],
				-matrix[15] + matrix[12]);
		right_plane.normalize();

		if ((matrix[8] == 0) && (matrix[9] == 0)) {
			return rad2deg(acos(abs(right_plane.normal.x))) * 2.0;
		} else {
			// our frustum is asymmetrical need to calculate the left planes angle separately..
			Plane left_plane = Plane(matrix[3] + matrix[0],
					matrix[7] + matrix[4],
					matrix[11] + matrix[8],
					matrix[15] + matrix[12]);
			left_plane.normalize();

			return rad2deg(acos(abs(left_plane.normal.x))) + rad2deg(acos(abs(right_plane.normal.x)));
		}
	}

	bool isOrthogonal() const
	{
		return matrix[3][3] == 1.0;
	}

	Array getProjectionPlanes(in Transform3D p_transform) const
	{
		/** Fast Plane Extraction from combined modelview/projection matrices.
		* References:
		* https://web.archive.org/web/20011221205252/https://www.markmorley.com/opengl/frustumculling.html
		* https://web.archive.org/web/20061020020112/https://www2.ravensoft.com/users/ggribb/plane%20extraction.pdf
		*/

		Array planes;

		const real_t* matrix = m.ptr;

		Plane new_plane;

		///////--- Near Plane ---///////
		new_plane = Plane(matrix[3] + matrix[2],
				matrix[7] + matrix[6],
				matrix[11] + matrix[10],
				matrix[15] + matrix[14]);

		new_plane.normal = -new_plane.normal;
		new_plane.normalize();

		planes.pushBack(p_transform.xform(new_plane));

		///////--- Far Plane ---///////
		new_plane = Plane(matrix[3] - matrix[2],
				matrix[7] - matrix[6],
				matrix[11] - matrix[10],
				matrix[15] - matrix[14]);

		new_plane.normal = -new_plane.normal;
		new_plane.normalize();

		planes.pushBack(p_transform.xform(new_plane));

		///////--- Left Plane ---///////
		new_plane = Plane(matrix[3] + matrix[0],
				matrix[7] + matrix[4],
				matrix[11] + matrix[8],
				matrix[15] + matrix[12]);

		new_plane.normal = -new_plane.normal;
		new_plane.normalize();

		planes.pushBack(p_transform.xform(new_plane));

		///////--- Top Plane ---///////
		new_plane = Plane(matrix[3] - matrix[1],
				matrix[7] - matrix[5],
				matrix[11] - matrix[9],
				matrix[15] - matrix[13]);

		new_plane.normal = -new_plane.normal;
		new_plane.normalize();

		planes.pushBack(p_transform.xform(new_plane));

		///////--- Right Plane ---///////
		new_plane = Plane(matrix[3] - matrix[0],
				matrix[7] - matrix[4],
				matrix[11] - matrix[8],
				matrix[15] - matrix[12]);

		new_plane.normal = -new_plane.normal;
		new_plane.normalize();

		planes.pushBack(p_transform.xform(new_plane));

		///////--- Bottom Plane ---///////
		new_plane = Plane(matrix[3] + matrix[1],
				matrix[7] + matrix[5],
				matrix[11] + matrix[9],
				matrix[15] + matrix[13]);

		new_plane.normal = -new_plane.normal;
		new_plane.normalize();

		planes.pushBack(p_transform.xform(new_plane));

		return planes;
	}

	bool getEndpoints(in Transform3D p_transform, Vector3 *p_8points) const
	{
		import std.array : staticArray;
		Array planes = getProjectionPlanes(Transform3D());
		const Planes[3][8] intersections =  [
			[ PLANE_FAR, PLANE_LEFT, PLANE_TOP ] ,
			[ PLANE_FAR, PLANE_LEFT, PLANE_BOTTOM ] ,
			[ PLANE_FAR, PLANE_RIGHT, PLANE_TOP ] ,
			[ PLANE_FAR, PLANE_RIGHT, PLANE_BOTTOM ] ,
			[ PLANE_NEAR, PLANE_LEFT, PLANE_TOP ] ,
			[ PLANE_NEAR, PLANE_LEFT, PLANE_BOTTOM ] ,
			[ PLANE_NEAR, PLANE_RIGHT, PLANE_TOP ] ,
			[ PLANE_NEAR, PLANE_RIGHT, PLANE_BOTTOM ] ,
		];

		for (int i = 0; i < 8; i++) {
			Vector3 point;
			bool res = (planes[intersections[i][0]].as!Plane).intersect3(
				planes[intersections[i][1]].as!Plane, 
				planes[intersections[i][2]].as!Plane, 
				&point);
			//ERR_FAIL_COND_V(!res, false);
			p_8points[i] = p_transform.xform(point);
		}

		return true;
	}

	Vector2 getViewportHalfExtents() const
	{
		const real_t* matrix = m.ptr;
		///////--- Near Plane ---///////
		Plane near_plane = Plane(matrix[3] + matrix[2],
				matrix[7] + matrix[6],
				matrix[11] + matrix[10],
				-matrix[15] - matrix[14]);
		near_plane.normalize();

		///////--- Right Plane ---///////
		Plane right_plane = Plane(matrix[3] - matrix[0],
				matrix[7] - matrix[4],
				matrix[11] - matrix[8],
				-matrix[15] + matrix[12]);
		right_plane.normalize();

		Plane top_plane = Plane(matrix[3] - matrix[1],
				matrix[7] - matrix[5],
				matrix[11] - matrix[9],
				-matrix[15] + matrix[13]);
		top_plane.normalize();

		Vector3 res;
		near_plane.intersect3(right_plane, top_plane, &res);

		return Vector2(res.x, res.y);
	}

	Vector2 getFarPlaneHalfExtents() const
	{
		const real_t* matrix = m.ptr;
		///////--- Far Plane ---///////
		Plane far_plane = Plane(matrix[3] - matrix[2],
				matrix[7] - matrix[6],
				matrix[11] - matrix[10],
				-matrix[15] + matrix[14]);
		far_plane.normalize();

		///////--- Right Plane ---///////
		Plane right_plane = Plane(matrix[3] - matrix[0],
				matrix[7] - matrix[4],
				matrix[11] - matrix[8],
				-matrix[15] + matrix[12]);
		right_plane.normalize();

		Plane top_plane = Plane(matrix[3] - matrix[1],
				matrix[7] - matrix[5],
				matrix[11] - matrix[9],
				-matrix[15] + matrix[13]);
		top_plane.normalize();

		Vector3 res;
		far_plane.intersect3(right_plane, top_plane, &res);

		return Vector2(res.x, res.y);
	}

	void invert()
	{
		int i, j, k;
		int[4] pvt_i, pvt_j; /* Locations of pivot matrix */
		real_t pvt_val; /* Value of current pivot element */
		real_t hold; /* Temporary storage */
		real_t determinant = 1.0f;
		for (k = 0; k < 4; k++) {
			/** Locate k'th pivot element **/
			pvt_val = matrix[k][k]; /** Initialize for search **/
			pvt_i[k] = k;
			pvt_j[k] = k;
			for (i = k; i < 4; i++) {
				for (j = k; j < 4; j++) {
					if (abs(matrix[i][j]) > abs(pvt_val)) {
						pvt_i[k] = i;
						pvt_j[k] = j;
						pvt_val = matrix[i][j];
					}
				}
			}

			/** Product of pivots, gives determinant when finished **/
			determinant *= pvt_val;
			if (isClose(determinant, 0)) {
				return; /** Matrix is singular (zero determinant). **/
			}

			/** "Interchange" elements (with sign change stuff) **/
			i = pvt_i[k];
			if (i != k) { /** If elements are different **/
				for (j = 0; j < 4; j++) {
					hold = -matrix[k][j];
					matrix[k][j] = matrix[i][j];
					matrix[i][j] = hold;
				}
			}

			/** "Interchange" columns **/
			j = pvt_j[k];
			if (j != k) { /** If columns are different **/
				for (i = 0; i < 4; i++) {
					hold = -matrix[i][k];
					matrix[i][k] = matrix[i][j];
					matrix[i][j] = hold;
				}
			}

			/** Divide column by minus pivot value **/
			for (i = 0; i < 4; i++) {
				if (i != k) {
					matrix[i][k] /= (-pvt_val);
				}
			}

			/** Reduce the matrix **/
			for (i = 0; i < 4; i++) {
				hold = matrix[i][k];
				for (j = 0; j < 4; j++) {
					if (i != k && j != k) {
						matrix[i][j] += hold * matrix[k][j];
					}
				}
			}

			/** Divide row by pivot **/
			for (j = 0; j < 4; j++) {
				if (j != k) {
					matrix[k][j] /= pvt_val;
				}
			}

			/** Replace pivot by reciprocal (at last we can touch it). **/
			matrix[k][k] = 1.0 / pvt_val;
		}

		/* That was most of the work, one final pass of row/column interchange */
		/* to finish */
		for (k = 4 - 2; k >= 0; k--) { /* Don't need to work with 1 by 1 corner*/
			i = pvt_j[k]; /* Rows to swap correspond to pivot COLUMN */
			if (i != k) { /* If elements are different */
				for (j = 0; j < 4; j++) {
					hold = matrix[k][j];
					matrix[k][j] = -matrix[i][j];
					matrix[i][j] = hold;
				}
			}

			j = pvt_i[k]; /* Columns to swap correspond to pivot ROW */
			if (j != k) { /* If columns are different */
				for (i = 0; i < 4; i++) {
					hold = matrix[i][k];
					matrix[i][k] = -matrix[i][j];
					matrix[i][j] = hold;
				}
			}
		}
	}

	Projection inverse() const
	{
		Projection cm = this;
		cm.invert();
		return cm;
	}

	Projection opBinary(string op : "*")(in Projection p_matrix) const
	{
		Projection new_matrix;

		for (int j = 0; j < 4; j++) {
			for (int i = 0; i < 4; i++) {
				real_t ab = 0;
				for (int k = 0; k < 4; k++) {
					ab += matrix[k][i] * p_matrix.matrix[j][k];
				}
				new_matrix.matrix[j][i] = ab;
			}
		}

		return new_matrix;
	}

	Plane xform4(in Plane p_vec4) const
	{
		Plane ret;

		ret.normal.x = matrix[0][0] * p_vec4.normal.x + matrix[1][0] * p_vec4.normal.y + matrix[2][0] * p_vec4.normal.z + matrix[3][0] * p_vec4.d;
		ret.normal.y = matrix[0][1] * p_vec4.normal.x + matrix[1][1] * p_vec4.normal.y + matrix[2][1] * p_vec4.normal.z + matrix[3][1] * p_vec4.d;
		ret.normal.z = matrix[0][2] * p_vec4.normal.x + matrix[1][2] * p_vec4.normal.y + matrix[2][2] * p_vec4.normal.z + matrix[3][2] * p_vec4.d;
		ret.d = matrix[0][3] * p_vec4.normal.x + matrix[1][3] * p_vec4.normal.y + matrix[2][3] * p_vec4.normal.z + matrix[3][3] * p_vec4.d;
		return ret;
	}

	Vector3 xform(in Vector3 p_vec3) const
	{
		Vector3 ret;
		ret.x = matrix[0][0] * p_vec3.x + matrix[1][0] * p_vec3.y + matrix[2][0] * p_vec3.z + matrix[3][0];
		ret.y = matrix[0][1] * p_vec3.x + matrix[1][1] * p_vec3.y + matrix[2][1] * p_vec3.z + matrix[3][1];
		ret.z = matrix[0][2] * p_vec3.x + matrix[1][2] * p_vec3.y + matrix[2][2] * p_vec3.z + matrix[3][2];
		real_t w = matrix[0][3] * p_vec3.x + matrix[1][3] * p_vec3.y + matrix[2][3] * p_vec3.z + matrix[3][3];
		return ret / w;
	}

	Vector4 xform(in Vector4 p_vec4) const
	{
		return Vector4(
			matrix[0][0] * p_vec4.x + matrix[1][0] * p_vec4.y + matrix[2][0] * p_vec4.z + matrix[3][0] * p_vec4.w,
			matrix[0][1] * p_vec4.x + matrix[1][1] * p_vec4.y + matrix[2][1] * p_vec4.z + matrix[3][1] * p_vec4.w,
			matrix[0][2] * p_vec4.x + matrix[1][2] * p_vec4.y + matrix[2][2] * p_vec4.z + matrix[3][2] * p_vec4.w,
			matrix[0][3] * p_vec4.x + matrix[1][3] * p_vec4.y + matrix[2][3] * p_vec4.z + matrix[3][3] * p_vec4.w);
	}

	Vector4 xform_inv(in Vector4 p_vec4) const
	{
		return Vector4(
			matrix[0][0] * p_vec4.x + matrix[0][1] * p_vec4.y + matrix[0][2] * p_vec4.z + matrix[0][3] * p_vec4.w,
			matrix[1][0] * p_vec4.x + matrix[1][1] * p_vec4.y + matrix[1][2] * p_vec4.z + matrix[1][3] * p_vec4.w,
			matrix[2][0] * p_vec4.x + matrix[2][1] * p_vec4.y + matrix[2][2] * p_vec4.z + matrix[2][3] * p_vec4.w,
			matrix[3][0] * p_vec4.x + matrix[3][1] * p_vec4.y + matrix[3][2] * p_vec4.z + matrix[3][3] * p_vec4.w);
	}

	void scaleTranslateToFit(in AABB p_aabb)
	{
		Vector3 min = p_aabb.position;
		Vector3 max = p_aabb.position + p_aabb.size;

		matrix[0][0] = 2 / (max.x - min.x);
		matrix[1][0] = 0;
		matrix[2][0] = 0;
		matrix[3][0] = -(max.x + min.x) / (max.x - min.x);

		matrix[0][1] = 0;
		matrix[1][1] = 2 / (max.y - min.y);
		matrix[2][1] = 0;
		matrix[3][1] = -(max.y + min.y) / (max.y - min.y);

		matrix[0][2] = 0;
		matrix[1][2] = 0;
		matrix[2][2] = 2 / (max.z - min.z);
		matrix[3][2] = -(max.z + min.z) / (max.z - min.z);

		matrix[0][3] = 0;
		matrix[1][3] = 0;
		matrix[2][3] = 0;
		matrix[3][3] = 1;
	}

	void addJitterOffset(in Vector2 p_offset)
	{
		matrix[3][0] += p_offset.x;
		matrix[3][1] += p_offset.y;
	}

	void makeScale(in Vector3 p_scale)
	{
		setIdentity();
		matrix[0][0] = p_scale.x;
		matrix[1][1] = p_scale.y;
		matrix[2][2] = p_scale.z;
	}

	int get_pixels_per_meter(int p_for_pixel_width) const
	{
		Vector3 result = xform(Vector3(1, 0, -1));

		return cast(int)((result.x * 0.5 + 0.5) * p_for_pixel_width);
	}

	Transform3D opCast(Transform3D)() const
	{
		Transform3D tr;
		const real_t* matrix = m.ptr;

		tr.basis.rows[0][0] = m[0];
		tr.basis.rows[1][0] = m[1];
		tr.basis.rows[2][0] = m[2];

		tr.basis.rows[0][1] = m[4];
		tr.basis.rows[1][1] = m[5];
		tr.basis.rows[2][1] = m[6];

		tr.basis.rows[0][2] = m[8];
		tr.basis.rows[1][2] = m[9];
		tr.basis.rows[2][2] = m[10];

		tr.origin.x = m[12];
		tr.origin.y = m[13];
		tr.origin.z = m[14];

		return tr;
	}

	void flipY()
	{
		for (int i = 0; i < 4; i++) {
			matrix[1][i] = -matrix[1][i];
		}
	}

	bool opEquals(const Projection p_cam) const
	{
		for (uint32_t i = 0; i < 4; i++) {
			for (uint32_t j = 0; j < 4; j++) {
				if (matrix[i][j] != p_cam.matrix[i][j]) {
					return false;
				}
			}
		}
		return true;
	}

	float getLODMultiplier() const
	{
		if (isOrthogonal()) {
			return getViewportHalfExtents().x;
		} else {
			float zn = getZNear();
			float width = getViewportHalfExtents().x * 2.0;
			return 1.0 / (zn / width);
		}

		// usage is lod_size / (lod_distance * multiplier) < threshold
	}
}

/**
2D Transformation. 3x2 matrix.

Copyright:
Copyright (c) 2007-2022 Juan Linietsky, Ariel Manzur.
Copyright (c) 2014-2022 Godot Engine contributors (cf. AUTHORS.md)
Copyright (c) 2017-2018 Godot-D contributors
Copyright (c) 2022-2022 Godot-DLang contributors

License: $(LINK2 https://opensource.org/licenses/MIT, MIT License)


*/
module godot.core.transform2d;

import godot.core.defs;
import godot.core.vector2;
import godot.core.rect2;

import std.math;
import std.algorithm.comparison;
import std.algorithm.mutation : swap;

/**
Represents one or many transformations in 2D space such as translation, rotation, or scaling. It is similar to a 3x2 matrix.
*/
struct Transform2D
{
	@nogc nothrow:
	
	union
	{
		Vector2[3] columns = [ Vector2(1,0), Vector2(0,1), Vector2(0,0) ];
		struct
		{
			Vector2 x_axis; /// 
			Vector2 y_axis; /// 
			Vector2 origin; /// 
		}
	}
	
	real_t tdotx(in Vector2 v) const { return columns[0][0] * v.x + columns[1][0] * v.y; }
	real_t tdoty(in Vector2 v) const { return columns[0][1] * v.x + columns[1][1] * v.y; }
	
	this(real_t xx, real_t xy, real_t yx, real_t yy, real_t ox, real_t oy)
	{
		columns[0][0] = xx;
		columns[0][1] = xy;
		columns[1][0] = yx;
		columns[1][1] = yy;
		columns[2][0] = ox;
		columns[2][1] = oy;
	}
	
	const(Vector2) opIndex(int axis) const { return columns[axis]; }
	ref Vector2 opIndex(int axis) return { return columns[axis]; }
	
	
	
	Vector2 basisXform(in Vector2 v) const
	{
		return Vector2(
			tdotx(v),
			tdoty(v)
		);
	}
	
	Vector2 basisXformInv(in Vector2 v) const
	{
		return Vector2(
			columns[0].dot(v),
			columns[1].dot(v)
		);
	}
	
	Vector2 xform(in Vector2 v) const
	{
		return Vector2(
			tdotx(v),
			tdoty(v)
		) + columns[2];
	}
	Vector2 xformInv(in Vector2 p_vec) const
	{
		Vector2 v = p_vec - columns[2];
		
		return Vector2(
			columns[0].dot(v),
			columns[1].dot(v)
		);
	}
	Rect2 xform(in Rect2 p_rect) const
	{
		Vector2 x=columns[0]*p_rect.size.x;
		Vector2 y=columns[1]*p_rect.size.y;
		Vector2 pos = xform( p_rect.position );
	
		Rect2 new_rect;
		new_rect.position=pos;
		new_rect.expandTo( pos+x );
		new_rect.expandTo( pos+y );
		new_rect.expandTo( pos+x+y );
		return new_rect;
	}
	
	void setRotationAndScale(real_t p_rot,in Vector2 p_scale)
	{
		columns[0][0]=cos(p_rot)*p_scale.x;
		columns[1][1]=cos(p_rot)*p_scale.y;
		columns[1][0]=-sin(p_rot)*p_scale.y;
		columns[0][1]=sin(p_rot)*p_scale.x;
	
	}
	
	Rect2 xformInv(in Rect2 p_rect) const
	{
		Vector2[4] ends=[
			xformInv( p_rect.position ),
			xformInv( Vector2(p_rect.position.x,p_rect.position.y+p_rect.size.y ) ),
			xformInv( Vector2(p_rect.position.x+p_rect.size.x,p_rect.position.y+p_rect.size.y ) ),
			xformInv( Vector2(p_rect.position.x+p_rect.size.x,p_rect.position.y ) )
		];
	
		Rect2 new_rect;
		new_rect.position=ends[0];
		new_rect.expandTo(ends[1]);
		new_rect.expandTo(ends[2]);
		new_rect.expandTo(ends[3]);
	
		return new_rect;
	}
	
	void invert()
	{
		// FIXME: this function assumes the basis is a rotation matrix, with no scaling.
		// affine_inverse can handle matrices with scaling, so GDScript should eventually use that.
		swap(columns[0][1],columns[1][0]);
		columns[2] = basisXform(-columns[2]);
	}
	
	Transform2D inverse() const
	{
		Transform2D inv=this;
		inv.invert();
		return inv;
	
	}
	
	void affineInvert()
	{
		real_t det = basisDeterminant();
		///ERR_FAIL_COND(det==0);
		real_t idet = 1.0 / det;
	
		swap( columns[0][0],columns[1][1] );
		columns[0]*=Vector2(idet,-idet);
		columns[1]*=Vector2(-idet,idet);
	
		columns[2] = basisXform(-columns[2]);
	
	}
	
	Transform2D affineInverse() const
	{
		Transform2D inv=this;
		inv.affineInvert();
		return inv;
	}
	
	void rotate(real_t p_phi)
	{
		this = Transform2D(p_phi,Vector2()) * (this);
	}
	
	real_t getRotation() const
	{
		real_t det = basisDeterminant();
		Transform2D m = orthonormalized();
		if (det < 0) {
			m.scaleBasis(Vector2(-1,-1));
		}
		return atan2(m[0].y,m[0].x);
	}
	
	void setRotation(real_t p_rot)
	{
		real_t cr = cos(p_rot);
		real_t sr = sin(p_rot);
		columns[0][0]=cr;
		columns[0][1]=sr;
		columns[1][0]=-sr;
		columns[1][1]=cr;
	}
	
	this(real_t p_rot, in Vector2 p_pos)
	{
		real_t cr = cos(p_rot);
		real_t sr = sin(p_rot);
		columns[0][0]=cr;
		columns[0][1]=sr;
		columns[1][0]=-sr;
		columns[1][1]=cr;
		columns[2]=p_pos;
	}
	
	Vector2 getScale() const
	{
		real_t det_sign = basisDeterminant() > 0 ? 1 : -1;
		return det_sign * Vector2( columns[0].length(), columns[1].length() );
	}
	
	void scale(in Vector2 p_scale)
	{
		scaleBasis(p_scale);
		columns[2]*=p_scale;
	}
	void scaleBasis(in Vector2 p_scale)
	{
		columns[0][0]*=p_scale.x;
		columns[0][1]*=p_scale.y;
		columns[1][0]*=p_scale.x;
		columns[1][1]*=p_scale.y;
	
	}
	void translate(real_t p_tx, real_t p_ty)
	{
		translate(Vector2(p_tx,p_ty));
	}
	void translate(in Vector2 p_translation)
	{
		columns[2]+=basisXform(p_translation);
	}
	
	void orthonormalize()
	{
		// Gram-Schmidt Process
	
		Vector2 x=columns[0];
		Vector2 y=columns[1];
	
		x.normalize();
		y = (y-x*(x.dot(y)));
		y.normalize();
	
		columns[0]=x;
		columns[1]=y;
	}
	Transform2D orthonormalized() const
	{
		Transform2D on=this;
		on.orthonormalize();
		return on;
	
	}
	
	void opOpAssign(string op : "*")(in Transform2D p_transform)
	{
		columns[2] = xform(p_transform.columns[2]);
	
		real_t x0,x1,y0,y1;
	
		x0 = tdotx(p_transform.columns[0]);
		x1 = tdoty(p_transform.columns[0]);
		y0 = tdotx(p_transform.columns[1]);
		y1 = tdoty(p_transform.columns[1]);
	
		columns[0][0]=x0;
		columns[0][1]=x1;
		columns[1][0]=y0;
		columns[1][1]=y1;
	}
	
	
	Transform2D opBinary(string op : "*")(in Transform2D p_transform) const
	{
		Transform2D t = this;
		t*=p_transform;
		return t;
	
	}
	
	Transform2D scaled(in Vector2 p_scale) const
	{
		Transform2D copy=this;
		copy.scale(p_scale);
		return copy;
	
	}
	
	Transform2D basisScaled(in Vector2 p_scale) const
	{
		Transform2D copy=this;
		copy.scaleBasis(p_scale);
		return copy;
	
	}
	
	Transform2D untranslated() const
	{
		Transform2D copy=this;
		copy.columns[2]=Vector2();
		return copy;
	}
	
	Transform2D translated(in Vector2 p_offset) const
	{
		Transform2D copy=this;
		copy.translate(p_offset);
		return copy;
	}
	
	Transform2D rotated(real_t p_phi) const
	{
		Transform2D copy=this;
		copy.rotate(p_phi);
		return copy;
	
	}
	
	real_t basisDeterminant() const
	{
		return columns[0].x * columns[1].y - columns[0].y * columns[1].x;
	}
	
	Transform2D interpolateWith(in Transform2D p_transform, real_t p_c) const
	{
		//extract parameters
		Vector2 p1 = origin;
		Vector2 p2 = p_transform.origin;
	
		real_t r1 = getRotation();
		real_t r2 = p_transform.getRotation();
	
		Vector2 s1 = getScale();
		Vector2 s2 = p_transform.getScale();
	
		//slerp rotation
		Vector2 v1 = Vector2(cos(r1), sin(r1));
		Vector2 v2 = Vector2(cos(r2), sin(r2));
	
		real_t dot = v1.dot(v2);
	
		dot = (dot < -1.0) ? -1.0 : ((dot > 1.0) ? 1.0 : dot); //clamp dot to [-1,1]
	
		Vector2 v;
	
		if (dot > 0.9995)
		{
			v = Vector2.linearInterpolate(v1, v2, p_c).normalized(); //linearly interpolate to avoid numerical precision issues
		}
		else
		{
			real_t angle = p_c*acos(dot);
			Vector2 v3 = (v2 - v1*dot).normalized();
			v = v1*cos(angle) + v3*sin(angle);
		}
	
		//construct matrix
		Transform2D res = Transform2D(atan2(v.y, v.x), Vector2.linearInterpolate(p1, p2, p_c));
		res.scaleBasis(Vector2.linearInterpolate(s1, s2, p_c));
		return res;
	}
}

/**
2D Axis-aligned bounding box.

Copyright:
Copyright (c) 2007-2022 Juan Linietsky, Ariel Manzur.
Copyright (c) 2014-2022 Godot Engine contributors (cf. AUTHORS.md)
Copyright (c) 2017-2018 Godot-D contributors
Copyright (c) 2022-2022 Godot-DLang contributors

License: $(LINK2 https://opensource.org/licenses/MIT, MIT License)


*/
module godot.core.rect2;

import godot.c.core;
import godot.core.defs;
import godot.core.vector2, godot.core.transform2d;
// import godot.globalenums;  // enum Side, but tbh it is bad idea to rely on this

import std.algorithm.comparison;
import std.algorithm.mutation : swap;

/**
Rect2 consists of a position, a size, and several utility functions. It is typically used for fast overlap tests.
*/
struct Rect2
{
	@nogc nothrow:
	
	Vector2 position;
	Vector2 size;

	deprecated("pos has been renamed to position, please use position instead") 
	alias pos = position;

	alias end = getEnd;
	
	this( real_t p_x, real_t p_y, real_t p_width, real_t p_height)
	{
		position=Vector2(p_x,p_y);
		size=Vector2(p_width, p_height);
	}

	this(in Rect2i b)
	{
		position = b.position;
		size = b.size;
	}
	
	real_t getArea() const { return size.width*size.height; }

	Vector2 end() const { return getEnd(); }

	void end(in Vector2 p_end)  {  setEnd(p_end); }
	
	bool intersects(in Rect2 p_rect) const
	{
		if ( position.x >= (p_rect.position.x + p_rect.size.width) )
			return false;
		if ( (position.x+size.width) <= p_rect.position.x  )
			return false;
		if ( position.y >= (p_rect.position.y + p_rect.size.height) )
			return false;
		if ( (position.y+size.height) <= p_rect.position.y  )
			return false;
		
		return true;
	}
	
	bool encloses(in Rect2 p_rect) const
	{
		return 	(p_rect.position.x>=position.x) && (p_rect.position.y>=position.y) &&
			((p_rect.position.x+p_rect.size.x)<(position.x+size.x)) &&
			((p_rect.position.y+p_rect.size.y)<(position.y+size.y));
	}
	bool hasNoArea() const
	{
		return (size.x<=0 || size.y<=0);
	}
	
	bool hasPoint(in Vector2 p_point) const
	{
		if (p_point.x < position.x)
			return false;
		if (p_point.y < position.y)
			return false;
		
		if (p_point.x >= (position.x+size.x) )
			return false;
		if (p_point.y >= (position.y+size.y) )
			return false;
		
		return true;
	}
	
	Rect2 grow(real_t p_by) const
	{
		Rect2 g=this;
		g.position.x-=p_by;
		g.position.y-=p_by;
		g.size.width+=p_by*2;
		g.size.height+=p_by*2;
		return g;
	}

	Rect2 expand(in Vector2 p_vector) const
	{
		Rect2 r = this;
		r.expandTo(p_vector);
		return r;
	}

	void expandTo(in Vector2 p_vector)
	{
		Vector2 begin=position;
		Vector2 end=position+size;
		
		if (p_vector.x<begin.x)
			begin.x=p_vector.x;
		if (p_vector.y<begin.y)
			begin.y=p_vector.y;
		
		if (p_vector.x>end.x)
			end.x=p_vector.x;
		if (p_vector.y>end.y)
			end.y=p_vector.y;
		
		position=begin;
		size=end-begin;
	}
	
	
	real_t distanceTo(in Vector2 p_point) const
	{
		real_t dist = 1e20;
		
		if (p_point.x < position.x)
		{
			dist=min(dist,position.x-p_point.x);
		}
		if (p_point.y < position.y)
		{
			dist=min(dist,position.y-p_point.y);
		}
		if (p_point.x >= (position.x+size.x) )
		{
			dist=min(p_point.x-(position.x+size.x),dist);
		}
		if (p_point.y >= (position.y+size.y) )
	    {
		    dist=min(p_point.y-(position.y+size.y),dist);
		}
		
		if (dist==1e20)
			return 0;
		else
			return dist;
	}
	
	Rect2 clip(in Rect2 p_rect) const
	{
	
		Rect2 new_rect=p_rect;
		
		if (!intersects( new_rect ))
			return Rect2();
		
		new_rect.position.x = max( p_rect.position.x , position.x );
		new_rect.position.y = max( p_rect.position.y , position.y );
		
		Vector2 p_rect_end=p_rect.position+p_rect.size;
		Vector2 end=position+size;
		
		new_rect.size.x=min(p_rect_end.x,end.x) - new_rect.position.x;
		new_rect.size.y=min(p_rect_end.y,end.y) - new_rect.position.y;
		
		return new_rect;
	}
	
	Rect2 merge(in Rect2 p_rect) const
	{
		Rect2 new_rect;
		
		new_rect.position.x=min( p_rect.position.x , position.x );
		new_rect.position.y=min( p_rect.position.y , position.y );
		
		
		new_rect.size.x = max( p_rect.position.x+p_rect.size.x , position.x+size.x );
		new_rect.size.y = max( p_rect.position.y+p_rect.size.y , position.y+size.y );
		
		new_rect.size = new_rect.size - new_rect.position; //make relative again
		
		return new_rect;
	}
	
	
	
	bool intersectsSegment(in Vector2 p_from, in Vector2 p_to, Vector2* r_pos,Vector2* r_normal) const
	{
		real_t min=0,max=1;
		int axis=0;
		real_t sign=0;
	
		for(int i=0;i<2;i++)
		{
			real_t seg_from=p_from[i];
			real_t seg_to=p_to[i];
			real_t box_begin=position[i];
			real_t box_end=box_begin+size[i];
			real_t cmin,cmax;
			real_t csign;
	
			if (seg_from < seg_to)
			{
				if (seg_from > box_end || seg_to < box_begin)
					return false;
				real_t length=seg_to-seg_from;
				cmin = (seg_from < box_begin)?((box_begin - seg_from)/length):0;
				cmax = (seg_to > box_end)?((box_end - seg_from)/length):1;
				csign=-1.0;
	
			}
			else
			{
				if (seg_to > box_end || seg_from < box_begin)
					return false;
				real_t length=seg_to-seg_from;
				cmin = (seg_from > box_end)?(box_end - seg_from)/length:0;
				cmax = (seg_to < box_begin)?(box_begin - seg_from)/length:1;
				csign=1.0;
			}
	
			if (cmin > min)
			{
				min = cmin;
				axis=i;
				sign=csign;
			}
			if (cmax < max)
				max = cmax;
			if (max < min)
				return false;
		}
	
	
		Vector2 rel=p_to-p_from;
	
		if (r_normal)
		{
			Vector2 normal;
			normal[axis]=sign;
			*r_normal=normal;
		}
	
		if (r_pos)
			*r_pos=p_from+rel*min;
	
		return true;
	}
	
	
	bool intersectsTransformed(in Transform2D p_xform, in Rect2 p_rect) const
	{
		//SAT intersection between local and transformed rect2
	
		Vector2[4] xf_points=[
			p_xform.xform(p_rect.position),
			p_xform.xform(Vector2(p_rect.position.x+p_rect.size.x,p_rect.position.y)),
			p_xform.xform(Vector2(p_rect.position.x,p_rect.position.y+p_rect.size.y)),
			p_xform.xform(Vector2(p_rect.position.x+p_rect.size.x,p_rect.position.y+p_rect.size.y)),
		];
	
		real_t low_limit;
	
		//base rect2 first (faster)
	
		if (xf_points[0].y>position.y)
			goto next1;
		if (xf_points[1].y>position.y)
			goto next1;
		if (xf_points[2].y>position.y)
			goto next1;
		if (xf_points[3].y>position.y)
			goto next1;
	
		return false;
	
		next1:
	
		low_limit=position.y+size.y;
	
		if (xf_points[0].y<low_limit)
			goto next2;
		if (xf_points[1].y<low_limit)
			goto next2;
		if (xf_points[2].y<low_limit)
			goto next2;
		if (xf_points[3].y<low_limit)
			goto next2;
	
		return false;
	
		next2:
	
		if (xf_points[0].x>position.x)
			goto next3;
		if (xf_points[1].x>position.x)
			goto next3;
		if (xf_points[2].x>position.x)
			goto next3;
		if (xf_points[3].x>position.x)
			goto next3;
	
		return false;
	
		next3:
	
		low_limit=position.x+size.x;
	
		if (xf_points[0].x<low_limit)
			goto next4;
		if (xf_points[1].x<low_limit)
			goto next4;
		if (xf_points[2].x<low_limit)
			goto next4;
		if (xf_points[3].x<low_limit)
			goto next4;
	
		return false;
	
		next4:
	
		Vector2[4] xf_points2=[
			position,
			Vector2(position.x+size.x,position.y),
			Vector2(position.x,position.y+size.y),
			Vector2(position.x+size.x,position.y+size.y),
		];
	
		real_t maxa=p_xform.columns[0].dot(xf_points2[0]);
		real_t mina=maxa;
	
		real_t dp = p_xform.columns[0].dot(xf_points2[1]);
		maxa=max(dp,maxa);
		mina=min(dp,mina);
	
		dp = p_xform.columns[0].dot(xf_points2[2]);
		maxa=max(dp,maxa);
		mina=min(dp,mina);
	
		dp = p_xform.columns[0].dot(xf_points2[3]);
		maxa=max(dp,maxa);
		mina=min(dp,mina);
	
		real_t maxb=p_xform.columns[0].dot(xf_points[0]);
		real_t minb=maxb;
	
		dp = p_xform.columns[0].dot(xf_points[1]);
		maxb=max(dp,maxb);
		minb=min(dp,minb);
	
		dp = p_xform.columns[0].dot(xf_points[2]);
		maxb=max(dp,maxb);
		minb=min(dp,minb);
	
		dp = p_xform.columns[0].dot(xf_points[3]);
		maxb=max(dp,maxb);
		minb=min(dp,minb);
	
	
		if ( mina > maxb )
			return false;
		if ( minb > maxa  )
			return false;
	
		maxa=p_xform.columns[1].dot(xf_points2[0]);
		mina=maxa;
	
		dp = p_xform.columns[1].dot(xf_points2[1]);
		maxa=max(dp,maxa);
		mina=min(dp,mina);
	
		dp = p_xform.columns[1].dot(xf_points2[2]);
		maxa=max(dp,maxa);
		mina=min(dp,mina);
	
		dp = p_xform.columns[1].dot(xf_points2[3]);
		maxa=max(dp,maxa);
		mina=min(dp,mina);
	
		maxb=p_xform.columns[1].dot(xf_points[0]);
		minb=maxb;
	
		dp = p_xform.columns[1].dot(xf_points[1]);
		maxb=max(dp,maxb);
		minb=min(dp,minb);
	
		dp = p_xform.columns[1].dot(xf_points[2]);
		maxb=max(dp,maxb);
		minb=min(dp,minb);
	
		dp = p_xform.columns[1].dot(xf_points[3]);
		maxb=max(dp,maxb);
		minb=min(dp,minb);
	
	
		if ( mina > maxb )
			return false;
		if ( minb > maxa  )
			return false;
	
	
		return true;
	
	}

	void setEnd(in Vector2 p_end) 
	{
		size = p_end - position;
	}

	Vector2 getEnd() const 
	{
		return position + size;
	}

}

struct Rect2i
{
	@nogc nothrow:
	
	Vector2i position;
	Vector2i size;

	// from godot.globalenums module
	enum
	{
		/** */
		sideLeft = 0,
		/** */
		sideTop = 1,
		/** */
		sideRight = 2,
		/** */
		sideBottom = 3,
	}
	alias Side = int;

	Vector2i end() const { return getEnd(); }

	void end(in Vector2i p_end)  { setEnd(p_end); }
	
	this(godot_int p_x, godot_int p_y, godot_int p_width, godot_int p_height)
	{
		position=Vector2i(p_x,p_y);
		size=Vector2i(p_width, p_height);
	}

	this(in Vector2i p_pos, in Vector2i p_size)
	{
		position = p_pos;
		size = p_size;
	}

	bool intersects(in Rect2i p_rect) const 
	{
		if (position.x > (p_rect.position.x + p_rect.size.width)) {
			return false;
		}
		if ((position.x + size.width) < p_rect.position.x) {
			return false;
		}
		if (position.y > (p_rect.position.y + p_rect.size.height)) {
			return false;
		}
		if ((position.y + size.height) < p_rect.position.y) {
			return false;
		}

		return true;
	}

	bool encloses(in Rect2i p_rect) const 
	{
		return (p_rect.position.x >= position.x) && (p_rect.position.y >= position.y) &&
			   ((p_rect.position.x + p_rect.size.x) < (position.x + size.x)) &&
			   ((p_rect.position.y + p_rect.size.y) < (position.y + size.y));
	}

	bool hasNoArea() const 
	{
		return (size.x <= 0 || size.y <= 0);
	}

	// Returns the instersection between two Rect2is or an empty Rect2i if there is no intersection
	Rect2i intersection(in Rect2i p_rect) const 
	{
		Rect2i new_rect = p_rect;

		if (!intersects(new_rect)) {
			return Rect2i();
		}

		new_rect.position.x = max(p_rect.position.x, position.x);
		new_rect.position.y = max(p_rect.position.y, position.y);

		Vector2i p_rect_end = p_rect.position + p_rect.size;
		Vector2i end = position + size;

		new_rect.size.x = cast(godot_int)(min(p_rect_end.x, end.x) - new_rect.position.x);
		new_rect.size.y = cast(godot_int)(min(p_rect_end.y, end.y) - new_rect.position.y);

		return new_rect;
	}

	Rect2i merge(in Rect2i p_rect) const ///< return a merged rect
	{ 

		Rect2i new_rect;

		new_rect.position.x = min(p_rect.position.x, position.x);
		new_rect.position.y = min(p_rect.position.y, position.y);

		new_rect.size.x = max(p_rect.position.x + p_rect.size.x, position.x + size.x);
		new_rect.size.y = max(p_rect.position.y + p_rect.size.y, position.y + size.y);

		new_rect.size = new_rect.size - new_rect.position; // make relative again

		return new_rect;
	}

	bool hasPoint(in Vector2i p_point) const 
	{
		if (p_point.x < position.x) {
			return false;
		}
		if (p_point.y < position.y) {
			return false;
		}

		if (p_point.x >= (position.x + size.x)) {
			return false;
		}
		if (p_point.y >= (position.y + size.y)) {
			return false;
		}

		return true;
	}

	bool opEquals(in Rect2i p_rect) const
	{
		return position == p_rect.position && size == p_rect.size;
	}

	Rect2i grow(int p_amount) const 
	{
		Rect2i g = this;
		g.position.x -= p_amount;
		g.position.y -= p_amount;
		g.size.width += p_amount * 2;
		g.size.height += p_amount * 2;
		return g;
	}

	Rect2i growSide(Side p_side, int p_amount) const 
	{
		Rect2i g = this;
		g = g.growIndividual((sideLeft == p_side) ? p_amount : 0,
				(sideTop == p_side) ? p_amount : 0,
				(sideRight == p_side) ? p_amount : 0,
				(sideBottom == p_side) ? p_amount : 0);
		return g;
	}

	Rect2i growSideBind(uint32_t p_side, int p_amount) const {
		return growSide(Side(p_side), p_amount);
	}

	Rect2i growIndividual(int p_left, int p_top, int p_right, int p_bottom) const 
	{
		Rect2i g = this;
		g.position.x -= p_left;
		g.position.y -= p_top;
		g.size.width += p_left + p_right;
		g.size.height += p_top + p_bottom;

		return g;
	}

	Rect2i expand(in Vector2i p_vector) const 
	{
		Rect2i r = this;
		r.expandTo(p_vector);
		return r;
	}

	void expandTo(in Vector2i p_vector) 
	{
		Vector2i begin = position;
		Vector2i end = position + size;

		if (p_vector.x < begin.x) {
			begin.x = p_vector.x;
		}
		if (p_vector.y < begin.y) {
			begin.y = p_vector.y;
		}

		if (p_vector.x > end.x) {
			end.x = p_vector.x;
		}
		if (p_vector.y > end.y) {
			end.y = p_vector.y;
		}

		position = begin;
		size = end - begin;
	}

	Rect2i abs() const 
	{
		return Rect2i(Vector2i(position.x + min(size.x, 0), position.y + min(size.y, 0)), size.abs());
	}

	void setEnd(in Vector2i p_end) 
	{
		size = p_end - position;
	}

	Vector2i getEnd() const 
	{
		return position + size;
	}

	Rect2 opCast(Rect2)() const
	{
		return Rect2(cast(Vector2) position, cast(Vector2) size);
	}
}
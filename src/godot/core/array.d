/**
Dynamic Variant array.

Copyright:
Copyright (c) 2007-2022 Juan Linietsky, Ariel Manzur.
Copyright (c) 2014-2022 Godot Engine contributors (cf. AUTHORS.md)
Copyright (c) 2017-2018 Godot-D contributors
Copyright (c) 2022-2022 Godot-DLang contributors

License: $(LINK2 https://opensource.org/licenses/MIT, MIT License)


*/
module godot.core.array;

import godot.c;
import godot.core.variant;
import godot.core.poolarrays;

// generated raw bindings
import godot.builtins;
import godot.d.bind;

import std.meta;
import std.traits, std.range;
import std.exception : assumeWontThrow;

/**
Generic array, contains several elements of any type, accessible by numerical index starting at 0. Negative indices can be used to count from the right, like in Python. Arrays are always passed by reference.
*/
struct Array
{
	int opApply(int delegate(size_t, ref Variant) dg)
	{
		foreach(i; 0..length)
		{
			Variant* v = cast(Variant*)&(this[i]);
			int res = dg(cast(size_t)i, *v);
			if(res) return res;
		}
		return 0;
	}
	
	int opApply(int delegate(size_t, const(Variant)) dg) const
	{
		foreach(i; 0..length)
		{
			int res = dg(cast(size_t)i, this[i]);
			if(res) return res;
		}
		return 0;
	}
	
	int opApply(int delegate(ref Variant) dg)
	{
		foreach(i; 0..length)
		{
			Variant* v = cast(Variant*)&(this[i]);
			int res = dg(*v);
			if(res) return res;
		}
		return 0;
	}
	
	int opApply(int delegate(const(Variant)) dg) const
	{
		foreach(i; 0..length)
		{
			int res = dg(this[i]);
			if(res) return res;
		}
		return 0;
	}

	/// Convert to a static array.
	/// Excess elements are discarded if the Array is longer than `T`.
	T as(T)() const if(isStaticArray!T && Variant.compatibleFromGodot!(ElementType!T))
	{
		import std.algorithm : min;
		T ret;
		foreach(i; 0..min(T.length, length)) ret[i] = (this[i]).as!(ElementType!T);
		return ret;
	}

	/// Create an Array from any D range or static array with compatible elements.
	static Array from(T)(T t) if((isForwardRange!T || isStaticArray!T) && Variant.compatibleToGodot!(ElementType!T))
	{
		import std.algorithm.iteration;
		Array ret = Array.make();
		static if(hasLength!T)
		{
			ret.resize(cast(int)t.length);
			int ei = 0;
			foreach(e; t) ret[ei++] = e;
		}
		else t.each!(e => ret ~= e);
		return ret;
	}
	
	//@nogc nothrow:
	
	package(godot) 
	{
		union array { godot_array _godot_array; Array_Bind _bind; }
		array _array;
	}

	alias _array this;

	package(godot) this(godot_array opaque)
	{
		_godot_array = opaque;
	}
	
	//@disable this(this);
	//{
	//	const godot_array tmp = _godot_array;
	//	_godot_api.get_variant_from_type_constructor(GDNATIVE_VARIANT_TYPE_ARRAY)(cast(GDNativeTypePtr) &_godot_array, cast(GDNativeTypePtr) &tmp);
	//	this = _bind.duplicate(false);
	//}

	this(const scope ref Array other)
	{
		//if (&_godot_array)
		//	_bind._destructor();
		_godot_array = other._godot_array;
	}
	
	Array opAssign(in Array other)
	{
		//if (&_godot_array)
		//	_bind._destructor();
		this = _bind.new1(other); // do we actually need a copy here?
		return this;
		//_godot_api.variant_destroy(&_godot_array);
		//_godot_api.variant_new_copy(&_godot_array, &other._godot_array);
		//return this;
	}
	
	/++
	Assigning null empties the Array variable, but unlike `clear`, does not
	destroy the original memory unless it was the only remaining reference.
	+/
	Array opAssign(in typeof(null) n)
	{
		return opAssign(Array.make());
	}

	/++
	Create an array and add all $(PARAM args) to it.
	+/
	static Array make(Args...)(Args args)
		if(allSatisfy!(Variant.compatibleToGodot, Args))
	{
		Array ret = void;
		ret._godot_array = godot_array.init;
		auto ct = _godot_api.variant_get_ptr_constructor(GDNATIVE_VARIANT_TYPE_ARRAY, 0);
		ct(cast(GDNativeTypePtr) &ret._godot_array, null);

		static if(args.length) ret.resize(args.length);
		static foreach(i, Arg; Args)
		{
			ret[i] = args[i];
		}
		return ret;
	}
	
	deprecated("Use Array.make() with 0 args instead.")
	static Array empty_array()
	{
		Array ret = void;
		_godot_api.variant_new_nil(&ret._godot_array);
		return ret;
	}
	
	this(in typeof(null) n)
	{
		//_godot_api.variant_new_nil(&_godot_array);
		_bind.new0();
	}
	
	// TODO: verify the following array constructors, since previous API's are gone
	// it now uses overloads of Array.from() extension method
	this(in PackedByteArray a)
	{
		_godot_api.variant_new_copy(&_godot_array, &a._godot_array);
	}
	
	this(in PackedInt32Array a)
	{
		_godot_api.variant_new_copy(&_godot_array, &a._godot_array);
	}

	this(in PackedInt64Array a)
	{
		_godot_api.variant_new_copy(&_godot_array, &a._godot_array);
	}
	
	this(in PackedFloat32Array a)
	{
		_godot_api.variant_new_copy(&_godot_array, &a._godot_array);
	}

	this(in PackedFloat64Array a)
	{
		_godot_api.variant_new_copy(&_godot_array, &a._godot_array);
	}
	
	this(in PackedStringArray a)
	{
		_godot_api.variant_new_copy(&_godot_array, &a._godot_array);
	}
	
	this(in PackedVector2Array a)
	{
		_godot_api.variant_new_copy(&_godot_array, &a._godot_array);
	}
	
	this(in PackedVector3Array a)
	{
		_godot_api.variant_new_copy(&_godot_array, &a._godot_array);
	}
	
	this(in PackedColorArray a)
	{
		_godot_api.variant_new_copy(&_godot_array, &a._godot_array);
	}

	auto ref inout(Variant) opIndex(size_t idx) inout
	{
		godot_variant* v = cast(godot_variant*) _godot_api.array_operator_index(cast(godot_array*)&_godot_array, cast(int)idx);
		return *cast(inout(Variant)*)v;
	}
	
	void opIndexAssign(T)(auto ref T value, in size_t idx) if(is(T : Variant) || Variant.compatibleToGodot!T)
	{
		Variant v = Variant(value);
		godot_variant* val = cast(godot_variant*) _godot_api.array_operator_index(&_godot_array, cast(int)idx);
		*val = v._godot_variant;
	}

	/// Append a single element.
	///
	/// Note: an Array or range will be appended as one single element of type
	/// Array, *not* concatenated to this Array. Use `appendRange` or
	/// `appendArray` to concatenate/chain ranges or Arrays into one.
	void append(T)(auto ref T t) if(is(T : Variant) || Variant.compatibleToGodot!T)
	{
		import godot.core.string;
		Variant v = Variant(t);
		//_godot_api.array_append(&_godot_array, &v._godot_variant);
		_bind.append(v);
	}
	void append(const(void)* nativeObjectPtr)
	{
		import godot.core.string;
		Array a = void;
		a._godot_array = _godot_array;
		// TODO: implement me
		//Variant v = Variant.from(a);
		//_godot_api.array_append(&_godot_array, &v._godot_variant);
		//v.as!Array.append(nativeObjectPtr);
	}
	/// ditto
	template opOpAssign(string op) if(op == "~" || op == "+")
	{
		alias opOpAssign = append;
	}

	/// Concatenate a range or another Array to the end of this one.
	void appendRange(R)(in auto ref R other) if(
		!is(Unqual!R : Array) &&
		isInputRange!R &&
		(is(ElementType!R : Variant) || Variant.compatible!(ElementType!R)))
	{
		static if(hasLength!R)
		{
			size_t l = length;
			resize(l + other.length);
			Variant[] slice = this[];
			size_t i = l;
			foreach(const v; other) slice[i++] = v;
		}
		else foreach(const v; other) append(v);
	}
	/// ditto
	void appendArray(in ref Array other)
	{
		appendRange(other[]);
	}

	private static Array fromConcat(R, S)(in auto ref R r, in auto ref S s)
	{
		Array ret = Array.make();
		ret.resize(r.length + s.length);
		Variant[] slice = ret[];
		size_t i = 0;
		foreach(const v; r) slice[i++] = v;
		foreach(const v; s) slice[i++] = v;
		return ret;
	}
	/// Concatenate two arrays into a new one. The originals are left unaffected
	/// if there are still other references to them remaining.
	Array opBinary(string op, R)(in auto ref R other) if(
		(op == "~" || op == "+") && !is(Unqual!R : Array) &&
		isInputRange!R && hasLength!R &&
		(is(ElementType!R : Variant) || Variant.compatible!(ElementType!R)))
	{
		return fromConcat(this[], other);
	}
	/// ditto
	Array opBinary(string op)(in auto ref Array other) if(op == "~" || op == "+")
	{
		return fromConcat(this[], other[]);
	}
	/// ditto
	Array opBinaryRight(string op, R)(in auto ref R other) if(
		(op == "~" || op == "+") && !is(Unqual!R : Array) &&
		isInputRange!R && hasLength!R &&
		(is(ElementType!R : Variant) || Variant.compatible!(ElementType!R)))
	{
		return fromConcat(other, this[]);
	}

	void clear()
	{
		_bind.clear();
	}
	
	size_t count(in Variant v)
	{
		//return _godot_api.array_count(&_godot_array, &v._godot_variant);
		return _bind.count(v);
	}
	
	bool empty() const
	{
		//return cast(bool)_godot_api.array_empty(&_godot_array);
		return _bind.isEmpty();
	}
	
	void erase(T)(T v)  if(is(T : Variant) || Variant.compatibleToGodot!T)
	{
		Variant vv = v;
		//_godot_api.array_erase(&_godot_array, &vv._godot_variant);
		_bind.erase(v);
	}
	
	Variant front() const
	{
		godot_variant v = void;
		v = _bind.front()._godot_variant;
		//godot_variant v = _godot_api.array_front(&_godot_array);
		return cast(Variant)v;
	}
	
	Variant back() const
	{
		//godot_variant v = _godot_api.array_back(&_godot_array);
		//return cast(Variant)v;
		return _bind.back();
	}
	
	int find(T)(in T what, size_t from) const if(is(T : Variant) || Variant.compatibleToGodot!T)
	{
		const Variant vv = what;
		//return _godot_api.array_find(&_godot_array, &vv._godot_variant, cast(int)from);
		return _bind.find(vv, from);
	}
	
	int findLast(T)(in T what) const if(is(T : Variant) || Variant.compatibleToGodot!T)
	{
		const Variant vv = what;
		//return _godot_api.array_find_last(&_godot_array, &vv._godot_variant);
		return _bind.findLast(vv);
	}
	
	bool has(T)(in T what) const if(is(T : Variant) || Variant.compatibleToGodot!T)
	{
		const Variant vv = what;
		//return cast(bool)_godot_api.array_has(&_godot_array, &vv._godot_variant);
		return _bind.has(vv);
	}
	
	@trusted
	uint hash() const nothrow
	{
		//return _godot_api.array_hash(&_godot_array);
		return cast(uint) assumeWontThrow(_bind.hash());
	}
	@trusted
	hash_t toHash() const nothrow
	{
		return cast(hash_t)hash();
	}
	
	void insert(T)(const size_t pos, T value) if(is(T : Variant) || Variant.compatibleToGodot!T)
	{
		Variant vv = value;
		//_godot_api.array_insert(&_godot_array, cast(int)pos, &vv._godot_variant);
		_bind.insert(pos, vv);
	}
	
	void invert()
	{
		//_godot_api.array_invert(&_godot_array);
		_bind.reverse();
	}
	
	Variant popBack()
	{
		//godot_variant v = _godot_api.array_pop_back(&_godot_array);
		//return cast(Variant)v;
		return _bind.popBack();
	}
	
	Variant popFront()
	{
		//godot_variant v = _godot_api.array_pop_front(&_godot_array);
		//return cast(Variant)v;
		return _bind.popFront();
	}
	
	void pushBack(T)(T v) if(is(T : Variant) || Variant.compatibleToGodot!T)
	{
		Variant vv = v;
		//_godot_api.array_push_back(&_godot_array, &vv._godot_variant);
		_bind.pushBack(vv);
	}
	
	void pushFront(T)(T v) if(is(T : Variant) || Variant.compatibleToGodot!T)
	{
		Variant vv = v;
		//_godot_api.array_push_front(&_godot_array, &vv._godot_variant);
		_bind.pushFront(vv);
	}
	
	void remove(size_t idx)
	{
		//_godot_api.array_remove(&_godot_array, cast(int)idx);
		_bind.removeAt(idx);
	}
	
	size_t size() const
	{
		//return _godot_api.array_size(&_godot_array);
		return _bind.size();
	}
	alias length = size; // D-style `length`
	alias opDollar = size;
	
	void resize(size_t size)
	{
		//_godot_api.array_resize(&_godot_array, cast(int)size);
		_bind.resize(size);
	}
	
	int rfind(T)(in T what, size_t from) const if(is(T : Variant) || Variant.compatibleToGodot!T)
	{
		const Variant vv = what;
		//return _godot_api.array_rfind(&_godot_array, &vv._godot_variant, cast(int)from);
		return _bind.rfind(vv, from);
	}
	
	void sort()
	{
		//_godot_api.array_sort(&_godot_array);
		_bind.sort();
	}
	
	/+void sort_custom(godot.Object obj, in ref String func)
	{
		_godot_api.array_sort_custom(&_godot_array, obj, &func._godot_string);
	}+/
	
	/// Allocate a new separate copy of the Array
	Array dup() const
	{
		Array ret = Array.make();
		size_t l = size();
		ret.resize(l);
		foreach(vi; 0..l)
		{
			ret[vi] = this[vi];
		}
		return ret;
	}

	/// Returns: a new Array containing a slice of the original. It is a copy,
	/// *not* a reference to the original Array's memory.
	///
	/// Note: `end` is non-inclusive, as in D slice operations, not as in Godot.
	Array slice(size_t start, size_t end, size_t stride = 1, bool deep = false) const
	{
		Array ret = void;
		//ret._godot_array = _godot_api.array_slice(&_godot_array,
		//	cast(int)start, cast(int)(end-1), cast(int)stride, deep);
		ret._godot_array = _bind.slice(start, end, stride, deep)._godot_array;
		return ret;
	}

	/++
	Returns: a slice of the array memory. The slice does *not* have ownership of
	the reference-counted memory and is invalid after the original Array goes
	out of scope or is resized.
	+/
	Variant[] opSlice(size_t start, size_t end)
	{
		Variant* ret = cast(Variant*)_godot_api.array_operator_index(&_godot_array, 0);
		return ret[start..end];
	}
	/// ditto
	const(Variant)[] opSlice(size_t start, size_t end) const
	{
		const(Variant)* ret = cast(const(Variant)*)_godot_api.array_operator_index_const(&_godot_array, 0);
		return ret[start..end];
	}
	/// ditto
	Variant[] opSlice() { return this[0..length]; }
	/// ditto
	const(Variant)[] opSlice() const { return this[0..length]; }
	// TODO: `scope` for the returned slices?
	
	~this()
	{
		//if (&_godot_array)
		//	_bind._destructor();
		_array = _array.init;
		//_godot_api.variant_destroy(&_godot_array);
	}
}

struct TypedArray(T)
{
	Array _array;
	alias _array this;

	this(this) {}
	
	this(Array other)
	{
		_array = other;
	}
}



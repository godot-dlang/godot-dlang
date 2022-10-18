/++
Implementation templates for new Godot-D native scripts
+/
module godot.d.script;

import std.meta, std.traits;
import std.experimental.allocator, std.experimental.allocator.mallocator;
import core.stdc.stdlib : malloc, free;

import godot.c, godot.core;
import godot.d.udas;
import godot.d.traits, godot.d.wrap;
import godot.d.reference;

/++
Base class for D native scripts. Native script instances will be attached to a
Godot (C++) object of Base class.
+/
class GodotScript(Base) if(isGodotBaseClass!Base)
{
	Base owner;
	alias owner this;
	
	pragma(inline, true)
	inout(To) as(To)() inout if(isGodotBaseClass!To)
	{
		static assert(extends!(Base, To), typeof(this).stringof~" does not extend "~To.stringof);
		return cast(inout(To))(owner.getGDNativeObject);
	}
	pragma(inline, true)
	inout(To) as(To, this From)() inout if(extendsGodotBaseClass!To)
	{
		static assert(extends!(From, To) || extends!(To, From), From.stringof~
			" is not polymorphic to " ~ To.stringof);
		return opCast!To(); // use D dynamic cast
	}

	///
	pragma(inline, true)
	bool opEquals(T, this This)(in T other) const if(extends!(T, This) || extends!(This, T))
	{
		static if(extendsGodotBaseClass!T) return this is other;
		else
		{
			const void* a = owner._godot_object.ptr, b = other._godot_object.ptr;
			return a is b;
		}
	}
	///
	pragma(inline, true)
	int opCmp(T)(in T other) const if(isGodotClass!T)
	{
		const void* a = owner._godot_object.ptr, b = other.getGodotObject._godot_object.ptr;
		return a is b ? 0 : a < b ? -1 : 1;
	}

	//@disable new(size_t s);
	
	/// HACK to work around evil bug in which cast(void*) invokes `alias this`
	/// https://issues.dlang.org/show_bug.cgi?id=6777
	void* opCast(T : void*)()
	{
		import std.traits;
		alias This = typeof(this);
		static assert(!is(Unqual!This == Unqual!Base));
		union U{ void* ptr; This c; }
		U u;
		u.c = this;
		return u.ptr;
	}
	const(void*) opCast(T : const(void*))() const
	{
		import std.traits;
		alias This = typeof(this);
		static assert(!is(Unqual!This == Unqual!Base));
		union U{ const(void*) ptr; const(This) c; }
		U u;
		u.c = this;
		return u.ptr;
	}
}

package(godot) void initialize(T)(T t) if(extendsGodotBaseClass!T)
{
	import godot.node;
	
	template isOnInit(string memberName)
	{
		static if(__traits(getProtection, __traits(getMember, T, memberName)) == "public")
			enum bool isOnInit = hasUDA!( __traits(getMember, T, memberName), OnInit);
		else enum bool isOnInit = false;
	}
	foreach(n; Filter!(isOnInit, FieldNameTuple!T ))
	{
		alias M = typeof(mixin("t."~n));
		static assert(getUDAs!(mixin("t."~n), OnInit).length == 1, "Multiple OnInits on "
			~T.stringof~"."~n);
		
		enum OnInit raii = is(getUDAs!(mixin("t."~n), OnInit)[0]) ?
			OnInit.makeDefault!(M, T)() : getUDAs!(mixin("t."~n), OnInit)[0];
		
		static if(raii.autoCreate)
		{
			mixin("t."~n) = memnew!M();
			static if( raii.autoAddChild && OnInit.canAddChild!(M, T) )
			{
				t.owner.addChild( mixin("t."~n).getGodotObject );
			}
		}
	}
	
	// call _init
	foreach(mf; godotMethods!T)
	{
		enum string funcName = godotName!mf;
		alias Args = Parameters!mf;
		static if(funcName == "_init" && Args.length == 0) t._init();
	}
}

package(godot) void finalize(T)(T t) if(extendsGodotBaseClass!T)
{
}

/++
Generic null check for all Godot classes. Limitations in D prevent using `is null`
on Godot base classes because they're really struct wrappers.
+/
@nogc nothrow pragma(inline, true)
bool isNull(T)(in T t) if(isGodotClass!T)
{
	static if(extendsGodotBaseClass!T) return t is null;
	else return t._godot_object.ptr is null;
}

/++
Allocate a new T and attach it to a new Godot object.
+/
RefOrT!T memnew(T)() if(extendsGodotBaseClass!T)
{
	import godot.refcounted;
	//GodotClass!T o = GodotClass!T._new();
	auto obj = _godot_api.classdb_construct_object(godotName!T);
	assert(obj !is null);

	auto id = _godot_api.object_get_instance_id(obj);
	T o = cast(T) _godot_api.object_get_instance_from_id(id);
	//static if(extends!(T, RefCounted))
	//{
	//	bool success = o.initRef();
	//	assert(success, "Failed to init refcount");
	//}
	// Set script and let Object create the script instance
	//o.setScript(NativeScriptTemplate!T);
	// Skip typecheck in release; should always be T
	//assert(o.as!T);
	//T t = cast(T)_godot_nativescript_api.godot_nativescript_get_userdata(o._godot_object);
	//T t = cast(T) &o._godot_object;
	return refOrT(o);
}

RefOrT!T memnew(T)() if(isGodotBaseClass!T)
{
	import godot.refcounted;
	/// FIXME: block those that aren't marked instanciable in API JSON (actually a generator bug)
	T t = T._new();
	static if(extends!(T, RefCounted))
	{
		bool success = t.initRef();
		assert(success, "Failed to init refcount");
	}
	return refOrT(t); /// TODO: remove _new and use only this function?
}

void memdelete(T)(T t) if(isGodotClass!T)
{
	_godot_api.object_destroy(t.getGDNativeObject.ptr);
}

package(godot) extern(C) __gshared GDNativeInstanceBindingCallbacks _instanceCallbacks = {
	&___binding_create_callback,
	&___binding_free_callback,
	&___binding_reference_callback
};

extern(C) static void* ___binding_create_callback(void *p_token, void *p_instance) {                                     
	return null;
}                                                                                                              
extern(C) static void ___binding_free_callback(void *p_token, void *p_instance, void *p_binding) {                       
}
extern(C) static GDNativeBool ___binding_reference_callback(void *p_token, void *p_instance, GDNativeBool p_reference) { 
	return cast(GDNativeBool) true;
}

extern(C) package(godot) void* createFunc(T)(void* data) //nothrow @nogc
{
	import std.conv;

	static assert(is(T==class));
	static assert(__traits(compiles, new T()), "script class " ~ T.stringof ~ " must have default constructor");
	static import godot;

	import std.exception;
	import godot.d.register : _GODOT_library;
	
	
	enum classname = cast(const char*)(godotName!T ~ '\0');
	T t = cast(T) _godot_api.mem_alloc(__traits(classInstanceSize, T));

	emplace(t);
	// class must have default ctor to be properly initialized
	t.__ctor();

	//static if(extendsGodotBaseClass!T)
	{
		if (!t.owner._godot_object.ptr)
			t.owner._godot_object.ptr = _godot_api.classdb_construct_object((GodotClass!T)._GODOT_internal_name);
		_godot_api.object_set_instance(cast(void*) t.owner._godot_object.ptr, classname, cast(void*) t);
	}
	//else
	//	t.owner._godot_object.ptr = cast(void*) t;
	godot.initialize(t);

	_godot_api.object_set_instance_binding(cast(void*) t.owner._godot_object.ptr, _GODOT_library, cast(void*)t, &_instanceCallbacks);
	
	return cast(void*) t.owner._godot_object.ptr;
}

extern(C) package(godot) void destroyFunc(T)(void* userData, void* instance) //nothrow @nogc
{
	static import godot;
	
	T t = cast(T)instance;
	godot.finalize(t);
	_godot_api.mem_free(cast(void*) t);
	//Mallocator.instance.dispose(t);
}


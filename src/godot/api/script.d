/++
Implementation templates for new Godot-D native scripts
+/
module godot.api.script;

import std.meta, std.traits;
import std.experimental.allocator, std.experimental.allocator.mallocator;
import core.stdc.stdlib : malloc, free;

import godot.abi, godot;
import godot.api.udas;
import godot.api.traits, godot.api.wrap;
import godot.api.reference;


// for now let's keep it simple, but later this will be a proper dub config
version(Windows) version = GODOT_USE_GC_RANGE;
version(Posix) version = GODOT_USE_GC_RANGE;
version(Android) version = GODOT_USE_GC_RANGE;


/++
Base class for D native scripts. Native script instances will be attached to a
Godot (C++) object of Base class.
+/
version(USE_CLASSES)
alias GodotScript(Base) = Base;
else
class GodotScript(Base) if (isGodotBaseClass!Base) {
    // Base in this case just points to a struct that serves as a interface, it also stores the object reference for native calls
    Base _godot_base;
    alias _godot_base this;
    ref inout(godot_object) _gdextension_handle() inout @nogc nothrow { return _godot_base._godot_object; }

    /// Helper function that provides typesafe way of emitting signals using 'emit!signal()' syntax
    GodotError emit(alias Sig, Args...)(Args args) if (hasUDA!(Sig, Signal)) {
        void ohno()() {
            static assert(
                false, "Can't call signal `" ~ __traits(identifier, Sig) ~ Parameters!Sig.stringof ~ "` with parameters " ~ Args.stringof
            );
        }
        alias pointerOf(alias T) = T*;
        // careful there, param is a signal argument, Args[i] is a passed value
        static foreach(i, param; Parameters!Sig) {
            // happy path, parameter matches argument type, yay
            static if (is(Args[i] == param)) {
                // do nothing
            }
            // check if parameter is string
            else static if (is(param == String) 
                            && !(is(Args[i] : string) || is(Args[i] == String))) {
                ohno!();
            }
            // parameter is base struct script and should take a pointer as well
            else static if (isGodotBaseClass!param
                            && (is(isPointer!(Args[i])) || is(Args[i] == typeof(null)))
                            && !is(Args[i] : pointerOf!param)) {
                            //&& !is(Args[i] == typeof(null))) {
                ohno!();
            }
        }
        return emitSignal(godotName!Sig, args);
    }

    pragma(inline, true)
    inout(To) as(To)() inout if (isGodotBaseClass!To) {
        static assert(extends!(Base, To), typeof(this).stringof ~ " does not extend " ~ To.stringof);
        return cast(inout(To))(_godot_base.getGDExtensionObject);
    }

    pragma(inline, true)
    inout(To) as(To, this From)() inout if (extendsGodotBaseClass!To) {
        static assert(extends!(From, To) || extends!(To, From), From.stringof ~
                " is not polymorphic to " ~ To.stringof);
        return opCast!To(); // use D dynamic cast
    }

    ///
    pragma(inline, true)
    bool opEquals(T, this This)(in T other) const 
            if (extends!(T, This) || extends!(This, T)) {
        static if (extendsGodotBaseClass!T)
            return this is other;
        else {
            const void* a = _godot_base._godot_object.ptr, b = other._godot_object.ptr;
            return a is b;
        }
    }
    ///
    pragma(inline, true)
    int opCmp(T)(in T other) const if (isGodotClass!T) {
        const void* a = _godot_base._godot_object.ptr, b = other.getGodotObject._godot_object.ptr;
        return a is b ? 0 : a < b ? -1 : 1;
    }

    //@disable new(size_t s);

    /// HACK to work around evil bug in which cast(void*) invokes `alias this`
    /// https://issues.dlang.org/show_bug.cgi?id=6777
    void* opCast(T : void*)() {
        import std.traits;

        alias This = typeof(this);
        static assert(!is(Unqual!This == Unqual!Base));
        union U {
            void* ptr;
            This c;
        }

        U u;
        u.c = this;
        return u.ptr;
    }

    const(void*) opCast(T : const(void*))() const {
        import std.traits;

        alias This = typeof(this);
        static assert(!is(Unqual!This == Unqual!Base));
        union U {
            const(void*) ptr;
            const(This) c;
        }

        U u;
        u.c = this;
        return u.ptr;
    }
}

package(godot) void initialize(T)(T t) if (extendsGodotBaseClass!T) {
    import godot.node;

    template isOnInit(string memberName) {
        static if (__traits(getProtection, __traits(getMember, T, memberName)) == "public")
            enum bool isOnInit = hasUDA!(__traits(getMember, T, memberName), OnInit);
        else
            enum bool isOnInit = false;
    }

    foreach (n; Filter!(isOnInit, FieldNameTuple!T)) {
        alias M = typeof(mixin("t." ~ n));
        static assert(getUDAs!(mixin("t." ~ n), OnInit).length == 1, "Multiple OnInits on "
                ~ T.stringof ~ "." ~ n);

        enum OnInit raii = is(getUDAs!(mixin("t." ~ n), OnInit)[0]) ?
            OnInit.makeDefault!(M, T)() : getUDAs!(mixin("t." ~ n), OnInit)[0];

        static if (raii.autoCreate) {
            mixin("t." ~ n) = memnew!M();
            static if (raii.autoAddChild && OnInit.canAddChild!(M, T)) {
                t._godot_base.addChild(mixin("t." ~ n).getGodotObject);
            }
        }
    }

    // call _init
    foreach (mf; godotMethods!T) {
        enum string funcName = godotName!mf;
        alias Args = Parameters!mf;
        static if (funcName == "_init" && Args.length == 0)
            t._init();
    }
}

package(godot) void finalize(T)(T t) if (extendsGodotBaseClass!T) {
    destroy(t);
}

/++
Generic null check for all Godot classes. Limitations in D prevent using `is null`
on Godot base classes because they're really struct wrappers.
+/
@nogc nothrow pragma(inline, true)
bool isNull(T)(in T t) if (isGodotClass!T) {
    static if (extendsGodotBaseClass!T)
        return t is null;
    else
        return t._godot_object.ptr is null;
}

/++
Allocate a new T and attach it to a new Godot object.
+/
RefOrT!T memnew(T)() if (extendsGodotBaseClass!T) {
    import godot.refcounted;

    // NOTE: Keep in sync with register.d register(T) template
    static if (hasUDA!(T, Rename))
        enum string name = godotName!T;
    else 
        enum string name = __traits(identifier, T);

    //GodotClass!T o = GodotClass!T._new();
    auto snName = StringName(name);
    auto obj = gdextension_interface_classdb_construct_object(cast(GDExtensionStringNamePtr) snName);
    assert(obj !is null);

    // if this is a D object it was already created using `createFunc` 
    // which sets the owning D object to it returned here
    T o = cast(T) gdextension_interface_object_get_instance_binding(obj, _GODOT_library, &_instanceCallbacks);

    return refOrT(o);
}

RefOrT!T memnew(T)() if (isGodotBaseClass!T) {
    /// FIXME: block those that aren't marked instanciable in API JSON (actually a generator bug)
    version (USE_CLASSES) {
      godot_object o = T._new();
      if (!o.ptr)
          return refOrT(T.init);
      return memnew!T(o);
    }
    else
      return refOrT(T._new());
}

/// Constructs D class instance and initializes it with godot object
RefOrT!T memnew(T)(godot_object handle) {
    import godot.refcounted;
    import std.conv : emplace;
    T t = cast(T) gdextension_interface_mem_alloc(__traits(classInstanceSize, T));
    emplace(t, handle);

    static if (extends!(T, RefCounted)) {
        bool success = t.initRef();
        assert(success, "Failed to init refcount");
    }
    return refOrT(t);
}

void memdelete(T)(T t) if (isGodotClass!T) {
    gdextension_interface_object_destroy(t.getGDExtensionObject.ptr);
}

package(godot) extern (C) __gshared GDExtensionInstanceBindingCallbacks _instanceCallbacks = {
    &___binding_create_callback,
    &___binding_free_callback,
    &___binding_reference_callback
};

extern (C) static void* ___binding_create_callback(void* p_token, void* p_instance) {
    return null;
}

extern (C) static void ___binding_free_callback(void* p_token, void* p_instance, void* p_binding) {
}

extern (C) static GDExtensionBool ___binding_reference_callback(void* p_token, void* p_instance, GDExtensionBool p_reference) {
    return cast(GDExtensionBool) true;
}

extern (C) package(godot) void* createFunc(T)(void* data) //nothrow @nogc
{
    import std.conv;

    static assert(is(T == class));

    // abstract classes can't be instantiated
    static if (__traits(isAbstractClass, T)) {
        printerr("Attempted to instantiate abstract class ", godotName!T);
        return null;
    }
    else {
        static assert(__traits(compiles, new T()), "script class " ~ T.stringof ~ " must have default constructor");
    }
    static import godot;

    import std.exception;
    import godot.api.register : _GODOT_library;

    // NOTE: Keep in sync with register.d register(T) template
    static if (hasUDA!(T, Rename))
        enum string name = godotName!T;
    else 
        enum string name = __traits(identifier, T);

    enum allocSize = __traits(classInstanceSize, T);
    T t = cast(T) gdextension_interface_mem_alloc(allocSize);

    // isAbstractClass check above will not prevent codegen for this part,
    // so do this in order to allow compilation to work and to avoid putting whole function under static if
    static if (!__traits(isAbstractClass, T)) {
        version(GODOT_USE_GC_RANGE) {
            static if (!hasUDA!(T, GCSkipScan)) {
                import core.memory;
                // the default conservative GC doesn't uses this type info, but other GC's probably might use it
                GC.addRange(cast(void*)t, allocSize, typeid(T));
            }
        }
        emplace(t);
    }


    //static if(extendsGodotBaseClass!T)
    {
        StringName classname = name;
        version (USE_CLASSES) {
          static if(extendsGodotBaseClass!T) {
            // check if base class extends godot base class, because when extending D classes there is no internal name
            // TODO: refactor before the number of these checks runs out of control
            static if (isGodotBaseClass!(BaseClassesTuple!T[0])){
                StringName snInternalName = (BaseClassesTuple!T)[0]._GODOT_internal_name; // parent class name
            }
            else {
                // skip abstract base classes
                enum IsNotAbstract(T) = !__traits(isAbstractClass, T);
                // don't do godotName in this case as this can result in wrong name
                // anyway it will fail when extending GodotObject...
                import godot.object;
                static if (Filter!(IsNotAbstract, BaseClassesTuple!T).length == 0 
                            || is(Filter!(IsNotAbstract, BaseClassesTuple!T)[0] == GodotObject))
                    StringName snInternalName = StringName("Object"); 
                else
                    StringName snInternalName = __traits(identifier, Filter!(IsNotAbstract, BaseClassesTuple!T)[0]); 
            }
          } else static if (isGodotBaseClass!T)
            StringName snInternalName = T._GODOT_internal_name;
          else
            static assert(0, "Unknown class name");
        } else {
            StringName snInternalName = (GodotClass!T)._GODOT_internal_name;
        }

        const bool hasValidHandle = t._gdextension_handle.ptr !is null;
        if (!hasValidHandle) {
            // allocate backing godot object for D one
            void* obj = gdextension_interface_classdb_construct_object(cast(GDExtensionStringNamePtr) snInternalName);
            t._gdextension_handle = godot_object(obj);
        }

        gdextension_interface_object_set_instance(cast(void*) t._gdextension_handle.ptr, cast(GDExtensionStringNamePtr) classname, cast(void*) t);
    }
    //else
    //	t.owner._godot_object.ptr = cast(void*) t;
    godot.initialize(t);

    // instance bindings allows to get associated object for Godot object
    gdextension_interface_object_set_instance_binding(cast(void*) t._gdextension_handle.ptr, _GODOT_library, cast(void*) t, &_instanceCallbacks);
    

    // return back the godot object
    return cast(void*) t._gdextension_handle.ptr;
}

extern (C) package(godot) void destroyFunc(T)(void* userData, void* instance) //nothrow @nogc
{
    static import godot;

    version(GODOT_USE_GC_RANGE) {
        static if (!hasUDA!(T, GCSkipScan)) {
            import core.memory;
            GC.removeRange(instance);
        }
    }

    T t = cast(T) instance;
    godot.finalize(t);
    gdextension_interface_mem_free(cast(void*) t);
    //Mallocator.instance.dispose(t);
}

extern(C) package(godot) GDExtensionClassInstancePtr recreateFunc(T)(void* p_class_userdata, GDExtensionObjectPtr p_object) { 
    // Hot-reload is meant for development only so turn off in release builds
    debug {
        // NOTE: Keep in sync with register.d register(T) template
        static if (hasUDA!(T, Rename))
            enum string name = godotName!T;
        else 
            enum string name = __traits(identifier, T);

        auto snName = StringName(name);

        import std.conv : emplace;

        // don't do that, it will double the amount of objects on every reload
        // auto o = memnew!T();
        // instead only allocate the new native instance
        enum allocSize = __traits(classInstanceSize, T);
        T o = cast(T) gdextension_interface_mem_alloc(allocSize);
        if (o) {
            static if (!__traits(isAbstractClass, T)) { // allows it to build, abstract classes can't be instantiated anyway
                version(GODOT_USE_GC_RANGE) {
                    static if (!hasUDA!(T, GCSkipScan)) {
                        import core.memory;
                        // the default conservative GC doesn't uses this type info, but other GC's probably might use it
                        GC.addRange(cast(void*)o, allocSize, typeid(T));
                    }
                }
                emplace(o);
            }

            // set owning godot object and instance bindings for new D instance to the same Godot object
            o._gdextension_handle = godot_object(p_object);
            
            gdextension_interface_object_set_instance_binding(p_object, _GODOT_library, cast(void*) o, &_instanceCallbacks);
            
            return cast(void*) o;
        }
    }
    return null;
}

/// Returns D object associated with Godot object
version (USE_CLASSES)
RefOrT!T getObjectInstance(T)(void* godotObj)
{
    // 1. try to get any existing callback first
    if (auto obj = gdextension_interface_object_get_instance_binding(godotObj, _GODOT_library, null))
        return refOrT(cast(T) obj);
    
    // 2. find more specific callbacks
    if (auto obj = gdextension_interface_object_get_instance_binding(godotObj, _GODOT_library, &_instanceCallbacks))
        return refOrT(cast(T) obj);

    // 3. give up and allocate new D object for it...
    T o = memnew!T(godot_object(godotObj));
    return refOrT(o);
}
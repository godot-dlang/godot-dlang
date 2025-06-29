/++
Templates for binding Godot C++ classes to use from D

The binding generator will implement these templates for the classes in Godot's
API JSON.
+/
module godot.api.bind;

import std.meta, std.traits;
import std.conv : text;

import godot, godot.abi;
public import godot.refcounted;
import godot.api.traits;

/// Type to mark varargs GodotMethod.
struct GodotVarArgs {

}

package(godot) struct MethodHash {
    uint hash;
}

package(godot) struct GodotName {
    string name;
}

/++
Definition of a method from API JSON.
+/
struct GodotMethod(Return, Args...) {
    GDExtensionMethodBindPtr mb; /// MethodBind for ptrcalls
    String name; /// String name from Godot (snake_case, not always valid D)

    static if (Args.length)
        enum bool hasVarArgs = is(Args[$ - 1] : GodotVarArgs);
    else
        enum bool hasVarArgs = false;

    /+package(godot)+/
    void bind(in string className, in string methodName, in GDExtensionInt hash = 0) {
        if (mb)
            return;
        mb = gdextension_interface_classdb_get_method_bind(cast(GDExtensionStringNamePtr) StringName(className), cast(GDExtensionStringNamePtr) StringName(methodName), hash);
        name = String(methodName);
    }

    /+package(godot)+/
    void bind(in GDExtensionVariantType type, in string methodName, in GDExtensionInt hash = 0) {
        if (mb)
            return;
        mb = gdextension_interface_variant_get_ptr_builtin_method(type, cast(GDExtensionStringNamePtr) StringName(methodName), hash);
        name = String(methodName);
    }
}

struct GodotMethodStatic(Return, Args...) {    
    GodotMethod!(Return, Args) m;
    alias m this;
}

struct GodotConstructor(Return, Args...) {
    GDExtensionPtrConstructor mb; /// MethodBind for ptrcalls

    /+package(godot)+/
    void bind(in GDExtensionVariantType type, in int index) {
        if (mb)
            return;
        mb = gdextension_interface_variant_get_ptr_constructor(type, index);
    }
}

/++
Raw Method call helper
+/
Return callBuiltinMethod(Return, Args...)(in GDExtensionPtrBuiltInMethod method, GDExtensionTypePtr obj, Args args) {
    static if (!is(Return == void)) {
        Return ret = void;
        (cast(ubyte*)(&ret))[0..Return.sizeof] = 0;
    }
    else
        typeof(null) ret = null;

    //import core.stdc.string;
    //memset(&ret, 0, Return.sizeof);

    GDExtensionTypePtr[Args.length + 1] _args;
    foreach (i, ref a; args) {
        // TODO: remove this static_if hack thing once the object casts mess will be resolved
        static if (is(typeof(a) == GodotObject))
          _args[i] = cast(void*) a;
        else static if (is(typeof(a) == void*))
          _args[i] = a;
        else
        _args[i] = &a;
    }

    method(obj, _args.ptr, &ret, _args.length);
    static if (!is(Return == void))
        return ret;
}

/++
Utility function call helper, the ones not belonging to any class
+/
Return callBuiltinFunction(Return, Args...)(in GDExtensionPtrUtilityFunction func, Args args) {
    static if (!is(Return == void))
        Return ret = void;
    else
        typeof(null) ret = null;

    import core.stdc.string;
    memset(&ret, 0, Return.sizeof);

    GDExtensionTypePtr[Args.length + 1] _args;
    foreach (i, ref a; args) {
        // TODO: remove this static_if hack thing once the object casts mess will be resolved
        static if (is(typeof(a) == GodotObject))
          _args[i] = cast(void*) a;
        else static if (is(typeof(a) == void*))
          _args[i] = a;
        else
        _args[i] = cast(void*) cast() &a;
    }

    func(&ret, _args.ptr, _args.length);
    static if (!is(Return == void))
        return ret;
}

//@nogc nothrow 
pragma(inline, true)
package(godot) void checkClassBinding(C)() {
    if (!C._classBindingInitialized) {
        initializeClassBinding!C();
    }
}

/++
Raw Method call helper
+/
Return callBuiltinCtor(Return, Args...)(in GDExtensionPtrConstructor method, GDExtensionTypePtr obj, Args args) {
    static if (!is(Return == void)) {
        Return ret = void;
        (cast(ubyte*)(&ret))[0..Return.sizeof] = 0;
    }
    else
        typeof(null) ret = null;

    //import core.stdc.string;
    //memset(&ret, 0, Return.sizeof);

    GDExtensionTypePtr[Args.length + 1] _args;
    foreach (i, ref a; args) {
        // TODO: remove this static_if hack thing once the object casts mess will be resolved
        static if (is(typeof(a) == GodotObject))
          _args[i] = cast(void*) a;
        else static if (is(typeof(a) == void*))
          _args[i] = a;
        else
        _args[i] = &a;
    }

    method(obj, _args.ptr);

    // TODO: there is actually no return as this call is ctor call on an already allocated object
    static if (!is(Return == void)) {
        return ret;
    }
}

// these have same order as in GDExtensionVariantType
private immutable enum coreTypes = [
        "Nil", "Bool", "Int", "Float", "String",

        "Vector2", "Vector2i", "Rect2", "Rect2i", "Vector3",
        "Vector3i", "Transform2D", "Vector4", "Vector4i",
        "Plane", "Quaternion", "AABB", "Basis", "Transform3D", "Projection",

        "Color", "StringName", "NodePath", "RID", "Object",
        "Callable", "Signal", "Dictionary", "Array",

        "PackedByteArray", "PackedInt32Array", "PackedInt64Array",
        "PackedFloat32Array",
        "PackedFloat64Array", "PackedStringArray", "PackedVector2Array",
        "PackedVector3Array",
        "PackedColorArray",
    ];

//@nogc nothrow 
pragma(inline, false)
package(godot) void initializeClassBinding(C)() {
    import std.algorithm;
    import std.string : indexOf;

    synchronized {
        if (!C._classBindingInitialized) {
            static foreach (n; __traits(allMembers, C.GDExtensionClassBinding)) {
                static if (n == "_singleton")
                    C.GDExtensionClassBinding._singleton = godot_object(
                        gdextension_interface_global_get_singleton(
                            cast(GDExtensionStringNamePtr) StringName(C.GDExtensionClassBinding._singletonName)));
                else static if (n == "_singletonName") {
                } else {
                    // core types require special registration for built-in types
                    static if (coreTypes.canFind(C._GODOT_internal_name)) {
                        static if (isInstanceOf!(GodotConstructor, __traits(getMember, C.GDExtensionClassBinding, n))) {
                            // binds constructor using GDExtensionVariantType and index
                            __traits(getMember, C.GDExtensionClassBinding, n).bind(
                                cast(int) coreTypes.countUntil(C._GODOT_internal_name),
                                to!int(getUDAs!(mixin("C.GDExtensionClassBinding." ~ n), GodotName)[0].name[$ - 2 .. $ - 1]), // get last number from name in form of "_new_2"
                                
                            );
                        } else {
                            // binds native built-in method
                            __traits(getMember, C.GDExtensionClassBinding, n).bind(
                                cast(int) coreTypes.countUntil(C._GODOT_internal_name),
                                getUDAs!(mixin("C.GDExtensionClassBinding." ~ n), GodotName)[0].name,
                                getUDAs!(mixin("C.GDExtensionClassBinding." ~ n), MethodHash)[0].hash,
                            );
                        }
                    } else static if (C.stringof.endsWith("Singleton")) {
                        // do nothing, let singleton load all methods on demand through getter check
                    } else {
                        //enum immutable(char*) cn = C._GODOT_internal_name;
                        __traits(getMember, C.GDExtensionClassBinding, n).bind(
                            C._GODOT_internal_name,
                            getUDAs!(__traits(getMember, C.GDExtensionClassBinding, n), GodotName)[0].name,
                            0 //getUDAs!(__traits(getMember, C.GDExtensionClassBinding, n), MethodHash)[0].hash,
                        
                        );
                    }
                }
            }
            C._classBindingInitialized = true;
        }
    }
}

enum bool needsConversion(Src, Dest) = !isGodotClass!Dest && !is(Src : Dest);

/// temporary var if conversion is needed
template tempType(Src, Dest) {
    static if (needsConversion!(Src, Dest))
        alias tempType = Dest;
    else
        alias tempType = void[0];
}

/++
Direct pointer call through MethodBind.
+/
RefOrT!Return ptrcall(Return, MB, Args...)(MB method, in godot_object self, Args args)
in {
    static if (!isInstanceOf!(GodotMethodStatic, MB))
    debug if (self.ptr is null) {
        auto utf8 = (String("Method ") ~ method.name ~ String(" called on null reference")).utf8;
        auto msg = cast(char[]) utf8.data[0 .. utf8.length];
        assert(0, msg);
    }
}
do {
    import std.typecons;
    import std.range : iota;

    alias MBArgs = TemplateArgsOf!(MB)[1 .. $];
    static assert(Args.length == MBArgs.length);

    static if (Args.length != 0) {
        alias _iota = aliasSeqOf!(iota(Args.length));
        alias _tempType(size_t i) = tempType!(Args[i], MBArgs[i]);
        const(void)*[Args.length] aarr = void;

        Tuple!(staticMap!(_tempType, _iota)) temp = void;
    }
    foreach (ai, A; Args) {
        static if (isGodotClass!A) {
            static assert(is(Unqual!A : MBArgs[ai]) || staticIndexOf!(
                    MBArgs[ai], GodotClass!A.GodotClass) != -1, "method" ~
                    " argument " ~ ai.text ~ " of type " ~ A.stringof ~
                    " does not inherit parameter type " ~ MBArgs[ai].stringof);
            aarr[ai] = &(args[ai]);
        } else static if (!needsConversion!(Args[ai], MBArgs[ai])) {
            aarr[ai] = cast(const(void)*)(&args[ai]);
        } else // needs conversion
        {
            static assert(is(typeof(MBArgs[ai](args[ai]))), "method" ~
                    " argument " ~ ai.text ~ " of type " ~ A.stringof ~
                    " cannot be converted to parameter type " ~ MBArgs[ai].stringof);

            import std.conv : emplace;

            emplace(&temp[ai], args[ai]);
            aarr[ai] = cast(const(void)*)(&temp[ai]);
        }
    }

    // because class is a just a pointer to an actual memory
    // we have to do extra work later compared to structs version
    version(USE_CLASSES) {
      static if (isGodotClass!Return) {
        godot_object r;
      }
      else static if (!is(Return : void))
        RefOrT!Return r = godotDefaultInit!(RefOrT!Return);
    }
    else static if (!is(Return : void))
        RefOrT!Return r = godotDefaultInit!(RefOrT!Return);

    static if (is(Return : void))
        alias rptr = Alias!null;
    else
        void* rptr = cast(void*)&r;

    static if (Args.length == 0)
        alias aptr = Alias!null;
    else
        const(void)** aptr = aarr.ptr;

    gdextension_interface_object_method_bind_ptrcall(method.mb, cast(GDExtensionObjectPtr) self.ptr, aptr, rptr);

    version(USE_CLASSES) {
      static if (isGodotClass!Return)
        return getObjectInstance!Return(r.ptr);
      else static if (!is(Return : void))
        return r;
    }
    else {
      static if (!is(Return : void))
        return r;
    }
}

/++
Variant call, for virtual and vararg methods.

Forwards to `callv`, but does compile-time type check of args other than varargs.
+/
Return callv(MB, Return, Args...)(MB method, godot_object self, Args args)
in {
    import std.experimental.allocator, std.experimental.allocator.mallocator;

    debug if (self.ptr is null) {
        CharString utf8 = (String("Method ") ~ method.name ~ String(" called on null reference"))
            .utf8;
        auto msg = utf8.data;
        assert(0, msg); // leak msg; Error is unrecoverable
    }
}
do {
    alias MBArgs = TemplateArgsOf!(MB)[1 .. $];

    import godot.object;

    GodotObject o = void;
    o._godot_object = self;

    Array a = Array.make();
    static if (Args.length != 0)
        a.resize(cast(int) Args.length);
    foreach (ai, A; Args) {
        static if (is(MBArgs[$ - 1] : GodotVarArgs) && ai >= MBArgs.length - 1) {
            // do nothing
        } else {
            static assert(ai < MBArgs.length, "Too many arguments");
            static assert(is(A : MBArgs[ai]) || isImplicitlyConvertible!(A, MBArgs[ai]),
                "method" ~ " argument " ~ ai.text ~ " of type " ~ A.stringof ~
                    " cannot be converted to parameter type " ~ MBArgs[ai].stringof);
        }
        a[ai] = args[ai];
    }

    Variant r = o.callv(method.name, a);
    return r.as!Return;
}

/++
Virtual method call
+/
bool vcall(alias fn, T, Args...)(in T self, out ReturnType!fn ret,  Args args) {
    import std.typecons;
    import std.range : iota;

    alias Return = ReturnType!fn;
    //static assert(hasUDA!(fn, Virtual), "This call is only for virtual godot methods.");

    static if (Args.length != 0) {
        alias _iota = aliasSeqOf!(iota(Args.length));
        alias _tempType(size_t i) = tempType!(Args[i], MBArgs[i]);
        const(void)*[Args.length] aarr = void;

        Tuple!(staticMap!(_tempType, _iota)) temp = void;
    }
    foreach (ai, A; Args) {
        static if (isGodotClass!A) {
            static assert(is(Unqual!A : Args[ai]) || staticIndexOf!(
                    Args[ai], GodotClass!A.GodotClass) != -1, "method" ~
                    " argument " ~ ai.text ~ " of type " ~ A.stringof ~
                    " does not inherit parameter type " ~ Args[ai].stringof);
            aarr[ai] = &(args[ai]);
        } else static if (!needsConversion!(Args[ai], Args[ai])) {
            aarr[ai] = cast(const(void)*)(&args[ai]);
        } else // needs conversion
        {
            static assert(is(typeof(Args[ai](args[ai]))), "method" ~
                    " argument " ~ ai.text ~ " of type " ~ A.stringof ~
                    " cannot be converted to parameter type " ~ Args[ai].stringof);

            import std.conv : emplace;

            emplace(&temp[ai], args[ai]);
            aarr[ai] = cast(const(void)*)(&temp[ai]);
        }
    }

    // because class is a just a pointer to an actual memory
    // we have to do extra work later compared to structs version
    version(USE_CLASSES) {
      static if (isGodotClass!Return) {
        godot_object r;
      }
      else static if (!is(Return : void))
        RefOrT!Return r = godotDefaultInit!(RefOrT!Return);
    }
    else static if (!is(Return : void))
        RefOrT!Return r = godotDefaultInit!(RefOrT!Return);

    static if (is(Return : void))
        alias rptr = Alias!null;
    else
        Variant vret;

    static if (Args.length == 0)
        alias aptr = Alias!null;
    else
        const(void)** aptr = aarr.ptr;

    StringName sn = StringName(godotName!fn);
    GDExtensionCallError ce;
    godot_object _this; // this can be const but it is not possible to assign later on
    static if (is(T == godot_object)) {
        _this = cast() self;
    }
    else {
        _this = cast() self._gdextension_handle();
    }
    if (gdextension_interface_object_has_script_method(cast(void*) _this.ptr, cast(void*) sn)) {
        gdextension_interface_object_call_script_method(cast(void*) _this.ptr, cast(void*) sn, aptr, Args.length, &vret, &ce);
        if (ce == cast(GDExtensionCallError) GDEXTENSION_CALL_OK) {
            version(USE_CLASSES) {
              static if (isGodotClass!Return)
                ret = getObjectInstance!Return(r.ptr);
              else static if (!is(Return : void))
                ret = vret.as!Return;
            }
            else {
              static if (!is(Return : void))
                ret = vret.as!Return;
            }
            return true;
        }
    }

    return false;

}

/++
Virtual method call
This one uses godot_object directly and does not do any validation except type-to-variant availability check.
Primarily useful for dynamic scripting or with script types not known at compile time.
method name to call is expected to be in godot style, e.g. 'do_something_with_foo'
+/
bool vcallRaw(Return = GodotObject, T, Args...)(in T self, string fn, out Return ret, Args args) { // UNTESTED
    import std.typecons;
    import std.range : iota;

    //static assert(hasUDA!(fn, Virtual), "This call is only for virtual godot methods.");

    static if (Args.length != 0) {
        alias _iota = aliasSeqOf!(iota(Args.length));
        alias _tempType(size_t i) = Variant.conversionToGodotType!(Args[i]);
        const(void)*[Args.length] aarr = void;

        Tuple!(staticMap!(_tempType, _iota)) temp = void;
    }
    foreach (ai, A; Args) {
        static if (isGodotClass!A) {
            static assert(is(Unqual!A : Args[ai]) || staticIndexOf!(
                    Args[ai], GodotClass!A.GodotClass) != -1, "method" ~
                    " argument " ~ ai.text ~ " of type " ~ A.stringof ~
                    " does not inherit parameter type " ~ Args[ai].stringof);
            aarr[ai] = &(args[ai]);
        } else static if (!needsConversion!(Args[ai], Args[ai])) {
            aarr[ai] = cast(const(void)*)(&args[ai]);
        } else // needs conversion
        {
            static assert(is(typeof(Args[ai](args[ai]))), "method" ~
                    " argument " ~ ai.text ~ " of type " ~ A.stringof ~
                    " cannot be converted to parameter type " ~ Args[ai].stringof);

            import std.conv : emplace;

            emplace(&temp[ai], args[ai]);
            aarr[ai] = cast(const(void)*)(&temp[ai]);
        }
    }

    // because class is a just a pointer to an actual memory
    // we have to do extra work later compared to structs version
    version(USE_CLASSES) {
      static if (isGodotClass!Return) {
        godot_object r;
      }
      else static if (!is(Return : void))
        RefOrT!Return r = godotDefaultInit!(RefOrT!Return);
    }
    else static if (!is(Return : void))
        RefOrT!Return r = godotDefaultInit!(RefOrT!Return);

    static if (is(Return : void))
        alias rptr = Alias!null;
    else
        Variant vret;

    static if (Args.length == 0)
        alias aptr = Alias!null;
    else
        const(void)** aptr = aarr.ptr;

    StringName sn = StringName(fn);
    GDExtensionCallError ce;
    godot_object _this;
    static if (is(T == godot_object)) {
        _this = cast() self;
    }
    else {
        _this = cast() self._gdextension_handle();
    }
    if (gdextension_interface_object_has_script_method(cast(void*) _this.ptr, cast(void*) sn)) {
        gdextension_interface_object_call_script_method(cast(void*) _this.ptr, cast(void*) sn, aptr, Args.length, &vret, &ce);
        if (ce == cast(GDExtensionCallError) GDEXTENSION_CALL_OK) {
            version(USE_CLASSES) {
              static if (isGodotClass!Return)
                ret = getObjectInstance!Return(r.ptr);
              else static if (!is(Return : void))
                ret = vret.as!Return;
            }
            else {
              static if (!is(Return : void))
                ret = vret.as!Return;
            }
            return true;
        }
    }

    return false;

}

package(godot)
mixin template baseCasts() {
    private import godot.api.reference, godot.api.traits : RefOrT, NonRef;

    inout(To) as(To)() inout if (isGodotBaseClass!To) {
        static if (extends!(typeof(this), To)) {
            version(USE_CLASSES)
              return this;
            else
              return cast(inout) To(cast() _godot_object);
        } else static if (extends!(To, typeof(this))) {
            if (_godot_object.ptr is null)
                return typeof(return).init;
            StringName classname = StringName(To._GODOT_internal_name);
            if (auto tag = gdextension_interface_classdb_get_class_tag(cast(GDExtensionStringNamePtr) classname)) {
                if (auto obj = gdextension_interface_object_cast_to(cast(void*) _godot_object.ptr, tag)) {
					version (USE_CLASSES) {
                      auto tmp = getObjectInstance!(To)(obj); // note: doesn't holds Ref, be careful
                      static if (is(To : RefCounted)) {
                        tmp.reference(); // FIXME: hack that makes it hold ref
                      }
                      To ret = tmp;
                      return cast(inout) ret;
					} else {
                      return inout(To)(typeof(_godot_object)(cast(inout) obj));
                    }
                }
            }
            return typeof(return).init;
        } else
            static assert(0, To.stringof ~ " is not polymorphic to "
                    ~ typeof(this).stringof);
    }

    inout(ToRef) as(ToRef)() inout 
            if (is(ToRef : Ref!To, To) && extends!(To, RefCounted)) {
        import std.traits : TemplateArgsOf, Unqual;

        ToRef ret = cast() as!(Unqual!(TemplateArgsOf!ToRef[0]));
        return cast(inout) ret;
    }

    inout(To) as(To)() inout if (extendsGodotBaseClass!To) {
        godot_object go = cast() _godot_object;
        return cast(inout(To)) gdextension_interface_object_get_instance_binding(go.ptr, _GODOT_library, &_instanceCallbacks);
    }


    version(USE_CLASSES)
    template opCast(To) if (isGodotBaseClass!To || extendsGodotBaseClass!To) {
        alias opCast = as!To;
    }
    else {
    template opCast(To) if (isGodotBaseClass!To) {
        alias opCast = as!To;
    }
    template opCast(To) if (extendsGodotBaseClass!To) {
        alias opCast = as!To;
    }
    } // else version 

    template opCast(ToRef) if (is(ToRef : Ref!To, To) && extends!(To, RefCounted)) {
        alias opCast = as!ToRef;
    }

    // this cast is used when passing parameters in ptrcall
    // classes can be used as is, but for struct we need godot object ptr
    version(USE_CLASSES) {
      void* opCast(T : void*)() const {
        return cast(void*) cast() super;
      }
    } else {
      // void* cast for passing this type to ptrcalls
      package(godot) void* opCast(T : void*)() const {
          return cast(void*) _godot_object.ptr;
      }
    }
    // strip const, because the C API sometimes expects a non-const godot_object
    godot_object opCast(T : godot_object)() const {
        return cast(godot_object) _godot_object;
    }
    // implicit conversion to bool like D class references
    bool opCast(T : bool)() const {
        return _godot_object.ptr !is null;
    }
}

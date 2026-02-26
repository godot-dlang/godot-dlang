/++
Compile-time introspection of Godot types
+/
module godot.api.traits;

import godot.util.string;
import godot.api.udas;
import godot.api.reference;

import std.meta, std.traits;

import godot, godot.abi;
import godot.object;

/// https://p0nce.github.io/d-idioms/#Bypassing-@nogc
/// Casts @nogc out of a function or delegate type.
auto assumeNoGC(T)(T t) if (isFunctionPointer!T || isDelegate!T) {
    enum attrs = functionAttributes!T | FunctionAttribute.nogc;
    return cast(SetFunctionAttributes!(T, functionLinkage!T, attrs)) t;
}

@nogc nothrow:

template from(string moduleName) {
    mixin("import from = " ~ moduleName ~ ";");
}

/++
Adds the Ref wrapper to T, if T is a Reference type
+/
template RefOrT(T) {
    import godot.refcounted;

    static if (isGodotClass!T && extends!(T, RefCounted))
        alias RefOrT = Ref!T;
    else
        alias RefOrT = T;
}

/++
Removes the Ref wrapper from R, if present
+/
template NonRef(R) {
    static if (is(R : Ref!T, T))
        alias NonRef = T;
    else
        alias NonRef = R;
}

/++
A UDA with which base Godot classes are marked. NOT used by new D classes.
+/
package(godot) enum GodotBaseClass;

/++
Determine if T is a class originally from the Godot Engine (but *not* a new D
class registered to Godot).
+/
template isGodotBaseClass(T) {
    version (USE_CLASSES) {
      static if (is(T == class))
        enum bool isGodotBaseClass = hasUDA!(T, GodotBaseClass);
      else
        enum bool isGodotBaseClass = false;
    } else {
      static if (is(T == struct))
        enum bool isGodotBaseClass = hasUDA!(T, GodotBaseClass);
      else
        enum bool isGodotBaseClass = false;
    }
    
}

/++
Determine if T is a D native script (extends a Godot base class).
+/
template extendsGodotBaseClass(T) {
    version (USE_CLASSES) {
      enum extendsFromGodotObject(alias C) = hasUDA!(C, GodotBaseClass);
      static if (is(T == class) && !hasUDA!(T, GodotBaseClass)) {
        enum bool extendsGodotBaseClass = Filter!(extendsFromGodotObject, BaseClassesTuple!(T)).length > 0;
      } else
        enum bool extendsGodotBaseClass = false;
    }
    else {
      static if (is(T == class) && hasMember!(T, "_godot_base")) {
        enum bool extendsGodotBaseClass = isGodotBaseClass!(typeof(T._godot_base));
      } else
        enum bool extendsGodotBaseClass = false;
    }
}

/++
A list of all of T's base classes, both script and C++, ending with GodotObject.

Has the same purpose as std.traits.BaseClassesTuple, but accounts for Godot's
script inheritance system.
+/
version (USE_CLASSES)
alias GodotBaseClasses = BaseClassesTuple;
else
template GodotBaseClasses(T) {
    static if (isGodotBaseClass!T)
        alias GodotBaseClasses = T.BaseClasses;
    else static if (extendsGodotBaseClass!T) {
        import std.traits : BaseClassesTuple;

        // the last two D base classes are GodotScript!<Base> and Object.
        alias GodotBaseClasses = AliasSeq!(BaseClassesTuple!(Unqual!T)[0 .. $ - 2],
            GodotClass!T, GodotClass!T.BaseClasses);
    }
}

/++
Checks whether R is a subtype of ParentR by Godot's script inheritance system.
Both D script and C++ classes are accounted for.
If R and ParentR are the same, `extends` is true as well.
+/
template extends(R, ParentR) {
    alias T = NonRef!R;
    alias Parent = NonRef!ParentR;
    version (USE_CLASSES) {
      static if (is(T == class))
      {
        static if (is(Unqual!T : Unqual!Parent))
          enum bool extends = true;
        else
          enum bool extends = staticIndexOf!(Unqual!Parent, GodotBaseClasses!T) != -1;
      }
      else
        enum bool extends = false;
    } else {
      static if (is(Unqual!T : Unqual!Parent))
        enum bool extends = true;
      else
        enum bool extends = staticIndexOf!(Unqual!Parent, GodotBaseClasses!T) != -1;
    }
    
}

/++
Get the Godot class of R (the class of the `owner` for D native scripts)
+/
template GodotClass(R) {
    alias T = NonRef!R;
    static if (isGodotBaseClass!T)
        alias GodotClass = T;
    else static if (extendsGodotBaseClass!T) {
        version (USE_CLASSES)
          alias GodotClass = T; // when using classes this should work through normal inheritance
        else
          alias GodotClass = typeof(T._godot_base);
    }
}


/++
Get the first ancestor of the type that is a Godot base class
+/
template GodotBaseOf(R) {
    alias T = NonRef!R;
    static if (isGodotBaseClass!T)
        alias GodotBaseOf = T;
    else static if (extendsGodotBaseClass!T) {
        alias GodotBaseOf = Filter!(isGodotBaseClass, GodotBaseClasses!T)[0];
    }
}

/++
Determine if T is any Godot class (base C++ class or D native script, but NOT
a godot struct)
+/
enum bool isGodotClass(T) = extendsGodotBaseClass!T || isGodotBaseClass!T;

/++
Get the C++ Godot Object pointer of either a Godot Object OR a D native script.

Useful for generic code.
+/
version (USE_CLASSES)
T getGodotObject(T)(in T t) if (isGodotClass!T) {
    // NOTE: signature kept for structs version and it is incorrect,
    // the returned value is godot object pointer and not a D object
    if (t is null)
        return null;
    return cast(T) t._gdextension_handle.ptr;
}
else
GodotClass!T getGodotObject(T)(in T t) if (isGodotClass!T) {
    GodotClass!T ret;
    ret._godot_object = t.getGDExtensionObject;
    return ret;
}

version (USE_CLASSES)
NonRef!R getGodotObject(R)(auto ref R r) if (is(R : Ref!U, U)) {
    return r._reference;
}
else
GodotClass!(NonRef!R) getGodotObject(R)(auto ref R r) if (is(R : Ref!U, U)) {
    return r._reference;
}

package(godot) godot_object getGDExtensionObject(T)(in T t) if (isGodotClass!T) {
    version (USE_CLASSES)
      return  t ? cast(godot_object) t._gdextension_handle : godot_object.init;
    else {
      static if (isGodotBaseClass!T)
          return cast(godot_object) t._godot_object;
      static if (extendsGodotBaseClass!T) {
          return (t) ? cast(godot_object) t._gdextension_handle : godot_object.init;
      }
    }
}

package(godot) godot_object getGDExtensionObject(R)(auto ref R r) if (is(R : Ref!U, U)) {
    return cast() r._reference._gdextension_handle;
}

/++
Alias to default-constructed T, as an expression.

A few Godot core types can't use D's `init` because they need to call a C++
constructor through GDExtension.
+/
template godotDefaultInit(T) {
    static if (is(T : Array))
        alias godotDefaultInit = Alias!(Array.make);
    else static if (is(T : Dictionary))
        alias godotDefaultInit = Alias!(
            Dictionary.make);
    else
        alias godotDefaultInit = Alias!(T.init);
}

/++
Get the Godot-compatible default value of a field in T.
+/
auto getDefaultValueFromAlias(T, string fieldName)() {
    alias a = Alias!(mixin("T." ~ fieldName));
    alias P = typeof(a);

    static if (hasUDA!(a, DefaultValue)) {
        alias defExprSeq = TemplateArgsOf!(getUDAs!(a, DefaultValue)[0]);
        static if (isCallable!(defExprSeq[0]))
            return defExprSeq[0]();
        else
            return defExprSeq[0];
    } else static if (is(typeof({ P p; }))) {
        import godot.math : isNaN;
        static if (isFloatingPoint!P && a.init.isNaN) {
            // Godot doesn't support NaNs. Initialize properties to 0.0 instead.
            return P(0.0);
        } else
            return a.init;
    } else {
        return Variant.init;
    }
}

package(godot) enum string dName(alias a) = __traits(identifier, a);
package(godot) template godotName(alias a) {
    alias udas = getUDAs!(a, Rename);
    static if (udas.length == 0) {
        static if (is(a == class) || is(a == struct)) {
            import std.string;

            // for classes keep using upper-case type name to match godot style
            enum string godotName = __traits(identifier, a).capitalize;
        } else {
            version (GodotNoAutomaticNamingConvention)
                enum string godotName = __traits(identifier, a);
            else
                enum string godotName = __traits(identifier, a).camelToSnake;
        }
    } else {
        static assert(udas.length == 1, "Multiple Rename UDAs on " ~
                fullyQualifiedName!a ~ "? Why?");

        static if (is(udas[0]))
            static assert(0, "Construct the UDA with a string: @Rename(\"name\")");
        else {
            enum Rename uda = udas[0];
            enum string godotName = uda.name;
        }
    }
}

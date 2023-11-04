module godot.api.reference;

import std.meta, std.traits; // std.typecons;
import std.algorithm : swap;

import godot, godot.abi;
import godot.refcounted, godot.object;
import godot.api.traits, godot.api.script;

/// Ref-counted container for Reference types
struct Ref(T) {
    static assert(extends!(T, RefCounted), "Ref may only be used with Reference-derived classes. Other Godot classes are not reference-counted.");
    static assert(!is(T == const), "Ref cannot contain a const Reference");
    //@nogc nothrow:

    static if (isGodotBaseClass!T) {
        package(godot) T _reference;
        alias _self = _reference;
    } else {
        package(godot) T _self;
        pragma(inline, true)
        package(godot) GodotClass!T _reference() {
            return (_self) ? _self.owner : GodotClass!T.init;
        }
    }

    /++
	Returns the reference without allowing it to escape the calling scope.
	
	TODO: dip1000
	+/
    T refPayload() const {
        return cast() _self;
    }

    alias refPayload this;

    ref Ref opAssign(T other) {
        if (_self.getGodotObject == other.getGodotObject)
            return this;
        unref();
        _self = other;
        if (_self)
            _reference.reference();
        return this;
    }

    ref Ref opAssign(R)(ref R other) if (is(R : Ref!U, U) && extends!(T, U)) {
        opAssign(other._self);
        return this;
    }

    ref Ref opAssign(R)(R other) if (is(R : Ref!U, U) && extends!(T, U)) {
        swap(_self, other);
        return this;
    }

    void unref() {
        if (_self && _reference.unreference()) {
            gdextension_interface_object_destroy(_reference._godot_object.ptr);
            static if (__traits(hasMember, T, "__xdtor"))
                _self.__xdtor();
        }
        _self = T.init;
    }

    Ref!U as(U)() if (isGodotClass!U && !is(U == GodotObject)) {
        // the only non-Reference this can possibly be is Object, so no need to account for non-Refs
        static assert(extends!(U, T) || extends!(T, U),
            U.stringof ~ " is not polymorphic to " ~ T.stringof);
        Ref!U ret = _self.as!U;
        return ret;
    }

    template as(R) if (is(R : Ref!U, U) && isGodotClass!(NonRef!R)) {
        alias as = as!(NonRef!R);
    }

    GodotObject as(R)() if (is(Unqual!R == GodotObject)) {
        return _reference;
    }

    template opCast(R) if (isGodotClass!(NonRef!R)) {
        alias opCast = as!R;
    }

    pragma(inline, true)
    bool opEquals(R)(in auto ref R other) const {
        return _self.getGDExtensionObject!T == other.getGDExtensionObject!T;
    }

    pragma(inline, true)
    bool isValid() const {
        return _self.getGodotObject != GodotClass!T.init;
    }

    alias opCast(T : bool) = isValid;
    pragma(inline, true)
    bool isNull() const {
        return _self.getGodotObject == GodotClass!T.init;
    }

    this(this) {
        if (_self)
            _reference.reference();
    }

    /++
	Construct from other reference
	+/
    this(T other) {
        _self = other;
        if (_self)
            _reference.reference();
    }

    this(R)(ref R other) if (is(R : Ref!U, U) && extends!(T, U)) {
        _self = other._self;
        if (_self)
            _reference.reference();
    }

    this(R)(R other) if (is(R : Ref!U, U) && extends!(T, U)) {
        swap(_self, other);
    }

    ~this() {
        unref();
    }
}

/++
Create a Ref from a pointer without incrementing refcount.
+/
package(godot) RefOrT!T refOrT(T)(T instance) {
    static if (extends!(T, RefCounted)) {
        Ref!T ret = void;
        ret._self = instance;
        return ret;
    } else
        return instance;
}

/++
Create a Ref from a pointer and increment refcount.
+/
package(godot) RefOrT!T refOrTInc(T)(T instance) {
    static if (extends!(T, RefCounted)) {
        Ref!T ret = void;
        ret._self = instance;
        if (ret._self)
            ret._reference.reference();
        return ret;
    } else
        return instance;
}

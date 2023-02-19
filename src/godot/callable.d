module godot.callable;

import godot.abi;
import godot.variant;
import godot.object;
import godot.array;
import godot.stringname;
import godot.builtins;

/// Untyped Callable that binds directly to Godot's Callable
struct GodotCallable {
    package(godot) union callable {
        godot_callable _godot_callable;
        GodotCallable_Bind _bind;
    }

    package(godot) callable _callable;
    alias _callable this;

    package(godot) this(godot_callable opaque) {
        _godot_callable = opaque;
    }

    this(ref scope const GodotCallable other) {
        _callable = other._callable;
    }


    this(in GodotObject object, in StringName method) {
        this = _bind.new2(object, method);
    }

    this(in GodotObject object, in string method) {
        StringName snMethod = method;
        this = _bind.new2(object, snMethod);
    }

    void _defaultCtor() {
        _bind.new0();
    }

    ~this() {
        _bind._destructor();
    }

    Variant callv(in Array arguments) const {
        return _bind.callv(arguments);
    }

    Variant call(Args...)(Args args) const {
        return _bind.call(args);
    }

    Variant callDeferred(Args...)(Args args) const {
        return _bind.callDeferred(args);
    }

    void rpc(Args...)(Args args) const {
        return _bind.rpc(args);
    }

    void rpcId(Args...)(long peerId, Args args) const {
        return _bind.rpcId(peerId, args);
    }

    bool isNull() const {
        return _bind.isNull();
    }

    bool isCustom() const {
        return _bind.isCustom();
    }

    bool isStandard() const {
        return _bind.isStandard();
    }

    bool isValid() const {
        return _bind.isValid();
    }

    GodotObject getObject() const {
        return _bind.getObject();
    }

    ObjectID getObjectId() const {
        return ObjectID(_bind.getObjectId());
    }

    StringName getMethod() const {
        return _bind.getMethod();
    }

    long getBoundArgumentsCount() const {
        return _bind.getBoundArgumentsCount();
    }

    Array getBoundArguments() const {
        return _bind.getBoundArguments();
    }

    long hash() const {
        return _bind.hash();
    }

    GodotCallable bindv(in Array arguments) {
        return _bind.bindv(arguments);
    }

    GodotCallable unbind(in long argcount) const {
        return _bind.unbind(argcount);
    }

    GodotCallable bind(Args...)(Args args) const {
        return _bind.bind(args);
    }
}


/// Type-safe Callable wrapper around Godot's Callable
version(none) struct GodotCallableT(Return, Args...) {
    GodotCallable _impl;

    this(GodotCallable callable) {
        _impl = callable;
    }

    ref typeof(this) opAssign(GodotCallable value)
    {
        _impl = value;
        return this;
    }

    Return call(Args args) {
        static if (is(Return == void))
            _impl.call(args);
        else
            return _impl.call(args);
    }
}

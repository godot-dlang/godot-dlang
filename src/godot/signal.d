module godot.signal;

import godot.abi;
import godot.builtins;
import godot.object;

struct GodotSignal {
    package(godot) union signal {
        godot_signal _godot_signal;
        GodotSignal_Bind _bind;
    }

    package(godot) signal _signal;
    alias _signal this;

    package(godot) this(godot_signal opaque) {
        _godot_signal = opaque;
    }

    this(ref scope const GodotSignal other) {
        _signal = other._signal;
    }

    this(in GodotObject object, in StringName signal) {
        this = _bind.new2(object, signal);
    }

    this(in GodotObject object, in string signal) {
        StringName snSignal = signal;
        this = _bind.new2(object, snSignal);
    }

    void _defaultCtor() {
        _bind.new0();
    }

    ~this() {
        _bind._destructor();
    }

    void emit(Args...)(Args args) {
        _bind.emit(args);
    }

    bool isNull() const {
        return _bind.isNull();
    }

    GodotObject getObject() const {
        return _bind.getObject();
    }

    ObjectID getObjectId() const {
        return ObjectID(_bind.getObjectId());
    }

    StringName getName() const {
        return _bind.getName();
    }

    int connect(in GodotCallable callable, in int flags = 0) {
        return cast(int) _bind.connect(callable, flags);
    }

    void disconnect(in GodotCallable callable) {
        _bind.disconnect(callable);
    }

    bool isConnected(in GodotCallable callable) const {
        return _bind.isConnected(callable);
    }

    Array getConnections() const {
        return _bind.getConnections();
    }

    void emit(Args...)(Args args) const {
        _bind.emit(args);
    }
}

/// Type-safe Signal wrapper around Godot's Signal
version(none) struct GodotSignalT(string Name, Args...) {

    GodotSignal _impl;

    enum string name = Name;

    this(GodotSignal sig) {
        _impl = sig;
    }

    ref typeof(this) opAssign(GodotSignal value)
    {
        _impl = value;
        return this;
    }

    void emit(Args args) {
        _impl.emit(args);
    }
}

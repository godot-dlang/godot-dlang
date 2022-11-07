module godot.core.callable;

import godot.abi;
import godot.builtins;

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
}

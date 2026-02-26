/++
Custom minimal runtime type information.

Provides building blocks for safe runtime casting without relying on D's `TypeInfo`.
+/
module godot.api.rtti;

import godot.api.traits : extendsGodotBaseClass;
import std.traits : BaseClassesTuple;

package(godot) struct RTTITag {
    const(RTTITag)* parent = null;
}

package(godot) const(RTTITag)* rttiTag(T)() if (extendsGodotBaseClass!T) {
    import core.builtins : unlikely;
    import core.atomic : atomicLoad, atomicStore, MemoryOrder;

    // tag's value is pointer to parent tag
    __gshared RTTITag tag;

    alias ParentClass = BaseClassesTuple!T[0];
    static if (extendsGodotBaseClass!ParentClass) {
        // Initialize tag parent lazily and safely (atomic).
        if (unlikely(tag.parent.atomicLoad!(MemoryOrder.acq) == null)) {
            tag.parent.atomicStore!(MemoryOrder.rel)(rttiTag!ParentClass);
        }
    }

    return &tag;
}

private bool rttiIsInstanceOf(const(RTTITag)* runtimeType, const(RTTITag)* targetType) {
    while (runtimeType) {
        if (runtimeType == targetType) {
            return true;
        }
        runtimeType = runtimeType.parent;
    }

    return false;
}

version (USE_CLASSES) {
import godot.object;
package(godot) bool rttiIsInstanceOf(T)(const GodotObject inst) if (extendsGodotBaseClass!T) {
    if (inst is null) return false;
    return rttiIsInstanceOf(inst._typeTag, rttiTag!T);
}
} else
package(godot) bool rttiIsInstanceOf(T, U)(const U inst) if (extendsGodotBaseClass!T && extendsGodotBaseClass!U) {
    if (inst is null) return false;
    return rttiIsInstanceOf(inst._typeTag, rttiTag!T);
}

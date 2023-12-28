module godot.abi.gdextension;

import std.meta;
import std.traits : isSomeFunction, isType;
import std.algorithm : startsWith, canFind;
import godot.util.string;
import godot.abi.core : _godot_get_proc_address;

version(importc) {
    public import godot.abi.gdextension_header;
    alias gdextension_interface = godot.abi.gdextension_header;
} else {
    public import godot.abi.gdextension_binding;
    alias gdextension_interface = godot.abi.gdextension_binding;
}

enum _exclude = [
    "GDExtensionInterfaceFunctionPtr", // this one is a type
    "GDExtensionInterfaceGetProcAddress" // ditto
];

/// helper method that filters out irrelevant functions
/// e.g. GDExtensionInterfaceGetGodotVersion will be converted into:
///   GDExtensionInterfaceGetGodotVersion gdextension_interface_get_godot_version;
enum bool isFunctionPtr(alias T) = T.startsWith("GDExtensionInterface") 
                                    && isSomeFunction!(__traits(getMember, gdextension_interface, T)) && isType!(__traits(getMember, gdextension_interface, T))
                                    && !_exclude.canFind(T);

/// this will convert function pointer declaration and create a variable
static foreach(symname; Filter!(isFunctionPtr, __traits(derivedMembers, gdextension_interface))) {
    mixin("__gshared " ~ symname ~ " " ~ symname.camelToSnake ~ ";");
}

// load function pointers for GDExtensionInterface
void loadGDExtensionInterface() {
    static foreach(symname; Filter!(isFunctionPtr, __traits(derivedMembers, gdextension_interface))) {
        // makes up the following loader code:
        //   gdextension_interface_get_godot_version = cast(GDExtensionInterfaceGetGodotVersion) _godot_get_proc_address("get_godot_version");
        mixin(symname.camelToSnake, " = cast(", symname, ") _godot_get_proc_address(\"", symname.camelToSnake["gdextension_interface_".length..$], "\");");
        //pragma(msg, mixin(symname.camelToSnake, " = cast(", symname, ") _godot_get_proc_address(\"", symname.camelToSnake["gdextension_interface_".length..$], "\");"));
    }
}
module godot.charstring;

import std.traits;
import std.exception : assumeWontThrow;
import godot.builtins;
import godot.poolarrays;
import godot.abi;
import godot.abi.gdextension;
import godot.stringname;

import godot.variant;

struct CharString {
    const(char)* data;
    int length;

    ~this() {
        if (data)
            _godot_api.mem_free(cast(void*) data);
        data = null;
        length = 0;
    }
}

struct Char16String {
    const(char16_t)* data;
    int length;

    ~this() {
        if (data)
            _godot_api.mem_free(cast(void*) data);
        data = null;
        length = 0;
    }
}

struct Char32String {
    const(char32_t)* data;
    int length;

    ~this() {
        if (data)
            _godot_api.mem_free(cast(void*) data);
        data = null;
        length = 0;
    }
}

struct CharWideString {
    const(wchar_t)* data;
    int length;

    ~this() {
        if (data)
            _godot_api.mem_free(cast(void*) data);
        data = null;
        length = 0;
    }
}
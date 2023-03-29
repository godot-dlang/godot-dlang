/++
Integration with Godot editor's output and debugger tabs
+/
module godot.api.output;

import godot.abi, godot;

/++
The release-mode Godot-D assert handler redirects assert messages to the Godot
error handlers and terminates the program.
+/
// nothrow
void godotAssertHandlerCrash(string file, size_t line, string msg) {
    import core.exception;
    import std.experimental.allocator.mallocator;

    char[] buffer = cast(char[]) Mallocator.instance.allocate(file.length + msg.length + 2);
    scope (exit)
        Mallocator.instance.deallocate(cast(void[]) buffer);

    buffer[0 .. file.length] = file[];
    buffer[file.length] = '\0';
    buffer[file.length + 1 .. $ - 1] = msg[];
    buffer[$ - 1] = '\0';

    _godot_api.print_error(&buffer.ptr[file.length + 1], "", buffer.ptr, cast(int) line, true);

    version (D_Exceptions)
        throw new AssertError(msg, file, line);
    else {
        assertHandler = null;
        assert(0, msg);
    }
}

/++
The debug-mode Godot-D assert handler redirects assert messages to the Godot
error handlers (including Debugger tab in editor and system console).

Unlike the default D assert handler, this one doesn't terminate the program,
allowing the messages to remain in Godot's Debugger tab and matching how Godot
error macros behave.
+/
// nothrow
void godotAssertHandlerEditorDebug(string file, size_t line, string msg) {
    import core.exception;
    import std.experimental.allocator.mallocator;

    char[] buffer = cast(char[]) Mallocator.instance.allocate(file.length + msg.length + 2);
    scope (exit)
        Mallocator.instance.deallocate(cast(void[]) buffer);

    buffer[0 .. file.length] = file[];
    buffer[file.length] = '\0';
    buffer[file.length + 1 .. $ - 1] = msg[];
    buffer[$ - 1] = '\0';

    _godot_api.print_error(&buffer.ptr[file.length + 1], "", buffer.ptr, cast(int) line, true);

    //version(assert) // any `assert(x)` gets compiled; usually a debug version
    //{
    //	// TODO: if in Editor Debugger, debug_break like GDScript asserts
    //}
    //else // only `assert(0)`/`assert(false)` get compiled; usually a release version
    {
        // crash on always-false asserts
        version (D_Exceptions)
            throw new AssertError(msg, file, line);
        else {
            assertHandler = null;
            assert(0, msg);
        }
    }
}

/**
Print to Godot's console and stdout.

Params:
	args = any Godot-compatible types or strings
*/
void print(Args...)(Args args, string fn = __FUNCTION__, string f = __FILE__, int l = __LINE__) {
    import godot.string, godot.variant;

    String str;
    static if (Args.length == 0)
        str = String(" ");
    foreach (arg; args) {
        static if (is(typeof(arg) : String))
            str ~= arg;
        else static if (is(typeof(arg) : NodePath))
            str ~= arg.str;
        else static if (is(typeof(arg) : string))
            str ~= String(arg);
        else static if (is(typeof(arg) : Variant))
            str ~= arg.as!String;
        else static if (Variant.compatibleToGodot!(typeof(arg)))
            str ~= Variant(arg).as!String;
        else
            static assert(0, "Unable to print type " ~ typeof(arg).stringof);
    }
    auto utfstr = str.utf8;
    _godot_api.print_warning(cast(char*) utfstr.data, &fn[0], &f[0], l, true);
}

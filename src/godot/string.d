/**
Godot's ref-counted wchar_t String class.

Copyright:
Copyright (c) 2007 Juan Linietsky, Ariel Manzur.
Copyright (c) 2014 Godot Engine contributors (cf. AUTHORS.md)
Copyright (c) 2017 Godot-D contributors
Copyright (c) 2022 Godot-DLang contributors

License: $(LINK2 https://opensource.org/licenses/MIT, MIT License)


*/
module godot.string;

import std.traits;
import std.exception : assumeWontThrow;
import godot.builtins;
import godot.poolarrays;
import godot.abi;
import godot.abi.gdextension;
import godot.abi.types;
import godot.stringname;
import godot.nodepath;
import godot.charstring;

import godot.variant;

/**
This is the built-in string class (and the one used by GDScript). 
It supports Unicode and provides all necessary means for string handling. 
Strings are reference counted and use a copy-on-write approach, 
so passing them around is cheap in resources.
*/
struct String {
    //@nogc nothrow:

    package(godot) union _String {
        godot_string _godot_string;
        // some issue with forward reference 
        // error: `godot.api.traits.getGodotObject!(Resource).getGodotObject.ret` size of type `Resource` is invalid
        //String_Bind _bind; 
        void* s;
    }

    // TODO: deal with union problem so this can be removed
    ref String_Bind _bind() const { return *cast(String_Bind*) &s; }

    package(godot) _String _string;
    alias _string this;

    this(StringName n) {
        _godot_string = _bind.new2(n);
    }

    this(NodePath n) {
        _godot_string = _bind.new3(n);
    }

    package(godot) this(in godot_string str) {
        _godot_string = str;
    }

    // this one is supposedly not needed because of this(S)(in S str) constructors
    // this(string s) {
    //     this = toGodotString(s);
    // }

    /++
	Numeric constructor. S can be a built-in numeric type.
	+/
    this(S)(in S num) if (isNumeric!S) {
        import std.conv : text;
        this(num.text);
    }

    /++
	UTF-8 constructor. S can be a slice (like `string`) or a null-terminated pointer.
	+/
    this(S)(in S str) if (isImplicitlyConvertible!(S, const(char)[]) ||
                          isImplicitlyConvertible!(S, const(char)*)) {
        // FIXME: check Variant where constructed String immediately freed (for example in Array.make due to variant releasing reference)
        // this prevents enabling string destructor!!!
        static if (isImplicitlyConvertible!(S, const(char)[])) {
            const(char)[] contents = str;
            gdextension_interface_string_new_with_utf8_chars_and_len(&_godot_string, contents.ptr, cast(int) contents.length);
        } else {
            const(char)* contents = str;
            gdextension_interface_string_new_with_utf8_chars(&_godot_string, contents);
        }
    }

    /++
	UTF-16 constructor. S can be a slice or a null-terminated pointer.
	+/
    // NOTE: it SHOULD be compatible with windows wide strings, 
    //    but there is also explicit static factory method see String.fromWideChars() for them
    this(S)(in S str) if (isImplicitlyConvertible!(S, const(wchar)[]) ||
                          isImplicitlyConvertible!(S, const(wchar)*)) {
        static if (isImplicitlyConvertible!(S, const(wchar)[])) {
            const(wchar_t)[] contents = str;
            gdextension_interface_string_new_with_utf16_chars_and_len(&_godot_string, contents.ptr, cast(int) contents.length);
        } else {
            const(wchar)* contents = str;
            gdextension_interface_string_new_with_utf16_chars(&_godot_string, contents);
        }
    }

    /++
	UTF-32 constructor. S can be a slice (like `dstring`) or a null-terminated pointer.
	+/
    this(S)(in S str) if (isImplicitlyConvertible!(S, const(dchar)[]) ||
                          isImplicitlyConvertible!(S, const(dchar)*)) {
        // FIXME: check Variant where constructed String immediately freed (for example in Array.make due to variant releasing reference)
        // this prevents enabling string destructor!!!
        static if (isImplicitlyConvertible!(S, const(dchar)[])) {
            const(dchar)[] contents = str;
            gdextension_interface_string_new_with_utf32_chars_and_len(&_godot_string, cast(char32_t*) contents.ptr, cast(int) contents.length);
        } else {
            const(dchar)* contents = str;
            gdextension_interface_string_new_with_utf32_chars(&_godot_string, cast(char32_t*) contents);
        }
    }

    /++
	Compatibility method that takes C/C++ wide strings. S can be a slice or a null-terminated pointer.
	+/
    String fromWideChars(S)(in S str) if (isImplicitlyConvertible!(S, const(wchar_t)[]) ||
                                          isImplicitlyConvertible!(S, const(wchar_t)*)) {
        godot_string _string;
        static if (isImplicitlyConvertible!(S, const(wchar_t)[])) {
            const(wchar_t)[] contents = str;
            gdextension_interface_string_new_with_wide_chars_and_len(&_string, contents.ptr, cast(int) contents.length);
        } else {
            import core.stdc.wchar_ : wcslen;

            const(wchar_t)* contents = str;
            gdextension_interface_string_new_with_wide_chars_and_len(&_string, contents, cast(int) wcslen(contents));
        }
        return String(_string);
    }

    void _defaultCtor() {
        _godot_string = String_Bind.new0();
    }

    ~this() {
        // see Variant issue in UTF-8 constructor
        _bind._destructor();
        _godot_string = _godot_string.init;
    }

    // causes tons of weird compiler errors in ptrcall() function:
    // classes\godot\acceptdialog.d(78,26): Error: template `godot.api.bind.ptrcall` is not callable using argument types `!(Button)(GodotMethod!(Button), godot_object)`
    // src\godot\api\bind.d(186,15):        Candidate is: `ptrcall(Return, MB, Args...)(MB method, in godot_object self, Args args)`
    //
    //this(ref const String other) {
    //    if (_godot_string._opaque)
    //        _bind._destructor();
    //    _godot_string = _bind.new1(other._godot_string);
    //}

    this(this) {
        auto other = _godot_string;
        if (_string.s !is null)
            _godot_string = _bind.new1(other);
        else
            _defaultCtor();
    }

    void opAssign(in String other) {
        // see Variant issue
        if (_godot_string._opaque)
            _bind._destructor();
        _godot_string = _bind.new1(other._godot_string);
    }

    void opAssign(in string other) {
        // see Variant issue
        if (_godot_string._opaque)
            _bind._destructor();

        this = String(other);
    }

    /+String substr(int p_from,int p_chars) const
	{
		return String.empty; // todo
	}
	
	alias opSlice = substr;+/

    ref char32_t opIndex(in size_t idx) {
        return *gdextension_interface_string_operator_index(&_godot_string, cast(int) idx);
    }

    char32_t opIndex(in size_t idx) const {
        return *gdextension_interface_string_operator_index(cast(godot_string*)&_godot_string, cast(int) idx);
    }

    /// Returns the length of the internal string array length, minus the zero terminator.
    size_t length() const {
        // for curious:
        //     string.length() and gdextension_interface_string_to_utf32_chars(this, null, 0) is basically same thing
        return cast(size_t)_bind.length();
    }

    /// Returns: $(D true) if length is 0
    bool empty() const {
        return length == 0;
    }

    int opCmp(in String s) const {
        // TODO: Fix me
        return 0;
        //if(_godot_string == s._godot_string) return true;
        //auto equal = gdextension_interface_string_operator_equal(&_godot_string, &s._godot_string);
        //if(equal) return 0;
        //auto less = gdextension_interface_string_operator_less(&_godot_string, &s._godot_string);
        //return less?(-1):1;
    }

    bool opEquals(in String other) const {
        if (_godot_string == other._godot_string)
            return true;

        if (_bind == other._bind)
            return true;

        // Godot 4.4 and up

        // Starting with Godot 4.4 the internal variant pointer is obtained with variant_get_ptr_internal_getter(),
        // which also adds another function call and I have not yet tested if its provides better the performance 
        // difference of versus using variant comparison operator
        bool ret;
        __gshared GDExtensionPtrOperatorEvaluator mb;
        if (!mb) {
            mb = gdextension_interface_variant_get_ptr_operator_evaluator(
                GDEXTENSION_VARIANT_OP_EQUAL, 
                GDEXTENSION_VARIANT_TYPE_STRING, 
                GDEXTENSION_VARIANT_TYPE_STRING
                );
        }
        mb(&_godot_string, &other._godot_string, &ret);

        return ret;
    }

    String opBinary(string op)(in String other) const if (op == "~" || op == "+") {
        // it has to be zero initialized or godot will try to unref it and crash
        //String ret;
        godot_string ret;

        // __gshared static GDExtensionPtrOperatorEvaluator mb;
        GDExtensionPtrOperatorEvaluator mb;
        if (!mb) {
            mb = gdextension_interface_variant_get_ptr_operator_evaluator(
                GDEXTENSION_VARIANT_OP_ADD, 
                GDEXTENSION_VARIANT_TYPE_STRING, 
                GDEXTENSION_VARIANT_TYPE_STRING
                );
        }
        mb(&_godot_string, &other._godot_string, &ret);

        return String(ret);
    }

    void opOpAssign(string op)(in String other) if (op == "~" || op == "+") {
        //this = opBinary!"+"(other);
        godot_string tmp;

        // __gshared static GDExtensionPtrOperatorEvaluator mb;
        GDExtensionPtrOperatorEvaluator mb;
        if (!mb) {
            mb = gdextension_interface_variant_get_ptr_operator_evaluator(
                GDEXTENSION_VARIANT_OP_ADD, 
                GDEXTENSION_VARIANT_TYPE_STRING, 
                GDEXTENSION_VARIANT_TYPE_STRING
                );
        }
        mb(&_godot_string, &other._godot_string, &tmp);
        //_bind._destructor();
        _godot_string = tmp;
    }

    /// Returns a pointer to the string data.
    immutable(char32_t)* ptr() const {
        return cast(immutable(char32_t)*) gdextension_interface_string_operator_index_const(
            &_godot_string, 0);
    }

    /// Returns a slice of the string data without the zero terminator.
    immutable(dchar)[] data() const {
        return cast(typeof(return)) cast(dchar[])(ptr[0 .. length]);
    }

    alias toString = data;

    CharString utf8() const {
        // untested, may overflow?
        int size = cast(int) gdextension_interface_string_to_utf8_chars(&_godot_string, null, 0);
        char* cstr = cast(char*) gdextension_interface_mem_alloc(size + 1);
        gdextension_interface_string_to_utf8_chars(&_godot_string, cstr, size);
        cstr[size] = '\0';
        return CharString(cstr, size);
    }

    String format(V)(V values) const if (is(V : Variant) || Variant.compatibleToGodot!V) {
        const Variant v = values;
        String new_string = void;
        new_string._godot_string = gdextension_interface_string_format(&_godot_string, cast(godot_variant*)&v);

        return new_string;
    }

    String format(V)(V values, String placeholder) const if (is(V : Variant) || Variant.compatibleToGodot!V) {
        const Variant v = values;
        String new_string = void;
        CharString contents = placeholder.utf8;
        new_string._godot_string = gdextension_interface_string_format_with_custom_placeholder(
            &_godot_string, cast(godot_variant*)&v, contents.ptr);

        return new_string;
    }

    @trusted
    hash_t toHash() const nothrow {
        return cast(hash_t) assumeWontThrow(_bind.hash());
        //static if(hash_t.sizeof == uint.sizeof) return gdextension_interface_string_hash(&_godot_string);
        //else return gdextension_interface_string_hash64(&_godot_string);
    }
}

/** 
 * Constructs Godot String from str
 * Params:
 *   str = string to convert from
 * Returns: Godot String
 */
String toGodotString(string str) {
    // FIXME: this is going to be slow as hell
    godot_string gs;
    gdextension_interface_string_new_with_utf8_chars_and_len(&gs, str.ptr, cast(int) str.length);
    return String(gs);
}

/** 
 * Constructs string from str
 * Params:
 *   str = Godot String
 * Returns: D string
 */
string toDString(String str) {
    // FIXME: check memaloc
    import std.conv: to;
    return str.data.to!string;

    // Another unsafer way to do that would be (converts to wstring)
    // return str.data.idup;
}

struct GodotStringLiteral(string data) {
    private __gshared godot_string gs;
    String str() const {
        static if (data.length)
            if (gs == godot_string.init) {
                synchronized {
                    if (gs == godot_string.init)
                        gdextension_interface_string_new_with_utf8_chars_and_len(&gs, data.ptr, cast(int) data
                                .length);
                }
            }
        String* ret = cast(String*) cast(void*) &gs;
        return *ret;
    }

    static if (data.length) {
        shared static ~this() {
            // clean up
            String* str = cast(String*) cast(void*) &gs;
            str.__dtor();
            gs = gs.init;
        }
    }
    alias str this;
}

/++
Create a GodotStringLiteral.

D $(D string) to Godot $(D String) conversion is expensive and cannot be done
at compile time. This literal does the conversion once the first time it's
needed, then caches the String, allowing it to implicitly convert to String at
no run time cost.
+/
enum gs(string str) = GodotStringLiteral!str.init;

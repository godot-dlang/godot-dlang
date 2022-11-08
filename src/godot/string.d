/**
Godot's ref-counted wchar_t String class.

Copyright:
Copyright (c) 2007-2022 Juan Linietsky, Ariel Manzur.
Copyright (c) 2014-2022 Godot Engine contributors (cf. AUTHORS.md)
Copyright (c) 2017-2018 Godot-D contributors
Copyright (c) 2022-2022 Godot-DLang contributors

License: $(LINK2 https://opensource.org/licenses/MIT, MIT License)


*/
module godot.string;

// import core.stdc.stddef : wchar_t;
import std.traits;
import std.exception : assumeWontThrow;
import godot.builtins;
import godot.poolarrays;
import godot.abi;
import godot.abi.gdextension;

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

/**
This is the built-in string class (and the one used by GDScript). It supports Unicode and provides all necessary means for string handling. Strings are reference counted and use a copy-on-write approach, so passing them around is cheap in resources.
*/
struct String {
    //@nogc nothrow:

    package(godot) union _String {
        godot_string _godot_string;
        String_Bind _bind;
    }

    package(godot) _String _string;
    alias _string this;

    this(StringName n) {
        // this = _bind.new2(n);
        // HACK: 
        // FIXME: ARE YOU SERIOUS?
        this = _bind.new2(godotNameToD(n));
        //_godot_api.variant_new_copy(&_godot_string, &n._godot_string_name);
    }

    package(godot) this(in godot_string str) {
        _godot_string = str;
    }

    this(string s) {
        this = dstringToGodotString(s);
    }

    /++
	wchar_t constructor. S can be a slice or a null-terminated pointer.
	+/
    this(S)(in S str)
            if (isImplicitlyConvertible!(S, const(wchar_t)[]) ||
            isImplicitlyConvertible!(S, const(wchar_t)*)) {
        static if (isImplicitlyConvertible!(S, const(wchar_t)[])) {
            const(wchar_t)[] contents = str;
            _godot_api.string_new_with_wide_chars_and_len(&_godot_string, contents.ptr, cast(int) contents
                    .length);
        } else {
            import core.stdc.wchar_ : wcslen;

            const(wchar_t)* contents = str;
            _godot_api.string_new_with_wide_chars_and_len(&_godot_string, contents, cast(int) wcslen(
                    contents));
        }
    }

    /++
	UTF-8 constructor. S can be a slice (like `string`) or a null-terminated pointer.
	+/
    this(S)(in S str)
            if (isImplicitlyConvertible!(S, const(char)[]) ||
            isImplicitlyConvertible!(S, const(char)*)) {
        static if (isImplicitlyConvertible!(S, const(char)[])) {
            const(char)[] contents = str;
            _godot_api.string_new_with_utf8_chars_and_len(&_godot_string, contents.ptr, cast(int) contents
                    .length);
        } else {
            const(char)* contents = str;
            _godot_api.string_new_with_utf8_chars(&_godot_string, contents);
        }
    }

    void _defaultCtor() {
        this = String_Bind.new0();
    }

    ~this() {
        //_bind._destructor();
    }

    void opAssign(in String other) {
        //_bind._destructor();
        _godot_string = other._godot_string;
        // other still owns the string, double free possible?
    }

    void opAssign(in string other) {
        //_bind._destructor();
        godot_string gs;
        _godot_api.string_new_with_utf8_chars_and_len(&gs, other.ptr, cast(int) other.length);
        _godot_string = gs;
        // other still owns the string, double free possible?
    }

    /+String substr(int p_from,int p_chars) const
	{
		return String.empty; // todo
	}
	
	alias opSlice = substr;+/

    ref char32_t opIndex(in size_t idx) {
        return *_godot_api.string_operator_index(&_godot_string, cast(int) idx);
    }

    char32_t opIndex(in size_t idx) const {
        return *_godot_api.string_operator_index(cast(godot_string*)&_godot_string, cast(int) idx);
    }

    /// Returns the length of the wchar_t array, minus the zero terminator.
    size_t length() const {
        return _bind.length();
        //return _godot_api.string_length(&_godot_string);
    }

    /// Returns: $(D true) if length is 0
    bool empty() const {
        return length == 0;
    }

    int opCmp(in String s) const {
        // TODO: Fix me
        return 0;
        //if(_godot_string == s._godot_string) return true;
        //auto equal = _godot_api.string_operator_equal(&_godot_string, &s._godot_string);
        //if(equal) return 0;
        //auto less = _godot_api.string_operator_less(&_godot_string, &s._godot_string);
        //return less?(-1):1;
    }

    bool opEquals(in String other) const {
        if (_godot_string == other._godot_string)
            return true;
        //return _godot_api.string_operator_equal(&_godot_string, &other._godot_string);
        return _bind == other._bind;
    }

    String opBinary(string op)(in String other) const if (op == "~" || op == "+") {
        // it has to be zero initialized or godot will try to unref it and crash
        //String ret;
        godot_string ret;

        // __gshared static GDNativePtrOperatorEvaluator mb;
        GDNativePtrOperatorEvaluator mb;
        if (!mb) {
            mb = _godot_api.variant_get_ptr_operator_evaluator(
                GDNATIVE_VARIANT_OP_ADD, 
                GDNATIVE_VARIANT_TYPE_STRING, 
                GDNATIVE_VARIANT_TYPE_STRING
                );
        }
        mb(&_godot_string, &other._godot_string, &ret);

        return String(ret);
    }

    void opOpAssign(string op)(in String other) if (op == "~" || op == "+") {
        //this = opBinary!"+"(other);
        godot_string tmp;

        // __gshared static GDNativePtrOperatorEvaluator mb;
        GDNativePtrOperatorEvaluator mb;
        if (!mb) {
            mb = _godot_api.variant_get_ptr_operator_evaluator(
                GDNATIVE_VARIANT_OP_ADD, 
                GDNATIVE_VARIANT_TYPE_STRING, 
                GDNATIVE_VARIANT_TYPE_STRING
                );
        }
        mb(&_godot_string, &other._godot_string, &tmp);
        _bind._destructor();
        _godot_string = tmp;
    }

    /// Returns a pointer to the wchar_t data. Always zero-terminated.
    immutable(char32_t)* ptr() const {
        return cast(immutable(char32_t)*) _godot_api.string_operator_index_const(
            &_godot_string, 0);
    }

    /// Returns a slice of the wchar_t data without the zero terminator.
    immutable(wchar_t)[] data() const {
        return cast(typeof(return)) ptr[0 .. length];
    }

    alias toString = data;

    CharString utf8() const {
        // untested, may overflow?
        int size = cast(int) _godot_api.string_to_utf8_chars(&_godot_string, null, 0);
        char* cstr = cast(char*) _godot_api.mem_alloc(size + 1);
        _godot_api.string_to_utf8_chars(&_godot_string, cstr, size);
        cstr[size] = '\0';
        return CharString(cstr, size);
    }

    String format(V)(V values) const 
            if (is(V : Variant) || Variant.compatibleToGodot!V) {
        const Variant v = values;
        String new_string = void;
        new_string._godot_string = _godot_api.string_format(&_godot_string, cast(godot_variant*)&v);

        return new_string;
    }

    String format(V)(V values, String placeholder) const 
            if (is(V : Variant) || Variant.compatibleToGodot!V) {
        const Variant v = values;
        String new_string = void;
        CharString contents = placeholder.utf8;
        new_string._godot_string = _godot_api.string_format_with_custom_placeholder(
            &_godot_string, cast(godot_variant*)&v, contents.ptr);

        return new_string;
    }

    @trusted
    hash_t toHash() const nothrow {
        return cast(hash_t) assumeWontThrow(_bind.hash());
        //static if(hash_t.sizeof == uint.sizeof) return _godot_api.string_hash(&_godot_string);
        //else return _godot_api.string_hash64(&_godot_string);
    }
}

struct StringName {
    //@nogc nothrow:

    package(godot) union _StringName {
        godot_string _godot_string_name;
        StringName_Bind _bind;
    }

    package(godot) _StringName _stringName;
    alias _stringName this;

    this(String s) {
    // this(string s) {
        // this = _bind.new2(s);
        this = _bind.new2(godotStringToD(s));
    }

    this(this) {

    }

    this(string s) {
        this = dstringToGodotName(s);
    }

    //this(ref const StringName s)
    //{
    //	this = _bind.new1(s);
    //}

    void _defaultCtor() {
        this = StringName_Bind.new0();
    }

    /// Returns the length of the wchar_t array, minus the zero terminator.
    size_t length() const {
        // FIXME: burn this before it spreads
        String str = String(this);
        size_t len = str.length;
        return len;
        //return _godot_api.string_length(&_godot_string);
    }

    /// Returns: $(D true) if length is 0
    bool empty() const {
        return length == 0;
    }

    /// Returns a pointer to the wchar_t data. Always zero-terminated.
    immutable(char32_t)* ptr() const {
        return cast(immutable(char32_t)*) _godot_api.string_operator_index_const(
            &_godot_string_name, 0);
    }

    /// Returns a slice of the wchar_t data without the zero terminator.
    immutable(wchar_t)[] data() const {
        return cast(typeof(return)) ptr[0 .. length];
    }

    package(godot) this(in godot_string strname) {
        _godot_string_name = strname;
    }

    /++
	char constructor. S can be a slice (like `string`) or a null-terminated pointer.
	+/
    this(S)(in S str)
            if (isImplicitlyConvertible!(S, const(char)[]) ||
            isImplicitlyConvertible!(S, const(char)*)) {
        static if (isImplicitlyConvertible!(S, const(char)[])) {
            const(char)[] contents = str;
            _godot_api.string_new_with_latin1_chars_and_len(&_godot_string_name, contents.ptr, cast(
                    int) contents.length);
        } else {
            import core.stdc.string : strlen;

            const(char)* contents = str;
            _godot_api.string_new_with_latin1_chars_and_len(&_godot_string_name, contents, cast(int) strlen(
                    contents));
        }
    }

    ~this() {
        //_bind._destructor();
        _godot_string_name = _godot_string_name.init;
    }

    void opAssign(in StringName other) {
        if (&_godot_string_name)
            _bind._destructor();

        _godot_string_name = other._godot_string_name;
    }

    void opAssign(in string other) {
        if (&_godot_string_name)
            _bind._destructor();
        godot_string gs;
        _godot_api.string_new_with_utf8_chars_and_len(&gs, other.ptr, cast(int) other.length);
        _godot_string_name = gs;
    }

    bool opEquals(in StringName other) const {
        if (_godot_string_name == other._godot_string_name)
            return true;
        // FIXME: no idea if there is actually such thing
        //return _godot_api.string_name_operator_equal(&_godot_string_name, &other._godot_string_name);
        return false;
    }

    String opCast(String)() const {
        return String(_godot_string_name);
    }

    @trusted
    hash_t toHash() const nothrow {
        return cast(hash_t) assumeWontThrow(_bind.hash());
        //static if(hash_t.sizeof == uint.sizeof) return _godot_api.string_hash(&_godot_string);
        //else return _godot_api.string_hash64(&_godot_string);
    }

}

struct GodotStringLiteral(string data) {
    private __gshared godot_string gs;
    String str() const {
        static if (data.length)
            if (gs == godot_string.init) {
                synchronized {
                    if (gs == godot_string.init)
                        _godot_api.string_new_with_utf8_chars_and_len(&gs, data.ptr, cast(int) data
                                .length);
                }
            }
        //String ret = void;
        //_godot_api.variant_new_copy(&ret._godot_string, &gs);
        //return ret;
        return String(gs);
    }

    static if (data.length) {
        shared static ~this() {
            //if(gs != godot_string.init) _godot_api.variant_destroy(&gs);
        }
    }
    alias str this;
}

String dstringToGodotString(string str) {
    // FIXME: this is going to be slow as hell
    godot_string gs;
    _godot_api.string_new_with_utf8_chars_and_len(&gs, str.ptr, cast(int) str.length);
    return String(gs);
}

string godotStringToD(String str) {
    // FIXME: this is going to be slow as hell
    import std.conv: to;
    return str.data.to!string;
}

/++
Create a GodotStringLiteral.

D $(D string) to Godot $(D String) conversion is expensive and cannot be done
at compile time. This literal does the conversion once the first time it's
needed, then caches the String, allowing it to implicitly convert to String at
no run time cost.
+/
enum gs(string str) = GodotStringLiteral!str.init;

struct GodotStringNameLiteral(string data) {
    private __gshared godot_string gs;
    StringName str() const {
        static if (data.length)
            if (gs == godot_string.init) {
                synchronized {
                    if (gs == godot_string.init)
                        _godot_api.string_new_with_utf8_chars_and_len(&gs, data.ptr, cast(int) data
                                .length);
                }
            }
        // a pointer so it won't destroy itself ahead of time
        String* p = cast(String*)&gs;
        //String ret = void;
        //_godot_api.variant_new_copy(&ret._godot_string, &gs);
        //return ret;
        return StringName(*p);
    }

    static if (data.length) {
        shared static ~this() {
            //if(gs != godot_string.init) _godot_api.variant_destroy(&gs);
        }
    }
    alias str this;
}

StringName dstringToGodotName(string str) {
    // FIXME: this is going to be slow as hell
    godot_string gs;
    _godot_api.string_new_with_utf8_chars_and_len(&gs, str.ptr, cast(int) str.length);
    String* p = cast(String*)&gs;
    return StringName(*p);
}

string godotNameToD(StringName str) {
    // FIXME: this is going to be slow as hell
    import std.conv: to;
    return str.data.to!string;
}

/++
Create a GodotStringNameLiteral.

D $(D string) to Godot $(D StringName) conversion is expensive and cannot be done
at compile time. This literal does the conversion once the first time it's
needed, then caches the StringName, allowing it to implicitly convert to StringName at
no run time cost.
+/
enum gn(string str) = GodotStringNameLiteral!str.init;

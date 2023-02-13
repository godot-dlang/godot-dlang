module godot.stringname;

import std.traits;
import std.exception : assumeWontThrow;
import godot.builtins;
import godot.poolarrays;
import godot.abi;
import godot.abi.gdextension;
import godot.string;

import godot.variant;

/// Initializes an empty StringName
alias stringName = StringName.makeEmpty;

struct StringName {
    //@nogc nothrow:

    package(godot) union _StringName {
        godot_string _godot_string_name;
        StringName_Bind _bind;
    }

    package(godot) _StringName _stringName;
    alias _stringName this;

    this(String s) {
        this = _bind.new2(s);
    }

    this(this) {

    }

    this(string s) {
        auto str = String(s);
        this(str);
    }
    
    /++
	Numeric constructor. S can be a built-in numeric type.
	+/
    this(S)(in S num) if (isNumeric!S) {
        import std.conv : text;
        this(num.text);
    }

    deprecated("Default struct ctor is not allowed, please use `stringName()` instead")
    @disable this();

    //this(ref const StringName s)
    //{
    //	this = _bind.new1(s);
    //}

    void _defaultCtor() {
        this = StringName_Bind.new0();
    }
    
    static StringName makeEmpty() {
        StringName sn = void;
        sn._defaultCtor();
        return sn;
    }

    /// Returns the length of the char32_t array, minus the zero terminator.
    size_t length() const {
        auto len = _godot_api.string_to_utf8_chars(&_godot_string_name, null, 0);
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

    /// Returns a slice of the char32_t data without the zero terminator.
    dstring data() const {
        // in godot-cpp there is actually no such things like data(), ptr() and length() for StringName
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
        //if (&_godot_string_name)
        //    _bind._destructor();

        _godot_string_name = other._godot_string_name;
    }

    void opAssign(in string other) {
        //if (&_godot_string_name)
        //    _bind._destructor();
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

    String opCast(T : String)() const {
        return String(_godot_string_name);
    }

    GDExtensionStringNamePtr opCast(T = GDExtensionStringNamePtr)() const {
        return cast(GDExtensionStringNamePtr) &_godot_string_name;
    }

    @trusted
    hash_t toHash() const nothrow {
        return cast(hash_t) assumeWontThrow(_bind.hash());
        //static if(hash_t.sizeof == uint.sizeof) return _godot_api.string_hash(&_godot_string);
        //else return _godot_api.string_hash64(&_godot_string);
    }

}

/** 
 * Constructs Godot String Name from str
 * Params:
 *   str = string to convert from
 * Returns: Godot String Name
 */
StringName toGodotStringName(string str) {
    // FIXME: this is going to be slow as hell
    godot_string gs;
    _godot_api.string_new_with_utf8_chars_and_len(&gs, str.ptr, cast(int) str.length);
    String* p = cast(String*)&gs;
    return StringName(*p);
}

/** 
 * Constructs string from str
 * Params:
 *   str = Godot String Name
 * Returns: D string
 */
string toDStringName(StringName str) {
    // FIXME: this is going to be slow as hell
    import std.conv: to;
    return str.data.to!string;
}

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

/++
Create a GodotStringNameLiteral.

D $(D string) to Godot $(D StringName) conversion is expensive and cannot be done
at compile time. This literal does the conversion once the first time it's
needed, then caches the StringName, allowing it to implicitly convert to StringName at
no run time cost.
+/
enum gn(string str) = GodotStringNameLiteral!str.init;

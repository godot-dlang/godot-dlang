module godot.tools.generator.methods;

import godot.util.string;
import godot.tools.generator.classes;
import godot.tools.generator.enums;
import godot.tools.generator.util;

import asdf;

import std.range;
import std.algorithm.searching;
import std.algorithm.iteration;
import std.path;
import std.conv : text;
import std.string;

import std.typecons;

class GodotMethod {
    @serdeOptional
    string name; // constructors doesn't have name
    @serdeOptional @serdeKeys("return_type", "return_value")
    Type return_type;
    @serdeOptional
    bool is_editor;
    @serdeOptional
    bool is_noscript;
    @serdeOptional
    bool is_const;
    @serdeOptional
    bool is_virtual;
    @serdeOptional
    bool is_static;
    @serdeOptional
    string category;
    @serdeOptional @serdeKeys("is_vararg", "has_varargs")
    bool has_varargs;
    @serdeOptional
    bool is_from_script;
    @serdeOptional
    uint hash;
    @serdeOptional
    GodotArgument[] arguments;

    void finalizeDeserialization(Asdf data) {
        // FIXME: why data is here if it's not used?
        if (!return_type)
            return_type = Type.get("void");
        foreach (i, ref arg; arguments) {
            arg.index = i;
            arg.parent = this;
        }
    }

@serdeIgnore:
    GodotClass parent;

    string ddoc;

    Constructor isConstructor() const {
        return null;
    }
    // Operator isOperator() { return null; }
    // Indexer isIndexer() { return null; }

    bool same(in GodotMethod other) const {
        return name == other.name && is_const == other.is_const;
    }

    string templateArgsString() const {
        string ret = "";
        bool first = true; // track first arg to skip comma
        foreach (i, ref arg; arguments) {
            if (arg.type.acceptImplicit) {
                if (first)
                    first = false;
                else
                    ret ~= ", ";
                ret ~= text(arg.type.godotType, "Arg", i);
            }
        }
        if (has_varargs) {
            if (!first)
                ret ~= ", ";
            ret ~= "VarArgs...";
        }
        // template parens only if it actually is a template
        if (ret.length != 0)
            ret = text("(", ret, ")");
        return ret;
    }

    string argsString() const {
        string ret = "(";

        foreach (i, ref arg; arguments) {
            // FIXME: do it prettier
            string typeString = "";

            if (i != 0) ret ~= ", ";
            if (arg.type.acceptImplicit) {
                ret ~= text(arg.type.dCallParamPrefix, arg.type.godotType, "Arg", i);
                typeString = text(arg.type.godotType, "Arg", i);
            } else {
                if (arg.type.dType == "String" || arg.type.dType == "StringName") {
                    // HACK: string auto-conversion
                    // FIXME: make exception list
                    ret ~= text(arg.type.dCallParamPrefix, "string");
                    typeString = "string";
                } else {
                    ret ~= text(arg.type.dCallParamPrefix, arg.type.dType);
                    typeString = arg.type.dType;
                }
            }

            ret ~= " " ~ arg.name.escapeDType;

            // HACK: look at GodotArgument
            // FIXME: Causes forward reference
            if (arg.default_value != "\0") {
                if (arg.type.isBitfield || arg.type.isEnum) {
                    ret ~= " = cast(" ~ typeString ~ ") " ~ escapeDefaultType(arg.type, arg.default_value);
                } else {
                    ret ~= " = " ~ escapeDefaultType(arg.type, arg.default_value);
                }
            }
        }
        if (has_varargs) {
            if (arguments.length != 0)
                ret ~= ", ";
            ret ~= "VarArgs varArgs";
        }
        ret ~= ")";
        return ret;
    }

    /++
	Outputs binding method declaration with meta information. 
	e.g.:

		@GodotName("insert") @MethodHash(0) GodotMethod!(long, long, Variant) method_insert;
	+/
    string binding() const {
        string ret;

        ret ~= "\t\t@GodotName(\"" ~ name ~ "\") GodotMethod!(" ~ return_type.dType;
        foreach (ai, const arg; arguments) {
            ret ~= ", " ~ arg.type.dType;
        }
        if (has_varargs)
            ret ~= ", GodotVarArgs";
        ret ~= ") " ~ wrapperIdentifier ~ ";\n";

        return ret;
    }

    /// Function pointer name for this method
    /// 	"constructor_new_0", "method_normalize", ...
    string wrapperIdentifier() const {
        return functionKindName ~ "_" ~ name.snakeToCamel.escapeDType;
    }

    /// Function type name used in some cases: like "method", "ctor", "getter", etc...
    string functionKindName() const {
        return "method";
    }

    /++ 
	Formats whole method including function signature and body with implementation.
	e.g.:
    ```d
    string getSlice(in string delimiter, in long slice) const {
		if (!GDNativeClassBinding.method_getSlice.mb)
			GDNativeClassBinding.method_getSlice.mb = _godot_api.variant_get_ptr_builtin_method(GDNATIVE_VARIANT_TYPE_STRING, "get_slice", 3535100402);
		return toDString(callBuiltinMethod!(String)(cast(GDNativePtrBuiltInMethod) GDNativeClassBinding.method_getSlice.mb, cast(void*) &_godot_object, cast() toGodotString(delimiter), cast() slice));
    }
    ```
	+/
    string source() const {
        string ret;

        // ddoc comment (if any)
        ret ~= "\t/**\n\t" ~ ddoc.replace("\n", "\n\t") ~ "\n\t*/\n";
        ret ~= "\t";

        ret ~= signature();

        ret ~= " {\n";

        ret ~= body_();

        ret ~= "\t}\n";

        return ret;
    }

    /// Formats function signature, e.g.
    ///   Array slice(in long begin, in long end, in long step, in bool deep) const
    string signature() const {
        string ret;

        // optional static modifier
        if (isConstructor)
            ret ~= "static ";
        // note that even though it strips constness of return type the method is still marked const
        // const in D is transitive, which means compiler should disallow modifying returned reference types
        // HACK: so much String
        string retType = return_type.stripConst.dRef;
        if (retType == "String" || retType == "StringName") retType = "string";
        ret ~= retType ~ " ";
        // ret ~= return_type.stripConst.dRef ~ " ";
        // none of the types (Classes/Core/Primitive) are pointers in D
        // Classes are reference types; the others are passed by value.
        ret ~= name.snakeToCamel.escapeDType;

        ret ~= templateArgsString;
        ret ~= argsString;

        // function const attribute
        if (is_const)
            ret ~= " const";
        else if (name == "callv" && parent.name.godotType == "Object")
            ret ~= " const"; /// HACK

        return ret;
    }

    /// Formats body containing implementation, omitting outer braces
    string body_() const {
        string ret;

        // load function pointer
        ret ~= "\t\tif (!GDNativeClassBinding." ~ wrapperIdentifier ~ ".mb) {\n";
        // tab() will indent it correctly starting from first element
        ret ~= loader().split('\n').map!(s => s.tab(3)).join('\n') ~ "\n";
        ret ~= "\t\t}\n";

        if (is_virtual || has_varargs) {
            // keep it like this for now, serves as example.
            // function will put normal arguments first, then varargs
            // next, in order to call that function we need actually array of pointers
            // after that we call the function with array of pointers instead of plain args array
            version (none)
                if (name == "emit_signal") {
                    // two tabs
                    ret ~= `		Variant[varArgs.length+2] _GODOT_args;
	_GODOT_args[0] = String("emit_signal");
	_GODOT_args[1] = signal;
	foreach(vai, VA; VarArgs) {
		_GODOT_args[vai+2] = Variant(varArgs[vai]);
	}
	Variant*[varArgs.length+2] _args;
	foreach(i; 0.._GODOT_args.length) {
		_args[i] = &_GODOT_args[i];
	}
	Variant ret;
	GDNativeCallError err;
	_godot_api.object_method_bind_call(GDNativeClassBinding.method_emitSignal.mb, _godot_object.ptr, cast(void**) _args.ptr, _GODOT_args.length, cast(void*) &ret, &err);
	debug if (int code = ret.as!int()) {
		import godot.api;
		print("signal error: ", signal, " code: ", code);
	}
	return cast(GodotError) err.error;`;
                }

            // static array must have at least 1 element
            import std.algorithm : max;

            int argsLength = max(1, (cast(int) arguments.length));
            // choose between varargs and regular function for arguments
            if (has_varargs) {
                ret ~= "\t\tVariant[varArgs.length+" ~ text(argsLength) ~ "] _GODOT_args;\n";
                ret ~= "\t\tVariant*[varArgs.length+" ~ text(argsLength) ~ "] _args;\n";
            } else {
                ret ~= "\t\tVariant[" ~ text(argsLength) ~ "] _GODOT_args;\n";
                ret ~= "\t\tVariant*[" ~ text(argsLength) ~ "] _args;\n";

            }
            foreach (i, const arg; arguments) {
                // gathers normal parameters in variant array to be later used as pointers
                ret ~= "\t\t_GODOT_args[" ~ text(cast(int) i) ~ "] = " ~ escapeDType(arg.name) ~ ";\n";
            }

            if (has_varargs) {
                // copy varargs after regular args
                ret ~= "\t\tforeach(vai, VA; VarArgs) {\n";
                ret ~= "\t\t\t_GODOT_args[vai+" ~ text(
                    cast(int) arguments.length) ~ "] = Variant(varArgs[vai]);\n";
                ret ~= "\t\t}\n";
            }

            // make pointer array
            ret ~= "\t\tforeach(i; 0.._GODOT_args.length) {\n";
            ret ~= "\t\t\t_args[i] = &_GODOT_args[i];\n";
            ret ~= "\t\t}\n";

            //ret ~= "\t\tStringName _GODOT_method_name = StringName(\""~name~"\");\n";

            ret ~= "\t\tVariant ret;\n";
            ret ~= "\t\tGDNativeCallError err;\n";
            ret ~= "\t\t_godot_api.object_method_bind_call(GDNativeClassBinding." ~ wrapperIdentifier ~ ".mb, cast(void*) _godot_object.ptr, cast(void**) _args.ptr, _GODOT_args.length, cast(void*) &ret, &err);\n";
            // ret ~= "\t\t";
            if (return_type.dType != "void") {
                ret ~= "\t\treturn ";
                if (return_type.dType != "Variant") {
                    // HACK
                    if (return_type.stripConst.dType == "String") ret ~= "toDString(";
                    if (return_type.stripConst.dType == "StringName") ret ~= "toDStringName(";
                    ret ~= "ret.as!(RefOrT!(" ~ return_type.stripConst.dType ~ "))";
                    if (return_type.stripConst.dType == "String") ret ~= ")";
                    if (return_type.stripConst.dType == "StringName") ret ~= ")";
                } else {
                    ret ~= "ret";
                }
                ret ~= ";\n";
            }
        } else { // end varargs/virtual impl
            // adds temp variable for static ctor
            if (isConstructor) {
                ret ~= "\t\t";
                ret ~= parent.name.canBeCopied ? parent.name.dType : parent.name.asOpaqueType;
                ret ~= " _godot_object;\n";
            }
            // omit return for constructors, it will be wrapped and returned later
            if (return_type.dType != "void" && !(isConstructor && parent.name.isCoreType)) {
                ret ~= "\t\treturn ";
            } else {
                ret ~= "\t\t";
            }
            // HACK
            if (return_type.dType == "String" && !isConstructor) ret ~= "toDString(";
            if (return_type.dType == "StringName" && !isConstructor) ret ~= "toDStringName(";

            ret ~= callType() ~ "!(" ~ return_type.dType ~ ")(";
            if (parent.isBuiltinClass)
                ret ~= "cast(GDNativePtrBuiltInMethod) ";
            ret ~= "GDNativeClassBinding." ~ wrapperIdentifier;
            if (parent.isBuiltinClass) // Adds method pointer accessor instead of template itself
                ret ~= ".mb";
            ret ~= ", ";
            if (parent.isBuiltinClass)
                ret ~= "cast(void*) &_godot_object";
            else
                ret ~= "_godot_object";
            foreach (ai, const arg; arguments) {
                // FIXME: const cast hack
                // FIXME: make auto-cast in escapeDType?
                ret ~= ", cast() " ~ arg.name.escapeDType(arg.type.godotType); 
            }
            // HACK
            if ((return_type.dType == "String" || return_type.dType == "StringName") && !isConstructor) {
                ret ~= ")";
            } 
            ret ~= ");\n";
            // wrap temporary object
            if (isConstructor) {
                if (parent.name.canBeCopied) {
                    ret ~= "\t\treturn _godot_object;\n";
                } else {
                    ret ~= "\t\treturn ";
                    // HACK
                    if (return_type.dType == "String") ret ~= "toDString(";
                    if (return_type.dType == "StringName") ret ~= "toDStringName(";
                    // ret ~= "\t\treturn " ~ return_type.dType ~ "(_godot_object);\n";
                    ret ~= return_type.dType ~ "(_godot_object";
                    if (return_type.dType == "String") ret ~= ")";
                    if (return_type.dType == "StringName") ret ~= ")";
                    ret ~= ");\n";
                }
            }
        } // end normal method impl

        return ret;
    }

    /// call type wrapper, "ptrcall", "callv", "callBuiltinMethod", etc...
    string callType() const {
        if (parent.isBuiltinClass)
            return "callBuiltinMethod";
        //if (has_varargs)
        //	return "callv";
        return "ptrcall";
    }

    /// formats function pointer loader, e.g.
    /// 	GDNativeClassBinding.method_append.mb = _godot_api.clasdb_get_methodbind("class", "method", hash);
    string loader() const {
        char[] buf;
        buf ~= "StringName classname = StringName(\"" ~ parent.name.godotType ~ "\");\n";
        buf ~= "StringName methodname = StringName(\"" ~ name ~ "\");\n";
        // probably better to move in its own subclass
        if (parent.isBuiltinClass) {
            return cast(string) buf ~ format(`GDNativeClassBinding.%s.mb = _godot_api.variant_get_ptr_builtin_method(%s, cast(GDNativeStringNamePtr) methodname, %d);`,
                wrapperIdentifier,
                parent.name.asNativeVariantType,
                hash
            );
        }

        return cast(string) buf ~ format(`GDNativeClassBinding.%s.mb = _godot_api.classdb_get_method_bind(cast(GDNativeStringNamePtr) classname, cast(GDNativeStringNamePtr) methodname, %d);`,
            wrapperIdentifier,
            hash,
        );
    }
}

struct GodotArgument {
    string name;
    Type type;
    
    // HACK: when godot doesn't want to specifically
    // tell you default it leaves it empty ("default_value": "")
    // so when asdf hits it sets default_value to []
    // which is the same as if it's undefined
    @serdeOptional
    string default_value = "\0";

@serdeIgnore:

    size_t index;
    GodotMethod parent;
}

class GodotProperty {
    string name;
    Type type;
    string getter, setter;
    int index;

@serdeIgnore:

    string ddoc;

    string getterSource(in GodotMethod m) const {
        string retType = m.return_type.dType;
        if (retType == "String" || retType == "StringName") {
            // HACK: string auto-conversion
            // FIXME: make exception list
            retType = "string";
        }
        string ret;
        ret ~= "\t/**\n\t" ~ ddoc.replace("\n", "\n\t") ~ "\n\t*/\n";
        ret ~= "\t@property " ~ retType ~ " " ~ name.replace("/", "_")
        // ret ~= "\t@property " ~ m.return_type.dType ~ " " ~ name.replace("/", "_")
            .snakeToCamel.escapeDType ~ "() {\n"; /// TODO: const?
        ret ~= "\t\treturn " ~ getter.snakeToCamel.escapeDType ~ "(";
        if (index != -1) {
            // add cast to enum types
            if (m.arguments[0].type.isEnum)
                ret ~= "cast(" ~ m.arguments[0].type.dType ~ ") ";
            ret ~= text(index);
        }
        ret ~= ");\n";
        ret ~= "\t}\n";
        return ret;
    }

    string setterSource(in GodotMethod m) const {
        string setType = m.arguments[$ - 1].type.dType;
        if (setType == "String" || setType == "StringName") {
            // HACK: string auto-conversion
            // FIXME: make exception list
            setType = "string";
        }
        string ret;
        ret ~= "\t/// ditto\n";
        ret ~= "\t@property void " ~ name.replace("/", "_")
            .snakeToCamel.escapeDType ~ "(" ~ setType ~ " v) {\n";
            // .snakeToCamel.escapeDType ~ "(" ~ m.arguments[$ - 1].type.dType ~ " v) {\n";
        ret ~= "\t\t" ~ setter.snakeToCamel.escapeDType ~ "(";
        if (index != -1) {
            // add cast to enum types
            if (m.arguments[0].type.isEnum)
                ret ~= "cast(" ~ m.arguments[0].type.dType ~ ") ";
            ret ~= text(index) ~ ", ";
        }
        ret ~= "v);\n";
        ret ~= "\t}\n";
        return ret;
    }
}

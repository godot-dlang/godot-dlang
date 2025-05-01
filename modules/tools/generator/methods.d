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


// list of math functions that have overloads with suffix for types,
// this is because GDscript does not have function overloading based on type.
// but here we would like to have these uniformly available
// $ is used as placeholder, it can be omitted or have 'i' or 'f' in its place
immutable mathOverloadSets = ["$posmod", "floor$", "ceil$", "round$", "abs$", "sign$", "snapped$", "lerp$", "wrap$", "max$", "min$", "clamp$", "rand$", "rand$Range" ];


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
        // Superbelko: Because this is post-serialize event and we only doing some adjustments here
        if (!return_type)
            return_type = Type.get("void");
        foreach (i, ref arg; arguments) {
            arg.index = i;
            arg.parent = this;
        }
    }

@serdeIgnore:
    GodotClass parent;

    // indicates that this method is a helper methods that simply 
    // redirectes all arguments to the specidied method, for example string types helpers
    GodotMethod redirectsTo; 

    string ddoc;

    Constructor isConstructor() const {
        return null;
    }

    // special constructor taking self type as the only parameter
    bool isCopyCtor() const {
        if (!isConstructor)
            return false;
        if (arguments.length != 1)
            return false;

        if (parent.name.godotType.canFind("Packed"))
            return false;

        auto ret = arguments[0].type.isCoreType 
            && Type.get(parent.name.godotType) == Type.get(arguments[0].type.godotType);
            //&& Type.get(parent.name.godotType) == Type.get(return_type.godotType);
        return ret;
    }

    // Operator isOperator() { return null; }
    // Indexer isIndexer() { return null; }

    bool same(in GodotMethod other) const {
        return name == other.name && is_const == other.is_const;
    }

    bool needsStringHelpers() const {
        static bool anyString (GodotArgument a) { 
            return a.type.stripConst.isGodotStringType; 
        }
        // const all the way...
        return (cast(GodotArgument[]) arguments).canFind!anyString();
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
                if (isCopyCtor) // allow copy construction avoiding recursion loop
                    ret ~= "in " ~ arg.type.asOpaqueType;
                else 
                    ret ~= text(arg.type.dCallParamPrefix, arg.type.dType);
                typeString = arg.type.dType;
            }

            ret ~= " " ~ arg.name.escapeDType;

            // HACK: look at GodotArgument
            // FIXME: Causes forward reference
            if (arg.default_value != "\0") {
                if (arg.type.isBitfield || arg.type.isEnum) {
                    ret ~= " = cast(" ~ typeString ~ ") " ~ escapeDefaultType(arg.type, arg.default_value);
                } else {
                    // This probably should be in StringHelper method class
                    if (redirectsTo && redirectsTo.arguments[i].type.isGodotStringType) {
                        ret ~= " = " ~ stripStringDefaultValueType(redirectsTo.arguments[i].type, arg.default_value);
                    }
                    else {
                        ret ~= " = " ~ escapeDefaultType(arg.type, arg.default_value);
                    }
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

        ret ~= "\t\t@GodotName(\"" ~ name ~ "\") ";
        if (is_static)
            ret ~= "GodotMethodStatic";
        else
            ret ~= "GodotMethod";
        ret ~= "!(" ~ return_type.dType;
        if (return_type.isSingleton)
            ret ~= "Singleton";
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
		if (!GDExtensionClassBinding.method_getSlice.mb)
			GDExtensionClassBinding.method_getSlice.mb = gdextension_interface_variant_get_ptr_builtin_method(GDEXTENSION_VARIANT_TYPE_STRING, "get_slice", 3535100402);
		return toDString(callBuiltinMethod!(String)(cast(GDExtensionPtrBuiltInMethod) GDExtensionClassBinding.method_getSlice.mb, cast(void*) &_godot_object, cast() toGodotString(delimiter), cast() slice));
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

        if (needsStringHelpers && !isConstructor()) {
            ret ~= "\n";

            // copy-paste a method
            auto m = new StringHelperGodotMethod(); {
                m.name = this.name;
                m.is_editor = this.is_editor;
                m.is_noscript = this.is_noscript;
                m.is_const = this.is_const;
                m.is_virtual = this.is_virtual;
                m.is_static = this.is_static;
                m.category = this.category;
                m.has_varargs = this.has_varargs;
                m.is_from_script = this.is_from_script;
                m.hash = this.hash;
                m.parent = cast() this.parent;
                m.return_type = cast() this.return_type;
                m.redirectsTo = cast() this;
            }
            GodotArgument[] newargs;
            foreach(a; arguments) {
                // replace string types with plain D string
                if (a.type.isGodotStringType)
                    newargs ~= GodotArgument(a.name, Type.get("string"), a.default_value, a.index, m);
                else
                    newargs ~= GodotArgument(a.name, cast() a.type, a.default_value, a.index, m);
            }
            m.arguments = newargs;
            ret ~= m.source();
        }

        return ret;
    }

    /// Formats function signature, e.g.
    ///   Array slice(in long begin, in long end, in long step, in bool deep) const
    string signature() const {
        string ret;

        // optional static modifier
        if (isConstructor || is_static) {
            ret ~= "static ";
        }
        // core types is a bit tricky to deal with D copy constructors so return the reference as raw handle
        // some core types like RID and 'Nil' (GDExtensionTypePtr_Bind) are not needed
        // Basically only String, StringName, NodePath and Array are of interest.
        if (isConstructor && !return_type.canBeCopied && return_type.isCoreType) {
            ret ~= return_type.asOpaqueType;
        }
        else {
            // note that even though it strips constness of return type the method is still marked const
            // const in D is transitive, which means compiler should disallow modifying returned reference types
            ret ~= return_type.stripConst.dRef;
        }
        if (return_type.isSingleton)
            ret ~= "Singleton";
        ret ~= " ";
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
        ret ~= "\t\tif (!GDExtensionClassBinding." ~ wrapperIdentifier ~ ".mb) {\n";
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
	GDExtensionCallError err;
	gdextension_interface_object_method_bind_call(GDExtensionClassBinding.method_emitSignal.mb, _godot_object.ptr, cast(void**) _args.ptr, _GODOT_args.length, cast(void*) &ret, &err);
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
            ret ~= "\t\tGDExtensionCallError err;\n";

            // there is subtle difference, we pass &godot_object for builtins and .ptr for any other object
            // but normally they should work just with &godot_object, we had issues with that in the past though
            // so here we now use real ptr value instead
            if (parent.isBuiltinClass)
                ret ~= "\t\tgdextension_interface_object_method_bind_call(GDExtensionClassBinding." ~ wrapperIdentifier ~ ".mb, cast(void*) &_godot_object, cast(void**) _args.ptr, _GODOT_args.length, cast(void*) &ret, &err);\n";
            else
                ret ~= "\t\tgdextension_interface_object_method_bind_call(GDExtensionClassBinding." ~ wrapperIdentifier ~ ".mb, cast(void*) _godot_object.ptr, cast(void**) _args.ptr, _GODOT_args.length, cast(void*) &ret, &err);\n";
            // ret ~= "\t\t";
            // DMD 2.101 complains about Type* pointers escaping function scope
            // So instead of returning it directly make a temporary pointer variable
            if (return_type.dType != "void") {
                if (return_type.isPointerType) {
                    ret ~= "\t\tauto r = ";
                }
                else {
                    ret ~= "\t\treturn ";
                }

                if (return_type.dType != "Variant") {
                    ret ~= "ret.as!(RefOrT!(" ~ return_type.stripConst.dType ~ "))";
                    if (return_type.isPointerType) {
                        ret ~= ";\n\t\treturn r";
                    }
                } 
                else {
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

            ret ~= callType() ~ "!(" ~ return_type.dType;
            if (return_type.isSingleton)
                ret ~= "Singleton";
            ret ~= ")(";
            if (parent.isBuiltinClass)
                ret ~= "cast(GDExtensionPtrBuiltInMethod) ";
            ret ~= "GDExtensionClassBinding." ~ wrapperIdentifier;
            if (parent.isBuiltinClass) // Adds method pointer accessor instead of template itself
                ret ~= ".mb";
            ret ~= ", ";
            if (is_static) {
                if (parent.isBuiltinClass)
                    ret ~= "null";
                else
                    ret ~= "godot_object.init";
            }
            else {
                if (parent.isBuiltinClass)
                    ret ~= "cast(void*) &_godot_object";
                else
                    ret ~= "_godot_object";
            }
            foreach (ai, const arg; arguments) {
                // FIXME: const cast hack
                // FIXME: make auto-cast in escapeDType?
                // FIXME: StringName pointer wrapping should be in call handlers
                //        it also relies on that ugly cast.
                //        The problem is that for some reason that call expects StringName**
                //        and unlike C++ I haven't come with a way to do that
                //if (arg.type.godotType == "StringName" && callType == "callBuiltinMethod")
                //    ret ~= ", cast(void*) " ~ arg.name.escapeDType(arg.type.godotType); 
                if (isCopyCtor) {
                    // this is needed to break infinite copy construction loop
                    ret ~= ", cast(void*) &" ~ arg.name.escapeDType(arg.type.godotType);
                }
                else
                    ret ~= ", cast() " ~ arg.name.escapeDType(arg.type.godotType); 
            }
            ret ~= ");\n";
            // wrap temporary object, but for core types such as strings just return the handle as is
            if (isConstructor) {
                if (parent.name.canBeCopied || return_type.isCoreType) {
                    ret ~= "\t\treturn _godot_object;\n";
                } else {
                    ret ~= "\t\treturn " ~ return_type.dType ~ "(_godot_object);\n";
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
    /// 	GDExtensionClassBinding.method_append.mb = gdextension_interface_clasdb_get_methodbind("class", "method", hash);
    string loader() const {
        char[] buf;
        buf ~= "StringName classname = StringName(\"" ~ parent.name.godotType ~ "\");\n";
        buf ~= "StringName methodname = StringName(\"" ~ name ~ "\");\n";
        // probably better to move in its own subclass
        if (parent.isBuiltinClass) {
            return cast(string) buf ~ format(`GDExtensionClassBinding.%s.mb = gdextension_interface_variant_get_ptr_builtin_method(%s, cast(GDExtensionStringNamePtr) methodname, %d);`,
                wrapperIdentifier,
                parent.name.asNativeVariantType,
                hash
            );
        }

        return cast(string) buf ~ format(`GDExtensionClassBinding.%s.mb = gdextension_interface_classdb_get_method_bind(cast(GDExtensionStringNamePtr) classname, cast(GDExtensionStringNamePtr) methodname, %d);`,
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
    @serdeOptional
    string getter, setter;
    @serdeOptional
    int index = -1;

@serdeIgnore:

    string ddoc;

    string getterSource(in GodotMethod m) const {
        string retType = m.return_type.dType;
        string ret;
        ret ~= "\t/**\n\t" ~ ddoc.replace("\n", "\n\t") ~ "\n\t*/\n";
        ret ~= "\t@property " ~ Type.get(retType).dRef ~ " " ~ name.replace("/", "_")
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


class StringHelperGodotMethod : GodotMethod {
    override string body_() const {
        // simply forwards all arguments to the actual method but wrap any string types
        string ret;

        // wrap string types before calling the method
        foreach (i, const arg; arguments) {
            auto realType = redirectsTo.arguments[i].type;
            if (realType.isGodotStringType) {
                // writes something like this:
                // StringName arg3 = StringName(p_name);
                ret ~= "\t\t" ~ escapeDType(realType.dType) ~ " arg" ~ text(cast(int) i) 
                    ~ " = " ~ escapeDType(realType.dType) ~ "(" ~ escapeDType(arg.name) ~ ");\n";
            }
            //ret ~= "\t\t_GODOT_args[" ~ text(cast(int) i) ~ "] = " ~ escapeDType(arg.name) ~ ";\n";
        }

        if (return_type.dType != "void") {
            ret ~= "\t\treturn ";
        }
        else {
            ret ~= "\t\t";
        }

        // now write the normal D method(not a godot one) call with wrapped arguments in place of D strings
        ret ~= name.snakeToCamel.escapeDType ~ "(";
        foreach (ai, const arg; arguments) {
            if (ai) {
                ret ~= ", ";
            }
            if (redirectsTo.arguments[ai].type.isGodotStringType) {
                ret ~= "arg" ~ text(cast(int) ai);
            }
            else {
                ret ~= arg.name.escapeDType; 
            }
        }
        if (has_varargs) {
            if (arguments.length != 0)
                ret ~= ", ";
            ret ~= "varArgs";
        }
        ret ~= ");\n";
        return ret;
    }
}

class GodotUtilityFunction : GodotMethod {

    override string callType() const { 
        return "callBuiltinFunction";
    }

    /// formats function pointer loader, e.g.
    /// 	_handle = gdextension_interface_variant_get_ptr_utility_function("method", hash);
    override string loader() const {
        char[] buf;
        buf ~= "StringName methodname = StringName(\"" ~ name ~ "\");\n";

        return cast(string) buf ~ format(`_handle = gdextension_interface_variant_get_ptr_utility_function(cast(GDExtensionStringNamePtr) methodname, %d);`,
            hash,
        );
    }

    override string signature() const {
        auto ret = "static " ~ return_type.dType ~ " " ~ name.snakeToCamel.escapeDType ~ "(";

        foreach (i, const arg; arguments) {
            if (i) ret ~= ", ";
            ret ~= "in " ~ arg.type.dType ~ " " ~ arg.name.escapeDType;
        }

        if (has_varargs) {
            if (arguments.length) ret ~= ", ";
            ret ~= "in Variant vargs ...";
        }

        ret ~= ")";

        return ret;
    }

    override string body_() const {
        string ret;
        // static method bind handle
        ret ~= "\t\t__gshared GDExtensionPtrUtilityFunction _handle;\n";

        // load function pointer
        ret ~= "\t\tif (!_handle) {\n";
        // tab() will indent it correctly starting from first element
        ret ~= loader().split('\n').map!(s => s.tab(3)).join('\n') ~ "\n";
        ret ~= "\t\t}\n";

        ret ~= "\t\t";
        if (return_type.dType != "void")
            ret ~= "return ";
        ret ~= callType ~ "!(" ~ return_type.dType  ~ ")(_handle";
        
        foreach (ai, const arg; arguments) {
            // even though most of the function uses primitive types there is still cases where it can take other types
            ret ~= ", cast() " ~ arg.name.escapeDType(arg.type.godotType); 
        }

        if (has_varargs) {
            ret ~= ", vargs";
        }
        ret ~= ");\n";
        return ret;
    }

}

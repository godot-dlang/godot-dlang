module api.methods;

import godotutil.string;
import api.classes, api.enums, api.util;

import asdf;

import std.range;
import std.algorithm.searching, std.algorithm.iteration;
import std.path;
import std.conv : text;
import std.string;





class GodotMethod
{
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
	
	
	void finalizeDeserialization(Asdf data)
	{
		if (!return_type)
			return_type = Type.get("void");
		foreach(i, ref a; arguments)
		{
			a.index = i;
			a.parent = this;
		}
	}
	
	@serdeIgnore:
	GodotClass parent;
	
	string ddoc;

	Constructor isConstructor() const { return null; }
	// Operator isOperator() { return null; }
	// Indexer isIndexer() { return null; }
	
	bool same(in GodotMethod other) const
	{
		return name == other.name && is_const == other.is_const;
	}
	
	string templateArgsString() const
	{
		string ret = "";
		bool first = true; // track first arg to skip comma
		foreach(i, ref a; arguments)
		{
			if(a.type.acceptImplicit)
			{
				if(first) first = false;
				else ret ~= ", ";
				ret ~= text(a.type.godot, "Arg", i);
			}
		}
		if(has_varargs)
		{
			if(!first) ret ~= ", ";
			ret ~= "VarArgs...";
		}
		// template parens only if it actually is a template
		if(ret.length != 0) ret = text("(", ret, ")");
		return ret;
	}
	
	string argsString() const
	{
		string ret = "(";
		bool hasDefault = false;
		foreach(i, ref a; arguments)
		{
			if(i != 0) ret ~= ", ";
			if(a.type.acceptImplicit) ret ~= text(a.type.dCallParamPrefix,
				a.type.godot, "Arg", i);
			else ret ~= text(a.type.dCallParamPrefix, a.type.d);
			
			ret ~= " " ~ a.name.escapeD;
			if(a.has_default_value || hasDefault)
			{
				ret ~= " = " ~ escapeDefault(a.type, a.default_value);
			}
		}
		if(has_varargs)
		{
			if(arguments.length != 0) ret ~= ", ";
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
	string binding() const
	{
		string ret;

		ret ~= "\t\t@GodotName(\""~name~"\") GodotMethod!("~return_type.d;
		foreach(ai, const a; arguments)
		{
			ret ~= ", " ~ a.type.d;
		}
		if(has_varargs) ret ~= ", GodotVarArgs";
		ret ~= ") " ~ wrapperIdentifier ~ ";\n";
		
		return ret;
	}

	/// Function pointer name for this method
	/// 	"constructor_new_0", "method_normalize", ...
	string wrapperIdentifier() const
	{
		return funKindName ~ "_" ~ name.snakeToCamel.escapeD;
	}

	/// Function type name used in some cases: like "method", "ctor", "getter", etc...
	string funKindName() const 
	{
		return "method";
	} 
	
	/++ 
	Formats whole method including function signature and body with implementation.
	e.g.:

		Array slice(in long begin, in long end, in long step, in bool deep) const
		{
			if (!GDNativeGDNativeClassBinding.method_slice)
				GDNativeClassBinding.slice = _godot_api.get_method_bind("Class", "Method", 42);
			return callBuiltinMethod!(Array)(cast(GDNativePtrBuiltInMethod) GDNativeClassBinding.slice.mb, cast(void*) &_godot_object, cast() begin, cast() end, cast() step, cast() deep);
		}
	+/
	string source() const
	{
		string ret;

		// ddoc comment (if any)
		ret ~= "\t/**\n\t"~ddoc.replace("\n", "\n\t")~"\n\t*/\n";
		ret ~= "\t";

		ret ~= signature();

		ret ~= "\n\t{\n";

			ret ~= body_();

		ret ~= "\t}\n";
		
		return ret;
	}

	/// Formats function signature, e.g.
	///   Array slice(in long begin, in long end, in long step, in bool deep) const
	string signature() const
	{
		string ret;

		// optional static modifier
		if (isConstructor)
			ret ~= "static ";
		// note that even though it strips constness of return type the method is still marked const
		// const in D is transitive, which means compiler should disallow modifying returned reference types
		ret ~= return_type.stripConst.dRef~" ";
		// none of the types (Classes/Core/Primitive) are pointers in D
		// Classes are reference types; the others are passed by value.
		ret ~= name.snakeToCamel.escapeD;
		
		ret ~= templateArgsString;
		ret ~= argsString;
		
		// function const attribute
		if(is_const) ret ~= " const";
		else if(name == "callv" && parent.name.godot == "Object") ret ~= " const"; /// HACK

		return ret;
	}

	/// Formats body containing implementation, omitting outer braces
	string body_() const
	{
		string ret;

		// load function pointer
		ret ~= "\t\tif (!GDNativeClassBinding." ~ wrapperIdentifier ~ ".mb)\n";
		ret ~= "\t\t\t" ~ loader() ~ "\n";

		if(is_virtual || has_varargs)
		{
			// keep it like this for now, serves as example.
			// function will put normal arguments first, then varargs
			// next, in order to call that function we need actually array of pointers
			// after that we call the function with array of pointers instead of plain args array
			version(none) if (name == "emit_signal")
			{
				// two tabs
				ret ~=`		Variant[varArgs.length+2] _GODOT_args;
	_GODOT_args[0] = String("emit_signal");
	_GODOT_args[1] = signal;
	foreach(vai, VA; VarArgs)
	{
		_GODOT_args[vai+2] = Variant(varArgs[vai]);
	}
	Variant*[varArgs.length+2] _args;
	foreach(i; 0.._GODOT_args.length)
	{
		_args[i] = &_GODOT_args[i];
	}
	Variant ret;
	GDNativeCallError err;
	_godot_api.object_method_bind_call(GDNativeClassBinding.method_emitSignal.mb, _godot_object.ptr, cast(void**) _args.ptr, _GODOT_args.length, cast(void*) &ret, &err);
	debug if (int code = ret.as!int())
	{
		import godot.d;
		print("signal error: ", signal, " code: ", code);
	}
	return cast(GodotError) err.error;`;
			}

			// static array must have at least 1 element
			import std.algorithm : max;
			int argsLength = max(1, (cast(int)arguments.length));
			// choose between varargs and regular function for arguments
			if (has_varargs)
			{
				ret ~= "\t\tVariant[varArgs.length+"~ text(argsLength) ~"] _GODOT_args;\n";
				ret ~= "\t\tVariant*[varArgs.length+"~ text(argsLength) ~"] _args;\n";
			}
			else 
			{
				ret ~= "\t\tVariant["~ text(argsLength) ~"] _GODOT_args;\n";
				ret ~= "\t\tVariant*["~ text(argsLength) ~"] _args;\n";

			}
			foreach(i, const a; arguments)
			{
				// gathers normal parameters in variant array to be later used as pointers
				ret ~= "\t\t_GODOT_args[" ~ text(cast(int)i) ~"] = "~escapeD(a.name)~";\n";
			}
			
			if(has_varargs)
			{
				// copy varargs after regular args
				ret ~= "\t\tforeach(vai, VA; VarArgs)\n";
				ret ~= "\t\t{\n";
				ret ~= "\t\t\t_GODOT_args[vai+"~ text(cast(int)arguments.length) ~"] = Variant(varArgs[vai]);\n";
				ret ~= "\t\t}\n";
			}

			// make pointer array
			ret ~= "\t\tforeach(i; 0.._GODOT_args.length)\n";
			ret ~= "\t\t{\n";
			ret ~= "\t\t\t_args[i] = &_GODOT_args[i];\n";
			ret ~= "\t\t}\n";
			
			//ret ~= "\t\tStringName _GODOT_method_name = StringName(\""~name~"\");\n";

			ret ~= "\t\tVariant ret;\n";
			ret ~= "\t\tGDNativeCallError err;\n";
			ret ~= "\t\t_godot_api.object_method_bind_call(GDNativeClassBinding." ~ wrapperIdentifier ~ ".mb, cast(void*) _godot_object.ptr, cast(void**) _args.ptr, _GODOT_args.length, cast(void*) &ret, &err);\n";
			ret ~= "\t\t";
			if(return_type.d != "void")
			{
				ret ~= "return ";
				if(return_type.d != "Variant")
					ret ~= "ret.as!(RefOrT!("~return_type.stripConst.d~"))";
				else ret ~= "ret";
				ret ~= ";\n";
			} 
		} // end varargs/virtual impl
		else
		{
			// add temp variable for static ctor
			if (isConstructor)
			{
				if (parent.name.canBeCopied)
					ret ~= parent.name.d;
				else
					ret ~= parent.name.opaqueType;
				ret ~= " _godot_object;\n\t\t";
			}
			// omit return for constructors, it will be wrapped and returned later
			if(return_type.d != "void" && !(isConstructor && parent.name.isCoreType)) ret ~= "return ";
			ret ~= callType() ~ "!(" ~ return_type.d ~ ")(";
			if (parent.isBuiltinClass)
				ret ~= "cast(GDNativePtrBuiltInMethod) ";
			ret ~= "GDNativeClassBinding." ~ wrapperIdentifier;
			if (parent.isBuiltinClass)  // Adds method pointer accessor instead of template itself
				ret ~= ".mb";
			ret ~= ", ";
			if (parent.isBuiltinClass)
				ret ~= "cast(void*) &_godot_object";
			else
				ret ~= "_godot_object";
			foreach(ai, const a; arguments)
			{
				ret ~= ", cast() "~a.name.escapeD; // FIXME: const cast hack
			}
			ret ~= ");\n";
			// wrap temporary object
			if (isConstructor)
			{
				if (parent.name.canBeCopied)
					ret ~= "\t\treturn _godot_object;\n";
				else
					ret ~= "\t\treturn " ~ return_type.d ~ "(_godot_object);\n";
			}
		} // end normal method impl

		return ret;
	}

	/// call type wrapper, "ptrcall", "callv", "callBuiltinMethod", etc...
	string callType() const
	{
		if (parent.isBuiltinClass)
			return "callBuiltinMethod";
		//if (has_varargs)
		//	return "callv";
		return "ptrcall";
	}

	/// formats function pointer loader, e.g.
	/// 	GDNativeClassBinding.method_append.mb = _godot_api.clasdb_get_methodbind("class", "method", hash);
	string loader() const
	{
		// probably better to move in its own subclass
		if (parent.isBuiltinClass)
		{
			return format(`GDNativeClassBinding.%s.mb = _godot_api.variant_get_ptr_builtin_method(%s, "%s", %d);`,
				wrapperIdentifier,
				parent.name.toNativeVariantType,
				name,
				hash
			);
		}

		return format(`GDNativeClassBinding.%s.mb = _godot_api.classdb_get_method_bind("%s", "%s", %d);`,
			wrapperIdentifier,
			parent.name.godot,
			name,
			hash,
		);
	}
}

struct GodotArgument
{
	string name;
	Type type;
	@serdeOptional
	bool has_default_value;
	@serdeOptional
	string default_value;
	
	@serdeIgnore:
	
	size_t index;
	GodotMethod parent;
}

class GodotProperty
{
	string name;
	Type type;
	string getter, setter;
	int index;
	
	@serdeIgnore:
	
	string ddoc;
	
	string getterSource(in GodotMethod m) const
	{
		string ret;
		ret ~= "\t/**\n\t" ~ ddoc.replace("\n", "\n\t") ~ "\n\t*/\n";
		ret ~= "\t@property " ~ m.return_type.d ~ " " ~ name.replace("/","_").snakeToCamel.escapeD ~ "()\n\t{\n"; /// TODO: const?
		ret ~= "\t\treturn " ~ getter.snakeToCamel.escapeD ~ "(";
		if(index != -1) 
		{
			// add cast to enum types
			if (m.arguments[0].type.isEnum)
				ret ~= "cast(" ~ m.arguments[0].type.d ~ ") ";
			ret ~= text(index);
		}
		ret ~= ");\n";
		ret ~= "\t}\n";
		return ret;
	}
	string setterSource(in GodotMethod m) const
	{
		string ret;
		ret ~= "\t/// ditto\n";
		ret ~= "\t@property void " ~ name.replace("/","_").snakeToCamel.escapeD ~ "(" ~ m.arguments[$-1].type.d ~ " v)\n\t{\n";
		ret ~= "\t\t" ~ setter.snakeToCamel.escapeD ~ "(";
		if(index != -1)
		{
			// add cast to enum types
			if (m.arguments[0].type.isEnum)
				ret ~= "cast(" ~ m.arguments[0].type.d ~ ") ";
			ret ~= text(index) ~ ", ";
		} 
		ret ~= "v);\n";
		ret ~= "\t}\n";
		return ret;
	}
}



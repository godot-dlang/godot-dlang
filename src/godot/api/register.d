/++
Initialization, termination, and registration of D libraries in Godot
+/
module godot.api.register;

import godot.util.classes;

import std.format;
import std.meta, std.traits;
import std.experimental.allocator, std.experimental.allocator.mallocator;
import core.stdc.stdlib : malloc, free;

import godot.api.traits;
import godot.api.script;
import godot.api.wrap;
import godot.api.udas;
import godot.api.reference;

import godot, godot.abi;

import godot.abi.gdextension;

// global instance for current library
__gshared GDNativeExtensionClassLibraryPtr _GODOT_library;

enum bool is_(alias a) = is(a);
template fileClassesAsLazyImports(FileInfo f) {
    template classFrom(string className) {
        mixin(
            "alias classFrom = from!\"" ~ f.moduleName ~ "\"" ~ className[f.moduleName.length .. $] ~ ";");
    }

    alias fileClassesAsLazyImports = staticMap!(classFrom, aliasSeqOf!(f.classes));
}

/++
Pass to GodotNativeLibrary to control D runtime initialization/termination.
Default is `yes` unless compiling with BetterC.
+/
enum LoadDRuntime : bool {
    no = false,
    yes = true
}

/++
This mixin will generate the GDExtension C interface functions for this D library.
Pass to it a name string for the library, followed by the GodotScript types to
register, functions to call, and other options to configure Godot-D.

The symbolPrefix must match the GDNativeLibrary's symbolPrefix in Godot.

D runtime will be initialized and terminated, unless you pass $(D LoadDRuntime.no)
or compile with BetterC.

Functions taking GodotInitOptions or no arguments will be called at init.
Functions taking GodotTerminateOptions will be called at termination.

Example:
---
import godot, godot.node;
class TestClass : GodotScript!Node
{ }
mixin GodotNativeLibrary!(
	"testlib",
	TestClass,
	(GodotInitOptions o){ print("Initialized"); },
	(GodotTerminateOptions o){ print("Terminated"); }
);
---
+/
mixin template GodotNativeLibrary(string symbolPrefix, Args...) {
    private static import godot.abi;

    private import godot.abi.gdextension;
    private import godot.abi.core;

    private static import godot.util.classes;
    private import godot.api.reference;

    static if (__traits(compiles, import("classes.csv"))) {
        enum godot.util.classes.ProjectInfo _GODOT_projectInfo = godot.util.classes.ProjectInfo.fromCsv(
                import("classes.csv"));
    } else {
        enum godot.util.classes.ProjectInfo _GODOT_projectInfo = godot.util.classes.ProjectInfo.init;
    }

    /// HACK: empty main to force the compiler to add emulated TLS.
    version (Android) void main() {
    }

    // Windows DLL entry points handle TLS+DRuntime initialization and thread attachment
    version (Windows) {
        version (D_BetterC) {
        } else {
            import core.sys.windows.dll : SimpleDllMain;

            mixin SimpleDllMain;
        }
    }

    /// This is the main entry point declared in your .gdextension file, it will be called by godot engine on load
    pragma(mangle, symbolPrefix ~ "_gdextension_entry")
    export extern (C) static GDNativeBool godot_gdextension_entry(GDNativeInterface* p_interface,
        GDNativeExtensionClassLibraryPtr p_library, GDNativeInitialization* r_initialization) {
        import godot.abi.gdextension;
        import godot.api.reference;
        import std.meta, std.traits;
        import core.runtime : Runtime;
        import godot.api.output;
        import godot.api.traits;
        static import godot.api.register;

        version (Windows) {
        } else {
            version (D_BetterC)
                enum bool loadDRuntime = staticIndexOf!(LoadDRuntime.yes, Args) != -1;
            else
                enum bool loadDRuntime = staticIndexOf!(LoadDRuntime.no, Args) == -1;
            static if (loadDRuntime)
                Runtime.initialize();
        }

        _godot_api = p_interface;
        godot.api.register._GODOT_library = p_library;

        //import core.exception : assertHandler;
        //assertHandler = (options.in_editor) ? (&godotAssertHandlerEditorDebug)
        //	: (&godotAssertHandlerCrash);

        // TODO: explore various stages, for example for making core classes
        r_initialization.minimum_initialization_level = GDNATIVE_INITIALIZATION_SCENE;
        r_initialization.initialize = &initializeLevel;
        r_initialization.deinitialize = &deinitializeLevel;

        foreach (Arg; Args) {
            static if (is(Arg)) {
            }  // is type
            else static if (isCallable!Arg) {
                static if (is(typeof(Arg())))
                    Arg();
                else static if (is(typeof(Arg(options))))
                    Arg(options);
            } else static if (is(typeof(Arg) == LoadDRuntime)) {
            } else {
                static assert(0, "Unrecognized argument <" ~ Arg.stringof ~ "> passed to GodotNativeLibrary");
            }
        }

        return 1; // return OK
    }

    extern (C) void initializeLevel(void* userdata, GDNativeInitializationLevel level) //@nogc nothrow
    {
        //writeln("Initializing level: ", level);
        import std.exception;

        register_types(userdata, level);
    }

    extern (C) void deinitializeLevel(void* userdata, GDNativeInitializationLevel level) //@nogc nothrow
    {
        //writeln("Deinitializing level: ", level);
    }

    static void register_types(void* userdata, GDNativeInitializationLevel level) //@nogc nothrow
    {
        import std.meta, std.traits;
        import godot.api.register : register, fileClassesAsLazyImports;
        import std.array : join;
        import godot.api.output;
        import godot.api.traits;

        // currently only scene-level scripts supportes
        if (level != GDNATIVE_INITIALIZATION_SCENE)
            return;

        alias classList = staticMap!(fileClassesAsLazyImports, aliasSeqOf!(_GODOT_projectInfo.files));
        static foreach (C; NoDuplicates!(classList, Filter!(is_, Args))) {
            static if (is(C)) {
                static if (extendsGodotBaseClass!C) {
                    register!C(_GODOT_library);
                }
            }
        }
    }

    /*
	pragma(mangle, symbolPrefix~"gdnative_terminate")
	export extern(C) static void godot_gdnative_terminate(godot.abi.godot_gdnative_terminate_options* options)
	{
		import std.meta, std.traits;
		import godot.api.script : NativeScriptTemplate;
		import std.array : join;
		import godot.api.output;
		import godot.api.traits;

		alias classList = staticMap!(fileClassesAsLazyImports, aliasSeqOf!(_GODOT_projectInfo.files));
		static foreach(C; NoDuplicates!(classList, Filter!(is_, Args)))
		{
			static if(is(C))
			{
				static if(extendsGodotBaseClass!C)
				{
					NativeScriptTemplate!C.unref();
				}
			}
		}
		
		foreach(Arg; Args)
		{
			static if(is(Arg)) // is type
			{
			}
			else static if(isCallable!Arg)
			{
				static if(is(typeof(Arg(options)))) Arg(options);
			}
			else static if(is(typeof(Arg) == LoadDRuntime)) { }
			else
			{
				static assert(0, "Unrecognized argument <"~Arg.stringof~"> passed to GodotNativeLibrary");
			}
		}
		
		_GODOT_library.unref();

		version(Windows) {}
		else
		{
			import core.runtime : Runtime;
			version(D_BetterC) enum bool loadDRuntime = staticIndexOf!(LoadDRuntime.yes, Args) != -1;
			else enum bool loadDRuntime = staticIndexOf!(LoadDRuntime.no, Args) == -1;
			static if(loadDRuntime) Runtime.terminate();
		}
	}
	*/
}

private extern (C)
godot_variant _GODOT_nop(godot_object o, void* methodData,
    void* userData, int numArgs, godot_variant** args) {
    godot_variant n;
    _godot_api.variant_new_nil(&n);
    return n;
}

/++
Register a class and all its $(D @GodotMethod) member functions into Godot.
+/
void register(T)(GDNativeExtensionClassLibraryPtr lib) if (is(T == class)) {
    import std.array;
    import godot.abi;
    import godot.object, godot.resource;
    import godot.api;

    //static import godot.nativescript;

    static if (BaseClassesTuple!T.length == 2) // base class is GodotScript; use owner
    {
            alias Base = typeof(T.owner);
            alias baseName = Base._GODOT_internal_name;
    }
    else // base class is another D script
    {
            alias Base = BaseClassesTuple!T[0];
            static if (hasUDA!(Base, Rename))
                enum string baseName = godotName!Base;
            else
                enum string baseName = __traits(identifier, Base);
    }

    static if (hasUDA!(T, Rename))
        enum string name = godotName!T;
    else
        enum string name = __traits(identifier, T);
    enum fqn = fullyQualifiedName!T ~ '\0';

    __gshared static GDNativeExtensionClassCreationInfo class_info;
    class_info.create_instance_func = &createFunc!T;
    class_info.free_instance_func = &destroyFunc!T;
    class_info.class_userdata = cast(void*) name.ptr;

    extern (C) static GDNativeExtensionClassCallVirtual getVirtualFn(void* p_userdata, const GDNativeStringNamePtr p_name) {
        import core.stdc.stdio;
        import core.stdc.string;
        import std.conv : to;

        //print("requested method ", *cast(StringName*) p_name);
        // FIXME: StringName issues
        auto v = Variant(*cast(StringName*) p_name);
        wstring str = v.as!String.data();
        static if (__traits(compiles, __traits(getMember, T, "_ready"))) {
            //if (MethodWrapper!(T, __traits(getMember, T, "_ready")).funName == p_name) {
            if (str == "_ready") {
                return cast(GDNativeExtensionClassCallVirtual) 
                    &OnReadyWrapper!(T, __traits(getMember, T, "_ready")).callOnReady;
            }
        }
        return VirtualMethodsHelper!T.findVCall(p_name);
    }

    class_info.get_virtual_func = &getVirtualFn;

    StringName snClass = StringName(name);
    StringName snBase = StringName(baseName);
    _godot_api.classdb_register_extension_class(lib, cast(GDNativeStringNamePtr) snClass, cast(GDNativeStringNamePtr) snBase, &class_info);

    void registerMethod(alias mf, string nameOverride = null)() {
        static if (nameOverride.length) {
            string mfn = nameOverride;
        } else {
            string mfn = godotName!mf;
        }

        uint flags = GDNATIVE_EXTENSION_METHOD_FLAGS_DEFAULT;

        // virtual methods like '_ready'
        if (__traits(identifier, mf)[0] == '_')
            flags |= GDNATIVE_EXTENSION_METHOD_FLAG_VIRTUAL;

        enum isOnReady = godotName!mf == "_ready" && onReadyFieldNames!T.length;

        StringName snFunName = StringName(mfn);
        GDNativeExtensionClassMethodInfo mi = {
            cast(GDNativeStringNamePtr) snFunName , //const char *name;
            &mf, //void *method_userdata;
            &MethodWrapper!(T, mf).callMethod, //GDNativeExtensionClassMethodCall call_func;
            &MethodWrapper!(T, mf).callPtrMethod, //GDNativeExtensionClassMethodPtrCall ptrcall_func;
            flags, //uint32_t method_flags; /* GDNativeExtensionClassMethodFlags */

            cast(GDNativeBool) !is(ReturnType!mf == void), //GDNativeBool has_return_value;
            MethodWrapperMeta!mf.getReturnInfo().ptr, //GDNativePropertyInfo* return_value_info;
            MethodWrapperMeta!mf.getReturnMetadata, //GDNativeExtensionClassMethodArgumentMetadata return_value_metadata;

            cast(uint32_t) arity!mf, //uint32_t argument_count;
            MethodWrapperMeta!mf.getArgInfo().ptr, //GDNativePropertyInfo* arguments_info;
            MethodWrapperMeta!mf.getArgMetadata(), //GDNativeExtensionClassMethodArgumentMetadata* arguments_metadata;

            MethodWrapperMeta!mf.getDefaultArgNum, //uint32_t default_argument_count;
            MethodWrapperMeta!mf.getDefaultArgs(), //GDNativeVariantPtr *default_arguments;
        
        };
        _godot_api.classdb_register_extension_class_method(lib, cast(GDNativeStringNamePtr) snClass, &mi);
        // cache StringName for comparison later on
        MethodWrapper!(T, mf).funName = cast(GDNativeStringNamePtr) snFunName;
    }

    void registerMemberAccessor(alias mf, alias propType, string funcName)() {
        static assert(Parameters!propType.length == 0 || Parameters!propType.length == 1,
            "only getter or setter is allowed with exactly zero or one arguments");

        //static if (funcName) {
        StringName snName = StringName(funcName);
        //} else
        //    StringName snName = StringName(godotName!mf);

        uint flags = GDNATIVE_EXTENSION_METHOD_FLAGS_DEFAULT;

        GDNativeExtensionClassMethodInfo mi = {
            cast(GDNativeStringNamePtr) snName, //const char *name;
            &mf, //void *method_userdata;
            &mf, //GDNativeExtensionClassMethodCall call_func;
            null, //GDNativeExtensionClassMethodPtrCall ptrcall_func;
            flags, //uint32_t method_flags; /* GDNativeExtensionClassMethodFlags */

            cast(GDNativeBool) !is(ReturnType!propType == void), //GDNativeBool has_return_value;
            MethodWrapperMeta!propType.getReturnInfo.ptr,
            MethodWrapperMeta!propType.getReturnMetadata,

            cast(uint32_t) arity!propType, //uint32_t argument_count;
            MethodWrapperMeta!propType.getArgInfo.ptr, //GDNativePropertyInfo* arguments_info;
            MethodWrapperMeta!propType.getArgMetadata, //GDNativeExtensionClassMethodArgumentMetadata* arguments_metadata;

            MethodWrapperMeta!propType.getDefaultArgNum, //uint32_t default_argument_count;
            MethodWrapperMeta!propType.getDefaultArgs(), //GDNativeVariantPtr *default_arguments;
        };

        _godot_api.classdb_register_extension_class_method(lib, cast(GDNativeStringNamePtr) snClass, &mi);
    }

    static foreach (mf; godotMethods!T) {
        {
            static if (hasUDA!(mf, Rename))
                enum string externalName = godotName!mf;
            else
                enum string externalName = (fullyQualifiedName!mf).replace(".", "_");
            registerMethod!mf();
        }
    }

    static foreach (sName; godotSignals!T) {
        {
            alias s = Alias!(mixin("T." ~ sName));
            static assert(hasStaticMember!(T, sName), "Signal declaration " ~ fullyQualifiedName!s
                    ~ " must be static. Otherwise it would take up memory in every instance of " ~ T
                    .stringof);

            static if (hasUDA!(s, Rename))
                enum string externalName = godotName!s;
            else
                enum string externalName = (fullyQualifiedName!s).replace(".", "_");

            __gshared static GDNativePropertyInfo[Parameters!s.length] prop;
            static foreach (int i, p; Parameters!s) {
                static assert(Variant.compatible!p, fullyQualifiedName!s ~ " parameter " ~ i.text ~ " \""
                        ~ ParameterIdentifierTuple!s[i] ~ "\": type " ~ p.stringof ~ " is incompatible with Godot");

                // get name or argN fallback placeholder in case of function pointers
                static if (ParameterIdentifierTuple!s[i].length > 0) {
                    StringName snArgName = StringName(ParameterIdentifierTuple!s[i]);
                }
                else {
                    StringName snArgName = StringName("arg" ~ i.stringof);
                }
                prop[i].name = cast(GDNativeStringNamePtr) snArgName;

                if (Variant.variantTypeOf!p == VariantType.object)
                    prop[i].class_name = cast(GDNativeStringNamePtr) snClass;
                else
                    prop[i].class_name = cast(GDNativeStringNamePtr) StringName();
                prop[i].type = Variant.variantTypeOf!p;
                prop[i].hint = 0;
                prop[i].hint_string = cast(GDNativeStringNamePtr) StringName();
                prop[i].usage = GDNATIVE_EXTENSION_METHOD_FLAGS_DEFAULT;
            }

            StringName snExternalName = StringName(externalName);
            _godot_api.classdb_register_extension_class_signal(
                lib, 
                cast(GDNativeStringNamePtr) snClass, 
                cast(GDNativeStringNamePtr) snExternalName, 
                prop.ptr, 
                Parameters!s.length
            );
        }
    }

    // -------- PROPERTIES

    enum bool matchName(string p, alias a) = (godotName!a == p);
    static foreach (pName; godotPropertyNames!T) {
        {
            alias getterMatches = Filter!(ApplyLeft!(matchName, pName), godotPropertyGetters!T);
            static assert(getterMatches.length <= 1); /// TODO: error message
            alias setterMatches = Filter!(ApplyLeft!(matchName, pName), godotPropertySetters!T);
            static assert(setterMatches.length <= 1);

            static if (getterMatches.length)
                alias P = NonRef!(ReturnType!(getterMatches[0]));
            else
                alias P = Parameters!(setterMatches[0])[0];
            //static assert(!is(P : Ref!U, U)); /// TODO: proper Ref handling
            enum VariantType vt = extractPropertyVariantType!(getterMatches, setterMatches);

            enum Property uda = extractPropertyUDA!(getterMatches, setterMatches);

            __gshared static GDNativePropertyInfo pinfo;


            StringName snPropName = StringName(pName);
            static if (Variant.variantTypeOf!P == VariantType.object) {
                StringName snParamClassName = StringName(godotName!(P));
            }
            else {
                StringName snParamClassName = StringName("");
            }
            static if (uda.hintString.length) {
                StringName snHintString = StringName(uda.hintString);
            }
            else {
                StringName snHintString = StringName("");
            }

            pinfo.class_name = cast(GDNativeStringNamePtr) snParamClassName;
            pinfo.type = vt;
            pinfo.name = cast(GDNativeStringNamePtr) snPropName;
            pinfo.hint = GDNATIVE_EXTENSION_METHOD_ARGUMENT_METADATA_NONE;
            //pinfo.usage = GDNATIVE_EXTENSION_METHOD_FLAGS_DEFAULT | GDNATIVE_EXTENSION_METHOD_FLAG_EDITOR;
            pinfo.usage = 7; // godot-cpp uses 7 as value which is default|const|editor currently, doesn't shows up in inspector without const. WTF?
            pinfo.hint_string = cast(GDNativeStringNamePtr) snHintString;

            // register acessor methods for that property
            static if (getterMatches.length) {
                enum get_prop = "get_" ~ pName ~ '\0';
                registerMethod!(getterMatches[0], cast(string) get_prop);
            } else
                enum get_prop = string.init;

            static if (setterMatches.length) {
                enum set_prop = "set_" ~ pName ~ '\0';
                registerMethod!(setterMatches[0], cast(string) set_prop);
            } else
                enum set_prop = string.init;

            StringName snSetProp = StringName(set_prop);
            StringName snGetProp = StringName(get_prop);
            _godot_api.classdb_register_extension_class_property(
                lib, 
                cast(GDNativeStringNamePtr) snClass, 
                &pinfo, 
                cast(GDNativeStringNamePtr) snSetProp, 
                cast(GDNativeStringNamePtr) snGetProp
            );
        }
    }
    static foreach (pName; godotPropertyVariableNames!T) {
        {
            import std.string;

            alias P = typeof(mixin("T." ~ pName));
            enum Variant.Type vt = Variant.variantTypeOf!P;
            alias udas = getUDAs!(mixin("T." ~ pName), Property);
            enum Property uda = is(udas[0]) ? Property.init : udas[0];

            __gshared static GDNativePropertyInfo pinfo;

            StringName snPropName = StringName(pName);
            static if (Variant.variantTypeOf!P == VariantType.object) {
                StringName snPName = StringName(godotName!(P));
            }
            else {
                StringName snPName = StringName("");
            }
            pinfo.class_name = cast(GDNativeStringNamePtr) snPName;
            pinfo.type = vt;
            pinfo.name = cast(GDNativeStringNamePtr) snPropName;
            pinfo.usage = GDNATIVE_EXTENSION_METHOD_FLAGS_DEFAULT | GDNATIVE_EXTENSION_METHOD_FLAG_EDITOR;
            static if (uda.hintString.length)
                pinfo.hint_string = uda.hintString;
            else
                pinfo.hint_string = cast(GDNativeStringNamePtr) StringName();

            // register acessor methods for that property
            enum get_prop = "get_" ~ pName ~ '\0';
            alias fnWrapper = VariableWrapper!(T, __traits(getMember, T, pName));
            static fnWrapper.getterType getterTmp; // dummy func for now because current registration code requires actual function, and there isn't one
            registerMemberAccessor!(fnWrapper.callPropertyGet, getterTmp, cast(string) get_prop);

            enum set_prop = "set_" ~ pName ~ '\0';
            static fnWrapper.setterType setterTmp; // dummy func for now because current registration code requires actual function, and there isn't one
            registerMemberAccessor!(fnWrapper.callPropertySet, setterTmp, cast(string) set_prop);

            StringName snSetProp = StringName(set_prop);
            StringName snGetProp = StringName(get_prop);
            _godot_api.classdb_register_extension_class_property(
                lib, 
                cast(GDNativeStringNamePtr) snClass, 
                &pinfo, 
                cast(GDNativeStringNamePtr) snSetProp, 
                cast(GDNativeStringNamePtr) snGetProp 
            );
        }
    }

    static foreach (E; godotEnums!T) {
        {
            static foreach (int i, ev; __traits(allMembers, E)) {
                //pragma(msg, ev, ":", cast(int) __traits(getMember, E, ev));
                // FIXME: static foreach scope complains about duplicate names
                mixin("StringName snEnum" ~ i.stringof ~ " = StringName(__traits(identifier, E));");
                mixin("StringName snVal" ~ i.stringof ~ "= StringName(ev);");
                _godot_api.classdb_register_extension_class_integer_constant(
                    lib, 
                    cast(GDNativeStringNamePtr) snClass, 
                    cast(GDNativeStringNamePtr) mixin("snEnum"~i.stringof), 
                    cast(GDNativeStringNamePtr) mixin("snVal"~i.stringof), 
                    cast(int) __traits(getMember, E, ev), 
                    false
                );
            }
        }
    }

    static foreach (pName; godotConstants!T) {
        {
            alias E = __traits(getMember, T, pName);
            //pragma(msg, pName, ":", cast(int) E);
            // FIXME: static foreach scope complains about duplicate names
            mixin("StringName snProp" ~ pName ~ " = StringName(pName);");
            _godot_api.classdb_register_extension_class_integer_constant(
                lib, 
                cast(GDNativeStringNamePtr) snClass, 
                cast(GDNativeStringNamePtr) StringName(), 
                cast(GDNativeStringNamePtr) mixin("snProp"~pName), 
                cast(int) E, 
                false
            );
        }
    }

    /*
	auto icf = godot_instance_create_func(&createFunc!T, null, null);
	auto idf = godot_instance_destroy_func(&destroyFunc!T, null, null);
	
	static if(hasUDA!(T, Tool)) _godot_nativescript_api.godot_nativescript_register_tool_class(handle, name, baseName, icf, idf);
	else _godot_nativescript_api.godot_nativescript_register_class(handle, name, baseName, icf, idf);
	
	if(GDNativeVersion.hasNativescript!(1, 1))
	{
		_godot_nativescript_api.godot_nativescript_set_type_tag(handle, name, NativeScriptTag!T.tag);
	}
	else // register a no-op function that indicates this is a D class
	{
		godot_instance_method md;
		md.method = &_GODOT_nop;
		md.free_func = null;
		_godot_nativescript_api.godot_nativescript_register_method(handle, name, "_GDNATIVE_D_typeid", godot_method_attributes.init, md);
	}
	
	static foreach(mf; godotMethods!T)
	{{
		godot_method_attributes ma;
		static if(is( getUDAs!(mf, Method)[0] )) ma.rpc_type = godot_method_rpc_mode
			.GODOT_METHOD_RPC_MODE_DISABLED;
		else
		{
			ma.rpc_type = cast(godot_method_rpc_mode)(getUDAs!(mf, Method)[0].rpcMode);
		}
		
		godot_instance_method md;
		static if(godotName!mf == "_ready" && onReadyFieldNames!T.length)
		{
			md.method = &OnReadyWrapper!T.callOnReady;
		}
		else md.method = &MethodWrapper!(T, mf).callMethod;
		md.free_func = null;
		
		char[godotName!mf.length+1] mfn = void;
		mfn[0..godotName!mf.length] = godotName!mf[];
		mfn[$-1] = '\0';
		_godot_nativescript_api.godot_nativescript_register_method(handle, name, mfn.ptr, ma, md);
	}}
	
	// OnReady when there is no _ready method
	static if(staticIndexOf!("_ready", staticMap!(godotName, godotMethods!T)) == -1
		&& onReadyFieldNames!T.length)
	{
		enum ma = godot_method_attributes.init;
		godot_instance_method md;
		md.method = &OnReadyWrapper!T.callOnReady;
		_godot_nativescript_api.godot_nativescript_register_method(handle, name, "_ready", ma, md);
	}
	
	static foreach(sName; godotSignals!T)
	{{
		alias s = Alias!(mixin("T."~sName));
		static assert(hasStaticMember!(T, sName), "Signal declaration "~fullyQualifiedName!s
			~" must be static. Otherwise it would take up memory in every instance of "~T.stringof);
		
		godot_signal gs;
		(*cast(String*)&gs.name) = String(godotName!s);
		gs.num_args = Parameters!s.length;
		
		static if(Parameters!s.length)
		{
			godot_signal_argument[Parameters!s.length] args;
			gs.args = args.ptr;
		}
		
		foreach(pi, P; Parameters!s)
		{
			static assert(Variant.compatible!P, fullyQualifiedName!s~" parameter "~pi.text~" \""
				~ParameterIdentifierTuple!s[pi]~"\": type "~P.stringof~" is incompatible with Godot");
			static if(ParameterIdentifierTuple!s[pi].length > 0)
			{
				(*cast(String*)&args[pi].name) = String(ParameterIdentifierTuple!s[pi]);
			}
			else
			{
				(*cast(String*)&args[pi].name) = (String(P.stringof) ~ String("Arg") ~ Variant(pi).as!String);
			}
			args[pi].type = Variant.variantTypeOf!P;
			args[pi].usage = cast(godot_property_usage_flags)Property.Usage.defaultUsage;
		}
		
		_godot_nativescript_api.godot_nativescript_register_signal(handle, name, &gs);
	}}
	
	enum bool matchName(string p, alias a) = (godotName!a == p);
	static foreach(pName; godotPropertyNames!T)
	{{
		alias getterMatches = Filter!(ApplyLeft!(matchName, pName), godotPropertyGetters!T);
		static assert(getterMatches.length <= 1); /// TODO: error message
		alias setterMatches = Filter!(ApplyLeft!(matchName, pName), godotPropertySetters!T);
		static assert(setterMatches.length <= 1);
		
		godot_property_set_func sf;
		godot_property_get_func gf;
		godot_property_attributes attr;
		
		static if(getterMatches.length) alias P = NonRef!(ReturnType!(getterMatches[0]));
		else alias P = Parameters!(setterMatches[0])[0];
		static assert(!is(P : Ref!U, U)); /// TODO: proper Ref handling
		enum Variant.Type vt = extractPropertyVariantType!(getterMatches, setterMatches);
		attr.type = cast(godot_int)vt;
		
		enum Property uda = extractPropertyUDA!(getterMatches, setterMatches);
		attr.rset_type = cast(godot_method_rpc_mode)uda.rpcMode;
		attr.hint = cast(godot_property_hint)uda.hint;

		static if(vt == Variant.Type.object && extends!(P, Resource))
		{
			attr.hint |= godot_property_hint.GODOT_PROPERTY_HINT_RESOURCE_TYPE;
		}

		static if(uda.hintString.length) _godot_api.string_parse_utf8(
			&attr.hint_string, uda.hintString.ptr);
		else
		{
			static if(vt == Variant.Type.object)
			{
				_godot_api.string_parse_utf8(&attr.hint_string,
					GodotClass!P._GODOT_internal_name);
			}
			else _godot_api.string_new(&attr.hint_string);
		}
		attr.usage = cast(godot_property_usage_flags)(uda.usage |
			Property.Usage.scriptVariable);
		
		Variant defval;
		static if(getterMatches.length) enum gDef = hasUDA!(getterMatches[0], DefaultValue);
		else enum gDef = false;
		static if(setterMatches.length) enum sDef = hasUDA!(setterMatches[0], DefaultValue);
		else enum sDef = false;

		static if(gDef || sDef)
		{
			static if(gDef) alias defExprSeq = TemplateArgsOf!(getUDAs!(getterMatches[0], DefaultValue)[0]);
			else alias defExprSeq = TemplateArgsOf!(getUDAs!(setterMatches[0], DefaultValue)[0]);
			defval = defExprSeq[0];
		}
		else static if( is(typeof( { P p; } )) ) // use type's default value
		{
			static if(isFloatingPoint!P)
			{
				// Godot doesn't support NaNs. Initialize properties to 0.0 instead.
				defval = 0.0;
			}
			else defval = P.init;
		}
		else
		{
			/// FIXME: call default constructor function
			defval = null;
		}
		attr.default_value = defval._godot_variant;
		
		static if(getterMatches.length)
		{
			alias GetWrapper = MethodWrapper!(T, getterMatches[0]);
			gf.get_func = &GetWrapper.callPropertyGet;
			gf.free_func = null;
		}
		else
		{
			gf.get_func = &emptyGetter;
		}
		
		static if(setterMatches.length)
		{
			alias SetWrapper = MethodWrapper!(T, setterMatches[0]);
			sf.set_func = &SetWrapper.callPropertySet;
			sf.free_func = null;
		}
		else
		{
			sf.set_func = &emptySetter;
		}
		
		char[pName.length+1] pn = void;
		pn[0..pName.length] = pName[];
		pn[$-1] = '\0';
		_godot_nativescript_api.godot_nativescript_register_property(handle, name, pn.ptr, &attr, sf, gf);
	}}
	static foreach(pName; godotPropertyVariableNames!T)
	{{
		import std.string;
		
		godot_property_set_func sf;
		godot_property_get_func gf;
		godot_property_attributes attr;
		
		alias P = typeof(mixin("T."~pName));
		enum Variant.Type vt = Variant.variantTypeOf!P;
		attr.type = cast(godot_int)vt;
		
		alias udas = getUDAs!(mixin("T."~pName), Property);
		enum Property uda = is(udas[0]) ? Property.init : udas[0];
		attr.rset_type = cast(godot_method_rpc_mode)uda.rpcMode;
		attr.hint = cast(godot_property_hint)uda.hint;

		static if(vt == Variant.Type.object && is(GodotClass!P : Resource))
		{
			attr.hint |= godot_property_hint.GODOT_PROPERTY_HINT_RESOURCE_TYPE;
		}

		static if(uda.hintString.length) _godot_api.string_parse_utf8(
			&attr.hint_string, uda.hintString.ptr);
		else
		{
			static if(vt == Variant.Type.object)
			{
				_godot_api.string_parse_utf8(&attr.hint_string,
					GodotClass!P._GODOT_internal_name);
			}
			else _godot_api.string_new(&attr.hint_string);
		}
		attr.usage = cast(godot_property_usage_flags)uda.usage |
			cast(godot_property_usage_flags)Property.Usage.scriptVariable;
		
		Variant defval = getDefaultValueFromAlias!(T, pName)();
		attr.default_value = defval._godot_variant;
		
		alias Wrapper = VariableWrapper!(T, pName);
		
		{
			gf.method_data = null;
			gf.get_func = &Wrapper.callPropertyGet;
			gf.free_func = null;
		}
		
		{
			sf.method_data = null;
			sf.set_func = &Wrapper.callPropertySet;
			sf.free_func = null;
		}
		
		enum pnLength = godotName!(mixin("T."~pName)).length;
		char[pnLength+1] pn = void;
		pn[0..pnLength] = godotName!(mixin("T."~pName))[];
		pn[$-1] = '\0';
		_godot_nativescript_api.godot_nativescript_register_property(handle, name, pn.ptr, &attr, sf, gf);
	}}
	
	
	
	godot.api.script.NativeScriptTemplate!T = memnew!(godot.nativescript.NativeScript);
	godot.api.script.NativeScriptTemplate!T.setLibrary(lib);
	godot.api.script.NativeScriptTemplate!T.setClassName(String(name));
	*/
}

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
__gshared GDExtensionClassLibraryPtr _GODOT_library;

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

The symbolPrefix must match the GDExtensionLibrary's symbolPrefix in Godot.

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
    export extern (C) static GDExtensionBool godot_gdextension_entry(GDExtensionInterface* p_interface,
        GDExtensionClassLibraryPtr p_library, GDExtensionInitialization* r_initialization) {
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
        r_initialization.minimum_initialization_level = GDEXTENSION_INITIALIZATION_SCENE;
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

    extern (C) void initializeLevel(void* userdata, GDExtensionInitializationLevel level) //@nogc nothrow
    {
        //writeln("Initializing level: ", level);
        import std.exception;

        register_types(userdata, level);
    }

    extern (C) void deinitializeLevel(void* userdata, GDExtensionInitializationLevel level) //@nogc nothrow
    {
        //writeln("Deinitializing level: ", level);

        unregister_types(userdata, level);
    }

    static void register_types(void* userdata, GDExtensionInitializationLevel level) //@nogc nothrow
    {
        import std.meta, std.traits;
        import godot.api.register : register, fileClassesAsLazyImports;
        import std.array : join;
        import godot.api.output;
        import godot.api.traits;

        // currently only scene-level scripts supportes
        if (level != GDEXTENSION_INITIALIZATION_SCENE)
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

    static void unregister_types(void* userdata, GDExtensionInitializationLevel level)
    {
        import std.meta, std.traits;
        import godot.api.register : register, fileClassesAsLazyImports;
        import std.array : join;
        import godot.api.output;
        import godot.api.traits;

        // currently only scene-level scripts supported
        if (level != GDEXTENSION_INITIALIZATION_SCENE)
            return;

        // TODO: this will likely crash in a real project, classes has to be sorted in such way that
        // descendants unregistered before parent
        alias classList = staticMap!(fileClassesAsLazyImports, aliasSeqOf!(_GODOT_projectInfo.files));
        static foreach (C; NoDuplicates!(classList, Filter!(is_, Args))) {
            static if (is(C)) {
                static if (extendsGodotBaseClass!C) {
                    unregister!C(_GODOT_library);
                }
            }
        }

        version(Windows) {}
		else
		{
			import core.runtime : Runtime;
			version(D_BetterC) enum bool loadDRuntime = staticIndexOf!(LoadDRuntime.yes, Args) != -1;
			else enum bool loadDRuntime = staticIndexOf!(LoadDRuntime.no, Args) == -1;
			static if(loadDRuntime) Runtime.terminate();
		}
    }
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
void register(T)(GDExtensionClassLibraryPtr lib) if (is(T == class)) {
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

    // NOTE: Keep in sync with script.d createFunc(T) template
    static if (hasUDA!(T, Rename))
        enum string name = godotName!T;
    else
        enum string name = __traits(identifier, T);
    enum fqn = fullyQualifiedName!T ~ '\0';

    __gshared static GDExtensionClassCreationInfo class_info;
    class_info.create_instance_func = &createFunc!T;
    class_info.free_instance_func = &destroyFunc!T;
    class_info.class_userdata = cast(void*) name.ptr;

    extern (C) static GDExtensionClassCallVirtual getVirtualFn(void* p_userdata, const GDExtensionStringNamePtr p_name) {
        import core.stdc.stdio;
        import core.stdc.string;
        import std.conv : to;

        //print("requested method ", *cast(StringName*) p_name);
        // FIXME: StringName issues
        auto v = Variant(*cast(StringName*) p_name);
        auto str = v.as!String.data();
        static if (__traits(compiles, __traits(getMember, T, "_ready"))) {
            //if (MethodWrapper!(T, __traits(getMember, T, "_ready")).funName == p_name) {
            if (str == "_ready") {
                return cast(GDExtensionClassCallVirtual) 
                    &OnReadyWrapper!(T, __traits(getMember, T, "_ready")).callOnReady;
            }
        }
        return VirtualMethodsHelper!T.findVCall(p_name);
    }

    class_info.get_virtual_func = &getVirtualFn;

    StringName snClass = StringName(name);
    StringName snBase = StringName(baseName);
    _godot_api.classdb_register_extension_class(lib, cast(GDExtensionStringNamePtr) snClass, cast(GDExtensionStringNamePtr) snBase, &class_info);

    void registerMethod(alias mf, string nameOverride = null)() {
        static if (nameOverride.length) {
            string mfn = nameOverride;
        } else {
            string mfn = godotName!mf;
        }

        uint flags = GDEXTENSION_METHOD_FLAGS_DEFAULT;

        // virtual methods like '_ready'
        if (__traits(identifier, mf)[0] == '_')
            flags |= GDEXTENSION_METHOD_FLAG_VIRTUAL;

        if (__traits(isStaticFunction, mf))
            flags = GDEXTENSION_METHOD_FLAG_STATIC;

        enum isOnReady = godotName!mf == "_ready" && onReadyFieldNames!T.length;

        StringName snFunName = StringName(mfn);
        GDExtensionClassMethodInfo mi = {
            cast(GDExtensionStringNamePtr) snFunName , //const char *name;
            &mf, //void *method_userdata;
            &MethodWrapper!(T, mf).callMethod, //GDExtensionClassMethodCall call_func;
            &MethodWrapper!(T, mf).callPtrMethod, //GDExtensionClassMethodPtrCall ptrcall_func;
            flags, //uint32_t method_flags; /* GDExtensionClassMethodFlags */

            cast(GDExtensionBool) !is(ReturnType!mf == void), //GDExtensionBool has_return_value;
            MethodWrapperMeta!mf.getReturnInfo().ptr, //GDExtensionPropertyInfo* return_value_info;
            MethodWrapperMeta!mf.getReturnMetadata, //GDExtensionClassMethodArgumentMetadata return_value_metadata;

            cast(uint32_t) arity!mf, //uint32_t argument_count;
            MethodWrapperMeta!mf.getArgInfo().ptr, //GDExtensionPropertyInfo* arguments_info;
            MethodWrapperMeta!mf.getArgMetadata(), //GDExtensionClassMethodArgumentMetadata* arguments_metadata;

            MethodWrapperMeta!mf.getDefaultArgNum, //uint32_t default_argument_count;
            MethodWrapperMeta!mf.getDefaultArgs(), //GDExtensionVariantPtr *default_arguments;
        
        };
        _godot_api.classdb_register_extension_class_method(lib, cast(GDExtensionStringNamePtr) snClass, &mi);
        // cache StringName for comparison later on
        MethodWrapper!(T, mf).funName = cast(GDExtensionStringNamePtr) snFunName;
    }

    void registerMemberAccessor(alias mf, alias propType, string funcName)() {
        static assert(Parameters!propType.length == 0 || Parameters!propType.length == 1,
            "only getter or setter is allowed with exactly zero or one arguments");

        //static if (funcName) {
        StringName snName = StringName(funcName);
        //} else
        //    StringName snName = StringName(godotName!mf);

        uint flags = GDEXTENSION_METHOD_FLAGS_DEFAULT;

        GDExtensionClassMethodInfo mi = {
            cast(GDExtensionStringNamePtr) snName, //const char *name;
            &mf, //void *method_userdata;
            &mf, //GDExtensionClassMethodCall call_func;
            null, //GDExtensionClassMethodPtrCall ptrcall_func;
            flags, //uint32_t method_flags; /* GDExtensionClassMethodFlags */

            cast(GDExtensionBool) !is(ReturnType!propType == void), //GDExtensionBool has_return_value;
            MethodWrapperMeta!propType.getReturnInfo.ptr,
            MethodWrapperMeta!propType.getReturnMetadata,

            cast(uint32_t) arity!propType, //uint32_t argument_count;
            MethodWrapperMeta!propType.getArgInfo.ptr, //GDExtensionPropertyInfo* arguments_info;
            MethodWrapperMeta!propType.getArgMetadata, //GDExtensionClassMethodArgumentMetadata* arguments_metadata;

            MethodWrapperMeta!propType.getDefaultArgNum, //uint32_t default_argument_count;
            MethodWrapperMeta!propType.getDefaultArgs(), //GDExtensionVariantPtr *default_arguments;
        };

        _godot_api.classdb_register_extension_class_method(lib, cast(GDExtensionStringNamePtr) snClass, &mi);
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

            __gshared static StringName[Parameters!s.length] snArgNames = void;
            __gshared static StringName[Parameters!s.length] snClassNames = void;
            __gshared static StringName[Parameters!s.length] snHintStrings = void;
            __gshared static GDExtensionPropertyInfo[Parameters!s.length] prop;
            static if (is(FunctionTypeOf!s FT == __parameters)){
                //pragma(msg, typeof(s), " : ", FT);
                alias PARAMS = FT;
            }
            static foreach (int i, p; Parameters!s) {
                static assert(Variant.compatible!p, fullyQualifiedName!s ~ " parameter " ~ i.text ~ " \""
                        ~ ParameterIdentifierTuple!s[i] ~ "\": type " ~ p.stringof ~ " is incompatible with Godot");

                // get name or argN fallback placeholder in case of function pointers
                static if (PARAMS.length > 0) {
                    // "(String message)" gets split in half, and then chop out closing parenthesis
                    // "(String message, String test)" handled as well
                    //pragma(msg, PARAMS[i..i+1].stringof.split()[1][0..$-1]);
                    snArgNames[i] = StringName(PARAMS[i..i+1].stringof.split()[1][0..$-1]);
                }
                else {
                    snArgNames[i] = StringName("arg" ~ i.stringof);
                }
                prop[i].name = cast(GDExtensionStringNamePtr) snArgNames[i];

                if (Variant.variantTypeOf!p == VariantType.object)
                    snClassNames[i] = snClass;
                else
                    snClassNames[i] = stringName();
                prop[i].class_name = cast(GDExtensionStringNamePtr) snClassNames[i];

                snHintStrings[i] = stringName();
                prop[i].hint_string = cast(GDExtensionStringNamePtr) snHintStrings[i];
                prop[i].type = Variant.variantTypeOf!p;
                prop[i].hint = 0;
                prop[i].usage = GDEXTENSION_METHOD_FLAGS_DEFAULT;
            }

            StringName snExternalName = StringName(externalName);
            _godot_api.classdb_register_extension_class_signal(
                lib, 
                cast(GDExtensionStringNamePtr) snClass, 
                cast(GDExtensionStringNamePtr) snExternalName, 
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

            __gshared static GDExtensionPropertyInfo pinfo;


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

            pinfo.class_name = cast(GDExtensionStringNamePtr) snParamClassName;
            pinfo.type = vt;
            pinfo.name = cast(GDExtensionStringNamePtr) snPropName;
            pinfo.hint = GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE;
            //pinfo.usage = GDEXTENSION_METHOD_FLAGS_DEFAULT | GDEXTENSION_METHOD_FLAG_EDITOR;
            pinfo.usage = 7; // godot-cpp uses 7 as value which is default|const|editor currently, doesn't shows up in inspector without const. WTF?
            pinfo.hint_string = cast(GDExtensionStringNamePtr) snHintString;

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
                cast(GDExtensionStringNamePtr) snClass, 
                &pinfo, 
                cast(GDExtensionStringNamePtr) snSetProp, 
                cast(GDExtensionStringNamePtr) snGetProp
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

            __gshared static GDExtensionPropertyInfo pinfo;

            StringName snPropName = StringName(pName);
            static if (Variant.variantTypeOf!P == VariantType.object) {
                StringName snPName = StringName(godotName!(P));
            }
            else {
                StringName snPName = StringName("");
            }
            pinfo.class_name = cast(GDExtensionStringNamePtr) snPName;
            pinfo.type = vt;
            pinfo.name = cast(GDExtensionStringNamePtr) snPropName;
            pinfo.usage = GDEXTENSION_METHOD_FLAGS_DEFAULT | GDEXTENSION_METHOD_FLAG_EDITOR;
            static if (uda.hintString.length)
                StringName snHintString = StringName(uda.hintString);
            else
                StringName snHintString = stringName();
            pinfo.hint_string = cast(GDExtensionStringNamePtr) snHintString;
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
                cast(GDExtensionStringNamePtr) snClass, 
                &pinfo, 
                cast(GDExtensionStringNamePtr) snSetProp, 
                cast(GDExtensionStringNamePtr) snGetProp 
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
                    cast(GDExtensionStringNamePtr) snClass, 
                    cast(GDExtensionStringNamePtr) mixin("snEnum"~i.stringof), 
                    cast(GDExtensionStringNamePtr) mixin("snVal"~i.stringof), 
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
                cast(GDExtensionStringNamePtr) snClass, 
                cast(GDExtensionStringNamePtr) stringName(), 
                cast(GDExtensionStringNamePtr) mixin("snProp"~pName), 
                cast(int) E, 
                false
            );
        }
    }

}

/++
Register a class and all its $(D @GodotMethod) member functions into Godot.
+/
void unregister(T)(GDExtensionClassLibraryPtr lib) if (is(T == class)) {
    import std.array;
    import godot.abi;
    import godot.object, godot.resource;
    import godot.api;

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

    void unregister() {
        StringName snClass = StringName(name);
        _godot_api.classdb_unregister_extension_class(lib, cast(GDExtensionStringNamePtr) snClass);
    }
}
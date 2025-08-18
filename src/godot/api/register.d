/++
Initialization, termination, and registration of D libraries in Godot
+/
module godot.api.register;

import godot.util.classes;

import std.format;
import std.meta, std.traits;

import godot.api.traits;
import godot.api.script;
import godot.api.wrap;
import godot.api.udas;
import godot.api.reference;

import godot, godot.abi;

import godot.abi.gdextension;

enum TRACE_METHOD_CALLS = false;

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
    export extern (C) static GDExtensionBool godot_gdextension_entry(GDExtensionInterfaceGetProcAddress p_get_proc_address,
        GDExtensionClassLibraryPtr p_library, GDExtensionInitialization* r_initialization) {
        import godot.abi.gdextension;
        import godot.api.reference;
        import std.meta, std.traits;
        import core.runtime : Runtime;
        import godot.api.output;
        import godot.api.traits;
        import godot.abi.types;
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

        // ----------------- GRACEFULLY QUIT IF GODOT < 4.1 ------------
        // Make sure we weren't passed the legacy struct.
        uint32_t* raw_interface = cast(uint32_t*)cast(void*)p_get_proc_address;
        if (raw_interface[0] == 4 && raw_interface[1] == 0) {
            // Use the legacy interface only to give a nice error.
            LegacyGDExtensionInterface* legacy_interface = cast(LegacyGDExtensionInterface*) p_get_proc_address;
		    gdextension_interface_print_error_with_message = cast(GDExtensionInterfacePrintErrorWithMessage) legacy_interface.print_error_with_message;
            printerr("Cannot load a GDExtension built for Godot 4.1+ in Godot 4.0.");
            return false;
        }

        // Load the "print_error_with_message" function first (needed by the printerr).
        gdextension_interface_print_error_with_message = cast(GDExtensionInterfacePrintErrorWithMessage)p_get_proc_address("print_error_with_message");
        if (!gdextension_interface_print_error_with_message) {
            version(WebAssembly) {
                // TODO: log error
            }
            else { 
            import core.stdc.stdio : printf;
            printf("ERROR: Unable to load GDExtension interface function print_error_with_message().\n");
            }
            return false;
        }
        // -------------------------------------------------------------

        _godot_get_proc_address = p_get_proc_address;
        godot.api.register._GODOT_library = p_library;

        loadGDExtensionInterface();

        //import core.exception : assertHandler;
        //assertHandler = (options.in_editor) ? (&godotAssertHandlerEditorDebug)
        //	: (&godotAssertHandlerCrash);

        // Scene is the lowest level to enable hot reload, core or server requires engine restart
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

        // this will only check if classes share inheritance chain, probably ok 
        // but maybe also need to check properties/method parameters.
        // note the order is reversed since we de-initilizing here
        enum SortHierarchy(C1, C2) = staticIndexOf!(C2, BaseClassesTuple!C1) == -1 ? 1 : -1;

        // TODO: this will likely crash in a real project, classes has to be sorted in such way that
        // descendants unregistered before parent
        alias classList = staticMap!(fileClassesAsLazyImports, aliasSeqOf!(_GODOT_projectInfo.files));
        static foreach (C; NoDuplicates!(classList, staticSort!(SortHierarchy, Filter!(is_, Args)))) {
            static if (is(C)) {
                static if (extendsGodotBaseClass!C) {
                    if (level == GDEXTENSION_INITIALIZATION_SCENE)
                        unregister!C(_GODOT_library);
                }
            }
        }

        // terminate D runtime on lowest possible level after all classes unregistered
        if (level != GDEXTENSION_INITIALIZATION_CORE)
            return;

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
    gdextension_interface_variant_new_nil(&n);
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
            // classes version may fail when deriving GodotObject directly as it doesn't have _godot_base field
            // if you change this then also see unregister()
            version(USE_CLASSES){
                alias Base = BaseClassesTuple!T[0];
            } else {
                alias Base = typeof(T._godot_base);
            }
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

    // Choose registration format, v2 required for hot reload
    import extVersion = godot.apiinfo;
    enum isGodot42orNewer = extVersion.VERSION_MAJOR == 4 && extVersion.VERSION_MINOR >= 2;
    enum isGodot43orNewer = extVersion.VERSION_MAJOR == 4 && extVersion.VERSION_MINOR >= 3;
    enum isGodot44orNewer = extVersion.VERSION_MAJOR == 4 && extVersion.VERSION_MINOR >= 4;
    enum isGodot45orNewer = extVersion.VERSION_MAJOR == 4 && extVersion.VERSION_MINOR >= 5;

    static if (isGodot45orNewer)
    __gshared static GDExtensionClassCreationInfo5 class_info;
    else static if (isGodot44orNewer)
    __gshared static GDExtensionClassCreationInfo4 class_info;
    else static if (isGodot43orNewer)
    __gshared static GDExtensionClassCreationInfo3 class_info;
    else static if (isGodot42orNewer)
    __gshared static GDExtensionClassCreationInfo2 class_info;
    else
    __gshared static GDExtensionClassCreationInfo class_info;


    static if (isGodot44orNewer)
    class_info.create_instance_func = &createFunc2!T;
    else 
    class_info.create_instance_func = &createFunc!T;
    class_info.free_instance_func = &destroyFunc!T;
    class_info.class_userdata = cast(void*) name.ptr;

    static if (isGodot42orNewer) {
        class_info.recreate_instance_func = &recreateFunc!T;
        class_info.is_exposed = true; // TODO: add some control over what class should be exposed
        class_info.is_abstract = __traits(isAbstractClass, T);
    }

    static if (!isGodot42orNewer) {
        static assert(!__traits(isAbstractClass, T), "abstract class support requires godot version 4.2 or higher");
    }

    // Since Godot 4.3 extensions can now specify if they want to opt out of being a "tool" script.
    // Extension developers now has the option to register the new scripts as being runtime-only,
    // such scripts will not run their methods in editor, which saves from adding Engine.is_editor_hint() checks everywhere.
    // 
    // Because runtime-only classes has some limitations when interacting with them in editor, 
    // we choose to make them explicitly marked as such, primarily for compatibility reasons with existing godot-dlang projects.
    //
    static if (isGodot43orNewer) {
        class_info.is_runtime = hasUDA!(T, RuntimeOnly);
    }
    

    // This function will be called for any virtual script method, the returned pointer is then cached internally by godot
    extern (C) static GDExtensionClassCallVirtual getVirtualFn(void* p_userdata, const GDExtensionStringNamePtr p_name) {
        //import core.stdc.stdio;
        //import core.stdc.string;
        import std.conv : to;

        //print("requested method ", *cast(StringName*) p_name);
        auto name = *cast(StringName*) p_name;
        static if (__traits(compiles, __traits(getMember, T, "_ready"))) {
            if (name == StringName("_ready")) {
                return &OnReadyWrapper!(T, __traits(getMember, T, "_ready")).virtualWrapper;
            }
        }
        return VirtualMethodsHelper!T.findVCall(p_name);
    }

    extern (C) static GDExtensionClassCallVirtual getVirtualFn2(void* p_userdata, const GDExtensionStringNamePtr p_name, uint p_hash) {
        return getVirtualFn(p_userdata, p_name);
    }

    static if (isGodot44orNewer)
    class_info.get_virtual_func = &getVirtualFn2;
    else
    class_info.get_virtual_func = &getVirtualFn;

    StringName snClass = StringName(name);
    StringName snBase = StringName(baseName);
    static if (isGodot45orNewer)
    gdextension_interface_classdb_register_extension_class5(lib, cast(GDExtensionStringNamePtr) snClass, cast(GDExtensionStringNamePtr) snBase, &class_info);
    else static if (isGodot44orNewer)
    gdextension_interface_classdb_register_extension_class4(lib, cast(GDExtensionStringNamePtr) snClass, cast(GDExtensionStringNamePtr) snBase, &class_info);
    else static if (isGodot43orNewer)
    gdextension_interface_classdb_register_extension_class3(lib, cast(GDExtensionStringNamePtr) snClass, cast(GDExtensionStringNamePtr) snBase, &class_info);
    else static if (isGodot42orNewer)
    gdextension_interface_classdb_register_extension_class2(lib, cast(GDExtensionStringNamePtr) snClass, cast(GDExtensionStringNamePtr) snBase, &class_info);
    else
    gdextension_interface_classdb_register_extension_class(lib, cast(GDExtensionStringNamePtr) snClass, cast(GDExtensionStringNamePtr) snBase, &class_info);

    void registerVirtualMethod(alias mf, string nameOverride = null)() {
        static assert(isGodot43orNewer, "Virtual methods requires Godot 4.3 or newer.");

        static if (nameOverride.length) {
            string mfn = nameOverride;
        } else {
            string mfn = godotName!mf;
        }

        uint flags = GDEXTENSION_METHOD_FLAGS_DEFAULT | GDEXTENSION_METHOD_FLAG_VIRTUAL;

        // virtual methods like '_ready'
        //if (__traits(identifier, mf)[0] == '_')
        //    flags |= GDEXTENSION_METHOD_FLAG_VIRTUAL;

        MethodWrapperMeta!mf methodInfo;
        methodInfo.initialize();

        StringName snFunName = StringName(mfn);
        GDExtensionClassVirtualMethodInfo mi = {
            cast(GDExtensionStringNamePtr) snFunName , //const char *name;
            flags, //uint32_t method_flags; /* GDExtensionClassMethodFlags */

            methodInfo.returnInfo[0], //GDExtensionPropertyInfo* return_value_info;
            methodInfo.returnMetadata, //GDExtensionClassMethodArgumentMetadata return_value_metadata;

            cast(uint32_t) arity!mf, //uint32_t argument_count;
            methodInfo.argumentsInfo.ptr, //GDExtensionPropertyInfo* arguments_info;
            methodInfo.argumentsMetadata, //GDExtensionClassMethodArgumentMetadata* arguments_metadata;        
        };

        // when loaded in older versions try handle this gracefully and let the user know they have unsupported version.
        if (gdextension_interface_classdb_register_extension_class_virtual_method !is null)
            gdextension_interface_classdb_register_extension_class_virtual_method(lib, cast(GDExtensionStringNamePtr) snClass, &mi);
        else {
            printerr("Trying to register virtual method which requires Godot v4.3 or newer. Reason: classdb_register_extension_class_virtual_method is null");
        }
        // cache StringName for comparison later on
        MethodWrapper!(T, mf).funName = cast(GDExtensionStringNamePtr) snFunName;
    }

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

        MethodWrapperMeta!mf methodInfo;
        methodInfo.initialize();

        StringName snFunName = StringName(mfn);
        GDExtensionClassMethodInfo mi = {
            cast(GDExtensionStringNamePtr) snFunName , //const char *name;
            &mf, //void *method_userdata;
            &MethodWrapper!(T, mf).callMethod, //GDExtensionClassMethodCall call_func;
            &MethodWrapper!(T, mf).callPtrMethod, //GDExtensionClassMethodPtrCall ptrcall_func;
            flags, //uint32_t method_flags; /* GDExtensionClassMethodFlags */

            cast(GDExtensionBool) !is(ReturnType!mf == void), //GDExtensionBool has_return_value;
            methodInfo.returnInfo.ptr, //GDExtensionPropertyInfo* return_value_info;
            methodInfo.returnMetadata, //GDExtensionClassMethodArgumentMetadata return_value_metadata;

            cast(uint32_t) arity!mf, //uint32_t argument_count;
            methodInfo.argumentsInfo.ptr, //GDExtensionPropertyInfo* arguments_info;
            methodInfo.argumentsMetadata, //GDExtensionClassMethodArgumentMetadata* arguments_metadata;

            methodInfo.defaultArgsNum, //uint32_t default_argument_count;
            methodInfo.defaultArgs, //GDExtensionVariantPtr *default_arguments;
        
        };
        gdextension_interface_classdb_register_extension_class_method(lib, cast(GDExtensionStringNamePtr) snClass, &mi);
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

        MethodWrapperMeta!propType methodInfo;
        methodInfo.initialize();

        GDExtensionClassMethodInfo mi = {
            cast(GDExtensionStringNamePtr) snName, //const char *name;
            &mf, //void *method_userdata;
            &mf, //GDExtensionClassMethodCall call_func;
            null, //GDExtensionClassMethodPtrCall ptrcall_func;
            flags, //uint32_t method_flags; /* GDExtensionClassMethodFlags */

            cast(GDExtensionBool) !is(ReturnType!propType == void), //GDExtensionBool has_return_value;
            methodInfo.returnInfo.ptr,
            methodInfo.returnMetadata,

            cast(uint32_t) arity!propType, //uint32_t argument_count;
            methodInfo.argumentsInfo.ptr, //GDExtensionPropertyInfo* arguments_info;
            methodInfo.argumentsMetadata, //GDExtensionClassMethodArgumentMetadata* arguments_metadata;

            methodInfo.defaultArgsNum, //uint32_t default_argument_count;
            methodInfo.defaultArgs, //GDExtensionVariantPtr *default_arguments;
        };

        gdextension_interface_classdb_register_extension_class_method(lib, cast(GDExtensionStringNamePtr) snClass, &mi);
    }

    static foreach (mf; godotMethods!T) {
        {
            static if (hasUDA!(mf, Rename))
                enum string externalName = godotName!mf;
            else
                enum string externalName = (fullyQualifiedName!mf).replace(".", "_");
            static if (!hasUDA!(mf, Virtual))
                registerMethod!mf();
            else
                registerVirtualMethod!mf();
        }
    }

    // helper template that builds argument name, it handles unnamed parameters as well by giving them generic name
    template SignalArgumentName(alias s, int i) {
        // get name or argN fallback placeholder in case of function pointers
        static if (is(FunctionTypeOf!s FT == __parameters)){
            //pragma(msg, typeof(s), " : ", FT);
            alias PARAMS = FT;
        }
        static if (PARAMS.length > 0 && PARAMS[i..i+1].stringof.split().length > 1) {
            // "(String message)" gets split in half, and then chop out closing parenthesis
            // "(String message, String test)" handled as well
            // static if checks if there is a parameter name, otherwise it will use generic arg# name
            //pragma(msg, PARAMS[i..i+1].stringof.split()[1][0..$-1]);
            enum SignalArgumentName = PARAMS[i..i+1].stringof.split()[1][0..$-1];
        }
        else {
            enum SignalArgumentName = "arg" ~ i.stringof;
        }
    }

    static foreach (sName; godotSignals!T) {
        {
            alias s = Alias!(mixin("T." ~ sName));

            // Signals can be a regular D methods, but having both godot method and signal with same name is not allowed
            // plain D method can be useful to provide uniform API, 
            //   e.g. emit signal in D code by calling function with same name
            static assert(!hasUDA!(s, Method), "Signal with @Method attribute is not allowed: " ~ fullyQualifiedName!s ~ " at "
                ~ format!"%s(%d,%d)"(__traits(getLocation, s))
            );

            // When signal defined as a delegate make sure it is made static for efficiency reasons
            static if (isFunctionPointer!s || isDelegate!s) {
                static assert(hasStaticMember!(T, sName), "Signal declaration " ~ fullyQualifiedName!s
                        ~ " must be static. Otherwise it would take up memory in every instance of " ~ T
                        .stringof);
            }

            enum string externalName = godotName!s;

            PropertyInfo[Parameters!s.length] propData;
            GDExtensionPropertyInfo[Parameters!s.length] pinfo;

            static foreach (int i, p; Parameters!s) {
                static assert(Variant.compatible!p, fullyQualifiedName!s ~ " parameter " ~ i.text ~ " \""
                        ~ ParameterIdentifierTuple!s[i] ~ "\": type " ~ p.stringof ~ " is incompatible with Godot");

                propData[i] = makePropertyInfo!(p, SignalArgumentName!(s, i));

                pinfo[i].name = cast(GDExtensionStringNamePtr) propData[i].snName;
                pinfo[i].class_name = cast(GDExtensionStringNamePtr) propData[i].snClassName;
                pinfo[i].hint_string = cast(GDExtensionStringPtr) &propData[i].snHint;
                pinfo[i].type = cast(GDExtensionVariantType) propData[i].typeKind;
                pinfo[i].hint = propData[i].hintFlags;
                pinfo[i].usage = propData[i].usageFlags;
            }

            StringName snExternalName = StringName(externalName);
            gdextension_interface_classdb_register_extension_class_signal(
                lib, 
                cast(GDExtensionStringNamePtr) snClass, 
                cast(GDExtensionStringNamePtr) snExternalName, 
                pinfo.ptr, 
                Parameters!s.length
            );
        }
    }

    // -------- PROPERTIES

    enum bool matchName(string p, alias a) = (godotName!a == p);
    static foreach (pName; godotPropertyNames!T) {
        {
            alias getterMatches = Filter!(ApplyLeft!(matchName, pName), godotPropertyGetters!T);
            static assert(getterMatches.length <= 1, format!"multiple functions matches getter type for property '%s.%s'"(__traits(identifier, T), pName));
            alias setterMatches = Filter!(ApplyLeft!(matchName, pName), godotPropertySetters!T);
            static assert(setterMatches.length <= 1, format!"multiple functions matches setter type for property '%s.%s'"(__traits(identifier, T), pName));

            static if (getterMatches.length)
                alias P = NonRef!(ReturnType!(getterMatches[0]));
            else
                alias P = Parameters!(setterMatches[0])[0];
            //static assert(!is(P : Ref!U, U)); /// TODO: proper Ref handling
            enum VariantType vt = extractPropertyVariantType!(getterMatches, setterMatches);

            enum Property uda = extractPropertyUDA!(getterMatches, setterMatches);

            PropertyInfo propData = makePropertyInfo!(P, pName)();
            GDExtensionPropertyInfo pinfo;
            
            pinfo.name = cast(GDExtensionStringNamePtr) propData.snName;
            pinfo.class_name = cast(GDExtensionStringNamePtr) propData.snClassName;
            pinfo.type = cast(GDExtensionVariantType) propData.typeKind;
            pinfo.hint = propData.hintFlags;
            pinfo.hint_string = cast(GDExtensionStringPtr) &propData.snHint;
            pinfo.usage = propData.usageFlags;
            assert(propData.typeKind == cast(GDExtensionVariantType) vt);

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
            gdextension_interface_classdb_register_extension_class_property(
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
            import godot.globalenums : PropertyUsageFlags;

            alias P = typeof(mixin("T." ~ pName));
            enum Variant.Type vt = Variant.variantTypeOf!P;
            alias udas = getUDAs!(mixin("T." ~ pName), Property);
            enum Property uda = is(udas[0]) ? Property.init : udas[0];

            PropertyInfo propData = makePropertyInfo!(P, pName)();
            GDExtensionPropertyInfo pinfo;

            pinfo.name = cast(GDExtensionStringNamePtr) propData.snName;
            pinfo.class_name = cast(GDExtensionStringNamePtr) propData.snClassName;
            pinfo.type = cast(GDExtensionVariantType) propData.typeKind;
            pinfo.hint = propData.hintFlags;
            pinfo.hint_string = cast(GDExtensionStringPtr) &propData.snHint;
            pinfo.usage = propData.usageFlags;

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
            gdextension_interface_classdb_register_extension_class_property(
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
                gdextension_interface_classdb_register_extension_class_integer_constant(
                    lib, 
                    cast(GDExtensionStringNamePtr) snClass, 
                    cast(GDExtensionStringNamePtr) mixin("snEnum"~i.stringof), 
                    cast(GDExtensionStringNamePtr) mixin("snVal"~i.stringof), 
                    cast(int) __traits(getMember, E, ev), // constant value
                    false // is a bitfield constant?
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
            gdextension_interface_classdb_register_extension_class_integer_constant(
                lib, 
                cast(GDExtensionStringNamePtr) snClass, 
                cast(GDExtensionStringNamePtr) stringName(), 
                cast(GDExtensionStringNamePtr) mixin("snProp"~pName), 
                cast(int) E, 
                false
            );
        }
    }

    static foreach (pName; godotSingletonVariableNames!T) {
        {
            import std.string;
            import godot.globalenums : PropertyUsageFlags;

            alias P = typeof(mixin("T." ~ pName));
            alias storageField = mixin("T."~pName);
            enum Variant.Type vt = Variant.variantTypeOf!P;
            alias udas = getUDAs!(mixin("T." ~ pName), Singleton);
            enum Singleton uda = is(udas[0]) ? Singleton.init : udas[0];

            alias renameAttr = getUDAs!(mixin("T." ~ pName), Rename);
            enum Rename renamed = is(renameAttr[0]) ? Rename.init : renameAttr[0];
            static if (renamed.name)
                StringName snPropName = StringName(renamed.name);
            else
                StringName snPropName = StringName(pName);

            storageField = memnew!P;
            
            import godot.engine;
            Engine.registerSingleton(snPropName, storageField._godot_base);
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
        // classes version may fail when deriving GodotObject directly as it doesn't have _godot_base field
        // if you change this also see register()
        version(USE_CLASSES){
            alias Base = BaseClassesTuple!T[0];
        } else {
            alias Base = typeof(T._godot_base);
        }
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

    {
        static foreach (pName; godotSingletonVariableNames!T) {{
            import std.string;
            import godot.engine;

            alias P = typeof(mixin("T." ~ pName));
            alias storageField = mixin("T."~pName);
            alias udas = getUDAs!(mixin("T." ~ pName), Singleton);
            enum Singleton uda = is(udas[0]) ? Singleton.init : udas[0];

            alias renameAttr = getUDAs!(mixin("T." ~ pName), Rename);
            enum Rename renamed = is(renameAttr[0]) ? Rename.init : renameAttr[0];
            static if (renamed.name)
                StringName snPropName = StringName(renamed.name);
            else
                StringName snPropName = StringName(pName);
                
            Engine.unregisterSingleton(snPropName);
            memdelete(storageField);
        }}

        StringName snClass = StringName(name);
        gdextension_interface_classdb_unregister_extension_class(lib, cast(GDExtensionStringNamePtr) snClass);
    }
}

extern(C) ReturnType!mf MethodPtr(T, alias mf, Args...)(T obj, Args args) {
    enum char* fqn = cast(char*) (&mf).stringof;

    static if (TRACE_METHOD_CALLS) {
        import core.stdc.stdio;
        printf("> %s\n", fqn);
        scope(exit) printf("< %s\n", fqn);
    }

    static if (is(ReturnType!mf == void))
        __traits(getMember, obj, mf.stringof)(args);
    else
        return __traits(getMember, obj, mf.stringof)(args);
}


// Partial definition of the legacy interface so we can detect it and show an error.
// same as in C++, because we want to print a nice error message instead of silently crash the editor
struct LegacyGDExtensionInterface {
	uint32_t version_major;
	uint32_t version_minor;
	uint32_t version_patch;
	const(char)* version_string;

	GDExtensionInterfaceFunctionPtr unused1;
	GDExtensionInterfaceFunctionPtr unused2;
	GDExtensionInterfaceFunctionPtr unused3;

	GDExtensionInterfacePrintError print_error;
	GDExtensionInterfacePrintErrorWithMessage print_error_with_message;
}
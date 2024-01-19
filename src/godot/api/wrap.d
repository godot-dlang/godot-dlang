/++
Templates for wrapping D classes, properties, methods, and signals to be passed
to Godot's C interface.
+/
module godot.api.wrap;

import std.algorithm : max;
import std.range;
import std.meta, std.traits;
import std.experimental.allocator, std.experimental.allocator.mallocator;
import core.stdc.stdlib : malloc, free;

import godot.api.udas;
import godot.api.traits, godot.api.script;

import godot, godot.abi;
import godot.node;

private template staticCount(alias thing, seq...) {
    template staticCountNum(size_t soFar, seq...) {
        enum size_t nextPos = staticIndexOf!(thing, seq);
        static if (nextPos == -1)
            enum size_t staticCountNum = soFar;
        else
            enum size_t staticCountNum = staticCountNum!(soFar + 1, seq[nextPos + 1 .. $]);
    }

    enum size_t staticCount = staticCountNum!(0, seq);
}

private string overloadError(methods...)() {
    alias godotNames = staticMap!(godotName, methods);
    foreach (m; methods) {
        static if (staticCount!(godotName!m, godotNames) > 1) {
            static assert(0, `Godot does not support overloading methods (`
                    ~ fullyQualifiedName!m ~ `, wrapped as "` ~ godotName!m ~
                    `"); rename one with @Rename("new_name") or use Variant args`);
        }
    }
}

package(godot) template godotMethods(T) {
    // Makes tuple of member functions excluding function pointers
    // this is basically std.traits.MemberFunctionsTuple but with static methods
    template mfs(alias mName) {
        static if (isSomeFunction!(__traits(getMember, T, mName)) 
               && !isFunctionPointer!(__traits(getMember, T, mName))) {
            static if (__traits(getOverloads, T, mName).length) {
                alias mfs = __traits(getOverloads, T, mName);
            }
            else {
                alias mfs = __traits(getMember, T, mName);
            }
        }
        else {
            alias mfs = AliasSeq!();
        }
    }
    
    alias allMfs = staticMap!(mfs, __traits(derivedMembers, T));
    enum bool isMethod(alias mf) = hasUDA!(mf, Method);

    alias godotMethods = Filter!(isMethod, allMfs);

    alias godotNames = staticMap!(godotName, godotMethods);
    static assert(godotNames.length == NoDuplicates!godotNames.length,
        overloadError!godotMethods());
}

package(godot) template godotSignals(T) {
    enum isSignalExpr(string n) = q{ isCallable!(mixin("T."~n))
		&& ( hasUDA!(mixin("T."~n), Signal) || is(ReturnType!(mixin("T."~n)) == Signal) ) };
    template isSignal(string n) {
        static if (__traits(compiles, mixin(isSignalExpr!n))) {
            enum bool isSignal = mixin(isSignalExpr!n);
        } else
            enum bool isSignal = false;
    }

    alias godotSignals = Filter!(isSignal, __traits(derivedMembers, T));
}

package(godot) template onReadyFieldNames(T) {
    import godot.node;

    static if (!is(GodotClass!T : Node))
        alias onReadyFieldNames = AliasSeq!();
    else {
        alias fieldNames = FieldNameTuple!T;
        template isORField(string n) {
            static if (staticIndexOf!(n, fieldNames) != -1 && staticIndexOf!(__traits(getProtection, __traits(
                    getMember, T, n)), "public", "export") != -1) {
                enum bool isORField = hasUDA!(__traits(getMember, T, n), OnReady);
            } else
                enum bool isORField = false;
        }

        alias onReadyFieldNames = Filter!(isORField, __traits(derivedMembers, T));
    }
}

package(godot) template godotPropertyGetters(T) {
    alias mfs(alias mName) = MemberFunctionsTuple!(T, mName);
    alias allMfs = staticMap!(mfs, __traits(derivedMembers, T));
    template isGetter(alias mf) {
        enum bool isGetter = hasUDA!(mf, Property) && !is(ReturnType!mf == void);
    }

    alias godotPropertyGetters = Filter!(isGetter, allMfs);

    alias godotNames = Filter!(godotName, godotPropertyGetters);
    static assert(godotNames.length == NoDuplicates!godotNames.length,
        overloadError!godotPropertyGetters());
}

package(godot) template godotPropertySetters(T) {
    alias mfs(alias mName) = MemberFunctionsTuple!(T, mName);
    alias allMfs = staticMap!(mfs, __traits(derivedMembers, T));
    template isSetter(alias mf) {
        enum bool isSetter = hasUDA!(mf, Property) && is(ReturnType!mf == void);
    }

    alias godotPropertySetters = Filter!(isSetter, allMfs);

    alias godotNames = Filter!(godotName, godotPropertySetters);
    static assert(godotNames.length == NoDuplicates!godotNames.length,
        overloadError!godotPropertySetters());
}

package(godot) template godotPropertyNames(T) {
    alias godotPropertyNames = NoDuplicates!(staticMap!(godotName, godotPropertyGetters!T,
            godotPropertySetters!T));
}

package(godot) template godotEnums(T) {
    import std.traits;

    alias mfs(alias mName) = __traits(getMember, T, mName);
    alias allMfs = staticMap!(mfs, __traits(derivedMembers, T));
    template isEnum(alias mf) {
        static if (is(mf Base == enum) && isIntegral!Base)
            enum bool isEnum = hasUDA!(mf, Enum);
        else
            enum bool isEnum = false;
    }

    alias godotEnums = Filter!(isEnum, allMfs);
}

package(godot) template godotConstants(T) {
    import std.traits;

    alias mfs(alias mName) = Alias!(__traits(getMember, T, mName));
    alias allMfs = staticMap!(mfs, __traits(derivedMembers, T));

    template isCompileTimeValue(alias V, T...)
            if (T.length == 0 || (T.length == 1 && is(T[0]))) {
        enum isKnown = is(typeof(() { enum v = V; }));
        static if (!T.length)
            enum isCompileTimeValue = isKnown;
        else
            enum isCompileTimeValue = isKnown && is(typeof(V) == T[0]);
    }

    template isConstant(alias mf) {
        static if (isCompileTimeValue!mf) {
            enum bool isConstant = hasUDA!(mf, Constant);
        } else
            enum bool isConstant = false;
    }

    enum isConstantMember(string m) = isConstant!(__traits(getMember, T, m));
    alias godotConstants = Filter!(isConstantMember, __traits(derivedMembers, T));
    //pragma(msg, filtered);
    //alias godotConstants = Filter!(isConstant, allMfs);
}

package(godot) template godotPropertyVariableNames(T) {
    alias fieldNames = FieldNameTuple!T;
    alias field(string name) = Alias!(__traits(getMember, T, name));
    template isVariable(string name) {
        static if (__traits(getProtection, __traits(getMember, T, name)) == "public")
            enum bool isVariable = hasUDA!(field!name, Property);
        else
            enum bool isVariable = false;
    }

    alias godotPropertyVariableNames = Filter!(isVariable, fieldNames);
}

package(godot) template godotSingletonVariableNames(T) {
    import std.traits;
    alias fieldNames = AliasSeq!(__traits(derivedMembers, T));
    alias field(string name) = Alias!(__traits(getMember, T, name));
    template isSingleton(string name) {
        static if (__traits(getProtection, __traits(getMember, T, name)) == "public" && hasStaticMember!(T, name))
            enum bool isSingleton = hasUDA!(field!name, Singleton);
        else
            enum bool isSingleton = false;
    }

    alias godotSingletonVariableNames = Filter!(isSingleton, fieldNames);
}

/// get the common Variant type for a set of function or variable aliases
package(godot) template extractPropertyVariantType(seq...) {
    template Type(alias a) {
        static if (isFunction!a && is(ReturnType!a == void))
            alias Type = Parameters!a[0];
        else static if (isFunction!a)
            alias Type = NonRef!(ReturnType!a);
        //else alias Type = typeof(a);

        static assert(Variant.compatible!Type, "Property type " ~
                Type.stringof ~ " is incompatible with Variant.");
    }

    alias types = NoDuplicates!(staticMap!(Variant.variantTypeOf, staticMap!(Type, seq)));
    static assert(types.length == 1); /// TODO: better error message
    enum extractPropertyVariantType = types[0];
}

package(godot) template extractPropertyUDA(seq...) {
    template udas(alias a) {
        alias udas = getUDAs!(a, Property);
    }

    enum bool isUDAValue(alias a) = !is(a);
    alias values = Filter!(isUDAValue, staticMap!(udas, seq));

    static if (values.length == 0)
        enum Property extractPropertyUDA = Property.init;
    else static if (values.length == 1)
        enum Property extractPropertyUDA = values[0];
    else {
        // verify that they all have the same value, to avoid wierdness
        enum Property extractPropertyUDA = values[0];
        enum bool isSameAsFirst(Property p) = extractPropertyUDA == p;
        static assert(allSatisfy!(isSameAsFirst, values[1 .. $]));
    }
}

/++
Variadic template for method wrappers.

Params:
	T = the class that owns the method
	mf = the member function being wrapped, as an alias
+/
package(godot) struct MethodWrapper(T, alias mf) {
    alias R = ReturnType!mf; // the return type (can be void)
    alias A = Parameters!mf; // the argument types (can be empty)

    enum string name = __traits(identifier, mf);

    // Used later instead of string comparison
    __gshared static GDExtensionStringNamePtr funName;

    /++
	C function passed to Godot that calls the wrapped method
	+/
    extern (C) // for calling convention
    static void callMethod(void* methodData, void* instance,
        const(void*)* args, long numArgs, void* r_return, GDExtensionCallError* r_error) //@nogc nothrow
        {
        // TODO: check types for Variant compatibility, give a better error here
        // TODO: check numArgs, accounting for D arg defaults

        if (!(__traits(isStaticFunction, mf) || instance)) {
            r_error.error = GDEXTENSION_CALL_ERROR_INSTANCE_IS_NULL;
            return;
        }

        //godot_variant vd;
        //gdextension_interface_variant_new_nil(&vd);
        //Variant* v = cast(Variant*)&vd; // just a pointer; no destructor will be called
        Variant v;

        // basically what we want here...
        //Variant*[] va = (cast(Variant**) args)[0..numArgs];
        // however there is also default params that we need to place here
        scope Variant*[Parameters!mf.length + 1] va;
        scope Variant[ParameterDefaults!mf.length] defaults;
        static foreach (i, defval; ParameterDefaults!mf) {
            // should never happen
            static if (is(defval == void))
                defaults[i] = Variant();
            else
                defaults[i] = Variant(defval);
        }

        if (args && numArgs)
            va[0 .. cast(size_t) numArgs] = (cast(Variant**) args)[0 .. cast(size_t) numArgs];
        if (args && numArgs < Parameters!mf.length) // <-- optional parameters that godot decided not to pass
        {
            foreach (i; numArgs .. ParameterDefaults!mf.length) {
                va[i] = &defaults[i];
            }
        }

        // it seems to work with static calls without this alias,
        // but let's make it a bit more safe
        static if (__traits(isStaticFunction, mf)) {
            alias obj = T;
        }
        else {
            T obj = cast(T) instance;
        } 

        A[ai] variantToArg(size_t ai)() {
            static if (isFloatingPoint!(A[ai])) {
                return (cast(Variant*)va[ai]).as!(A[ai]);
            }
            else {
                return va[ai].as!(A[ai]);
            }
        }

        template ArgCall(size_t ai) {
            alias ArgCall = variantToArg!ai; //A[i] function()
        }

        alias argIota = aliasSeqOf!(iota(A.length));
        alias argCall = staticMap!(ArgCall, argIota);

        static if (is(R == void)) {
            mixin("obj." ~ name ~ "(argCall);");
        } else {
            // allow Variant to be returned as is, i.e. no wrapping
            static if (is(R == Variant)) {
                mixin("v = obj." ~ name ~ "(argCall);");
            }
            else {
                v = Variant(__traits(getMember, obj, name)(argCall));
            }

            if (r_return && v._godot_variant._opaque.ptr) {
                //*cast(godot_variant*) r_return = vd;   // since alpha 12 instead of this now have to copy it
                gdextension_interface_variant_new_copy(r_return, &v._godot_variant); // since alpha 12 this is now the case
            }
        }
        //return vd;
    }

    extern (C)
    static void callPtrMethod(void* methodData, void* instance,
        const(void*)* args, void* r_return) {

        T obj = cast(T) instance;

        A[ai] nativeToArg(size_t ai)() {
            static if (isFloatingPoint!(A[ai])) {
                return cast(A[ai]) (*cast(godot_float*)args[ai]);
            } 
            else 
                return (*cast(A[ai]*) args[ai]);
        }

        template ArgCall(size_t ai) {
            alias ArgCall = nativeToArg!ai; //A[i] function()
        }

        alias argIota = aliasSeqOf!(iota(A.length));
        alias argCall = staticMap!(ArgCall, argIota);

        static if (is(R == void)) {
            mixin("obj." ~ name ~ "(argCall);");
        } else {
            mixin("*(cast(R*) r_return) = obj." ~ name ~ "(argCall);");
        }
    }

    extern (C)
    static void virtualCall(GDExtensionClassInstancePtr instance, const GDExtensionTypePtr* args, GDExtensionTypePtr ret) {
        callPtrMethod(&mf, instance, args, ret);
    }
}


/// Holds a data such as StringNames and conveniently wraps it into GDExtension registration format
package(godot) struct MethodWrapperMeta(alias mf) {
    import godot.variant;
    import std.meta : staticMap;
    import std.traits;

    alias R = ReturnType!mf; // the return type (can be void)
    alias A = Parameters!mf; // the argument types (can be empty)

    this(this) {} // to silence annoying warnings

    PropertyInfo _returnInfo;
    PropertyInfo[A.length+1] _argumentsInfo;
    // Unlike arguments info this is strictly variant type index
    VariantType[A.length+1] _argVariantTypes = [staticMap!(Variant.variantTypeOf, A)];
    VariantType[2] _retVariantTypes = [Variant.variantTypeOf!R, VariantType.nil ];
    // Godot Arguments Metadata, not yet implemented
    GDExtensionClassMethodArgumentMetadata[A.length] _argInfo = GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE;
    // Default values for arguments
    Variant[ParameterDefaults!mf.length + 1] _defaults;
    Variant*[ParameterDefaults!mf.length + 1] _defaultsPtrs;

    void initialize() {
        _returnInfo = initReturnInfo();
        _argumentsInfo = initArgumentsInfo();
        _defaults = initDefaultArgs();
        for(int i = 0; i < _defaults.length; i++) {
            _defaultsPtrs[i] = &_defaults[i];
        }
    }


    GDExtensionPropertyInfo[2] returnInfo() { 
        GDExtensionPropertyInfo[2] retInfo = [ 
            GDExtensionPropertyInfo(
                cast(GDExtensionVariantType) _returnInfo.typeKind,
                cast(GDExtensionStringNamePtr) _returnInfo.snName,
                cast(GDExtensionStringNamePtr) _returnInfo.snClassName,
                _returnInfo.hintFlags, 
                cast(GDExtensionStringPtr) &_returnInfo.snHint,
                _returnInfo.usageFlags
            ), 
            GDExtensionPropertyInfo.init 
        ];
        return retInfo;
    }

    GDExtensionPropertyInfo[A.length+1] argumentsInfo() {
        GDExtensionPropertyInfo[A.length+1] argsInfo;
        static foreach (i; 0 .. A.length) {
            argsInfo[i] = GDExtensionPropertyInfo(
                cast(GDExtensionVariantType) _argumentsInfo[i].typeKind,
                cast(GDExtensionStringNamePtr) _argumentsInfo[i].snName,
                cast(GDExtensionStringNamePtr) _argumentsInfo[i].snClassName,
                _argumentsInfo[i].hintFlags, 
                cast(GDExtensionStringPtr) &_argumentsInfo[i].snHint,
                _argumentsInfo[i].usageFlags
            );
        }
        return argsInfo;
    }

    GDExtensionVariantType* argumentsTypes() {
        return cast(GDExtensionVariantType*) _argVariantTypes.ptr;
    }

    // yeah, it says return types, godot goes brrr
    GDExtensionVariantType* returnTypes() {
        return cast(GDExtensionVariantType*) _retVariantTypes.ptr;
    }

    // function parameter type information
    private static PropertyInfo[A.length+1] initArgumentsInfo() {
        PropertyInfo[A.length+1] argsInfo;
        static foreach (i; 0 .. A.length) {
            argsInfo[i] = makePropertyInfo!(A[i], (ParameterIdentifierTuple!mf)[i])();
        }
        return argsInfo;
    }

    // return type information
    private static PropertyInfo initReturnInfo() {
        return makePropertyInfo!(R, null)();
    }

    // metadata array for argument types
    GDExtensionClassMethodArgumentMetadata* argumentsMetadata() {
        __gshared static GDExtensionClassMethodArgumentMetadata[A.length] argInfo = GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE;
        return argInfo.ptr;
    }

    // metadata for return type
    GDExtensionClassMethodArgumentMetadata returnMetadata() {
        return GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE;
    }

    // this function expected to return Variant pointers array containing default values
    GDExtensionVariantPtr* defaultArgs() {
        return cast(GDExtensionVariantPtr*) _defaultsPtrs.ptr;
    }
    

    private enum bool notVoid(alias T) = !is(T == void);
    enum defaultArgsNum = cast(int32_t) Filter!(notVoid, ParameterDefaults!mf).length;
    private enum size_t defaultsStart = ParameterDefaults!mf.length - defaultArgsNum;
    //enum getDefaultArgNum = cast(int32_t) Parameters!mf.length;

    Variant[A.length+1] initDefaultArgs() {
        //pragma(msg, "fn: ", __traits(identifier, mf), " > ",  ParameterDefaults!mf);
        Variant[ParameterDefaults!mf.length + 1] defaults;
        static foreach (i, val; ParameterDefaults!mf[defaultsStart..$]) {
            // typeof val is needed because default value returns alias/expression and not a type itself
            static if (is(val == void) || !Variant.compatibleToGodot!(typeof(val)))
                defaults[i] = Variant(null); // even though it doesn't have it we probably need some value
            else
                defaults[i] = Variant(val);
        }
        defaults[ParameterDefaults!mf.length + 1 .. $] = Variant();
        return defaults;
    }
}

// Special wrapper that fetches OnReady members and then calls real _ready 
// NOTE: test this and use version to choose T/GodotClass!T depending on USE_CLASSES version
package(godot) struct OnReadyWrapper(T, alias mf) if (is(GodotClass!T : Node)) {
    extern (C) // for calling convention
    static void callOnReady(void* methodData, void* instance,
        const(void*)* args, long numArgs, void* r_return, GDExtensionCallError* r_error) {
        //if (!instance)
        //{
        //	*r_error = cast(GDExtensionCallError) GDEXTENSION_CALL_ERROR_INSTANCE_IS_NULL;
        //	return;
        //}
        //
        //auto id = gdextension_interface_object_get_instance_id(instance);
        //auto obj = gdextension_interface_object_get_instance_from_id(id);
        T t = cast(T) methodData; // method data is an actual D object backing godot instance

        if (!t)
            return;

        foreach (n; onReadyFieldNames!T) {
            alias udas = getUDAs!(__traits(getMember, T, n), OnReady);
            static assert(udas.length == 1, "Multiple OnReady UDAs on " ~ T.stringof ~ "." ~ n);

            alias A = Alias!(TemplateArgsOf!(udas[0])[0]);
            alias F = typeof(mixin("T." ~ n));

            // First, determine where to obtain the value to assign, and put it in `result`.
            // `result` will be alias to void if nothing to assign.
            static if (isCallable!A) {
                // pass the class itself to the function
                static if (Parameters!A.length && isImplicitlyConvertible!(T, Parameters!A[0]))
                    alias arg = t;
                else
                    alias arg = AliasSeq!();
                static if (is(ReturnType!A == void)) {
                    alias result = void;
                    A(arg);
                } else {
                    auto result = A(arg); /// temp variable for return value
                }
            } else static if (is(A))
                static assert(0, "OnReady arg can't be a type");
            else static if (isExpressions!A) // expression (string literal, etc)
            {
                    alias result = A;
                }
            else // some other alias (a different variable identifier?)
            {
                    static if (__traits(compiles, __traits(parent, A)))
                        alias P = Alias!(__traits(parent, A));
                    else
                        alias P = void;
                    static if (is(T : P)) {
                        // A is another variable inside this very same T
                        auto result = __traits(getMember, t, __traits(identifier, A));
                    } else
                        alias result = A; // final fallback: pass it unmodified to assignment
                }

            // Second, assign `result` to the field depending on the types of it and `result`
            static if (!is(result == void)) {
                import godot.resource;

                static if (isImplicitlyConvertible!(typeof(result), F)) {
                    // direct assignment
                    mixin("t." ~ n) = result;
                } else static if (__traits(compiles, mixin("t." ~ n) = F(result))) {
                    // explicit constructor (String(string), NodePath(string), etc)
                    mixin("t." ~ n) = F(result);
                } else static if (isGodotClass!F && extends!(F, Node)) {
                    // special case: node path
                    auto np = NodePath(result);
                    mixin("t." ~ n) = cast(F) t.getNode(np);
                } else static if (isGodotClass!F && extends!(F, Resource)) {
                    // special case: resource load path
                    import godot.resourceloader;

                    mixin("t." ~ n) = cast(F) ResourceLoader.load(result);
                } else
                    static assert(0, "Don't know how to assign " ~ typeof(result)
                            .stringof ~ " " ~ result.stringof ~
                            " to " ~ F.stringof ~ " " ~ fullyQualifiedName!(
                                mixin("t." ~ n)));
            }
        }

        // Finally, call the actual _ready() if it exists.
        enum bool isReady(alias func) = "_ready" == func;
        alias readies = Filter!(isReady, __traits(derivedMembers, T));
        static if(readies.length) {
            // superbelko: note that method_data here is actually D object instance 
            //
            // Explanation:
            //   IIRC I just took some existing function that is for regular calls,
            //   but then there is a special dedicated function for that or something like that,
            //   but because we already have too much template heavy code 
            //   adding yet another special case was too cumbersome.
            //   But... it was quite some time ago and I forgot the details so I maybe wrong.
            MethodWrapper!(T, mf).callMethod(null, methodData, args, numArgs, r_return, r_error); 
        }
    }
}

// Wrapper for GDExtensionPropertyInfo that holds data and allows it to be released unlike __gshared
struct PropertyInfo {
    this(this) {} // to silence annoying message
    StringName snName = void;
    StringName snClassName = void;
    String snHint = void; // suddenly it is a string and not a StringName
    GDExtensionVariantType typeKind;
    int hintFlags;
    int usageFlags;
}

package(godot) PropertyInfo makePropertyInfo(alias T, string Name)() {
    static if (is(T == Variant)) {
        import godot.globalenums : PropertyUsageFlags;
        enum propUsageFlags = PropertyUsageFlags.propertyUsageNilIsVariant;
        // fallback value in case for some reason this enum will go away
        //enum propUsageFlags = 131072;
    }
    else {
        enum propUsageFlags = PropertyUsageFlags.propertyUsageDefault;
    }
    static if (Name.length)
    StringName snName = StringName(Name);
    else
    StringName snName = stringName();

    static if (is(T == TypedArray!U, U))
        String snHint = String(makeTypeHint!T);
    else static if (extends!(T, Node) || extends!(T, Resource))
        String snHint = T.stringof;
    else
        String snHint = String();

    static if (Variant.variantTypeOf!T == VariantType.object) {
        static if (is(T == GodotObject))
            StringName snClassName = StringName("Object");
        else static if (is(T == Ref!U, U))
            StringName snClassName = StringName(U.stringof);
        else static if (!is(T == void))
            StringName snClassName = StringName(T.stringof);
        else
            StringName snClassName = stringName();
    }
    else {
        static if (is(T == TypedArray!U, U)) // typed array has no class name but a hint
            StringName snClassName = stringName();
        else static if (is(T == PackedArray!U, U))
            StringName snClassName = StringName(T.InternalName);
        else
            StringName snClassName = StringName(T.stringof);
    }

    static if (is(T == TypedArray!U, U))
        enum hintFlags = PropertyHint.propertyHintTypeString;
    else static if(extends!(T, Resource))
        enum hintFlags = PropertyHint.propertyHintResourceType;
    else static if(extends!(T, Node))
        enum hintFlags = PropertyHint.propertyHintNodeType;
    else
        enum hintFlags = 0;

    PropertyInfo retInfo = {
        snName: snName,
        snClassName: snClassName,
        snHint: snHint,
        typeKind: Variant.variantTypeOf!T,
        hintFlags: hintFlags,
        usageFlags: propUsageFlags,
    };
    return retInfo;
}

package(godot) template makeTypeHint(alias T) {
    // hint string is implemented in editor by parsing the encoded string in form of 
    //   subType/subTypeHint:nextSubtype
    // e.g. if your typed array is Array[Node3D] the string will be "24/34:Node3D"
    //      where 24 is VariantType.Object and 34 is PropertyHint.hintNodeType and will show node picker
    //      for classes that derives from Resource use hintResourceType(17) instead 
    // another example Array[Vector2] - "5/Vector2" where 5 is VariantType.vector2
    static if (is(T == TypedArray!U, U) && Variant.variantTypeOf!U == VariantType.object) {
        enum hint = cast(int)( extends!(U, Resource) ? PropertyHint.propertyHintResourceType : PropertyHint.propertyHintNodeType);
        string makeTypeHint = (cast(int) Variant.variantTypeOf!U).stringof 
            ~ "/" 
            ~ hint.stringof ~ ":" ~ U.stringof;
    }
    else static if (Variant.variantTypeOf!T != VariantType.nil) {
        string makeTypeHint = (cast(int) Variant.variantTypeOf!T).stringof 
            ~ "/" ~ U.stringof;
    }
    else 
        string makeTypeHint = null;
}

/++
Template for public variables exported as properties.

Params:
	T = the class that owns the variable
	var = the name of the member variable being wrapped
+/
package(godot) struct VariableWrapper(T, alias var) {
    import godot.refcounted, godot.api.reference;

    alias P = typeof(var);
    static if (extends!(P, RefCounted))
        static assert(is(P : Ref!U, U),
            "Reference type property " ~ T.stringof ~ "." ~ var ~ " must be ref-counted as Ref!("
                ~ P.stringof ~ ")");

    alias getterType = P function();
    alias setterType = void function(P v); // ldc doesn't likes 'val' name here

    extern (C) // for calling convention
    static void callPropertyGet(void* methodData, void* instance,
        const(void*)* args, long numArgs, void* r_return, GDExtensionCallError* r_error) {
        auto obj = cast(T) instance;
        if (!obj) {
            r_error.error = GDEXTENSION_CALL_ERROR_INSTANCE_IS_NULL;
            return;
        }
        if (numArgs > 0) {
            r_error.error = GDEXTENSION_CALL_ERROR_TOO_MANY_ARGUMENTS;
            return;
        }
        Variant* v = cast(Variant*) r_return;
        *v = Variant(mixin("obj." ~ __traits(identifier, var)));
    }

    extern (C) // for calling convention
    static void callPropertySet(void* methodData, void* instance,
        const(void*)* args, long numArgs, void* r_return, GDExtensionCallError* r_error) {
        auto obj = cast(T) instance;
        if (!obj) {
            r_error.error = GDEXTENSION_CALL_ERROR_INSTANCE_IS_NULL;
            return;
        }
        if (numArgs < 1) {
            r_error.error = GDEXTENSION_CALL_ERROR_TOO_FEW_ARGUMENTS;
            return;
        }
        Variant* v = cast(Variant*) args[0];
        mixin("obj." ~ __traits(identifier, var)) = v.as!P;
    }
}

extern (C) package(godot) void emptySetter(godot_object self, void* methodData,
    void* userData, godot_variant* value) {
    assert(0, "Can't call empty property setter");
    //return;
}

extern (C) package(godot) godot_variant emptyGetter(godot_object self, void* methodData,
    void* userData) {
    assert(0, "Can't call empty property getter");
    /+godot_variant v;
	gdextension_interface_variant_new_nil(&v);
	return v;+/
}

struct VirtualMethodsHelper(T) {
    static bool matchesNamingConv(string name)() {
        import std.uni : isAlphaNum;

        return name[0] == '_' && name[1].isAlphaNum;
    }
    import std.meta;
    static bool isFunc(alias member)() {
        return isFunction!(__traits(getMember, T, member));
    }

    alias derivedMfs = Filter!(matchesNamingConv, __traits(derivedMembers, T));
    alias onlyFuncs = Filter!(isFunc, derivedMfs);

    static GDExtensionClassCallVirtual findVCall(const GDExtensionStringNamePtr func) {
        // FIXME: StringName issues
        auto v = Variant(*cast(StringName*) func);
        auto fname = v.as!String.data();
        static foreach (name; onlyFuncs) {
            //if (MethodWrapper!(T, __traits(getMember, T, name)).funName == func)
            if (__traits(identifier, __traits(getMember, T, name)) == fname)
                return &MethodWrapper!(T, __traits(getMember, T, name)).virtualCall;
        }
        return null;
    }
}

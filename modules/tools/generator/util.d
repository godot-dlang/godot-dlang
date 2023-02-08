module godot.tools.generator.util;

import godot.tools.generator.classes;

import std.range;
import std.algorithm.searching;
import std.algorithm.iteration;
import std.path;
import std.conv : text;
import std.string;

import asdf;

//import asdf.source.asdf.asdf;

struct TypeStruct {
    @serdeKeys("name", "type") string name;
    @serdeOptional string meta;

    SerdeException deserializeFromAsdf(Asdf data) {
        // here we try read 3 options, 'name' variant is for native_structs
        name = data["type"].get!string(null);
        meta = data["meta"].get!string(null);
        if (name is null) {
            string val;
            if (auto exc = deserializeScopedString(data, val))
                return exc;
            name = val;
        }

        return null;
    }
}

//@serdeProxy!string
@serdeProxy!TypeStruct
class Type {
    static Type[string] typesByGodotName;
    static Type[string] typesByDName;

    static Type[] enums;

    GodotClass objectClass;
    GodotClass original; // original GodotClass associated with this Type
    string dType;
    string godotType;
    bool isNativeStruct;

    @property string dRef() const {
        return isRef ? ("Ref!" ~ dType) : dType;
    }

    Type enumParent;

    //alias dType this;

    string asModuleName() const {
        if (isPrimitive || isCoreType)
            return null;
        if (isNativeStruct)
            return "structs"; // module godot.structs
        return godotType.chompPrefix("_").toLower;
    }

    /// Backing opaque type to use instead of raw GDExtensionTypePtr
    string asOpaqueType() const {
        switch (godotType) {
        case "TypedArray":
        case "Array":
            return "godot_array";
        case "Variant":
            return "godot_variant";
        case "String":
        case "StringName":
            return "godot_string";
        case "NodePath":
            return "godot_node_path";
        case "Dictionary":
            return "godot_dictionary";
        case "PackedByteArray":
        case "PackedInt32Array":
        case "PackedInt64Array":
        case "PackedFloat32Array":
        case "PackedFloat64Array":
        case "PackedStringArray":
        case "PackedVector2Array":
        case "PackedVector3Array":
        case "PackedColorArray":
            //case "Nil":
            return "GDExtensionTypePtr";
        default:
            break;
        }

        if (!isRef || canBeCopied)
            return this.dType;

        return "godot_object";
    }

    bool isEnum() const {
        return godotType.startsWith("enum::");
    }

    bool isBitfield() const {
        return godotType.startsWith("bitfield::");
    }

    bool isTypedArray() const {
        return godotType.startsWith("typedarray::");
    }

    bool isMetaType() const {
        return isEnum || isBitfield || isTypedArray;
    }

    bool isPointerType() const {
        return dType.indexOf("*") != -1;
    }

    // Any type that is internally backed by godot string
    bool isGodotStringType() const {
        import std.algorithm : among;
        return godotType.among("StringName", "String", "NodePath") > 0;
    }

    bool isPrimitive() const {
        if (isEnum || isBitfield)
            return true;
        return only("int", "bool", "real", "float", "void", "double", "real_t",
            "uint8_t", "int8_t", "uint16_t", "int16_t", "uint32_t", "int32_t", "uint64_t", "int64_t", // well...
            "uint8", "int8", "uint16", "int16", "uint32", "int32", "uint64", "int64" // hope they will merge it or smth

            

        ).canFind(stripConstPointer.godotType);
    }

    // types that have simple value semantics and doesn't require special wrappers
    bool canBeCopied() const {
        return only("Vector2", "Vector2i", "Vector3", "Vector3i", "Vector4", "Vector4i",
            "Transform2D", "Transform3D", "Projection", "Rect2", "Rect2i",
            "Color", "Plane", "AABB", "Quaternion", "Basis", "RID"
        ).canFind(stripConstPointer.godotType);
    }

    bool isCoreType() const {
        if (auto arraytype = arrayType())
            return arraytype.isCoreType();
        // basically all types from extension_api.json from builtin_classes
        auto coreTypes = only("AABB",
            "Array",
            "Basis",
            "Callable",
            "Color",
            "Dictionary",
            "GodotError",
            "NodePath",
            "StringName",
            "Plane",
            "PackedByteArray",
            "PackedInt32Array",
            "PackedInt64Array",
            "PackedFloat32Array",
            "PackedFloat64Array",
            "PackedStringArray",
            "PackedVector2Array",
            "PackedVector3Array",
            "PackedColorArray",
            "Quaternion",
            "Rect2",
            "Rect2i",
            "RID",
            "String",
            "Transform3D",
            "Transform2D",
            "TypedArray",
            "Projection",
            "Variant",
            "Vector2",
            "Vector2i",
            "Vector3",
            "Vector3i",
            "Vector4",
            "Vector4i",
            "Nil", // why godot, why?
            "ObjectID");
        return coreTypes.canFind(godotType);
    }

    /// Get variant type name for method calls
    string asNativeVariantType() const {
        import godot.util.string;

        // useless but ok
        if (!(isCoreType || isPrimitive))
            return "GDEXTENSION_VARIANT_TYPE_OBJECT";

        return "GDEXTENSION_VARIANT_TYPE_" ~ camelToSnake(godotType).toUpper;
    }

    /// returns TypedArray type
    Type arrayType() const {
        if (!isTypedArray)
            return null;
        return Type.get(godotType["typedarray::".length .. $]);
    }

    bool isRef() const {
        return objectClass && objectClass.is_reference;
    }

    /// type should be taken as template arg by methods to allow implicit conversion in ptrcall
    bool acceptImplicit() const {
        auto accept = only("Variant");
        return accept.canFind(godotType);
    }

    /// prefix for function parameter of this type
    string dCallParamPrefix() const {
        if (isRef)
            return "";
        else if (objectClass)
            return "";
        else if (godotType.indexOf("const") != -1)
            return "";
        else
            return "in ";
    }
    /// how to pass parameters of this type into ptrcall void** arg
    string ptrCallArgPrefix() const {
        if (isPrimitive || isCoreType)
            return "&";
        return "";
        //return "cast(godot_object)"; // for both base classes and D classes (through alias this)
    }

    /// returns value name from string literal, default values in api.json uses integers instead of qualified enum values
    string getEnumValueStr(string value) const {
        import std.conv : to;
        import godot.util.string;

        if (!isEnum())
            return null;

        import godot.tools.generator.enums;

        // global enums doesn't have parent
        auto parent = Type.get(godot.tools.generator.enums.enumParent(godotType));
        if (!parent)
            parent = Type.get("CoreConstants");

        // just the enum name, without parent class name
        string innerName = splitEnumName(godotType)[1];

        // FIXME why it's always parent.original?
        auto searchInParent = parent.godotType == "CoreConstants" ? parent.original
            : parent.original;

        // HACK: core types not available here
        // if (searchInParent is null && parent.isCoreType) {
        // FIXME higher if throws access violation when searching later
        if (searchInParent is null) {
            return "cast(" ~ dType ~ ")" ~ value;
        }
        auto found = searchInParent.enums.find!(s => s.name == innerName);
        if (!found.empty) {
            foreach (pair; found.front.values)
                if (pair.value == to!int(value))
                    return dType ~ "." ~ snakeToCamel(pair.name);
        }

        return "cast(" ~ dType ~ ")" ~ value;
    }

    /// strip constness, also strips indirections (despite the name)
    Type stripConstPointer() const {
        char[] unqualified = cast(char[]) godotType.replace("const ", "").dup;
        while (unqualified[$ - 1] == '*') {
            unqualified[$ - 1] = '\0';
            unqualified = unqualified[0 .. $ - 1];
        }
        unqualified = unqualified.stripRight; // strip whitespace leftovers
        return Type.get(cast(string) unqualified);
    }

    // same as stripConstPointer() but only strips constness, useful for return types and template params
    Type stripConst() const {
        char[] unqualified = cast(char[]) godotType.replace("const ", "").dup;
        unqualified = unqualified.stripRight; // strip whitespace leftovers
        return Type.get(cast(string) unqualified);
    }

    // removes any prefixed meta names such as "enum::" in "enum::MyClass.MyEnum"
    Type stripMeta() const {
        // NOTE: this method is marked const, but we want it to be convenient.
        // this can lead to potential UB when user modifies the returned value,
        // and there is no other way around because Type.get(godotName) will return
        // same object as this.
        if (isEnum) {
            static import enumutils = godot.tools.generator.enums;
            // returns cached parent first, otherwise extract from name string
            if (enumParent)
                return cast() enumParent;
            return Type.get(enumutils.enumParent(godotType));
        }
        if (isBitfield) {
            return Type.get(godotType["bitfield::".length .. $]);
        }
        if (isTypedArray) {
            return Type.get(godotType["typedarray::".length .. $]);
        }
        return cast() this;
    }

    // Companion method for stripMeta, usually meta types is a nested types inside another class
    // so we have to take their enclosing type
    Type getParentType() const {
        import std.string : lastIndexOf;
        auto pos = godotType.lastIndexOf('.');
        if (pos > 0) {
            const parentName = godotType[0..pos];
            if (auto parent = parentName in Type.typesByGodotName)
                return *parent;
        }
        return null;
    }

    this(string godotName) {
        godotType = godotName;
        dType = godotName.escapeGodotType;
    }

    this(TypeStruct t) {
        // here t.name usually specifies old type like int, with meta describing actual length like int64
        if (t.meta)
            this(t.meta);
        else
            this(t.name);
    }

    static Type get(string godotName) {
        if (!godotName.length)
            return null; // no type (used in base_class)
        if (Type* ptr = godotName in typesByGodotName)
            return *ptr;
        Type ret = new Type(godotName);

        static import godot.tools.generator.enums;

        if (ret.isEnum) {
            ret.enumParent = get(godot.tools.generator.enums.enumParent(godotName));
            enums ~= ret;
        }

        typesByGodotName[godotName] = ret;
        typesByDName[ret.dType] = ret;

        return ret;
    }

    /*
	SerdeException deserializeFromAsdf(Asdf data)
    {
        string val;
        if (auto exc = deserializeScopedString(data, val))
            return exc;

        godotType = val;
		dType = godotType.escapeGodotType;

        return null;
    }
*/
    /*
	static Type deserialize(ref Asdf asdf)
	{
		string gn = asdf.get!string(null);
		Type ret = get(gn);
		return ret;
	}
	*/
}

/// the default value to use for an argument if none is provided
string defaultTypeString(in Type type) {
    import std.string;
    import std.conv : text;

    bool isPointer = type.dType.indexOf("*") != -1;

    switch (type.dType) {
    case "String":
        // FIXME: might cause some issues with auto-conversion?
        return `gs!""`;
    case "Dictionary":
        return type.dType ~ ".make()";
    case "Array":
        return type.dType ~ ".make()";
    default: { // all default-blittable types
            if (isPointer) {
                return "(" ~ type.dType ~ ").init";
            } else {
                return type.dType ~ ".init"; // D's default initializer
            }
            ///return "null";
        }
    }
}

/++
PoolVector2Array
PoolColorArray
Array
Vector2
float
Color
bool
Object
PoolVector3Array
Vector3
Transform2D
RID
int
Transform
Rect2
String
Variant
PoolStringArray
+/
string escapeDefaultType(in Type type, string arg) {
    import std.string;
    import std.conv : text;

    if (!arg || arg.length == 0)
        return defaultTypeString(type);

    if (type.isTypedArray) {
        // examples of typedarray:
        //   Array[RDPipelineSpecializationConstant]([])
        //   Array[RID]([])
        //   Array[Array]([])
        //   []
        // TODO: other cases such as that where it actually has values in it
        if (arg.startsWith("Array[") && arg.endsWith("([])")) {
            return "[]";
        }
    }
    // parse the defaults in api.json
    switch (type.dType) {
    case "Color": // "1,1,1,1"
        if (arg.startsWith("Color("))
            return arg;
        return "Color(" ~ arg ~ ")";
    case "bool": // True, False
        return arg.toLower;
    case "Array": // "[]", "Null" - just use the empty one
    case "Dictionary":
    case "PackedByteArray":
    case "PackedInt32Array":
    case "PackedInt64Array":
    case "PackedFloat32Array":
    case "PackedFloat64Array":
    case "PackedVector2Array":
    case "PackedVector3Array":
    case "PackedStringArray":
    case "PackedColorArray":
        return defaultTypeString(type);
    case "Transform3D": // "1, 0, 0, 0, 1, 0, 0, 0, 1 - 0, 0, 0" TODO: parse this
        if (arg.startsWith("Transform3D("))
            return arg;
        return "Transform3D(" ~ arg ~ ")";
    case "Transform2D":
        if (arg.startsWith("Transform2D("))
            return arg;
        return "Transform2D(" ~ arg ~ ")";
    case "Projection":
        if (arg.startsWith("Projection("))
            return arg;
        return "Projection(" ~ arg ~ ")";
    case "RID": // always empty?
        return defaultTypeString(type); // D's default initializer
    case "Vector2": // "(0, 0)"
    case "Vector2i": // "(0, 0)"
    case "Vector3":
    case "Vector3i":
    case "Vector4":
    case "Vector4i":
    case "Rect2": // "(0, 0, 0, 0)"
    case "AABB":
        if (arg.startsWith(type.godotType)) // prevent junk like 'Vector2Vector2(0, 0)'
            arg = arg[type.godotType.length .. $];
        return type.dType ~ arg;
    case "Variant":
        if (arg == "Null")
            return "Variant.nil";
        else
            return arg;
    case "String":
    case "StringName":
    case "NodePath": 
        // TODO: use this instead 
        version(none) {
            return type.dType ~ "(" ~ stripStringDefaultValueType() ~ ")"; 
        } 
        if (arg[0] == '&')
            arg = arg[1 .. $];
        // node path has default value that includes type, 
        // must strip it from here as we deal with string helpers later
        // example value: NodePath("")
        if (arg.startsWith("NodePath("))
            arg = arg["NodePath(".length..$-1];

        // HACK: hack in string, trying auto-convert?
        // if (arg.canFind('"'))
        //     return "gn!" ~ arg;
        // return "gn!\"" ~ arg ~ "\"";
        if (arg.canFind('"'))
            return type.dType ~ "(" ~ arg ~ ")";
        return type.dType ~ "(\"" ~ arg ~ "\")";
    default: // all Object types
    {
            if (arg == "Null" || arg == "null")
                return defaultTypeString(type);
            if (arg == "[Object:null]")
                return defaultTypeString(type);
            if (type.isEnum)
                return type.getEnumValueStr(arg);
            return arg;
        }
    }
}

// Same as above except it returns only the string itself without the prepending type
string stripStringDefaultValueType(in Type type, string arg) {
    // only mess up with strings
    if (!type.isGodotStringType)
        return arg;

    if (arg[0] == '&')
        arg = arg[1 .. $];
    // node path has default value that includes type, 
    // must strip it from here as we deal with string helpers later
    // example value: NodePath("")
    if (arg.startsWith("NodePath("))
        arg = arg["NodePath(".length..$-1];

    // HACK: hack in string, trying auto-convert?
    // if (arg.canFind('"'))
    //     return "gn!" ~ arg;
    // return "gn!\"" ~ arg ~ "\"";
    if (arg[0]=='"')
        return arg;
    else
        return "";
}

string escapeGodotType(string t) {
    import godot.tools.generator.enums : asEnumName;

    t = t.chompPrefix("_");

    if (t == "Object")
        return "GodotObject";
    if (t == "Error")
        return "GodotError";
    if (t == "Callable")
        return "GodotCallable";
    if (t == "Signal")
        return "Signal";
    if (t == "float")
        return "double";
    if (t == "int")
        return "long";
    if (t == "Nil")
        return "GDExtensionTypePtr";
    if (t.startsWith("enum::"))
        return t.asEnumName;
    if (t.startsWith("bitfield::"))
        return t["bitfield::".length .. $];
    if (t.startsWith("typedarray::"))
        return t.asTypedArray;
    return t;
}

string escapeDType(string s, string godotType = "") {
    import std.meta;
    import std.uni, std.utf;

    /// TODO: there must be a better way of doing this...
    /// maybe one of the D parser libraries has a list of keywords and basic types

    if (s.toUTF32[0].isNumber)
        s = "_" ~ s; // can't start with a number

    alias keywords = AliasSeq!(
        "class",
        "interface",
        "struct",
        "enum",
        "bool",
        "ubyte",
        "byte",
        "ushort",
        "short",
        "uint",
        "int",
        "ulong",
        "long",
        "cent", // really?
        "ucent",
        "float",
        "double",
        "real",
        "char",
        "wchar",
        "dchar",
        "function",
        "delegate",
        "override",
        "default",
        "case",
        "switch",
        "export",
        "import",
        "template",
        "new",
        "delete",
        "return",
        "with",
        "align",
        "in",
        "out",
        "ref",
        "scope",
        "auto",
        "init",
        "version",
        "body", // for now at least...
    );
    switch (s) {
    case "Object":
        return "GodotObject";
    case "Error":
        return "GodotError";
    case "Signal":
        return "GodotSignal";
    case "Callable":
        return "GodotCallable";
    foreach (kw; keywords) case kw:
        return "_" ~ s;
    default:
        return s;
    }
}

string asTypedArray(string type) {
    return "TypedArray!(" ~ type["typedarray::".length .. $] ~ ")";
}

string tab(string s, int tabs) {
    import std.conv : to;
    return repeat('\t', tabs).to!string ~ s;
}
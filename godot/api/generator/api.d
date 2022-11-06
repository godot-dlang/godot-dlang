module godot.api.generator.api;

import std.range;
import std.algorithm;
import std.path;
import std.conv;
import std.string;
import std.stdio;

import godot.api.generator.util;
import godot.api.generator.classes, godot.api.generator.methods, godot.api.generator.enums;

import godot.api.util.string;

import asdf;

struct Header {
    int version_major, version_minor, version_patch;
    string version_status, version_build, version_full_name;
}

struct TypeSize {
    string name;
    int size;
}

struct ConfigurationTypeSizes {
    string build_configuration;
    TypeSize[] sizes;
}

struct MemberOffset {
    string member;
    int offset;
}

struct TypeMemberOffsets {
    string name;
    MemberOffset[] members;
}

struct ConfigurationTypeMemberOffsets {
    string build_configuration;
    TypeMemberOffsets[] classes;
}

struct NativeStructure {
    Type name; // definition? maybe?
    string format; // expression(ish)

@serdeIgnore:

    // additional types that requires import
    Type[] used_classes;

    void addUsedClass(in Type c) {
        auto u = c.unqual();
        if (u.isNativeStruct || u.isPrimitive || u.isCoreType || u.godotType == "Object")
            return;
        if (u.isEnum)
            u = u.enumParent;
        // aww this sucks
        else if (u.godotType.canFind('.'))
            u = Type.get(u.godotType[0 .. u.godotType.indexOf('.')]);
        if (!used_classes.canFind(u))
            used_classes ~= u;
    }

    // parse format string and convert directly to D source, 
    // would be better to create GodotClass from it or even dedicated type
    string parseMembers() {
        string buf;
        auto s = appender(buf);
        foreach (field; format.split(';')) {
            // replace scope access symbol
            auto f = field.replace("::", ".");
            auto space = f.indexOf(' ');
            auto type = f[0 .. space];
            auto expr = f[space + 1 .. $];

            // now there is 3 possible variants: normal variable, pointer variable, function pointer
            // 1) pointer - starts with '*' in member name (second part)
            // 2) function pointer - starts with '(*' in member  name part and additionally have second pair braces for arguments
            // 3) variables can also have default values 'int start = -1', floats is usually written in form '0.f' which is invalid in D

            // case 2 - function pointer
            if (expr.startsWith("(*")) {
                auto rb = expr.indexOf(')');
                auto name = expr[2 .. rb]; // strip '(*'
                addUsedClass(Type.get(type.adjustTypeNameOnField.getArrayType)); // ewww, side effects...
                s ~= gdnToDType(type) ~ " function(";

                auto last = expr.indexOf(')', rb + 1);
                foreach (i, arg; expr[rb + 2 .. last].split(',')) {
                    if (i != 0)
                        s ~= ", ";
                    auto adjustedField = adjustTypeNameOnField(arg.strip);
                    auto pair = adjustedField.split(' ');
                    s ~= gdnToDType(pair[0]) ~ " " ~ pair[1];
                    addUsedClass(Type.get(pair[0].adjustTypeNameOnField.getArrayType)); // ewww, side effects...
                }

                s ~= ") " ~ name ~ ";\n";
            } else // plain variable
            {
                auto adjustedField = adjustTypeNameOnField(f);
                auto pair = adjustedField.split(' ');
                s ~= gdnToDType(pair[0]) ~ " " ~ pair[1];
                addUsedClass(Type.get(pair[0].adjustTypeNameOnField.getArrayType)); // ewww, side effects...
                if (auto idx = pair.countUntil(["="])) {
                    // TODO: convert default value
                }
                s ~= ";\n";
            }
        }
        return s[];
    }
}

struct Singleton {
    Type name;
    Type type;
}

alias Constant = int[string];

struct ExtensionsApi {
    Header header;
    ConfigurationTypeSizes[] builtin_class_sizes;
    ConfigurationTypeMemberOffsets[] builtin_class_member_offsets;
    Constant[] global_constants;
    GodotEnum[] global_enums;
    GodotMethod[] utility_functions;
    GodotClass[] builtin_classes; // only basic types such as Vector3, Color, Dictionary, etc...
    GodotClass[] classes;
    Singleton[] singletons;
    NativeStructure[] native_structures;

    void finalizeDeserialization(Asdf data) {
        foreach (cls; builtin_classes) {
            cls.isBuiltinClass = true;
        }

        // update native structs before binding classes
        foreach (s; native_structures) {
            Type.get(s.name.godotType).isNativeStruct = true;
        }

        // mark singletons before writing class bindings
        foreach (s; singletons) {
            auto cls = classes.find!(c => c.name.godotType == s.name.godotType);
            if (!cls.empty)
                cls.front.singleton = true;
        }

        // 
        foreach (c; classes) {
            if (c.name.godotType != "Object") {
                c.base_class = Type.get(c.base_class.godotType);
                //c.base_class.original = Type.get(c.base_class.godot).original;
                //c.base_class.objectClass = Type.get(c.base_class.godot).objectClass;
            }
        }
    }
}

string generateHeader(ref ExtensionsApi api) {
    Appender!string s;

    s ~= "enum VERSION_MAJOR = " ~ api.header.version_major.text ~ ";\n";
    s ~= "enum VERSION_MINOR = " ~ api.header.version_minor.text ~ ";\n";
    s ~= "enum VERSION_PATCH = " ~ api.header.version_patch.text ~ ";\n";
    s ~= `enum VERSION_STATUS = "%s";`.format(api.header.version_status) ~ '\n';
    s ~= `enum VERSION_BUILD = "%s";`.format(api.header.version_build) ~ '\n';
    s ~= `enum VERSION_FULLNAME = "%s";`.format(api.header.version_full_name) ~ '\n';

    return s[];
}

string generateBuiltins(ref ExtensionsApi ap) {
    string s;

    s ~= "module godot.builtins;\n\n";

    s ~= `import std.meta : AliasSeq, staticIndexOf;
import std.traits : Unqual;
import godot.d.traits;
import godot.core;
import godot.c;
import godot.d.bind;
import godot.d.reference;
import godot.globalenums;
import godot.object;
import godot.classdb;`;
    s ~= "\n";
    s ~= "// This module contains low level type bindings and only provides raw pointers.\n\n";

    foreach (cls; ap.builtin_classes) {
        // skip unneeded types like Nil
        if (!cls.name.isCoreType())
            continue;

        s ~= cls.source();
    }
    return s;
}

string generateGlobals(ref ExtensionsApi api) {
    return null;
}

string generateSingletons(ref ExtensionsApi api) {
    return null;
}

void writeBindings(ref ExtensionsApi ap, string dirPath) {
    import std.file, std.path;

    // write global enums
    writeGlobalEnums(ap, dirPath);

    foreach (cls; ap.classes) {
        auto path = dirPath.buildPath(cls.name.moduleName ~ ".d");

        std.file.write(path, cls.source());
    }

    writeStructs(ap, dirPath);
}

void writeGlobalEnums(ref ExtensionsApi ap, string dirPath) {
    string buf;
    auto s = appender(buf);
    s ~= "module godot.globalenums;\n\n";

    foreach (en; ap.global_enums) {
        if (en.name.startsWith("Variant."))
            continue;
        if (en.name == "Error") // ignore this, already in core defs
            continue;

        s ~= en.source();
        s ~= "\n";
    }

    import std.file, std.path;

    std.file.write(dirPath.buildPath("globalenums.d"), s[]);
}

void writeStructs(ref ExtensionsApi api, string dirPath) {
    string buf;
    auto s = appender(buf);
    s ~= "module godot.structs;\n\n";
    s ~= "import godot.core;\n";
    s ~= "import godot.c;\n\n";

    foreach (st; api.native_structures) {
        auto source = st.parseMembers();

        foreach (imp; st.used_classes)
            s ~= "import godot." ~ imp.moduleName ~ ";\n";

        s ~= "struct " ~ st.name.dType ~ "\n{\n";

        // quick hack to indent fields
        string[dchar] transTable = ['\n': "\n    "];
        // add leading indent, but skip last one
        s ~= "    " ~ source[0 .. $ - 1].translate(transTable) ~ '\n';

        s ~= "}\n\n\n";
    }

    import std.file, std.path;

    std.file.write(dirPath.buildPath("structs.d"), s[]);
}

// converts GDExtension native types such as ones in Built-In Structures to D form
string gdnToDType(string type) {
    return type;
}

// strips pointers from name part and place it next to type
string adjustTypeNameOnField(string expr) {
    auto pos = expr.indexOf(' ');
    if (pos == -1)
        return expr;

    // simply bubble all * to left on a duplicate
    char[] str = expr.dup;
    while (pos + 1 < str.length) {
        // stop when reach name delimiters
        if (str[pos + 1].among(';', ':', '(', ')', '='))
            break;

        if (str[pos + 1] == '*') {
            auto temp = str[pos];
            str[pos] = '*';
            str[pos + 1] = temp;
        }

        pos++;
    }

    // rewrite C style array with D style array
    if (str.endsWith("]")) {
        pos = str.indexOf(' ');
        if (pos != -1) {
            auto leftBr = str.lastIndexOf('[');
            auto dim = str[leftBr .. $];
            // reassemble string moving array dimensions next to type
            auto temp = str[0 .. pos] ~ dim ~ str[pos .. leftBr];
            str = temp;
        }
    }

    return cast(string) str;
}

/// strips array size from type
string getArrayType(string type) {
    auto pos = type.indexOf('[');
    if (pos == -1)
        return type;
    return type[0 .. pos];
}

// make operator name from operator symbol,
// e.g. "!=" -> "notEqual", "<" -> "less"
string opName(string op) {
    __gshared static string[string] opNames;

    if (!opNames)
        opNames = [
            "==": "equal",
            "!=": "not_equal",
            "<": "less",
            "<=": "less_equal",
            ">": "greater",
            ">=": "greater_equal",
            "+": "add",
            "-": "subtract",
            "*": "multiply",
            "/": "divide",
            "unary-": "negate",
            "unary+": "positive",
            "%": "module",
            "<<": "shift_left",
            ">>": "shift_right",
            "&": "bit_and",
            "|": "bit_or",
            "^": "bit_xor",
            "~": "bit_negate",
            "and": "and",
            "or": "or",
            "xor": "xor",
            "not": "not",
            "and": "and",
            "in": "in",
        ];

    return opNames.get(op, "wtf");
}

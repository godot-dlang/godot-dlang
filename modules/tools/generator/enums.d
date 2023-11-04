module godot.tools.generator.enums;

import godot.util.string;
import godot.tools.generator.classes;
import godot.tools.generator.util;

import asdf;

import std.range;
import std.algorithm.searching;
import std.algorithm.iteration;
import std.algorithm.sorting;
import std.path;
import std.conv : text;
import std.string;

string enumParent(string name) {
    return name.splitEnumName[0];
}

/// splits the name of an enum as obtained from the JSON into [class, enum] names.
string[2] splitEnumName(string type) {
    // skip 'enum::' part
    string name = type[6 .. $];
    auto end = name.countUntil("."); // enum:: arleady skipped, now look for scope qualifier e.g. TextServer.Hinting 
    if (end == -1)
        return [null, name]; // not a class
    return [name[0 .. end], name[end + 1 .. $]];
}

/// format the enum type for D.
string asEnumName(string type) {
    string[2] split = type.splitEnumName;
    if (!split[0])
        return split[1].escapeDType;
    return Type.get(split[0]).dType ~ "." ~ split[1].escapeDType;
}

struct EnumValues {
    string name;
    long value;
}

struct GodotEnum {
    string name;
    EnumValues[] values;
    @serdeOptional bool is_bitfield;

@serdeIgnore:
    GodotClass parent;

    string[string] ddoc;

    string source() const {
        string ret = "\t/// \n\tenum " ~ name.escapeDType ~ " : long {\n";

        foreach (n; values /*.sort!((a, b)=>(a.value < b.value))*/ ) {
            if (auto ptr = n.name in ddoc)
                ret ~= "\t\t/**\n\t\t" ~ (*ptr).replace("\n", "\n\t\t") ~ "\n\t\t*/\n";
            else
                ret ~= "\t\t/** */\n";
            ret ~= "\t\t" ~ n.name.snakeToCamel.escapeDType ~ " = " ~ n.value.text ~ ",\n";
        }

        ret ~= "\t}\n";
        return ret;
    }
}

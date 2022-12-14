module godot.tools.generator.d;

import godot.util.string;
import godot.tools.generator.util;
import godot.tools.generator.classes;
import godot.tools.generator.methods;

import std.algorithm.iteration;
import std.range;
import std.path;
import std.conv : text;
import std.string;

private:

static immutable string copyrightNotice =
`Copyright (c) 2007-2022 Juan Linietsky, Ariel Manzur.
Copyright (c) 2014-2022 Godot Engine contributors (cf. AUTHORS.md)
Copyright (c) 2017-2018 Godot-D contributors
Copyright (c) 2022-2022 Godot-DLang contributors`;

string[2] generatePackage(GodotClass c) {
    if (c.name.godotType == "CoreConstants")
        return [null, null];

    if (c.descendant_ptrs.length == 0)
        return [null, null];

    string filename = buildPath("godot", c.name.asModuleName, "all.d");
    string ret;

    ret ~= "module godot.";
    ret ~= c.name.asModuleName;
    ret ~= ".all;\n\n";

    ret ~= "public import\n\tgodot." ~ c.name.asModuleName;

    const(GodotClass)[] recursiveDescendants;
    void addDescendant(GodotClass d) {
        import std.algorithm.searching;

        if (!recursiveDescendants[].canFind(d))
            recursiveDescendants ~= d;
        foreach (rd; d.descendant_ptrs[])
            addDescendant(rd);
    }

    foreach (d; c.descendant_ptrs[])
        addDescendant(d);

    foreach (di, d; recursiveDescendants[]) {
        ret ~= ",\n\tgodot." ~ d.name.asModuleName;
    }
    ret ~= ";\n";

    string[2] arr = [filename, ret];
    return arr;
}

string[2] generateClass(GodotClass c) {
    if (c.name.godotType == "CoreConstants")
        return [null, null];

    string folder = "godot";
    string filename = (c.descendant_ptrs.length == 0) ?
        buildPath(folder, c.name.asModuleName ~ ".d") : buildPath(folder, c.name.asModuleName, "package.d");
    string ret;

    ret ~= "/**\n" ~ c.ddocBrief ~ "\n\n";
    ret ~= "Copyright:\n" ~ copyrightNotice ~ "\n\n";
    ret ~= "License: $(LINK2 https://opensource.org/licenses/MIT, MIT License)\n\n";
    ret ~= "\n*/\n";

    // module names should be all lowercase in D
    // https://dlang.org/dstyle.html
    ret ~= "module godot.";
    ret ~= c.name.asModuleName;
    ret ~= ";\n";
    ret ~= "public import std.meta : AliasSeq, staticIndexOf;\n";
    ret ~= "public import std.traits : Unqual;\n";
    ret ~= "public import godot.api.traits;\nimport godot;\nimport godot.abi;\n";
    ret ~= "public import godot.api.bind;\n";
    ret ~= "public import godot.api.reference;\n";
    ret ~= "public import godot.globalenums;\n";

    if (c.name.godotType != "Object") {
        ret ~= "public import godot.object;\n";
    }

    if (c.instanciable) {
        ret ~= "public import godot.classdb;\n";
    }

    ret ~= c.source;

    string[2] arr = [filename, ret];
    return arr;
}

string[2] generateGlobalConstants(GodotClass c) {
    import std.conv : text;
    import std.string;
    import std.meta;
    import std.algorithm.iteration, std.algorithm.searching, std.algorithm.sorting;
    import std.range : array;

    if (c.name.godotType != "CoreConstants")
        return [null, null];

    string filename = buildPath("godot", "globalconstants.d");
    string ret;

    ret ~= "/// \n";
    ret ~= "module godot.globalconstants;\n";
    ret ~= "public import godot.globalenums;\n";

    foreach (constant; c.constants) {
        ret ~= "enum int " ~ constant.name.snakeToCamel.escapeDType ~ " = " ~ text(
            constant.value) ~ ";\n";
    }

    string[2] arr = [filename, ret];
    return arr;
}

string[2] generateGlobalEnums(GodotClass c) {
    import std.conv : text;
    import std.string;
    import std.meta;
    import std.algorithm.iteration, std.algorithm.searching, std.algorithm.sorting;
    import std.range : array;

    if (c.name.godotType != "CoreConstants")
        return [null, null];

    string filename = buildPath("godot", "globalenums.d");
    string ret;

    ret ~= "/// \n";
    ret ~= "module godot.globalenums;\n";

    /// Try to put at least some of these in grouped enums
    static struct Group {
        string name; /// The name of the new enum
        string prefix; /// The prefix to strip from original name
    }

    alias groups = AliasSeq!(
        Group("Key", "KEY_"),
        Group("MouseButton", "MOUSE_BUTTON_"),
        Group("PropertyHint", "PROPERTY_HINT_"),
        Group("PropertyUsage", "PROPERTY_USAGE_"),
        Group("Type", "TYPE_"),
        Group("TransferMode", "TRANSFER_MODE_"),
        Group("InlineAlign", "INLINE_ALIGN_"),
    );

    import godot.tools.generator.enums;

    foreach (g; c.enums) {
        // Skip Variant.Type & Variant.Operator, they are defined in core C module
        if (g.name.startsWith("Variant.") || g.name == "PropertyUsageFlags")
            continue;

        ret ~= "enum " ~ g.name ~ " : int {\n";

        foreach (e; g.values) {
            ret ~= "\t" ~ e.name.snakeToCamel.escapeDType
                ~ " = " ~ text(e.value) ~ ",\n";
        }

        ret ~= "}\n";
    }

    // Godot itself never refers to these, but some modules like Goost do.
    // Allow bindings for them to compile by keeping the original names.
    //string[2][] aliases = [["KeyList", "Key"], ["PropertyUsageFlags", "PropertyUsage"], ["ButtonList", "MouseButton"]];
    //foreach(a; aliases)
    //{
    //	ret ~= "alias " ~ a[0] ~ " = " ~ a[1] ~ ";\n";
    //}

    string[2] arr = [filename, ret];
    return arr;
}

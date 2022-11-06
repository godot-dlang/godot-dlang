// module godot.api.generator;

import godot.api.generator.util;
import godot.api.generator.c;
import godot.api.generator.classes, godot.api.generator.methods, godot.api.generator.enums;
import godot.api.generator.doc;
import godot.api.generator.api;

import godot.api.generator.d;

import asdf;

import std.string : toLower, chompPrefix;
import std.stdio : writeln, writefln;
import std.file : exists, readText, mkdirRecurse, isDir, writeFile = write, dirEntries, SpanMode, rmdirRecurse;
import std.path : buildPath, dirName, extension, stripExtension, baseName;
import std.format : format;
import std.getopt : defaultGetoptPrinter, getopt, GetoptResult;
import std.range : empty;

void usage(GetoptResult opt) {
    defaultGetoptPrinter("Usage: [OPTION]... [outputDir]\n", opt.options);
    writeln();
}

int main(string[] args) {
    string extensionsJson = "extension_api.json";
    string godotSource;
    bool overwrite = false;
    auto opt = args.getopt(
        "json|j", "Extensions API JSON (default: extensions_api.json)", &extensionsJson,
        "source|s", "Godot source directory, for documentation (also sets gdnative if unset)", &godotSource,
        "overwrite|o", "Overwrite outputDir unconditionally", &overwrite
    );

    writeln(args);
    if (opt.helpWanted) {
        usage(opt);
        return 0;
    }

    string outputDir;
    if (args.length >= 2)
        outputDir = args[1];
    else {
        outputDir = args[0].dirName.buildPath("classes");
        writefln("Outputting to default directory %s...", outputDir);
    }
    if (outputDir.exists) {
        if (!outputDir.isDir) {
            usage(opt);
            writefln("Error: '%s' is not a directory", outputDir);
            return 1;
        }

        bool shouldOverwrite = overwrite;
        // check if it looks like the API directory
        if (outputDir.buildPath("godot", "c", "api.d").exists)
            shouldOverwrite = true;
        if (!shouldOverwrite) {
            usage(opt);
            writefln("Error: output directory '%s' already exists. Pass '-o' to overwrite it.", outputDir);
            return 1;
        }
        writefln("Overwriting existing output directory '%s'...", outputDir);
        rmdirRecurse(outputDir);
    }
    outputDir.mkdirRecurse;

    ExtensionsApi extApi = extensionsJson.readText.deserialize!(ExtensionsApi);
    auto cPath = outputDir.buildPath("godot");

    // some crazy issues on Windows, exists() doesn't work
    mkdirRecurse(cPath);
    if (!cPath.dirName.exists)
        cPath.dirName.mkdirRecurse;

    // write extension api header with version info
    writeFile(cPath.buildPath("apiinfo.d"), extApi.generateHeader);

    // write actual declarations sorted by category
    writeFile(cPath.buildPath("builtins.d"), extApi.generateBuiltins);
    writeFile(cPath.buildPath("globals.d"), extApi.generateGlobals);
    writeFile(cPath.buildPath("singletons.d"), extApi.generateSingletons);
    // generate files for classes
    extApi.writeBindings(cPath);

    writefln("Done! API bindings written to '%s'", outputDir);
    return 0;
}

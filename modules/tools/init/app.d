import std.stdio: write, writeln, readln, File;
import std.getopt: Option, getopt, GetoptResult, config;
import std.file: getcwd, isDir, mkdir;
import std.path: absolutePath, buildNormalizedPath, dirSeparator;
import std.array: split;
import std.format: format;
import std.datetime: Clock;
import std.process: spawnProcess, wait;
import std.conv: to;

import core.stdc.stdlib: getenv;

string jsonTemplate = `
{
    "name": "%s",
    "description": "%s",
    "authors": ["%s"],
    "licence": "%s",
    "copyright": "%s",
    
    %s
    "dflags-windows-ldc": ["-dllimport=defaultLibsOnly"],
    
    "targetType": "dynamicLibrary",
    %s
    "targetName": "%s",

    %s
}
`;

string sdlTemplate = `
name "%s"
description "%s"
authors "%s"
licence "%s"
copyright "%s"

%s
dflags "-dllimport=defaultLibsOnly" platform="windows-ldc2"

targetType "dynamicLibrary"
%s
targetName "%s"

%s
`;

string gdextTemplate = `
[configuration]

entry_symbol = "%s_gdextension_entry"

[libraries]

linux.64 = "lib%s.so"
windows.64 = "%s.dll"
`;

string mainTemplate = `
import godot.api.register;

mixin GodotNativeLibrary!(
    "%s"
    // Add your classes here after comma
);
`;

int main(string[] args) {
    string path = getcwd();
    bool importc = false;
    string cgodotpath = "";

    GetoptResult help = getopt(
        args,
        config.bundling, config.passThrough, config.caseSensitive,
        "path|p", "Set project init path", &path,
        "importc|i", "Make project use C header instead of manual bindings", &importc,
        "custom|c", "Set custom path to godot-dlang", &cgodotpath
    );

    if (help.helpWanted) {
        printGetopt(
            "Usage: godot-dlang:init [args]",
            "Example:\n" ~
            "dub run godot-dlang:init\n" ~
            "dub run godot-dlang:init -- -p custom/project/ -c ../custom/path/godot-dlang/",
            help.options
        );
        return 0;
    }

    path = path.buildNormalizedPath.absolutePath;

    if (!path.isDir) {
        writeln("Path must be a directory. Aborting.");
        return 1;
    }

    write("Do you want to initialize godot-dlang project in \"", path,"\"? [Y/n]: ");
    char answer = readln()[0];
    if (answer != 'y' && answer != 'Y' && answer != '\n') return 0;
    
    bool sdl = false;
    string pkgfmt;
    while (true) {
        write("Package recipe format (sdl/json) [json]: ");
        pkgfmt = readln()[0..$-1];
        if (pkgfmt == "json" || pkgfmt == "sdl" || pkgfmt == "") break;
        writeln("Error, invalid format '", pkgfmt, ", enter either 'sdl' or 'json'.");
    }
    if (pkgfmt == "sdl") sdl = true;

    version (Windows) {
        string uname = getenv("USERNAME").to!string;
    } else {
        string uname = getenv("USER").to!string;
    }
    string[] pathArr = path.split(dirSeparator);
    string pkgname = prompt("Name", pathArr[pathArr.length.to!int - 1]);
    string description = prompt("Description", "A minimal Godot-DLang project.");
    string authors = prompt("Author name", uname);
    string license = prompt("License", "proprietary");
    string copyright = prompt("Copyright string", "Copyright © " ~ Clock.currTime.year.to!string ~ ", " ~ authors);
    // TODO: check paths
    string targetPath = prompt("Target path (type '.' for pwd)", "lib");
    
    string dubTemplate = sdl ? sdlTemplate : jsonTemplate;
    string icstring = sdl ? "dflags \"-version=importc\"" : "\"dflags\": \"-version=importc\",";
    string libstr = sdl ? "dependency \"godot-dlang\" path=\"" ~ cgodotpath ~  "\"" : 
                          "\"dependencies\": {\n        \"godot-dlang\": {\"path\": \"" ~ 
                          cgodotpath ~ "\"}\n    },";
    string targetStr = sdl ? "targetPath \"" ~ targetPath ~ "\"" : "\"targetPath\": \"" ~ targetPath ~ "\",";

    string dub = dubTemplate.format(
        pkgname,
        description,
        authors,
        license,
        copyright,
        importc ? icstring : "",
        targetPath == "." ? "" : targetStr,
        pkgname,
        cgodotpath == "" ? "" : libstr
    );
    
    File f = File(path ~ dirSeparator ~ "dub." ~ (sdl ? "sdl" : "json"), "w");
    f.write(dub);
    f.close();

    if (cgodotpath == "") {
        wait(spawnProcess(["dub", "add", "godot-dlang", "--root=" ~ path]));
    }

    while (true) {
        write("Add dependency (leave empty to skip) []: ");
        string dep = readln()[0..$-1];
        if (dep == "") break;
        wait(spawnProcess(["dub", "add", dep, "--root=" ~ path]));
    }
    
    writeln("Creating entrypoint.");

    mkdir(path ~ dirSeparator ~ "source");

    f = File(path ~ dirSeparator ~ "source" ~ dirSeparator ~ "lib.d", "w");
    f.write(mainTemplate.format(pkgname));
    f.close();
    
    writeln("Creating GDExtension file.");

    f = File(path ~ dirSeparator ~ pkgname ~ ".gdextension", "w");
    f.write(gdextTemplate.format(pkgname, pkgname, pkgname));
    f.close();

    writeln("Project successfully initialized.");

    return 0;
}

/*
Package recipe format (sdl/json) [json]: 
Name [Application]: 
Description [A minimal D application.]: 
Author name [Name]: 
License [proprietary]: 
Copyright string [Copyright © 2023, Name]: 
Add dependency (leave empty to skip) []: 
*/

string prompt(string _prompt, string _default) {
    write(_prompt ~ " [" ~ _default ~ "]: ");
    string _out = readln()[0..$-1];
    if (_out == "") return _default;
    return _out;
}

import std.algorithm : max;
import std.stdio : writefln;

/** 
Helper function to get std.getopt.Option
Params:
    _long = Option name
    _help = Option help
Returns: std.getopt.Option
*/
Option customOption(string _long, string _help) { return Option("", _long, _help, false); }

private enum bool isOptionArray(T) = is(T == Option[]);
private enum bool isOption(T) = is(T == Option);
private enum bool isString(T) = is(T == string);

/** 
Prints passed **Option**s and text in aligned manner on stdout, i.e:
```
A simple cli tool
Usage: 
  scli [options] [script] \
  scli run [script]
Options: 
  -h, --help   This help information. \
  -c, --check  Check syntax without running. \
  --quiet      Run silently (no output). 
Commands:
  run          Runs script. \
  compile      Compiles script.
```
Can be used like:
---------
printGetopt("Usage", "Options", help.options, "CustomOptions", customArray, customOption("opt", "-h"));
---------
Params:
  S = Can be either std.getopt.Option[], std.getopt.Option or string
*/
void printGetopt(S...)(S args) { // string text, string usage, Option[] opt, 
    size_t maxLen = 0;
    bool[] isNextOpt = [];

    foreach (arg; args) {
        alias A = typeof(arg);

        static if(isOptionArray!A) {
            foreach (it; arg) {
                int sep = it.optShort == "" ? 0 : 2;
                maxLen = max(maxLen, it.optShort.length + it.optLong.length + sep);
            }
            isNextOpt ~= true;
            continue;
        } else
        static if(isOption!A) {
            int sep = arg.optShort == "" ? 0 : 2;
            maxLen = max(maxLen, arg.optShort.length + arg.optLong.length + sep);
            isNextOpt ~= true;
            continue;
        } else
        static if(isString!A) {
            isNextOpt ~= false;
            continue;
        }
    }

    int i = 0;
    foreach (arg; args) {
        alias A = typeof(arg);
        static if(isOptionArray!A) {
            foreach (it; arg) {
                string opts = it.optShort ~ (it.optShort == "" ? "" : ", ") ~ it.optLong;
                writefln("  %-*s  %s", maxLen, opts, it.help);
            }
        } else 
        static if(isOption!A) {
            string opts = arg.optShort ~ (arg.optShort == "" ? "" : ", ") ~ arg.optLong;
            writefln("  %-*s  %s", maxLen, opts, arg.help);
        } else
        static if(isString!A) {
            bool nopt = i + 1 < isNextOpt.length ? (isNextOpt[ i + 1 ]) : (false);
            bool popt = i - 1 > 0 ? (isNextOpt[ i - 1 ]) : (false);
            writefln((popt ? "\n" : "") ~ arg ~ (nopt ? ":" : "\n"));
        }

        ++i;
    }
}

module godot.tools.generator.c;

import godot.tools.generator.util;

import std.string;
import std.format;
import std.algorithm.iteration;
import std.algorithm.comparison;

import asdf;

// FIXME there's a lot of @nogc

struct Function {
    string name;
    string return_type;
    string[2][] arguments; // type, name

@serdeIgnore:

}

struct ApiVersion {
    int major, minor;

    int opCmp(ApiVersion other) const {
        return cmp([major, minor], [other.major, other.minor]);
    }

@serdeIgnore:

    string str() {
        return format!"_%d_%d"(major, minor);
    }
}

struct Api {
    ApiPart core;
    ApiPart[] extensions;

@serdeIgnore:

    string source() {
        string ret = "module godot.abi.api;\n\n";
        ret ~= "public import godot.abi.core;\n\n";
        foreach (v; extensions)
            ret ~= "public import godot.abi." ~ v.name ~ ";\n";

        ret ~= "public import std.meta : AliasSeq, staticIndexOf;\n";
        ret ~= "public import std.format : format;\nimport std.string : capitalize, toLower;\nimport std.conv : text;\n";
        ret ~= "public import core.stdc.stdint;\nimport core.stdc.stddef : wchar_t;\n\n";

        ret ~= q{
			extern(C) struct godot_gdextension_api_version
			{
				uint major, minor;
			}
			mixin template ApiStructHeader()
			{
				uint type;
				godot_gdextension_api_version ver;
				const godot_gdextension_api_struct *next;
			}
			extern(C) struct godot_gdextension_api_struct
			{
				mixin ApiStructHeader;
			}
			private string versionError(string name, int major, int minor)
			{
				string ret = "Bindings for GDExtension extension "~name;
				if((major == 1 && minor == 0)) ret ~= " do not exist. ";
				else ret ~= format!" exist, but not for version %d.%d. "(major, minor);
				ret ~= "Please provide a more recent gdextension_api.json to the binding generator to fix this.";
				return ret;
			}
		};

        ret ~= "enum ApiType : uint {\n";
        ret ~= "\t" ~ core.type.toLower ~ ",\n";
        foreach (part; extensions)
            ret ~= "\t" ~ part.type.toLower ~ ",\n";
        ret ~= "}\n";

        ret ~= "private {\n";
        ret ~= core.versionSource;
        foreach (part; extensions)
            ret ~= part.versionSource;
        ret ~= "}\n";

        ret ~= "struct GDExtensionVersion {\n";
        ret ~= core.versionGetterSource;
        foreach (part; extensions)
            ret ~= part.versionGetterSource;
        ret ~= q{
			@nogc nothrow
			static bool opDispatch(string name)()
			{
				static assert(name.length > 3 && name[0..3] == "has",
					"Usage: `GDExtensionVersion.has<Extension>!(<major>, <minor>)`");
				static assert(0, versionError(name[3..$], 1, 0));
			}
		};
        ret ~= "}\n";

        ret ~= core.source("core");
        ApiPart coreNext = core.next;
        while (coreNext) {
            ret ~= coreNext.source("core");
            coreNext = coreNext.next;
        }
        foreach (part; extensions) {
            ApiPart p = part;
            while (p) {
                ret ~= p.source(part.name);
                p = p.next;
            }
        }

        ret ~= q{
			@nogc nothrow
			void godot_gdextension_api_struct_init(in godot_gdextension_core_api_struct* s)
			{
				import std.traits : EnumMembers;
				
				@nogc nothrow static void initVersions(ApiType type)(in godot_gdextension_api_struct* main)
				{
					const(godot_gdextension_api_struct)* part = main;
					while(part)
					{
						foreach(int[2] v; SupportedVersions!type)
						{
							if(part.ver.major == v[0] && part.ver.minor == v[1]) mixin(format!"has%s_%d_%d"
								(type.text.capitalize, v[0], v[1])) = true;
						}
						part = part.next;
					}
				}
				
				if(!s) assert(0, "godot_gdextension_core_api_struct is null");
				if(_godot_api) return; // already initialized
				_godot_api = s;
				initVersions!(ApiType.core)(cast(const(godot_gdextension_api_struct)*)(cast(void*)s));
				foreach(ext; s.extensions[0..s.num_extensions])
				{
					// check the actual extension type at runtime, instead of relying on the order in the JSON
					if(ext.type == 0) continue; // core? should never happen
					if(ext.type >= EnumMembers!ApiType.length)
					{
						continue; // unknown extension type
					}
					ApiTypeSwitch: final switch(cast(ApiType)ext.type)
					{
						foreach(E; EnumMembers!ApiType)
						{
							case E:
								apiStruct!E = cast(typeof(apiStruct!E))(cast(void*)ext);
								initVersions!E(ext);
								break ApiTypeSwitch;
						}
					}
				}
			}
		};
        return ret;
    }
}

class ApiPart {
    @serdeOptional
    string name;
    string type;
    @serdeKeys("version") ApiVersion ver;
    Function[] api;

    void finalizeDeserialization(Asdf asdf) {
        next = asdf["next"].get(ApiPart.init);
        if (next)
            next.topLevel = false;
    }

@serdeIgnore:
    bool topLevel = true; /// is the "main" struct for an extension
    ApiPart next;

    string versionID() {
        return format!"%s_%d_%d"(type.capitalize, ver.major, ver.minor);
    }

    string versionSource() {
        string ret;
        string verList = "\talias SupportedVersions(ApiType type : ApiType." ~ type.toLower ~ ") = AliasSeq!(";
        ApiPart p = this;
        while (p) {
            ret ~= "\t__gshared bool has" ~ p.versionID ~ " = false;\n";
            ret ~= "\tversion(GDExtensionRequire" ~ p.versionID ~ ") enum bool requires" ~ p.versionID ~ " = true;\n";
            if (p.next)
                ret ~= "\telse enum bool requires" ~ p.versionID ~ " = requires" ~ p.next.versionID ~ ";\n";
            else
                ret ~= "\telse enum bool requires" ~ p.versionID ~ " = false;\n";

            verList ~= format!"[%d, %d], "(p.ver.major, p.ver.minor);

            p = p.next;
        }
        verList ~= ");\n";
        return verList ~ ret;
    }

    string versionGetterSource() {
        string ret;

        ret ~= "\tenum bool supports" ~ type.capitalize ~ "(int major, int minor) = staticIndexOf!(";
        ret ~= "[major, minor], SupportedVersions!(ApiType." ~ type.toLower ~ ")) != -1;\n";

        ApiPart p = this;
        while (p) {
            ret ~= "\tstatic if(requires" ~ p.versionID;
            ret ~= format!") enum bool has%s(int major : %d, int minor : %d) = true;\n\telse "(p.type.capitalize, p
                    .ver.major, p.ver.minor);
            ret ~= format!"@property @nogc nothrow pragma(inline, true) static bool has%s(int major : %d, int minor : %d)() {"(
                p.type.capitalize, p.ver.major, p.ver.minor);
            ret ~= " return has" ~ p.versionID ~ "; }\n";

            p = p.next;
        }
        ret ~= format!"\t@property @nogc nothrow static bool has%s(int major, int minor)()"(
            type.capitalize);
        ret ~= " if(!supports" ~ type.capitalize ~ "!(major, minor)) {\n";
        ret ~= "\t\tstatic assert(0, versionError(\"" ~ type.capitalize ~ "\", major, minor));\n\t}\n";
        return ret;
    }

    string source(string name) {
        bool core = name == "core";

        string ret;

        ret ~= "private extern(C) @nogc nothrow {\n";
        foreach (const ref f; api) {
            ret ~= "\talias da_" ~ f.name ~ " = " ~ f.return_type.escapeCType ~ " function(";
            foreach (ai, const ref a; f.arguments) {
                if (ai != 0)
                    ret ~= ", ";
                ret ~= a[0].escapeCType ~ " " ~ a[1].escapeDType;
            }
            ret ~= ");\n";
        }
        ret ~= "}\n";

        ret ~= "public extern(C) struct " ~ name.structName(ver) ~ " {\n";
        ret ~= "@nogc nothrow:\n";

        if (core && ver == ApiVersion(4, 0))
            ret ~= q{
			mixin ApiStructHeader;
			uint num_extensions;
			const godot_gdextension_api_struct **extensions;
		};
        else
            ret ~= q{
			mixin ApiStructHeader;
		};

        foreach (const ref f; api) {
            ret ~= "\tda_" ~ f.name ~ " " ~ f.name.escapeDType ~ ";\n";
        }

        if (next) {
            ret ~= "const(" ~ name.structName(
                next.ver) ~ "*) nextVersion() const { return cast(typeof(return))next; }\n";
            ret ~= "alias nextVersion this;\n";
        }

        ret ~= "}\n";

        if (topLevel) {
            ret ~= "__gshared const(" ~ name.structName(
                ver) ~ ")* " ~ name.globalVarName ~ " = null;\n";

            ret ~= "private alias apiStruct(ApiType t : ApiType." ~ type.toLower ~ ") = ";
            ret ~= name.globalVarName ~ ";\n";
        }

        ret ~= "\n";

        return ret;
    }
}

string structName(string name, ApiVersion ver) {
    return (name == "core") ? ("godot_gdextension_core_api_struct" ~
            (ver == ApiVersion(4, 0) ? "" : ver.str)) : (
        "godot_gdextension_ext_" ~ name ~ "_api_struct" ~ ver.str);
}

string globalVarName(string name, ApiVersion ver = ApiVersion(-1, -1)) {
    string ret;
    if (name == "core")
        ret = "_godot_api";
    else
        ret = "_godot_" ~ name ~ "_api";
    if (ver.major != -1)
        ret ~= ver.str;
    return ret;
}

string escapeCType(string cType) {
    import std.algorithm, std.string;

    cType = cType.chompPrefix("signed ");

    if (cType.canFind("godot_object") && cType.endsWith("*"))
        return cType[0 .. $ - 1];
    else
        return cType;
}

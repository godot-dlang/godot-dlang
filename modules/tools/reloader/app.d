import core.stdc.string;


import std.conv;
import std.getopt;
import std.stdio;
import std.utf;
import std.uni;

import vibe.d;

enum TYPE_STRING = 4;

enum ExtensionAction 
{
    load,
    unload
}

// ------------------ PROGRAM PARAMETERS

ExtensionAction action;
string extensionName;
int editorPort = 23972;

// ------------------- DECLARATIONS

// NOTE: these packets requires parsing due to array usage

// unlike sending packets receiving has different layout
struct GodotVariantPacket
{
    int unk;
    GodotPacket data;

    this(ubyte[] pdata)
    {
        unk = *cast(int*) &pdata[0];
        data = GodotPacket.fromPacket(pdata[4..$]);
    }
}

// Raw packet part according to godot "binary serialization" document
struct GodotPacket
{
    int header;
    ubyte[] bytes;

    static GodotPacket fromPacket(ubyte[] data)
    {
        GodotPacket p;
        p.header = *cast(int*) data.ptr;
        p.bytes = data[4..$];
        return p;
    }

    ubyte[] rawbytes() const {
        ubyte[] buf;
        buf.length = 8+bytes.length;
        *cast(int*)(&buf[0]) = header;
        *cast(int*)(&buf[4]) = cast(int) bytes.length;
        buf[8..$] = bytes;
        return buf;
    }

    void str(string s) 
    {
        //int base_type = TYPE_STRING & 0xFFFF;
        //int flags = base_type >> 16;
        header = TYPE_STRING;		
        int len = cast(int) s.length;
        bytes.length = 4 + len;
        memcpy(&bytes[0], &len, 4);
        bytes[4..4+len] = cast(ubyte[]) s.dup;
    }

    string str() const
    {
        if (bytes.length <= 4)
            return null;
        assert(header == TYPE_STRING); // not that simple for other types
        int len = *cast(int*)bytes.ptr;
        return cast(string) cast(char[]) bytes[4.. 4+len];
    }
}



void main(string[] args)
{
    if (!parseArgs(args))
        return;
    run();
}

/// Parses argument, returns true if app can continue or false if it should abort immediately
bool parseArgs(string[] args)
{
    auto opts = getopt(
        args,
        "action", "[load|unload] action", &action,
        "extension|e", "Target extension partial name, e.g. 'mycoolplugin'", &extensionName,
        "port|p", "Editor port override (default: 23972)", &editorPort,
    );

    if (opts.helpWanted)
    {
        defaultGetoptPrinter("Simple package that tells godot editor to load/unload native extension",
            opts.options);
        return false;
    }

    // assume we have only name remaining (arg zero is executable name)
    if (args.length > 1)
        extensionName = args[1];

    return true;
}

void run()
{
    if (auto conn = connectTCP("127.0.0.1", cast(ushort) editorPort))
    {
        Json req = Json.emptyObject;
        req["action"] = to!string(action);
        req["target"] = extensionName;

        //if (conn.waitForData(200.msecs))
        //{
        //	ubyte[128] dst;
        //	conn.read(dst, IOMode.once);
        //	
        //	auto packet = GodotVariantPacket(dst);
        //	writeln(packet.data.str);
        //}

        string json = req.toString();
        GodotPacket output;
        output.str = json;
        conn.write(output.rawbytes);

        conn.finalize();
        conn.close();
    }
}

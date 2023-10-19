// A simple tool to convert gdextension_interface.h to D
// This tool doesn't support the whole C grammar and is not a C parser by any means, 
// it expects a well-formed source code as input.
module makebind;

import std.algorithm;
import std.exception;
import std.string;
import std.array;
import std.stdio;
import std.file;
import std.ascii;
import std.range;

// any AST like node such a enum declaration, enum value, a function decl, etc...
class Node
{
    
}

// Top of the header, can have zero or more child nodes
class Root : Node
{
    Node[] child;
}

class BlockNode : Node
{
    this(Block block, Node parent) { this.blk = block; this.parent = parent;}

    Block blk;
    Node parent;
    Node[] child;
}

class Comment : Node 
{
    this(string text, bool multiline) { this.text = text; this.multiline = multiline; }

    string text;
    bool multiline;
}

// Enum decralation containing zero or more members
class EnumDecl : Node
{
    this(string name) { this.name = name; }

    string name;
    EnumMemberDecl[] members;
}

class EnumMemberDecl : Node
{
    string name;
    string value;
}

// ugh, this one has two responsibilities but ok
class Type
{
    this(string name) { this.name = name; }

    // the type itself 
    string name;
    // Function Pointer info
    bool isFunPtr;
    string fptrName; // name of a function pointer part
    string paramName; // name of a parameter
    Type[] params;
    Type ret;
}

// plain typedef for a type
class TypeAliasDecl : Node
{
    this(string name, Type type) { this.name = name; this.targetType = type; }

    Type targetType;
    string name;
}

class StructDecl : Node
{
    this(string name) { this.name = name; }

    string name;
    StructMemberDecl[] members;
}

class StructMemberDecl : Node
{
    string name;
    Type type;
}

// Only most important tokens or constructs, since header doesn't have any expressions or templates
// we don't have to parse whole language.
enum TokType
{
    lparen, rparen,      // ( )
    lbracket, rbracket,  // [ ]
    lbrace, rbrace,      // { }

    newline,             // \n or \r\n
    whitespace,
    comma,               // ,
    semicolon,           // ;
    identifier,          // C identifier (can be invalid in D)
    text,                // quoted string
    comment,             // single-line or multiline comment

    typedef_,            // type alias
    enum_,               // typedef enum
    struct_,             // typedef struct
    block,               // nested code block such as code inside braces { } 
}

// primitive pseudo parser that operates on raw text
// 1) it counts number of opening and closing braces { } and builds nested structure
// 2) it then reads where is "typedef" is encountered
// 3) typedefs are branched to match enum vs struct vs type declarations
// 4) these decls is then translated to a D code
class Parser
{
    Root root;
    string _source;
    size_t _offset;

    // other tokens buffer, for example when reading multipart stuff like `const void *`
    char[] buf; 

    

    void parse(string source)
    {
        _offset = 0;
        _source = source;
        root = new Root();
        parseDecls();

        //writeln(root.child.filter!(s => cast(Comment)s is null));

        //foreach (c; root.child)
        //if (auto com = cast(Comment) c)
        //    writeln(com.text);
        //    writeln(c);

        //foreach (c; root.child)
        //if (auto e = cast(EnumDecl) c)
        //{
        //    writeln(e.name);
        //    e.child.each!(s => writeln(s.name ~ " " ~ s.value));
        //}

        //foreach (c; root.child)
        //if (auto s = cast(StructDecl) c)
        //{
        //    writeln(s.name);
        //    s.child.each!(m => writeln("    " ~ m.name ~ " : " ~ m.type));
        //}

        //foreach (c; root.child)
        //if (auto d = cast(TypeAliasDecl) c)
        //{
        //    writeln("typedef " ~ d.name ~ " = " ~ d.targetType.name);
        //}

    }

    void parseDecls()
    {
    Lnext:
        if (_offset >= _source.length)
            return;

        if (_offset > 2626)
            int x = 0;

        if (_source[_offset] == '/' && (next=='*' || next=='/'))
            readComment();
        else if (_source[_offset] == '{') 
            readBlock();
        else if (startsWith(_source[_offset..$], "typedef") && isWhite(_source[_offset+"typedef".length]))
            readTypedef();
        else if (_source[_offset] == '(')
            readParens();
        else if (startsWith(_source[_offset..$], `extern "C"`)) // this is just to skip this block that spans over whole file
        {
            auto pos = indexOf(_source, '{', _offset);
            _offset = pos;
            readBlock();
            BlockNode externc = cast(BlockNode) root.child[$-1];
            _offset = externc.blk.start + 1;
            parseDecls();
            _offset = externc.blk.end + 1;
        }
        else 
        {
            if (!buf.length && isLineBreak(_source[_offset]))
            {
                // no-op, skip lots of empty lines
            }
            else
            {
                // keep reading into a buf until next special symbol is encountered
                buf ~= _source[_offset];
            }
            _offset++;
        }

        goto Lnext;
    }

    dchar next(size_t inc = 1) const
    {
        return _source[_offset+inc];
    }

    private void readComment()
    {
        dchar next = _source[_offset+1];
        size_t end = _source.length; // assume EOF if read fails
        bool multiline = false;
        if (next == '/')
        {
            multiline = false;
            auto lineEnd = countUntil!isLineBreak(_source[_offset..$]);
            if (lineEnd != -1)
                end = _offset+lineEnd+1;
        }
        else if (next == '*')
        {
            multiline = true;
            auto cend = _source.indexOf("*/", _offset);
            if (cend != -1)
                end = cend+2; // indexOf returns start position
        }
        else
            return;
        auto content = _source[_offset..end];
        //if (end < _source.length)
        //    writefln("pos: %d:%d next: %d :: %s", _offset, end, end+1, _source[end+1..end+5]);
        root.child ~= new Comment(content, multiline);
        _offset = end; // next symbol after comment break
    }
    
    private void readBlock()
    {
        auto block = readNextBlock(_source, _offset);
        _offset = block.end + 1;
        root.child ~= new BlockNode(block, root);
    }

    private void readParens()
    {
        auto block = readNextBlock!('(', ')')(_source, _offset);
        _offset = block.end + 1;
    }

    private void readTypedef()
    {
        // we already know this is correct `typedef ` string
        _offset += "typedef ".length;

        if (_source[_offset..$].startsWith("enum"))
        {
            _offset += "enum".length;
            readEnum();
        }
        else if (_source[_offset..$].startsWith("struct"))
        {
            _offset += "struct".length;
            readStruct();
        }
        else 
        {
            // it's a type then, we are doomed...
            // technically typedef can have multiple aliases to the same type listed after comma, 
            // moreover it allows slap pointer to them too, eww
            // we don't do that here though
            size_t next;
            size_t end = _source.indexOf(';', _offset);
            auto ltype = parseType(_source[_offset..end], next);
            if (!ltype.isFunPtr)
            {
                auto rtype = parseType(_source[_offset+next..end], next);
                root.child ~= new TypeAliasDecl(rtype.name, ltype);
            }
            else
                root.child ~= new TypeAliasDecl(ltype.fptrName, ltype); // well, that's crazy
            _offset = end;
        }
    }

    private void readEnum()
    {
        // note that enum can have comments inside but we don't care if they are shifted
        auto begin = indexOf(_source, '{', _offset);
        auto end = indexOf(_source, '}', begin);
        auto semicolon = indexOf(_source, ';', end);
        auto name = _source[end+1..semicolon].strip();
        auto members = split(_source[begin+1..end], ',');
        auto enumDecl = new EnumDecl(name);
        foreach (i, m; members)
        {
            auto member = new EnumMemberDecl();
            auto valueIdx = m.indexOf('=');
            if (valueIdx != -1)
            {
                member.name = m[0..valueIdx].strip();
                member.value = m[valueIdx+1..$].strip();
            }
            else
            {
                member.name = m.strip();
            }
            enumDecl.members ~= member;
        }
        root.child ~= enumDecl;
        _offset = semicolon + 1;
    }

    private void readStruct()
    {
        const s = _source;
        // due to possible nesting it is probably safer to use readBlock here but ok
        auto begin = indexOf(_source, '{', _offset);
        auto end = indexOf(_source, '}', begin);
        auto semicolon = indexOf(_source, ';', end);
        auto name = s[end+1..semicolon].strip();
        auto members = split(s[begin+1..end].ignoreComments, ';').filter!(s => !s.all!isWhite);
        auto structDecl = new StructDecl(name);
        foreach (m; members)
        {
            auto member = new StructMemberDecl();
            auto trimmed = m.strip;
            size_t next;
            auto ty = parseType(trimmed, next);
            member.type = ty;
            if (ty.isFunPtr)
                member.name = ty.fptrName;
            else
                member.name = trimmed[next..$].strip();
            structDecl.members ~= member;
        }
        root.child ~= structDecl;
        _offset = semicolon + 1;
    }

    // tries to build a type from a string or null on failure.
    // string is assumed to be clear of comments, 
    // no identifier validation is done, i.e. it will hapily return 1int as a type
    private Type parseType(string s, out size_t outpos)
    {
        char[] parts;
        size_t pos;
        int funNamePartPos = -1;
        string fptrName;
        char lastChar;
        bool isSep;
        bool isFunName;
        bool isConst; // FIXME: unused
        bool isReadingParams;
        int level; // current level of parenthesis
        Type[] args;
    Louter:
        while (pos < s.length)
        {
            if (s[pos] == ';')
                break;
            if (s[pos..$].startsWith("const "))
            {
                //isConst = true;
                pos += 6;
                parts ~= "const ";
                lastChar = ' ';
                isConst = true;
                isSep = true;
                continue;
            }
            if (s[pos].isWhite || s[pos].isLineBreak)
            {
                isSep = true;
                lastChar = s[pos];
                pos++;
                //parts ~= ' ';
                continue;
            }
            if (lastChar == '(' && s[pos] == '*')
            {
                if (parts.length && pos+2 <= s.length)
                {
                    isFunName = true;
                    funNamePartPos = cast(int) pos-1;
                }
            }
            // when encountered white space can only look for pointers
            // but also there is special case for function pointer name part
            if (isSep && !isConst) 
            {
                size_t succ;

                // check fptr name first
                auto lparen = s.indexOf('(', pos);
                if (lparen != -1 && lparen+1 < s.length && s[lparen+1] == '*')
                {
                    isSep = false;
                    goto Lout;
                }

                for (auto i = pos; i < s.length; i++)
                {
                    if ((s[i].isWhite || s[i].isLineBreak) && !parts[$-1].isWhite)
                        continue;
                    else if (s[i] == '*') 
                    {
                        succ = i;
                        // parsing has reached end of string and will now jump to exit
                        // this last '*' will be picked up at the end of this function
                        // otherwise it will emit extra '*' for example in fptr parameters
                        if (i == s.length-1)
                            break Louter;
                        else
                            parts ~= '*';
                    }
                    else 
                    {
                        if (succ)
                            pos = succ+1; // move to next symbol
                        break Louter;
                    }
                }
                Lout:
            }
            if (s[pos] == '(')
                level++;
            else if (s[pos] == ')')
            {   
                level--;
                parts ~= ')';
                pos++;
                if (pos >= s.length)
                    break;
                if (level < 1 && (!isFunName || isReadingParams))
                {
                    // assume we are done
                    break;
                }
                else
                {
                    if (level < 1 && isFunName)
                    {
                        fptrName = s[funNamePartPos+2..pos-1]; // e.g. (*someFunctionPtr) without ptr and parens
                    }
                    isReadingParams = true;
                }
            }

            if (s[pos] == ',' && !isReadingParams)
            {
                break;
            }
            if (isReadingParams)
            {
                parts ~= '(';
                level++;
                scope(exit) level--;
                pos++;

                // messed up declaration
                if (s.canFind("GDExtensionInterfaceWorkerThreadPoolAddNativeGroupTask"))
                    int x = 0;

                // list of comma breaks
                size_t[] commas = getCommaPositions(s[pos..$]);
                foreach(ref c; commas)
                    c += pos;
                //if (commas.empty && pos < s.length) // just add one stop for that case...
                {
                    commas ~= s.length-1;
                }
                size_t skip;
                for (auto nextcomma = 0; nextcomma < commas.length; nextcomma++)
                {
                    auto paramStr = s[pos..commas[nextcomma]];
                    // clean up a bit... because this algorithm is stupid
                    while(paramStr.length)
                    {
                        if (paramStr[0] == ',' || paramStr[0].isWhite) 
                        {
                            paramStr = paramStr[1..$];
                            pos++;
                        }
                        else break;
                    }

                    auto ty = parseType(paramStr, skip);
                    string pname;
                    // read the remaining part as parameter name
                    if (skip < paramStr.length)
                    {
                        pname = paramStr[skip..$];
                    }
                    ty.paramName = pname;
                    args ~= ty;
                    pos += paramStr.length;
                }
                // yeah, that 'if s[pos] == )' got it first...
                //parts ~= ')';

            }

            if (pos >= s.length)
            {
                pos = s.length;
                break;
            }

            lastChar = s[pos];
            parts ~= s[pos];
            pos++;
            isSep = false;
            isConst = false;
        }
        // advance offset position and build type representation
        outpos = pos;
        auto ty = new Type(cast(string)parts);
        if (isFunName)
        {
            ty.isFunPtr = isFunName;
            ty.fptrName = fptrName;
            ty.ret = new Type(s[0..funNamePartPos].strip());
            ty.params = args;
        }
        return ty;
    }

    private Block readNextBlock(dchar B = '{', dchar E = '}')(in string source, size_t offset)
    {
        int level = 0;
        int it = cast(int) offset;
        int start = cast(int) offset;
        for(; it < source.length; it++)
        {
            if (source[it] == B)
                level++;
            if (source[it] == E)
            {
                if (level-1 == 0) {
                    break;
                }
                level--;
            }
        }
        return Block(start, it, source);
    }

    // list of comma positions on zero parentehisis level
    private size_t[] getCommaPositions(string s)
    {
        int level;
        size_t[] commas;
        for(auto i = 0; i < s.length; i++)
        {
            if (s[i] == '(')
                level++;
            else if (s[i] == ')')
                level--;
            else if (s[i] == ',' && level == 0)
                commas ~= i;
        }
        return commas;
    }
}


// takes an input string and clear all comments
string ignoreComments(in string source)
{
    char[] buf;
    size_t pos;
    char lastChar;
    bool isSlash;
    bool isInsideComment;
    bool isMultiline;
    while (pos < source.length)
    {
        lastChar = source[pos];
        if (isSlash && (source[pos] == '/' || source[pos] == '*'))
        {
            isMultiline = source[pos] == '*';
            isInsideComment = true;
            isSlash = false;
        }
        if (!isInsideComment && source[pos] == '/') {
            isSlash = true;
            pos++;
            continue;
        }
        if (isInsideComment && !isMultiline && source[pos].isLineBreak)
        {
            isInsideComment = false;
            isMultiline = false;
            isSlash = false;
            pos++;
            continue;
        }
        if (isInsideComment && pos>0 && source[pos] == '/' && source[pos-1] == '*')
        {
            isInsideComment = false;
            isMultiline = false;
            isSlash = false;
            pos++;
            continue;
        }
        if (!isInsideComment)
            buf ~= lastChar;
        pos++;
    }
    return cast(string) buf;
}

size_t getLineNumber(string source, size_t loc)
{
    size_t count;
    for (int i = 0; i < loc; i++)
    {
        if (isLineBreak(source[i]))
        {
            count += 1;
        }
    }
    return count;
}

bool isLineBreak(dchar d) { return d == '\n' || d == '\r'; }

// range in the parent scope and the inner source text
struct Block
{
    // symbol offsets, i.e. character in array
    int start = -1; 
    int end = -1;
    string source;

    @property bool isValid() { return start != -1 && source; }

    // check if two blocks overlaps and not nested
    @property bool isOverlaps(Block other) 
    { 
        Block a = this;
        Block b = other;
        if (start > other.start)
        {
            a = other;
            b = this;
        }
        bool isTouching = a.start < b.start && b.start < a.end;
        if (isTouching)
        {
            return a.end < b.end; // a overlaps with b and b is not nested
        }
        return true;
    }
}


// fake preprocessor, simply discards any preprocessor directive on that line
// in case of godot it is possible to just discard the preprocessor work
string preprocess(string source) 
{
    size_t offset = 0;
Lnext:
    if (source[offset] == '#')
    {
        if (source.canMatch(offset, "#define") 
            || source.canMatch(offset, "#ifndef")
            || source.canMatch(offset, "#ifdef")
            || source.canMatch(offset, "#endif")
            || source.canMatch(offset, "#include"))
        {
            auto found = source[offset..$].countUntil("\r\n", "\n", "\r");
            if (found != -1)
            {
                source = source[0..offset] ~ source[offset+found..$];
            }
        }
    }

    offset++;
    if (source.length > offset)
        goto Lnext;
    return source;
}

bool canMatch(string str, size_t offset, string what)
{
    return str[offset..$].startsWith(what);
}

void writeBindings(Root header, string outFile)
{
    auto file = File(outFile, "w");
    scope(exit) 
        file.close();

    file.writeln("module godot.abi.gdextension_binding;");
    file.writeln();
    file.writeln("import godot.abi.types;");
    file.writeln("import core.stdc.config;");
    file.writeln("public import core.stdc.stddef : wchar_t;");
    file.writeln();
    file.writeln("extern (C):");
    file.writeln();

    foreach(decl; header.child)
    {
        auto s = print(decl);
        file.writeln(s);
    }
}

// Formats the node declaration as a D code
string print(Node n)
{
    if (auto c = cast(Comment) n)
        return print(cast(Comment) c);
    if (auto td = cast(TypeAliasDecl) n)
        return print(cast(TypeAliasDecl) td);
    if (auto st = cast(StructDecl) n)
        return print(cast(StructDecl) st);
    if (auto e = cast(EnumDecl) n)
        return print(cast(EnumDecl) e);
    return null;
}

string print(Comment c)
{
    return c.text;
}

string print(EnumDecl decl)
{
    string buf;
    buf ~= "alias " ~ decl.name ~ " = int;\n";
    buf ~= "enum : " ~ decl.name ~ "\n{\n";
    foreach(i, m; decl.members)
    {
        buf ~= "    " ~ m.name;
        if (m.value)
            buf ~= " = " ~ m.value;
        if (i+1 < decl.members.length)
            buf ~= ",\n";
    }
    buf ~= "\n}\n";
    return buf;
}

string print(StructDecl decl)
{
    string buf;
    buf ~= "struct " ~ decl.name ~ "\n{\n";
    foreach (m; decl.members)
    {
        buf ~= "    " ~ print(m.type) ~ " " ~ m.name;
        buf ~= ";\n";
    }
    buf ~= "}\n";
    return buf;
}

string print(TypeAliasDecl decl)
{
    string buf;
    buf ~= "alias " ~ decl.name ~ " = ";
    buf ~= print(decl.targetType);
    buf ~= ";\n";
    return buf;
}

string print(Type type)
{
    string buf;
    if (!type.isFunPtr)
    {
        auto constPosition = type.name.indexOf("const ");
        if (constPosition != -1)
        {
            auto tmp = type.name.dup;
            tmp["const".length] = '(';

            auto nextPtrPart = tmp.indexOf('*', constPosition);
            auto nextWsPart = tmp.indexOf(' ', constPosition+"const ".length+1);
            size_t stop;
            if (nextPtrPart != -1 && nextWsPart != -1)
            {
                stop = min(nextPtrPart, nextWsPart);
            }
            else
                stop = max(nextPtrPart, nextWsPart);
            if (stop != -1)
            {
                tmp.insertInPlace(stop, ')');
                //tmp[stop] = ')';
            }
            else
                tmp ~= ')';
            buf ~= tmp.strip();
        }
        else
            buf ~= type.name.strip();
    }
    else
    {
        buf ~= print(type.ret) ~ " function(";
        foreach(i, p; type.params)
        {
            if (p.isFunPtr)
                buf ~= print(p);
            else
            {
                buf ~= print(p);
                if (p.paramName)
                    buf ~= " " ~ p.paramName.strip();
            }
            if (i+1 < type.params.length)
                buf ~= ", ";
        }
        buf ~= ")";
    }
    return buf;
}


void main(string[] args)
{
    enforce(args.length > 2, format("2 arguments expected: inpath, outpath - %d given", args.length-1));

    auto inFilePath = args[1];
    auto outFilePath = args[2];

    auto headerText = readText(inFilePath);
    auto header = preprocess(headerText);

    auto parser = new Parser();
    parser.parse(header);

    writeBindings(parser.root, outFilePath);
    writeln("Writing file '" ~ outFilePath ~ "' done.");
}
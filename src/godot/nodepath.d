/**
Pre-parsed scene tree path.

Copyright:
Copyright (c) 2007 Juan Linietsky, Ariel Manzur.
Copyright (c) 2014 Godot Engine contributors (cf. AUTHORS.md)
Copyright (c) 2017 Godot-D contributors
Copyright (c) 2022 Godot-DLang contributors

License: $(LINK2 https://opensource.org/licenses/MIT, MIT License)


*/
module godot.nodepath;

import core.lifetime : emplace;

import godot.string;
import godot.stringname;
import godot.abi;
import godot.builtins;

/**
A pre-parsed relative or absolute path in a scene tree, for use with $(D Node.getNode) and similar functions. It can reference a node, a resource within a node, or a property of a node or resource. For instance, `"Path2D/PathFollow2D/Sprite:texture:size"` would refer to the size property of the texture resource on the node named “Sprite” which is a child of the other named nodes in the path. Note that if you want to get a resource, you must end the path with a colon, otherwise the last element will be used as a property name.

Exporting a `NodePath` variable will give you a node selection widget in the properties panel of the editor, which can often be useful.

A `NodePath` is made up of a list of node names, a list of “subnode” (resource) names, and the name of a property in the final node or resource.
*/
struct NodePath {
    //@nogc nothrow:

    package(godot) union nodepath {
        godot_node_path _node_path;
        NodePath_Bind _bind;
    }

    package(godot) nodepath _nodepath;
    alias _nodepath this;

    this(ref const NodePath other) {
        _node_path = _bind.new1(other._node_path);
    }

    package(godot) this(godot_node_path n) {
        _node_path = n;
    }

    this(in String from) {
        _node_path = _bind.new2(from);
    }

    this(in string name) {
        String from = String(name);
        this(from);
    }

    bool opEquals(in NodePath other) const {
        if (_node_path == other._node_path)
            return true;
        //return gdextension_interface_node_path_operator_equal(&_node_path, &other._node_path);
        return _bind == other._bind;
    }

    StringName getName(in int idx) const {
        return _bind.getName(idx);
        //godot_string str = gdextension_interface_node_path_get_name(&_node_path, idx);
        //return String(str);
    }

    int getNameCount() const {
        //return gdextension_interface_node_path_get_name_count(&_node_path);
        return cast(int) _bind.getNameCount();
    }

    StringName getSubname(in int idx) const {
        return _bind.getSubname(idx);
        //godot_string str = gdextension_interface_node_path_get_subname(&_node_path, idx);
        //return String(str);
    }

    int getSubnameCount() const {
        return cast(int) _bind.getSubnameCount();
        //return gdextension_interface_node_path_get_subname_count(&_node_path);
    }

    bool isAbsolute() const {
        return _bind.isAbsolute();
        //return cast(bool)gdextension_interface_node_path_is_absolute(&_node_path);
    }

    bool isEmpty() const {
        return _bind.isEmpty();
        //return cast(bool)gdextension_interface_node_path_is_empty(&_node_path);
    }

    String str() const {
        return String(this);
    }

    /// Splits a NodePath into a main node path and a property subpath (starting
    /// with a ':'). The second element is left empty if there is no property.
    NodePath[2] split() const {
        static immutable wchar_t colon = ':';
        NodePath[2] ret;
        if (_node_path == godot_node_path.init)
            return ret;
        String path = str();
        immutable(wchar_t)[] data = path.data();
        if (data.length == 0)
            return ret;
        if (data[0] == colon) {
            ret[1] = cast() this;
            return ret;
        }

        ptrdiff_t colonIndex = 0;
        // Windows requires UTF-16 decoding to find the ':'
        static if (is(wchar_t == wchar)) {
            import utf_bc;

            enum TextFormat gdFormat = TextFormat.UTF_16;
            auto decoded = data.decode!gdFormat;
            do {
                dchar front = decoded.front;
                decoded.popFront();
                if (front == colon)
                    break;
                colonIndex += codeLength!gdFormat(front);
            }
            while (!decoded.empty);
            if (decoded.empty)
                colonIndex = -1;
        } else {
            import std.algorithm : countUntil;

            colonIndex = data[].countUntil(colon);
        }

        // node only
        if (colonIndex == -1) {
            ret[0] = cast() this;
            return ret;
        }
        ret[0] = NodePath(String(data[0 .. colonIndex]));
        ret[1] = NodePath(String(data[colonIndex .. $]));
        return ret;
    }

    //this(ref return scope const NodePath other) // copy ctor
    NodePath opAssign(ref const NodePath other) {
        if (_node_path._opaque.ptr)
            _bind._destructor();
        
        _node_path = _bind.new1(other._node_path);
        return this;
    }

    NodePath opAssign(in NodePath other) {
        if (_node_path._opaque.ptr)
            _bind._destructor();
        
        _node_path = _bind.new1(other._node_path);
        return this;
    }

    ~this() {
        if (_node_path._opaque.ptr)
        	_bind._destructor();
        _node_path = _node_path.init;
    }
}

/**
Handle for a $(D Resource)‘s unique ID.

Copyright:
Copyright (c) 2007 Juan Linietsky, Ariel Manzur.
Copyright (c) 2014 Godot Engine contributors (cf. AUTHORS.md)
Copyright (c) 2017 Godot-D contributors
Copyright (c) 2022 Godot-DLang contributors

License: $(LINK2 https://opensource.org/licenses/MIT, MIT License)


*/
module godot.rid;

import godot.abi;
import godot.object;
import godot.resource;
import godot.builtins;

/**
The RID type is used to access the unique integer ID of a resource. They are opaque, so they do not grant access to the associated resource by themselves. They are used by and with the low-level Server classes such as $(D VisualServer).
*/
struct RID {
    //@nogc nothrow:

    package(godot) union _RID {
        godot_rid _godot_rid;
        RID_Bind _bind;
    }

    package(godot) _RID _rid;
    alias _rid this;

    /// Get the RID of a Resource
    @disable this(scope Resource resource) {
        // wtf this means?
        //gdextension_interface_rid_new_with_resource(&_godot_rid, cast(const godot_object)(cast(void*)resource));
    }

    int getId() const {
        return cast(int) _bind.getId();
        //return gdextension_interface_rid_get_id(&_godot_rid);
    }

    ///
    bool isValid() const {
        return *cast(void**)&_godot_rid !is null;
    }

    alias opCast(T : bool) = isValid;
}

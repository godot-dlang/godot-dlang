/++
Attributes for specifying how Godot-D should register the marked classes,
properties, methods, and signals into Godot.
+/
module godot.api.udas;

import godot, godot.abi;
import godot.api.traits;

import std.meta, std.traits;


/++
A UDA to enable a script class to run in the Godot editor even without the game
running. Required for $(D EditorPlugin)s and other tools used in the editor.
+/
deprecated("Tool scripts is default behavior in Godot 4 extensions, if you want to opt-out use RuntimeOnly attribute instead.") 
enum Tool;

/++
A UDA to opt-out script class from being run in the Godot editor, the script will only run code while the game is
running. This is the opposite of Tool attribute.

Requires Godot 4.3 or newer.
+/
enum RuntimeOnly;

/// 
enum RPCMode {
    disabled,
    remote,
    sync,
    master,
    slave,
}

/++
A UDA to change the Godot name of a method, property, or signal. Useful for
overloads, which D supports but Godot does not.
+/
struct Rename {
    string name;
}

/++
A UDA to mark a method that should be registered into Godot
+/
struct Method {
    RPCMode rpcMode = RPCMode.disabled;
}

/++
A UDA to mark a method that should be virtual. 
Works in conjunction with @Method attribute.
Virtual methods allows subclasses to override it to implement custom logic, either via GodotScript or other extensions.
It is required to disambiguate if this is a desired behavior because in D every method is virtual unless marked with 'final' keyword.
+/
enum Virtual;

/++
A UDA to mark a signal. The signal should be a static function/delegate
variable that defines the signal's arguments.
+/
struct Signal {
}

/++

+/
struct OnReady(alias arg) {

}

// TODO: rename to @Export
// FIXME: doens't show in editor
/++
A UDA to mark a public variable OR accessor methods as a property in Godot.

Using just the type as a UDA uses default configuration. The UDA can also be
constructed at compile-time to customize how the property should be registered
into Godot.
+/
struct Property {
    /// 
    enum Hint {
        none, /// no hint provided.
        range, /// hintText = "min,max,step,slider; //slider is optional"
        expRange, /// hintText = "min,max,step", exponential edit
        enumType, /// hintText= "val1,val2,val3,etc"
        expEasing, /// exponential easing funciton (math::ease)
        length, /// hintText= "length" (as integer)
        spriteFrame,
        keyAccel, /// hintText= "length" (as integer)
        flags, /// hintText= "flag1,flag2,etc" (as bit flags)
        layers2DRender,
        layers2DPhysics,
        layers3DRender,
        layers3DPhysics,
        file, /// a file path must be passed, hintText (optionally) is a filter "*.png,*.wav,*.doc,"
        dir, /// a directort path must be passed
        globalFile, /// a file path must be passed, hintText (optionally) is a filter "*.png,*.wav,*.doc,"
        globalDir, /// a directort path must be passed
        resourceType, /// a resource object type
        multilineText, /// used for string properties that can contain multiple lines
        colorNoAlpha, /// used for ignoring alpha component when editing a color
        imageCompressLossy,
        imageCompressLossless,
        objectId,
        typeString, /// a type string, the hint is the base type to choose
        nodePathToEditedNode, /// so something else can provide this (used in scripts)
        methodOfVariantType, /// a method of a type
        methodOfBaseType, /// a method of a base type
        methodOfInstance, /// a method of an instance
        methodOfScript, /// a method of a script & base
        propertyOfVariantType, /// a property of a type
        propertyOfBaseType, /// a property of a base type
        propertyOfInstance, /// a property of an instance
        propertyOfScript, /// a property of a script & base
    }

    /// 
    enum Usage {
        storage = 1,
        editor = 2,
        network = 4,
        editorHelper = 8,
        checkable = 16, /// used for editing global variables
        checked = 32, /// used for editing global variables
        internationalized = 64, /// hint for internationalized strings
        group = 128, /// used for grouping props in the editor
        category = 256,
        storeIfNonZero = 512, /// only store if nonzero
        storeIfNonOne = 1024, /// only store if false
        noInstanceState = 2048,
        restartIfChanged = 4096,
        scriptVariable = 8192,
        storeIfNull = 16384,
        animateAsTrigger = 32768,
        updateAllIfModified = 65536,

        defaultUsage = storage | editor | network, /// storage | editor | network
        defaultIntl = storage | editor | network | internationalized, /// storage | editor | network | internationalized
        noEditor = storage | network, /// storage | network
    }

    Hint hint = Hint.none; /// 
    string hintString = null; /// 
    Usage usage = Usage.defaultUsage; /// 
    RPCMode rpcMode = RPCMode.disabled; /// 

    /// 
    this(Hint hint, string hintString = null, Usage usage = Usage.defaultUsage,
        RPCMode rpcMode = RPCMode.disabled) {
        this.hint = hint;
        this.hintString = hintString;
        this.usage = usage;
        this.rpcMode = rpcMode;
    }

    /// 
    this(Usage usage, Hint hint = Hint.none, string hintString = null,
        RPCMode rpcMode = RPCMode.disabled) {
        this.hint = hint;
        this.hintString = hintString;
        this.usage = usage;
        this.rpcMode = rpcMode;
    }
}

/++
A UDA to mark a enum or static members to be used by Godot as a constant.
+/
struct Constant {

}

/++
A UDA to mark a enum to be registered with Godot.
+/
struct Enum {

}

/++
A UDA for explicitly specifying the default value of a Property.

This UDA works with getter/setter functions. It should be attached to only one
of the two functions.

The normal D default value will still be used if no `@DefaultValue` UDA is
attached.

Example:
---
class S : GodotScript!Node
{
	// UDA is needed to give getter/setter functions a default value
	@Property @DefaultValue!5
	int number() const
	{
		// ...
	}
	void number(int val)
	{
		// ...
	}
	
	// plain variable; no UDA is needed
	@Property int simpler = 6;
}
---
+/
struct DefaultValue(Expression...) {
}

/++
A UDA for marking script variables that should be automatically created when
the script is created, right before _init() is called.

Options for automatically deleting or adding as child node the tagged variable
can be set in the UDA.
+/
struct OnInit {
    bool autoCreate = true; /// create it when the script is created
    bool autoDelete = true; /// delete it when the script is destroyed
    bool autoAddChild = true; /// add it as a child (only for Node types)

    private import godot.node;

    package(godot) enum bool canAddChild(R, Owner) = extends!(GodotClass!R, Node)
        && extends!(GodotClass!Owner, Node);

    static OnInit makeDefault(R, Owner)() {
        import godot.refcounted, godot.node, godot.resource;

        OnInit ret;
        static if (is(GodotClass!R : RefCounted))
            ret.autoDelete = false; // ref-counted
        static if (canAddChild!(R, Owner)) {
            ret.autoAddChild = true;
            ret.autoDelete = false; // owned by parent node
        }
        return ret;
    }
}

/++
A UDA to mark a static field to be used by Godot as a global singleton object.
+/
struct Singleton {

}

/++ 
Advanced attribute that tells godot-dlang memory allocation funtions to not register it to D garbage collector.

This attribute is applied on classes directly, 
there is no granular per object control, 
every instance of class will be affected.

Note that GodotScript objects are not allocated by GC and 
uses GC.addRange mechanism to tell GC to scan memory for pointers inside that object.
This attribute has effect that any pointer to a GC allocated memory will essentially be a weak reference,
and will no longer prevent garbage collection despite that there might still be live references in it.
Simply put, marked objects may have its GC managed data collected when you don't expect it.
Examples of such pointers is a regular D strings, arrays, or other objects allocated using 'new' keyword.

This is a D specific feature.
Use sparingly if you are very memory limited and the object doesn't have pointers to GC memory.

Example:
---
// Every instance of HealthComponent is now assumed to not contain GC allocated memory
@GCSkipScan
class HealthComponent : GodotScript!Node
{
	@Property int health = 10;
    
    // ... health component implementation ...
}
---
+/
struct GCSkipScan {

}
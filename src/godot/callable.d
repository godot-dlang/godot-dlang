module godot.callable;

import std.meta;

import godot.abi;
import godot.variant;
import godot.object;
import godot.array;
import godot.stringname;
import godot.builtins;

/// Untyped Callable that binds directly to Godot's Callable
struct GodotCallable {
    package(godot) union callable {
        godot_callable _godot_callable;
        GodotCallable_Bind _bind;
    }

    package(godot) callable _callable;
    alias _callable this;

    package(godot) this(godot_callable opaque) {
        _godot_callable = opaque;
    }

    this(ref scope const GodotCallable other) {
        _godot_callable = _bind.new1(other._godot_callable);
    }


    this(in GodotObject object, in StringName method) {
        _godot_callable = _bind.new2(object, method);
    }

    this(in GodotObject object, in string method) {
        StringName snMethod = method;
        _godot_callable = _bind.new2(object, snMethod);
    }

    void _defaultCtor() {
        _godot_callable = _bind.new0();
    }

    ~this() {
        _bind._destructor();
    }

    Variant callv(in Array arguments) const {
        return _bind.callv(arguments);
    }

    Variant call(Args...)(Args args) const {
        return _bind.call(args);
    }

    void callDeferred(Args...)(Args args) const {
        return _bind.callDeferred(args);
    }

    void rpc(Args...)(Args args) const {
        return _bind.rpc(args);
    }

    void rpcId(Args...)(long peerId, Args args) const {
        return _bind.rpcId(peerId, args);
    }

    bool isNull() const {
        return _bind.isNull();
    }

    bool isCustom() const {
        return _bind.isCustom();
    }

    bool isStandard() const {
        return _bind.isStandard();
    }

    bool isValid() const {
        return _bind.isValid();
    }

    GodotObject getObject() const {
        return _bind.getObject();
    }

    ObjectID getObjectId() const {
        return ObjectID(_bind.getObjectId());
    }

    StringName getMethod() const {
        return _bind.getMethod();
    }

    long getBoundArgumentsCount() const {
        return _bind.getBoundArgumentsCount();
    }

    Array getBoundArguments() const {
        return _bind.getBoundArguments();
    }

    long hash() const {
        return _bind.hash();
    }

    GodotCallable bindv(in Array arguments) {
        return _bind.bindv(arguments);
    }

    GodotCallable unbind(in long argcount) const {
        return _bind.unbind(argcount);
    }

    GodotCallable bind(Args...)(Args args) const {
        return _bind.bind(args);
    }
}


/// Type-safe Callable wrapper around Godot's Callable
/// This is mainly used to document your intents in code rather than strictly prohibit from doing wrong things with it.
/// All of its type magic will disappear as soon as you use .untyped() getter in order to get plain GodotCallable from it.
struct GodotCallableT(Return, Args...) {
    GodotCallable _impl;

    alias getInternalCallable this; // allow other const methods without explicit implementation

    /// Although you can construct a callable directly from regular one consider to use `makeCallable` instead as it offers more convenience and checks.
    this(GodotCallable callable) {
        _impl = callable;
    }

    package(godot) this(godot_callable opaque) {
        _impl = GodotCallable(opaque);
    }

    const(GodotCallable) getInternalCallable() const { return _impl; }

    /// Getter for internal callable, i.e. to pass it to other godot methods
    GodotCallable untyped() { return _impl; }

    // TODO: make sure it respects type
    private ref typeof(this) opAssign(GodotCallable value) {
        _impl = value;
        return this;
    }

    Return call(Args args) {
        static if (is(Return == void))
            _impl.call(args);
        else
            return _impl.call(args);
    }

    void callDeferred(Args args) const {
        _impl.callDeferred(args);
    }

    void rpc(Args args) const {
        _impl.rpc(args);
    }

    void rpcId(long peerId, Args args) const {
        _impl.rpcId(peerId, args);
    }

    /// Creates a new callable with numArgs more arguments
    /// example:
    /// Start with a callable that takes (int, float)
    ///   auto cb = GodotCallableT!(int, int, float)();
    /// Unbind 2 arguments (appends Variant, Variant)
    ///   auto unbound = cb.unbindT!2();
    /// Verify that the new callable is a callable with 4 arguments
    ///   static assert(unbound is GodotCallableT!(int, int, float, Variant, Variant));
    GodotCallableT!(Return, AliasSeq!(Args, Repeat!(numArgs, Variant))) unbindT(size_t numArgs)() const {
        return typeof(return)(_impl.unbind(numArgs));
    }

    /// Binds arguments T appending them to the rightmost T.length positional arguments of the original callable, 
    /// returning new callable taking T.length less arguments
    GodotCallableT!(Return, Args[0..$-T.length]) bindT(T...)(T t) const {
        import std.conv;
        // tbh this hides proper error message and I'd prefer to see real error showing user type mismatch error rather than useless 'no you can't call function taking 2 arguments with 42 more of them'
        static assert(Args.length > 0 && T.length <= Args.length, 
            "Cannot bind " ~ text(T.length) ~ " arguments to a functinon taking " ~ text(Args.length) ~ " arguments.");

        alias p = AliasSeq!(Args[$-T.length..$], T); // just a pack of types in same order from both source and bind target
        // debug print types
        //static foreach(i; 0..T.length) {
        //    pragma(msg, p[i].stringof ~ "> and <" ~ p[i+T.length].stringof);
        //}
        // check types and force compiler to emit authentic type error message
        static if (!__traits(compiles, { 
            static foreach(i; 0..T.length) {
                static assert(is(p[i] : p[i+T.length]) || is(p[i+T.length] : p[i]), "no implicit conversion between types");
            }
            })){
            // it looks horribly unreadable in console...
            //static foreach(i; 0..T.length) {
            //    static assert(is(p[i] : p[i+T.length]) || is(p[i+T.length] : p[i]), "no implicit conversion exists between types <" ~ p[i].stringof ~ "> and <" ~ p[i+T.length].stringof);
            //}
            Return function(Args) target;
            Return function(AliasSeq!(Args[0..$-T.length], T)) bound;
            target = bound;
        }
        //pragma(msg, "args: ", Args[$-T.length..$], ", T: ", T, "; is same: ",  is(Args[$-T.length..$] == T));

        return typeof(return)(_impl.bind(t));
    }
}

// ensure it handle bind properly
static assert(__traits(compiles, { GodotCallableT!(void, float, int) c1; c1.bindT(42); } ));
static assert(__traits(compiles, { GodotCallableT!(void, float, int) c1; c1.bindT(1.0, 42); } ));
static assert(!__traits(compiles, { GodotCallableT!(void, float, int) c1; c1.bindT("foo"); }));
// and call too
static assert(__traits(compiles, { GodotCallableT!(void, float, int) c1; c1.call(1.0, 42); } ));
static assert(__traits(compiles, { GodotCallableT!(void, float, long) c1; c1.call(1.0, 42L); } ));
static assert(!__traits(compiles, { GodotCallableT!(void, float, int) c1; c1.call(1.0, "42"); } ));

/**
 * Creates a type-safe callable for a method.
 *
 * Validates that the method has the @Method UDA before creating
 * the callable. This ensures only explicitly marked methods can be
 * wrapped.
 *
 * Parameters:
 *   object  - The GodotObject instance to call on
 *   method  - The method to call, must have @Method UDA
 *
 * Returns: A typed callable with the method's signature
 *
 * Example:
 * ----
 * class Player : GodotObject!Node2D {
 *     @Method void move(Vector2 direction, float delta) { ... }
 * }
 *
 * auto player = memnew!Player();
 * auto callable = makeCallable!(player.move)(player);
 * callable.call(Vector2(2.0, 1.0), 0.016f);  // fully typed!
 * ----
 */
auto makeCallable(alias method, T)(T object) {
    import std.traits;

    static assert( hasUDA!(method, Method) || isGodotBaseClass!(__traits(parent, method)),
        "makeCallable: Method '" ~ __traits(identifier, method) ~
        "' must be annotated with @Method. " ~
        "Add @Method to the method declaration."
    );

    // Return typed callable using method's signature
    return GodotCallableT!(ReturnType!method, Parameters!method)(GodotCallable(object, godotName!method));
}

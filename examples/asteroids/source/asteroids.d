import godot;
import godot.object;
import godot.node;
import godot.node3d;
import godot.area3d;
import godot.rigidbody3d;
import godot.engine;

import std.random;
import std.math;

import player;

mixin GodotNativeLibrary!(
    "asteroids",
    Asteroids,
    Player
);

class Asteroids : GodotScript!Node3D {
    alias owner this;

    enum float spread = PI / 4f;
    enum float speed = 20f;
    enum float speedVariance = 5f;

    @OnReady!"CameraTarget" Node3D cameraTarget;
    @OnReady!"Player" Area3D player;

    //@OnReady!"Asteroids" Node3D asteroids;

    @Method _ready() {
        if (Engine.isEditorHint())
            return;
        foreach (i; 0 .. 10)
            addAsteroid();
    }

    @Method _process(float delta) {
        cameraTarget.position = player.position;

        foreach (ch; getChildren(false)) {
            if (RigidBody3D rock = ch.as!RigidBody3D) {
                if (rock.position.length > 60f)
                    addAsteroid(rock);
            }
        }
    }

    @Method addAsteroid(RigidBody3D recycled = RigidBody3D.init) {
        import godot.resourceloader, godot.packedscene;

        RigidBody3D rock = recycled;

        if (!rock) {
            Ref!PackedScene scene = ResourceLoader.load("res://Rock.tscn", "", ResourceLoader
                    .CacheMode.cacheModeReplace).as!PackedScene;
            rock = scene.instantiate(PackedScene.GenEditState.genEditStateInstance).as!RigidBody3D;
            addChild(rock, false, Node.InternalMode.internalModeDisabled);
        }

        Vector3 randomDir = Vector3(0, 0, 1).rotated(Vector3(0, 1, 0), uniform(0f, 2f * PI));
        rock.position = 55f * randomDir;

        Vector3 velocity = (-randomDir).rotated(Vector3(0, 1, 0), uniform!"[]"(-spread, spread));
        velocity *= speed + uniform!"[]"(-speedVariance, speedVariance);
        rock.linearVelocity = velocity;
    }

    this() {
    }
}

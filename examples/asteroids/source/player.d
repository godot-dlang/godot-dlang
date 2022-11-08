import godot;
import godot.object;
import godot.area3d;
import godot.camera3d;
import godot.input;
import godot.inputevent;
import godot.engine;

class Player : GodotScript!Area3D {
    alias owner this;

    enum float speed = 25; /// units per second

    this() {
    }

    @Method _ready() {

    }

    @Method _process(double delta) {
        if (Engine.isEditorHint)
            return;

        Vector2 mousePos = getTree.root.getMousePosition;
        Camera3D camera = getTree.root.getCamera3d;
        Vector3 rayOrigin = camera.projectRayOrigin(mousePos);
        Vector3 rayNormal = camera.projectRayNormal(mousePos);

        Plane plane = Plane(Vector3(0f, 1f, 0f), 0f);
        Vector3 intersect;
        if (plane.intersectsRay(rayOrigin, rayNormal, &intersect)) {
            lookAt(intersect, Vector3(0f, 1f, 0f));
        }

        if (Input.isActionPressed("fly", false)) {
            translateObjectLocal(Vector3(0f, 0f, -delta * speed));
            if (position.length > 50f)
                position = 50f * position.normalized;
        }
    }

    @Method hit(GodotObject o) {
        import godot.control;

        setProcess(false);
        hide();
        getNode(NodePath("GameOver")).as!Control.show();
    }
}

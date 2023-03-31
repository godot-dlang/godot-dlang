module godot.abi.gdextension;

version(importc) {
    public import godot.abi.gdextension_header;
} else {
    public import godot.abi.gdextension_binding;
}

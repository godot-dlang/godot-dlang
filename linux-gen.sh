#!/bin/bash
# TODO: add arg option
# echo "[Dumping GDExtension interface]"

godot --dump-gdextension-interface -q --headless
clang -E gdextension_interface.h -o src/godot/abi/gdextension_header.i

# echo "[Dumping GDExtension API]" 

godot --dump-extension-api -q --headless

echo "Generating API"

dub run godot-dlang:generator -- -j extension_api.json -o




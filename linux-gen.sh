#!/bin/bash
# TODO: add arg option
# echo "Dumping GDExtension interface"

# godot --dump-gdextension-interface
# clang -E gdextension_interface.h -o src/godot/abi/gdextension.i

echo "Dumping GDExtension API" 

godot --dump-extension-api

echo "Generating API"

dub run godot-dlang:generator -- -j extension_api.json -o




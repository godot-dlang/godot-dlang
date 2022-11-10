Godot-DLang API Binding Generator
=============================
This program generates D bindings for the API exported by Godot. It requires one JSON file: `extension_api.json`.

All the modules in `classes/` are generated using this program.

Usage
-----
- Export the API from the Godot editor with `<godot editor executable> --dump-extension-api`.
- Copy (or symlink) the generated `extension_api.json` to `godot-dlang/` (next to `dub.json`).
  - Note: take it from up-to-date Godot source even if you'll use an older Godot binary. Any newer GDExtension functions used by the bindings must be declared for them to compile, but your library will be backwards-compatible thanks to GDExtension's extension API.
- Compile and run the generator with `dub run :generator -- -o -j extension_api.json`. It will place the generated classes in `classes/` automatically.  
(Remember to delete the entire `classes` directory first when re-exporting, in case any classes were removed.)

The main Godot-DLang package can now be compiled.

If you need the generator to use a different API JSON or output directory, you can still specify those options: `dub run :generator -- -o -j [path/to/api.json] [output/dir]`

API Documentation
-----------------
The generator can include Godot's API documentation as ddoc comments by reading it from the XML files in the Godot source. This can be useful for generating D-themed doc pages or for showing class/method documentation in your IDE. Pass your Godot source directory to the generator with the `-s` switch:  

``` sh
dub run :generator -- -j path/to/api.json -o
```


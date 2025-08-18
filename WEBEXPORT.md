# Exporting for WASM-Emscripten

_This document assumes user already knows about GDExtension, godot-dlang building, and loading D extensions in godot._

Exporting web targets currently is __very experimental__, the process relies on multiple tech pieces working together, at the moment it is only supports a specific version set of all tools used in the process, read this document carefully.

> At the moment of writing it is possible that the only way it work will through in-source building from within godot-dlang repo, this means you will have to clone godot-dlang somewhere to work locally, and develop your project inside that folder.

The process itself consists of:
1) installing `emscripten` sdk
2) building `godot` engine for web
3) getting the custom `D runtime`
4) patching your `LDC` installation
5) finally, building your projects
6) export!

To run your project in browser you will also need a web server, this is due to security policy changes in last years, godot project has a python script allowing to host simple server to test changes locally (for security reasons it is not suitable to deploy on hosting platforms).

### Supported tools versions

- LDC 1.40.1 (other minor versions might work too)
- dub 1.41+ (it is not yet released, you might need to build dub from current master)
- godot 4.4
- emscripten 3.1.62 (might work up to 4.0.2, but godot itself sticks to specific version in CI)

You may try newer godot versions, however the key piece here is emscripten, everything is tied to it and godot does not runs ahead to support newer versions, there is a known breakage after emscripten v4.0.2.

emscripten has a specific LLVM version which is a cornerstone of its binary compatibility and likely would not work when you mix LLVM versions (e.g. emscripten 3.1.62-3.1.64 was built around LLVM 19, likewise LDC 1.40 was built with LLVM 19, and they work, but trying to use LDC 1.41 built with LLVM 20 will likely fail due to internal linker script changes).

### Getting started

In order to export godot-dlang project to web target you will need to build godot engine with gdextension support, for that you will need to get an emscripten tools.

1) clone godot git repo, and go read the godot guide https://docs.godotengine.org/en/stable/contributing/development/compiling/compiling_for_web.html
2) proceed to emsdk site and follow the instructions https://emscripten.org/docs/getting_started/downloads.html
3) build godot export templates for web 
	- `scons platform=web dlink_enabled=yes target=template_debug debug=yes` 
	- `scons platform=web dlink_enabled=yes target=template_release`
4) download D runtime zip branch `2110` https://github.com/Superbelko/webassembly/tree/2110 and extract it to `godot-dlang/extras`
5) (optional) "patch" your LDC installation, just extract `patches/<your_ldc_version>-emscripten.zip` over to your LDC folder.
6) (Windows) due to dub treating emscripten as posix platform it will try to run check classes bash script which will fail, you might need to comment it in dub.sdl to be able to build for emscripten target.

### Building asteroids example

This step assumes your already has working godot-dlang setup, at this point you don't need to have godot built for web.

It is important to know that LDC currently generates lots of unused symbols that will end up in produced binary dramatically increasing its size, it is currently necessary to build sources all to once (requiring over 8GB of RAM) in order to produce a binary with a minimal set of unneded symbols for emscripten to be able to load your `.wasm` file.

Additional step is to set up environment variable that points to location with emscripten libc.

unix shell
```sh
export emsdk_libs="/path/to/emsdk/upstream/emscripten/cache/sysroot/lib/wasm32-emscripten"
```

windows cmd/batch
```bat
set emsdk_libs="C:/emsdk/upstream/emscripten/cache/sysroot/lib/wasm32-emscripten"
```

windows powershell
```ps1
$env:emsdk_libs="C:/emsdk/upstream/emscripten/cache/sysroot/lib/wasm32-emscripten"
```

And then build

```sh
cd godot-dlang
dub build :asteroids --compiler=ldc2 --arch=wasm32-unknown-emscripten -v --force --build-mode=allAtOnce --combined
```

you don't need `-v` and `--force`, but a verbose output can be helpful in diagnosing issues in build process, while force make sure this is a clean build without previous artifacts being used.

The produced binary will contain debug information. If something went wrong at least you will see your D call stack, debugging wasm currently is next to impossible, so having a detailed call stack already is of great help. 
Remember to strip debug symbols later on when you ready to ship, for both securing your source code and reducing download size.

!! __important__ : LDC builds shared libraries for wasm with .so extensions, it might be necessary to rename .so to .wasm depending on how your GDExtension configured.
### Export godot project

If you haven't build godot export templates now is the time to do so.

Open up godot project, go to Project->Export menu, add a new target for Web.
For web target set up a paths for Release export template (e.g. `C:/godot/bin/godot.web.template_release.wasm32.dlink.zip`) and optional for debug.

in `Variant` section check both marks for:
- [v] Extension support
- [v] Thread support   

Failing to do so will make your export not working.

Select where you want to place the distributive files and hit `Export project...` in the bottom of this dialog. Remove the "Export with debug" mark to export release version (recommended, this is for godot itself, there little to no benefit having debug builds for debugging D extensions in web environment).

### Testing web project locally

For this step you need a web server properly configured with CORS headers and few extra headers, godot has a python script for quick testing which can be found here `godot\platform\web\serve.py`, copy the script to a more convenient location and run it with root pointing at your project distribution. 
(in this examle i just copied it in that same folder)

```sh
python ./serve.py --root .
```

Open up your browser (default address is http://127.0.0.1:8060/) and navigate to your `<project name>.html`, you should should see your project running in browser.

At this point the guide is done and there is nothing more to tell.

It is worth saying though that basically only Chrome and to some extent Firefox supports WASM at this moment, with Firefox debugging is close to non-existing.

Chrome has a C++ debugger extension that supports DWARF debug information, it works very well with D --gc flag (generate c++ compatible debug info). This way you can have almost full debug info about D extension including types, callstack, local variables, etc... unfortunatelly the godot itself still have pretty much no debug information due to optimization steps.
https://chromewebstore.google.com/detail/pdcpmagijalfljmkmjngeonclgbbannb

Extra information:
these HTTP headers may or may not be necessary for your own server, not sure about last one.

```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Resource-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

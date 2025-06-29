[![DLang Logo](logo.png)](https://github.com/godot-dlang/godot-dlang)

# Godot-DLang

[![dub](https://img.shields.io/dub/v/godot-dlang.svg?logo=d&style=flat-square)](https://code.dlang.org/packages/godot-dlang)
[![git](https://img.shields.io/github/v/release/godot-dlang/godot-dlang?label=git&logo=github&style=flat-square)](https://github.com/godot-dlang/godot-dlang)
![dub rating](https://badgen.net/dub/rating/godot-dlang?style=flat)
![dub rating](https://badgen.net/github/stars/godot-dlang/godot-dlang?style=flat)

D language bindings for the [Godot Engine](https://godotengine.org/)'s
[GDExtension API](https://github.com/godotengine/godot-headers).

Originally a fork of [godot-d](https://github.com/godot-d/godot-d)

**WIP**: These bindings are still under development. Until v1.0.0, expect
breaking changes, bugs, and missing documentation. Please report any issues and
confusing or undocumented features on the GitHub page.

<!--toc:start-->
- [Usage](#usage)
- [Dependencies](#dependencies)
- [Install](#install-godot-dlang-using-dub)
- [Manually building (advanced)](#manually-building-advanced)
- [Generating Godot Bindings](#generating-godot-bindings)
- [Manually creating project](#manually-creating-project)
  - [Creating Godot project](#creating-godot-project)
  - [Creating dub project](#creating-dub-project)
  - [Creating your first D script](#creating-your-first-d-script)
  - [Register GDExtension](#register-gdextension)
  - [Use D scripts in godot](#use-d-scripts-in-godot)
  - [Exporting for Web] (#exporting-for-web)
- [Creating project by using init script](#creating-project-by-using-init-script)
- [Extend as you wish!](#extend-as-you-wish)
<!-- - [Automatic reloading of native extension](#automatic-reloading-of-native-extension) -->
- [Godot API](#godot-api)
- [Versioning](#versioning)
<!--toc:end-->

## Usage

### Dependencies
- D compiler:
  - [DMD 2.096+](https://dlang.org/download.html#dmd) or
  - [LDC 1.26.0+](https://github.com/ldc-developers/ldc#from-a-pre-built-package)
- [DUB](https://dub.pm) package/build tool (usually included with both compilers)
- [Godot 4](https://godotengine.org) editor (standard version)

Before you start please keep in mind that this is purely experimental unstable volatile WIP project intended for those brave people who would like to try D and Godot.

In no situation do not use it to ship your product, doing so of course is possible but by no means the author is responsible for the consequences.

<!-- In order to proceed you will need D compiler (`dmd` or `ldc2`) with `dub`, `git`, and `godot editor` (x64 version assumed) -->

### Install godot-dlang using dub

This will download and cache dub package
- Run `dub fetch godot-dlang`

Proceed to [Manually creating project](#manually-creating-project) for adding it to your D project.

### Manually building (advanced)

_Normaly one would use dub package, this section is for advanced users who would like to develop or hack godot-dlang._

- Clone git repo `git clone https://github.com/godot-dlang/godot-dlang.git`
- Switch it to master branch `git checkout master`
- Use dub local project version lock file `dub.selections.json` to specify where to look for your local copy

> Note that if you have strange errors in `dub run` you might have godot-dlang cached in dub, you might need to remove it by using `dub remove godot-dlang`

### Generating Godot Bindings
- Download godot 4 editor and place it in somewhere like `C:\godot`
- Step into that directory and open terminal
- Generate script API information with command `godot.exe --dump-extension-api`
- Run binding generator (-j tells where to look for script API and -o tells to overwrite any existing bindings) `dub run godot-dlang:generator -- -j extension_api.json -o`

> This step is one time process, though you would need to re-generate API and bindings for every godot release

### Manually creating project
#### Creating Godot project
- Open Godot editor, and create a new project in some known location like `C:\godot\mycoolgame`
- Open it now and let Godot do initial loading

#### Creating dub project
- Open your newly created project in terminal
- Run `dub init`, make sure to give it a name for example `mydplugin`
- Add Godot-dlang master dependency `dub add godot-dlang@~master` <!--DEPRECATED-->
- (optional) (Windows) If you use `ldc2` as compiler, then add `"dflags-windows-ldc": ["-dllimport=defaultLibsOnly"]` to your `dub.json`, or you will have linker errors
- Open up `dub.json` and add `"targetType": "dynamicLibrary",` after `authors` field
your dub.json file should look like this now:

__dub.json__:
```json
{
    "authors": [
        "Godot-DLang"
    ],
    "targetType": "dynamicLibrary",
    "dflags-windows-ldc": ["-dllimport=defaultLibsOnly"],
    "copyright": "Copyright © 2022, Godot-DLang",
    "dependencies": {
        "godot-dlang": "~master", <!--DEPRECATED-->
    },
    "description": "A minimal D application.",
    "license": "proprietary",
    "name": "mydplugin"
}
```
- Do a test build `dub build`, you might see some warnings but that's ok

#### Creating your first D script
- Rename `source/app.d` file into something like `source/greeter.d`
- Open `source/greeter.d` in your favorite text/code editor and add following content:

__source/greeter.d__:
```d
import godot;
// import godot.api.script; // for GodotScript!
// import godot.api.register; // for GodotNativeLibrary
// import godot.string; // for gs!

import godot.node;

// minimal class example with _ready method that will be invoked on creation
class Greeter : GodotScript!Node {
    @Property String name;

    // this method is a special godot entry point when object is added to the scene
    @Method
    void _ready() {
        // 'gs' is a string wrapper that converts D string to godot string
        // usually there is helper functions that takes regular D strings and do this for you
        print(gs!"Hello ", name);
    }
}

// register classes, initialize and terminate D runtime, only one per plugin
mixin GodotNativeLibrary!(
    // this is a name prefix of the plugin to be acessible inside godot
    // it must match the prefix in .gdextension file:
    //     entry_symbol = "mydplugin_gdextension_entry"
    "mydplugin",

    // here goes the list of classes you would like to expose in godot
    Greeter,
);
```
- Build plugin again `dub build`, in some rare cases you might do a full rebuild by adding `--force` switch, build should be ok

> You would need to build your plugin every time you have modified the code in order to see changes

> Currently AFAIK there is no way to unload/reload GDExtension, because of that on Windows it will prevent rebuilding plugin until you close the editor!

#### Register GDExtension
- Currently there is no UI for that AFAIK, so lets do that manually
- Create a file in your Godot project root called `mydplugin.gdextension` and fill with following content:

__mydplugin.gdextension__:
```
[configuration]

entry_symbol = "mydplugin_gdextension_entry"
compatibility_minimum = "4.1"

[libraries]

linux.64 = "libmydplugin.so"
windows.64 = "mydplugin.dll"
web = "libmydplugin.wasm"
```

> Note that entry_symbol should match class registration in D inside of `GodotNativeLibrary` declaration

#### Use D scripts in godot
- If you still have godot editor open reload project by using main menu `Project->Reload Current Project`
- In editor now create an empty `3D Node` scene
- Select root object and attach new `Node` entity, navigate and pick `Greeter` class
- As soon as it gets added to the scene you should see Hello message in log in the panel below.

![hellod](hellogd4.jpg)


#### Exporting for Web

**EXPERIMENTAL** See this [document](WEBEXPORT.md) for more information.

### Creating project by using init script
Run command `dub run godot-dlang:init` to initialize new project in current folder. This script will walk you through standard dub project set up and will create dub config, library entrypoint and gdextension plugin.

It is important that you use this script **after** creating godot project since you can't create godot project in non-empty directory.

Arguments:
- `-p, --path` - Sets path for project to be initialized in.
- `-i, --importc` - Adds dflag to use C header instead of D bindings (advanced, use only if you know what you're doing).
- `-c, --custom` - Sets custom path for godot-dlang, can be used if you've cloned master branch.

Example:
```bash
# Initialize project in current directory: 
dub run godot-dlang:init

# Initialize project in custom directory:
dub run godot-dlang:init -- --path path/to/folder

# Initialize project with custom godot-dlang path:
dub run godot-dlang:init -- --custom path/to/godot/dlang

# Initialize project with custom godot-dlang path in custom directory:
dub run godot-dlang:init -- -p folder/ -c godot-dlang/
```

After running this script you'll have theese new files in selected folder:
```python
├── dub.json/sdl # - Your dub config
├── projectname.gdextension # - GDExtension plugin
└── source/
    └── lib.d # - Library entrypoint that contains "mixin GodotNativeLibrary!"
```

### Extend as you wish!
- Remember that there still might be some bugs, sometimes confusing, sometimes blocking your progress, and sometimes even missing features

Enjoy your new game!

<!-- TODO:
### Automatic reloading of native extension

_This feature is experimental_

Copy `addons/reload-d` editor plugin to your godot project `addons` folder and enable `reload-d` plugin in `Project -> Project Settings -> Plugins` menu.

Next update your `dub.json` project and add following lines, this will automatically tells editor to unload library and then load it again after build.

```json
"preGenerateCommands": ["dub run godot-dlang:reloader -- --action unload -e $DUB_TARGET_NAME"],

"postGenerateCommands": ["dub run godot-dlang:reloader -- --action load -e $DUB_TARGET_NAME"],
```
-->

### Godot API
Godot's full [script API](http://docs.godotengine.org/) can be used from D:  
- `Godot` submodules contain container, math, and engine structs like `Vector3` and `String`.
- Other submodules of `Godot` contain bindings to Godot classes, auto-generated from the engine's API. These are the native classes scripts can be attached to.
- These bindings use camelCase instead of snake_case.
    ```D
    // Change window to fullscreen example:
    // GDScript
    OS.set_window_fullscreen(false)

    // Would be:
    // D
    OS.setWindowFullscreen(false);
    ```
- D code should use D naming conventions (PascalCase for classes, camelCase for properties and methods). 

<!--
### ImportC
WIP
-->

## Versioning

The GDExtension API should be binary-compatible between Godot minor versions as in SemVer convention, so a D library
built for Godot v4.0.0 should work with any v4.0.x versions but not guaranteed to work with v4.1.0 or later. 

D bindings must be generated for your target Godot minor release version
(`godot.exe --dump-extension-api`).

Extension version properties can be checked to prevent newer functions from
being called with older Godot binaries. For example:
```D
import godot.apiinfo; // contains version information about bindings

if(VERSION_MINOR > 0) useNewGodotFunctions();
else doNothing();
```

License
-------
MIT - <https://opensource.org/licenses/MIT>

Github Links
-----
- GitHub repository - <https://github.com/godot-dlang/godot-dlang>
- GDExtension repository - <https://github.com/godotengine/godot-headers>
- C++ bindings these are based on - <https://github.com/godotengine/godot-cpp>
- D bindings these are based on - <https://github.com/godot-d/godot-d>

Links
-----
- Godot Engine - <https://godotengine.org>
- D programming language - <https://dlang.org>

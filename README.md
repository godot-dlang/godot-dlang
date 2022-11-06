[<img src="logo.svg" alt="Godot-DLang Logo" width="600"/>](https://github.com/godot-dlang/godot-dlang)

Godot-DLang
=======
D language bindings for the [Godot Engine](https://godotengine.org/)'s
[GDNative C interface](https://github.com/godotengine/godot-headers).

Originally a fork of [godot-d](https://github.com/godot-d/godot-d)

**WIP**: These bindings are still under development. Until v1.0.0, expect
breaking changes, bugs, and missing documentation. Please report any issues and
confusing or undocumented features on the GitHub page.

# Usage

Before you start please keep in mind that this is purely experimental unstable volatile WIP project not officially maintained (or maintained at all) intented for those brave people who would like to try D and Godot.

In no situation do not use it to ship your product, doing so of course is possible but by no means the author is responsible for the consequences.

In order to proceed you will need D compiler (`dmd` or `ldc2`) with `dub`, `git`, and `godot editor beta4` (x64 version assumed)

## 1) Get godot-dlang for godot 4 ready
- after download godot beta4 editor and place it in somewhere like `C:\godot`
- step into that directory and open terminal
- clone git repo `git clone https://github.com/godot-dlang/godot-dlang.git`
- switch it to master branch `git checkout master`
- add local dub package `dub add-local . ~master`, or if you have package from dub `dub add-override godot-dlang ~master .`  
- you should see that dub package version "~master" is registered
- now go to an editor location in terminal and generate script API information `godot.windows.editor.x86_64.exe --dump-extension-api`
- move `extension_api.json` into `godot-dlang` folder
- step inside godot-dlang in terminal `cd godot-dlang`
- build binding generator (-j tells where to look for script api and -o tells to overwrite any existing bindings) `dub run :api-binding-generator -- -j extension_api.json -o` or run `generate-api.sh`

> This step is one time process, though you would need to re-generate API and bindings for every godot release
> Note that if you have strange errors in `dub run` you might have godot-dlang cached in dub, you might need to remove it by using `dub remove godot-dlang`  
> Also note that `dub add-local` might sometimes not works and how `Non-optional dependency not found` error ([dlang/dub#986](https://github.com/dlang/dub/issues/986)). In that case do `dub remove-local .` in "godot-dlang" folder and then `dub add-path .` instead.

## 2) Creating godot project
- open godot editor, and create a new project in some known location like `C:\godot\mycoolgame`
- open it now and let godot do initial loading

## 3) Creating dub project
- open your newly created project in terminal
- run `dub init`, make sure to give it a name for example `mydplugin`
- add godot-dlang master dependency `dub add godot-dlang@~master`
- if you use `ldc2` as compiler, then add `"dflags-windows-ldc": ["-link-defaultlib-shared=false"]` to your `dub.json`
- open up `dub.json` and add `"targetType": "dynamicLibrary",` after `authors` field
your dub.json file should look like this now:

__dub.json__:
```json
{
	"authors": [
		"Godot-DLang"
	],
	"targetType": "dynamicLibrary",
    "dflags-windows-ldc": ["-link-defaultlib-shared=false"],
	"copyright": "Copyright © 2022, Godot-DLang",
	"dependencies": {
		"godot-dlang": "~master",
	},
	"description": "A minimal D application.",
	"license": "proprietary",
	"name": "mydplugin"
}
```
- do a test build `dub build`, you might see some warnings but that's ok

## 4) Creating your first D script
- rename `source/app.d` file into something like `source/greeter.d`
- open `source/greeter.d` in your favorite text/code editor and add following content:

__source/greeter.d__:
```d
import godot;
import godot.c;

import godot.node;

// minimal class example with _ready method that will be invoked on creation
class Greeter : GodotScript!Node {
	// this method is a special godot entry point when object is added to the scene
	@Method 
    void _ready() {
		print(gs!"Hello from D");
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
- build plugin again `dub build`, in some rare cases you might do a full rebuild by adding `--force` switch, build should be ok

> You would need to build your plugin every time you have modified the code in order to see changes

> Currently AFAIK there is no way to unload/reload GDNativeExtension, because of that on Windows it will prevent rebuilding plugin until you close the editor!

## 4.1) Register GDNativeExtension
- Currently there is no UI for that AFAIK, so lets do that manually
- create a file in your godot project root called `mydplugin.gdextension` and fill with following content:

__mydplugin.gdextension__:
```
[configuration]

entry_symbol = "mydplugin_gdextension_entry"

[libraries]

linux.64 = "libmydplugin.so"
windows.64 = "mydplugin.dll"
```

> Note that entry_symbol should match class registration in D inside of `GodotNativeLibrary` declaration

## 5) Use D scripts in godot
- If you still have godot editor open reload project by using main menu `Project->Reload Current Project`
- In editor now create an empty `3D Node` scene
- Select root object and attach new `Node` entity, navigate and pick `Greeter` class
- As soon as it gets added to the scene you should see Hello message in log in the panel below.

![hellod](hellogd4.jpg)

## 6) Extend as you wish!
- remember that there still might be some bugs, sometimes confusing, sometimes blocking your progress, and sometimes even missing features

Enjoy your new game!

-----

Usage (from godot-d)
-----
#### Dependencies
- D compiler:
  - [DMD 2.082+](https://dlang.org/download.html#dmd) or
  - [LDC 1.11.0+](https://github.com/ldc-developers/ldc#from-a-pre-built-package)
- [DUB](https://dub.pm) package/build tool (usually included with both compilers)

#### Project setup
The easiest way to build your library is to use D's package/build manager, DUB.
Create a [DUB project](https://code.dlang.org/getting_started) in a file called
`dub.json` in your Godot project folder:

	{
		"name": "asteroids-demo",
		"sourcePaths": ["asteroids"],
		"importPaths": ["asteroids"],
		"targetType": "dynamicLibrary",
		"dependencies": {
			"godot-dlang": "~>0.1.4"
		},
		"preGenerateCommands": [
			"dub run godot-dlang:pregenerate"
		]
	}

Your project will usually be organized like this:

	asteroids-demo
	├─ project.godot         Godot project
	├─ <other Godot assets>
	│
	├─ addons
	│  └─ godot-dlang-importer   D editor plugin
	│
	├─ dub.json              DUB project
	├─ *.dll / .so           Compiled libraries for each platform
	└─ asteroids
	   ├─ *.d                D source files
	   └─ entrypoint.d       Entry point (auto-generated)

The location of the D source files is up to you. In this example, we use a
subfolder with the game's name to keep them neatly organized, since the file
path is used as both the D module name and the Godot resource path.

#### D native scripts
In Godot, a "script" is an object that exposes methods, properties, and signals
to the engine. It is always attached to one of the engine's own C++ classes,
listed in the [class reference](http://docs.godotengine.org/en/latest/classes/).  
To expose a D class to the engine as a native script, inherit from GodotScript
with the Godot class the script should be attached to:  
```D
import godot, godot.button;

class TestButton : GodotScript!Button
{
	@Property(Property.Hint.range, "1,10") int number = 9;
	
	@Signal static void function(String message, int num) sendMessage;
	
	@Method void _pressed()
	{
		print("Button was pressed. `number` is currently ", number);
		emitSignal("send_message", "`number` is currently ", number);
	}
	
	...
}
```
Properties and methods can be exposed to Godot with the `Property` and
`Method` UDAs. Exposed properties will be saved/loaded along with instances of
the class and can be modified in the Godot editor. The optional hint parameter
can specify how the editor should treat the property, for example limiting a
number to the range 1-10.

#### Library initialization
Your library needs to expose an entry point through which Godot will load and
initialize it:

##### 1: Automatic entry point generator
Add `godot-dlang:pregenerate` to your DUB project's `preGenerateCommands`:  
```JSON
	"preGenerateCommands": [ "dub run godot-dlang:pregenerate" ],
```

The pregenerate tool will create the entry point `entrypoint.d` in your source
directory and a list of script classes in your string import directory (`views`
by default).

Your GDNativeLibrary's `symbol_prefix` will be the name of your DUB project,
with symbols like `-` replaced by underscores.

##### 2: Manual entry point mixin
Put the `GodotNativeLibrary` mixin into one of your files:  
```D
import godot.d.register;

mixin GodotNativeLibrary!
(
	// your GDNativeLibrary resource's symbol_prefix
	"platformer",
	
	// a list of all of your script classes
	Player,
	Enemy,
	Level,
	
	// functions to call at initialization and termination (both optional)
	(GodotInitOptions o){ writeln("Library initialized"); },
	(GodotTerminateOptions o){ writeln("Library terminated"); }
);
```

##### 3: Both
You can manually create the `GodotNativeLibrary` mixin while still using the
pregenerate tool. It will not create a new `entrypoint.d` if the mixin already
exists. You no longer need to list your script classes, but can still use
`GodotNativeLibrary` to configure your library.

#### Godot API
Godot's full [script API](http://docs.godotengine.org/) can be used from D:  
- `godot.core` submodules contain container, math, and engine structs like
  `Vector3` and `String`.
- Other submodules of `godot` contain bindings to Godot classes, auto-generated
  from the engine's API. These are the C++ classes scripts can be attached to.
- These bindings use camelCase instead of snake_case.

  Change window to fullscreen example:
  ```GDSCRIPT
  # GDScript
  OS.set_window_fullscreen(false)
  ```
  Would be:
  ```D
  // D
  OS.setWindowFullscreen(false);
  ```

- D code should use D naming conventions (PascalCase for classes, camelCase for
  properties and methods). Your method and property names will be converted to
  Godot's own snake_case style when registered into Godot, so refer to them in
  snake_case from inside the editor and GDScript. This behavior can be disabled
  with the `GodotNoAutomaticNamingConvention` version switch if you prefer to
  use camelCase even inside Godot/GDScript.

Building Godot-DLang manually
-------------------------
DUB package releases will contain pre-generated bindings for official releases
of Godot, but you can generate your own bindings in a few cases:  
- using the master branch of Godot
- using the master branch of Godot-DLang, which doesn't include pre-built bindings
- using a custom Godot build or custom C++ modules

Make a local clone of Godot-DLang and generate updated bindings using the
[API generator](util/generator/README.md). In your game project, use this local
clone's path as a dependency instead of a released version of `godot-dlang`:  
```JSON
	"dependencies":
	{
		"godot-dlang": { "path": "../godot-dlang-customized" },
	},
```

Versioning
----------
The GDNative API is binary-compatible between Godot versions, so a D library
can be used with a Godot build older or newer than the one used to generate the
bindings. D bindings must still be generated with the most recent GDNative API
(`modules/gdnative/gdnative_api.json` in the Godot repository) even if an older
Godot binary will be used.

Extension version properties can be checked to prevent newer functions from
being called with older Godot binaries. For example:
```D
if(GDNativeVersion.hasNativescript!(1, 1)) useNewNativescriptFunctions();
else doNothing();
```

A D library can also specify minimum required extensions using a compiler flag
or the `versions` property in their DUB project. The format of the version flag
is `GDNativeRequire<Extension name or "Core">_<major version>_<minor version>`.
For example, with `"versions": [ "GDNativeRequireNativescript_1_1" ]` in
`dub.json`, runtime checks and non-1.1 code such as the example above can be
safely optimized out in both library code and binding-internal code.

License
-------
MIT - <https://opensource.org/licenses/MIT>  

Links
-----
GitHub repository - <https://github.com/godot-dlang/godot-dlang>  
C++ bindings these are based on - <https://github.com/godotengine/godot-cpp>  
D bindings these are based on - <https://github.com/godot-d/godot-d>  
GDNative repository - <https://github.com/godotengine/godot-headers>  

Godot Engine - <https://godotengine.org>  
D programming language - <https://dlang.org>  

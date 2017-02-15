# Haxe Debug
[![Build Status](https://travis-ci.org/vshaxe/vshaxe-debugadapter.svg?branch=master)](https://travis-ci.org/vshaxe/vshaxe-debugadapter) [![Version](http://vsmarketplacebadge.apphb.com/version-short/vshaxe.haxe-debug.svg)](https://marketplace.visualstudio.com/items?itemName=vshaxe.haxe-debug) [![Installs](http://vsmarketplacebadge.apphb.com/installs-short/vshaxe.haxe-debug.svg)](https://marketplace.visualstudio.com/items?itemName=vshaxe.haxe-debug)

This is an extension for debugging Haxe applications on the Flash target via [FDB][1]. It is best used with the [vshaxe][2] extension.

Support for the C++ target via [hxcpp-debugger][3] is planned.

![Example](images/example.png)

## Usage

Swf files have to be compiled using the `-D fdb` define. Additionally, `java` needs to be in your `PATH` (to run `fdb.jar`).

The `launch.json` should look something like this:

```json
{ 
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Flash",
            "type": "fdb",
            "request": "launch",
            "program": "${workspaceRoot}/bin/application.swf"
        }
    ]
}
```

Replace `/bin/application.swf` with the path to your swf file.

You can also generate a config via `Add Configuration...` -> `Haxe (Flash)`:

![Add Configuration](images/add_configuration.png)

## Installing from source
1. Navigate to the extensions folder (`C:\Users\<username>\.vscode\extensions` on Windows, `~/.vscode/extensions` otherwise)
2. Recursively clone this repo: `git clone --recursive https://github.com/vshaxe/vshaxe-debugadapter`
3. Change current directory to the cloned one: `cd vshaxe-debugadapter`.
4. Do `npm install`
5. Do `haxe build.hxml`

   [1]: http://help.adobe.com/en_US/flex/using/WS2db454920e96a9e51e63e3d11c0bf69084-7ffb.html
   [2]: https://marketplace.visualstudio.com/items?itemName=nadako.vshaxe
   [3]: https://github.com/HaxeFoundation/hxcpp-debugger
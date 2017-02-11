# Haxe Debug
[![Build Status](https://travis-ci.org/vshaxe/vshaxe-debugadapter.svg?branch=master)](https://travis-ci.org/vshaxe/vshaxe-debugadapter)

This is an extension for debugging Haxe applications on the Flash target via [FDB][1]. It is best used with the [vshaxe][2] extension.

Support for the C++ target via [hxcpp-debugger][3] is planned.

![](images/example.png)

## Usage

Swf files need to be compiled using the `-D fdb` define. The `launch.json` should look something like this:

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

You can also generate a config via `Add Configuration...` -> `Haxe (Flash)`.

## Installing from source
1. Navigate to the extensions folder (`C:\Users\<username>\.vscode\extensions` on Windows, `~/.vscode/extensions` otherwise)
2. Recursively clone this repo: `git clone --recursive https://github.com/vshaxe/vshaxe-debugadapter`
3. Change current directory to the cloned one: `cd vshaxe-debugadapter`.
4. Do `npm install`
5. Do `haxe build.hxml`

   [1]: http://help.adobe.com/en_US/flex/using/WS2db454920e96a9e51e63e3d11c0bf69084-7ffb.html
   [2]: https://marketplace.visualstudio.com/items?itemName=nadako.vshaxe
   [3]: https://github.com/HaxeFoundation/hxcpp-debugger
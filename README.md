# qwsv-lua

This project aims to be a complete conversion from QuakeC to Lua 5.3 of the original `qwprogs` game source and the required engine changes for `qwsv` to support running it.

## Goals

 * Complete as-is conversion of QuakeWorld QuakeC source to Lua
 * High compatiblity with original `qwsv` (minimal changes to engine)
 * Portability to production quality forks of `qwsv` like MVDSV

## Non-goals

 * Changing QW gameplay in the converted progs
 * Adding new functionality to converted progs
 * Changing the engine in any way
 * Engine Windows compatibility

## Nice-to-haves

 * Savegame support (patches welcome)
 * NetQuake monsters for single player (patches welcome)

## Building

Requirements:

 - Lua 5.3
 - GNU Make and GCC

To build:

```
$ make
```

Run after extracting `pak0.pak` to `id1` directory:

```
$ ./qwsv +gamedir lua
```

Tested to build and run on:

 - Fedora 26 x86_64
 - Ubuntu 16.04 x86_64 running on Bash on Windows

## Disclaimer

Please note this project is not yet feature complete, the engine integration optimized or the code high quality. Patches are always welcome when they advance towards the goals.

Original QW source was chosen as the base for simplicity as many forks have extended the built-in functions of QW and those are not needed to run the original game.

Included `qwsv` has been imported as-is from the original source release. That means all bugs and exploits that were present when the source was released are in it so it might not be a good idea to run a public server.

Native Windows compatiblity is not a priority as you can build and run the project with Bash on Ubuntu on Windows.

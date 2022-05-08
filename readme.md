## Overview
Nu Replayer is a standalone add-on for Planets Nu, written in FreeBASIC. It is designed to build and view replays of completed games. Nu Replayer is currently in alpha, as many features are still missing or incomplete.

## Interface ##
The default interface that is opened up is a menu, housing access to the game list, network functions, and configuration.

### Game Room ###
The game room is a common interface, originally the default when Nu Replayer is first opened. It contains a list of finished games, and a filter can be applied to make it easier to find a desired game.

### Starmap ###
After a suitable game has been selected (either with converted or raw files present), then the game opens into the starmap interface as shown on the right, converting the last turn of the game to a more readable format if necessary.

By default, the starmap is accessed using the entire screen. To get a smaller window (if one is using a desktop &gt;1024&times;768), simply turn on the Compressed View setting in the Engine Options.

The starmap interface contains many useful features. The most notable features of Nu Replayer are currently the planet reports (given when one mouses near a planet on the map), a default mapping (which includes starships, along with a faint territory map, bound to F1) and island mapping (bound to F2).

Turns within a game can be navigate with PageUp / PageDown, or a specific turn can be reached via Ctrl+J.

### Object Lists ###
Nu Replayer carries multiple object lists that supplement the starmap. These lists come in their own screen and, as a result, will need to be accessed with a key in order to view the list. The playerlist is currently bound to F5, the planet list to F6, and the ship list to F7.

## Networking ##
Nu Replayer's ultimate goal is to have complete networking support, allowing downloading of lists and turns *without* relying on any other tools (not even a web browser). Although that goal has not yet been achieved, version 0.25 serves as a step in the right direction by allowing raw game lists to be downloaded from Planets Nu's servers, with an *immediate* conversion afterward. For safety reasons, this operation carries an 8 hour cooldown, during which another game list may not be downloaded from within Nu Replayer

Starting with version 0.27, it is also possible to download the last turns and settings of a game in Nu Replayer. The download room functions similarly to the game room, only it serves the exclusive purpose of downloading *new* games. This operation carries a 5 minute cooldown.

## Installing ##
Installing under Windows is very simple. All you have to do (if you haven't already done so) is extract the package that Nu Replayer and its assets were in, and you are all set. Nu Replayer has been tested on Windows XP/7/8/10. It has been compiled using FreeBASIC 1.09.0.

### GNU/Linux ###
Installing under GNU/Linux, on the other hand, is not so simple. Since the architecture for this system is all over the place, no binaries are provided for GNU/Linux, so you must compile from the included source. Furthermore, FreeBASIC has not been seen in any package manager, so you will likely need to download it directly from the <a href="http://www.freebasic.net">developer website</a> and follow its installation instructions. A simple makefile is supplied.

You will likely need to install additional libraries, notably development variants of SDL, SDL_mixer, and SDL_net, zlib, and libzip. Feel free to poke around until you are able to get a spiffy new binary built just for your system.

### FreeBSD ###
FreeBSD support was added in FreeBASIC 1.09.0. We presume instructions are similiar to GNU/Linux, but this is untested. Feel free to experiment as need be, until you are able to build your own program.

### Wine ###
Alternatively, if you can figure out how to use [Wine](http://www.winehq.org/), then you can use it to run the pre-compiled Windows binaries. This is likely the only way to run Nu Replayer outside of the systems above, as FreeBASIC compiler tools are not provided for any other platforms (except DOS).

That being said, it *might* be remotely possible to compile a native DOS build, but this is extremely tricky to pull off, and is impossible to cross-compile from a 64-bit Windows system. Nu Replayer also does not currently comply with the 8.3 filename system. To summarize, building for DOS is untested.

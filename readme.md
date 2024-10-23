## Overview
Nu Replayer is a standalone add-on for Planets Nu, written in FreeBASIC. It is designed to build and view replays of completed games. Nu Replayer is currently in beta, as most core features are in place.

## Interface
The default interface that is opened up is a menu, housing access to the game list, network functions, and configuration.

### Game Room
The game room is a common interface, originally the default when Nu Replayer is first opened. It contains a list of finished games, and a filter can be applied to make it easier to find a desired game.

### Starmap
After a suitable game has been selected (either with converted or raw files present), then the game opens into the starmap interface, converting the last turn of the game to a more readable format if necessary.

By default, the starmap is accessed using the entire screen. To get a smaller window (if one is using a desktop &gt;1024&times;768), simply turn on the Compressed View setting in the Engine Options. The starmap itself can be zoomed via the +/- keys.

The starmap interface contains many useful features. The most notable features of Nu Replayer are the detailed object reports. These are given when one clicks near such a key object, and can be closed via the X key. Supporting objects can be selected via numeric keys and also PageUp / PageDown.

Turns within a game can be navigate with I/O, or a specific turn can be reached via Ctrl+J.

### Object Lists
Nu Replayer carries multiple object lists that supplement the starmap. These lists come in their own screen and, as a result, will need to be accessed with a key in order to view the list. The playerlist is currently bound to F5, the planet list to F6, and the ship list to F7.

## Networking
Nu Replayer features complete network support, allowing downloading of lists and turns *without* relying on any other tools (not even a web browser).

Raw game lists can be downloaded and auto-converted to CSV. Additionally, it is possible to download a complete game just by visiting the download room. The download room functions similarly to the game room, only it serves the exclusive purpose of downloading *new* games.

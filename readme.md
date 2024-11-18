## Overview
Nu Replayer is a standalone add-on for Planets Nu, written in FreeBASIC. It is designed to build and view replays of completed games. Nu Replayer is currently in beta, as most core features are in place.

The default interface that is opened up is a menu, housing access to the game list, network functions, and configuration.

## Game Room
The game room is a common interface. It contains a list of finished games, and a filter can be applied to make it easier to find a desired game.

## Starmap
After a suitable game has been selected (either with converted or raw files present), then the game opens into the starmap interface, converting the last turn of the game to a more readable format if necessary.

By default, the starmap is accessed using the entire screen. To get a smaller window (if one is using a desktop &gt;1024&times;768), simply turn on the Compressed View setting in the Engine Options. The starmap interface contains many useful features. The most notable features of Nu Replayer are the detailed object reports.

### Controls
* Starmap Zoom: +/-
* Open a report: Click (closest object gets selected)
* Select another object in the same point: B for the base / P for the planet / 1-0 for all other objects
* Pagination navigation: PageUp/PageDn for most lists + Home/End for the starbase storage
* Close the active report: X
* Change turns: I/O
* Jump to any turn: Ctrl+J
* Quickly convert raw turns: Ctrl+Q
* Start a slideshow from the current turn: Ctrl+W
* View a combat: V
* Player List: F5
* Planet List: F6
* Ship List: F7
* VCR List: F8

## VCR Player
Nu Replayer comes with its own Visual Combat Recording (or simply VCR) player. In addition to being able to watch VCRs that have taken place, Nu Replayer also automatically computes "what ifs" for each VCR, and summarizes them as percentages that a given outcome occurs.

### Controls
* Change replay speed: 1-9
* Enter step mode: Spacebar (any other key exits step mode

## Networking
Nu Replayer features complete network support, allowing downloading of lists and turns *without* relying on any other tools (not even a web browser).

Raw game lists can be downloaded and auto-converted to CSV. Additionally, it is possible to download a complete game just by visiting the download room. The download room functions similarly to the game room, only it serves the exclusive purpose of downloading *new* games.

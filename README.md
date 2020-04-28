# homegirl-tic
This is a [TIC-80](https://github.com/nesbox/TIC-80) compatiblity layer made for the [Homegirl Fantasy Console](https://github.com/poeticAndroid/homegirl).

## A word of warning
This is still missing several important functions, but some very basic games should run already.
Right now, you cannot load .tic files directly. This means you will have to manually extract the code, spritesheet and map from the program you want to try to run. Keep in mind things like sound or music are not possible yet.

## Installation
- Copy `tic.lua` into `usr:cmd`
- Copy `tic_big.8b.gif` into `usr:fonts`

## Usage
`tic [folder]` - Launch a game using TIC-80 compatiblity mode

## Extracting .tic data for use in Homegirl
To play a game made for TIC-80 in Homegirl using this tool, you'll have to follow the following steps:
1. Create a folder in Homegirl's `usr` drive. This will be where the game data has to be stored in.
2. Open TIC-80 and load the game you want to extract data from.
3. In TIC-80, use `export map` and `export sprites` to export the spritesheet and map. Store the files in the folder you created.
4. In TIC-80, press `ESC` to open the code viewer. Use `CTRL+A` to select everything, then copy the code into the folder you created.

The file structure should be as follows (Make sure the filenames are identical):
```
mainfighter
|- code.lua
|- sprites.gif
|- world.map
```
Now, open Homegirl and navigate to the `usr` drive. Run `tic [folder]` to launch the game.

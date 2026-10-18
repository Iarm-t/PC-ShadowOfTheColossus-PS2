Shadow of the Colossus - experimental native Windows port

QUICK START

1. Extract the entire ZIP to a writable folder on your PC.
2. Put your own game disc image in the Game folder. Keep its .iso extension;
   any filename is fine.
3. Double-click Play.bat.

You do not need Visual Studio, Python, CMake, Ninja, or a local build.
The Microsoft C++ runtime DLLs are included beside sotc.exe.

Only this disc release is supported:
  Shadow of the Colossus (Europe, Australia), PAL
  SCES-53326, version 1.00
  4,635,918,336 bytes
  ISO SHA-256:
  068925770645266189005f09c9a9a1fee25726bfc93c89b12f832f3673664ac4

The game checks the boot executable and module hashes before booting and
reads the remaining assets directly from your ISO. No disc image, extracted
assets, BIOS, personal settings, or saves are included in this package.

You can keep the ISO elsewhere to avoid copying it. Drag the ISO onto
Play.bat, or run:
  Play.bat "D:\Games\Shadow of the Colossus.iso"
The SOTC_ISO environment variable is also supported.
Keep the ISO available while playing. Do not run the game inside the ZIP.

REQUIREMENTS

Windows 10 or 11, 64-bit; an AVX2-capable CPU; and OpenGL 4.6 graphics.
Update your graphics driver if the game cannot create its graphics context.
Only the exact PAL v1.00 disc works; NTSC, later revisions, and patched or
trimmed images are unsupported.

CONTROLS

Move: W A S D             Camera: mouse
Jump: F                  Draw weapon/dismount: right mouse button
Attack: left mouse       Whistle/mount: Space
Grab: left Shift         Focus camera: Q
Start: Enter             Select: Tab
D-pad: arrow keys        Fullscreen: F11
Save state: F5           Load state: F9

A gamepad is supported. Settings are created in sotc.ini on first launch.
See Docs/CONFIGURATION.md for the complete settings reference.
Saves are in memcards; quick states are in states; caches are in game_data.
Preserve those folders and sotc.ini when updating to another release.

SUPPORT AND SOURCE

This is an experimental fan project with known rendering and audio issues.
If the game exits, Play.bat keeps the error visible. Include that error,
BUILD-INFO.txt, and your CPU/GPU details when reporting a problem:
https://github.com/LightVelox/sotc-vibe-pc/issues

Source and build instructions:
https://github.com/LightVelox/sotc-vibe-pc
The original ISO is still required to regenerate the game-specific code.
See LICENSE and licenses for the software licenses and third-party notices.
The repository's license grants no rights to the original game.

This project is not affiliated with Sony Interactive Entertainment, Team Ico,
or Japan Studio. Shadow of the Colossus is a trademark of its respective owners.

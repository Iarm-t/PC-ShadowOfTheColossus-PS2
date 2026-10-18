# Packaging a Windows release

Let `setup.bat` finish successfully first. Packaging reuses `build/port/bin/sotc.exe` and does not configure,
compile, regenerate game code, or modify that build directory. It is safe to prepare these packaging files
while a build is running, but the executable must be complete before creating the ZIP.

Commit the source and packaging changes first so the package records the commit that will be released.
If game or runtime source changed since the completed build, rebuild before packaging.

Run this on the build machine while the MSVC build tools and their redistributable files are still installed:

```bat
package-release.bat v0.1.0-preview.1
```

Without a version argument, the name is `experimental-<source commit>`. The output is:

```text
out/releases/sotc-<version>-windows-x64.zip
out/releases/sotc-<version>-windows-x64.zip.sha256
```

The ZIP contains a portable `sotc.exe`, the toolchain's x64 Microsoft C++ runtime DLLs, any other non-system
DLL dependencies, `Play.bat`, instructions, license notices, and source/build identification. It excludes
the ISO, extracted game assets, generated source files, build tools, debug symbols, personal settings,
caches, and saved games. The packager checks DLL dependencies and runs the staged executable with `--help`
using only Windows' System32 directory on `PATH` before writing the archive. Existing ZIPs are not replaced.

## Validate the package

Extract the ZIP to a different writable directory. Put the supported ISO in its `Game` directory and run
`Play.bat`, or drag the ISO onto `Play.bat` to avoid making another copy. Confirm that the game starts and
reaches the title screen. Test on a Windows x64 PC without Visual Studio when possible. Missing and wrong
disc images must produce a visible error rather than triggering a build.

The packaged runtime checks the boot executable and module hashes and reads the remaining assets directly
from the ISO. Users do not need Python, Visual Studio, CMake, Ninja, or the source repository.

## Publish an experimental release

Push the source commit recorded in `BUILD-INFO.txt`, including the packaging changes. Create a GitHub release
with a matching tag pointing at that commit, mark it as a prerelease, and attach the ZIP and checksum.
Do not attach the ISO, local saves, extracted files, or the build directory. GitHub's automatically generated
source archive does not include submodules; include the pinned PS2Recomp source link from `BUILD-INFO.txt`
in the release notes, along with the recursive clone/build instructions and dependency license notices.

The release notes should state the supported disc (SCES-53326 v1.00 PAL), Windows x64/AVX2/OpenGL 4.6
requirements, the extract/drop-ISO/run-Play.bat steps, and the experimental status with known issues.

### First preview: GitHub website

1. Push the committed changes with `git push origin main`.
2. Open [the new-release form](https://github.com/LightVelox/sotc-vibe-pc/releases/new).
3. Under **Choose a tag**, enter `v0.1.0-preview.1` and choose **Create new tag**. Set **Target** to `main`.
4. Set the title to **Shadow of the Colossus - Windows preview 1**.
5. Paste the Markdown from [the prepared release notes](releases/v0.1.0-preview.1.md) into the description.
6. In the binary attachments area, upload `sotc-v0.1.0-preview.1-windows-x64.zip` and its `.zip.sha256`
   file from `out/releases`. Wait for both uploads to finish. Do not upload the staging directory.
7. Select **This is a pre-release**. Review the tag, description, and both assets.
8. Click **Publish release**, or **Save draft** to review it later.

The source commit in the ZIP's `BUILD-INFO.txt` must be the commit selected by the release tag.
After publishing, users download the Windows ZIP under **Assets**, rather than GitHub's automatic source archives.

These steps follow [GitHub's release documentation](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository).

GitHub CLI can create a draft for review before publishing:

```bat
gh release create v0.1.0-preview.1 out/releases/sotc-v0.1.0-preview.1-windows-x64.zip out/releases/sotc-v0.1.0-preview.1-windows-x64.zip.sha256 --draft --prerelease --title "Windows experimental preview" --notes-file Docs/releases/v0.1.0-preview.1.md
```

The packager does not upload anything. Inspect the archive and release notes before publishing.

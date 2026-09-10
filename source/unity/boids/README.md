# Boids — Unity project source

Coursework / learning project from Jinge Guo's local Unity collection.

## Open the project

1. Extract the ZIP or clone this repository.
2. In Unity Hub, add this folder (the one containing Assets, Packages, and ProjectSettings).
3. Use the editor version listed in `ProjectSettings/ProjectVersion.txt`. Unity restores registry packages and generates its Library on first import.

This export includes the supplied scenes, prefabs, code, textures, audio, materials, fonts, and package manifests. It preserves the original prototype state; exporting it does not fix missing scene references, unfinished scripts, or filename/class mismatches. See the website project page for known limitations. Full clean-import/gameplay validation has not been performed on this export.

## Export boundaries

- Library, Temp, Logs, obj, UserSettings, builds, local IDE files, and credentials are excluded.
- Unity Cloud account/project associations and signing fields are cleared in the exported settings; cloud connections are disabled. Original files are untouched.
- The optional Boids Code Assist editor tool is excluded and its lock entry removed. It is not a gameplay dependency.
- Original assets, notices, license files, and comments are retained. Included third-party assets remain subject to their own terms; no new blanket license is assigned.
- `manifest.json` records the original and exported SHA-256 hash of each project file and flags sanitized files. All gameplay C# files are unchanged.

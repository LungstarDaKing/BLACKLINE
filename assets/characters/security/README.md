# characters/security

**What belongs here:** security guards: the Mission 01 enemy replacements (currently capsules in `scenes/enemies/enemy.tscn`).

**Format:** GLB preferred. **Skeleton:** REQUIRED (shared humanoid). **Animations:** Idle, Walk, Run, Melee attack, Hit reaction, Death (in place). Aim/Fire later.
**Compatibility:** `scripts/enemies/enemy.gd` reads `$Visual/Body` (for colour/flash) and rotates the root node. A replacement must keep a `Visual/Body` node (a MeshInstance3D) or the script must be updated deliberately. Do not replace the current enemies until a test scene passes and the user approves.
**Orientation and scale:** faces -Z, feet at Y = 0, 1 unit = 1 m, about 1.8 m. Budget about 6,000 to 10,000 triangles, textures 512 to 1024. Two or three variants can share one skeleton and one texture atlas.
**Record keeping:** source, author, licence, date in `docs/ASSET_LICENSES.md`; status in `docs/ASSET_CATALOGUE.md`.

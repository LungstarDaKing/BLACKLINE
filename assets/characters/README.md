# assets/characters

All human characters. One sub-folder per role: `protagonist/`, `antagonists/`, `police/`, `security/`, `civilians/`.

**Format:** GLB (glTF 2.0 binary) preferred. FBX is accepted (Godot 4.3+ imports it natively), e.g. Mixamo downloads.
**Skeleton:** every character must be a rigged humanoid, or have a documented workflow to rig it (see `docs/ASSET_PIPELINE.md`). Use ONE shared humanoid skeleton across roles where possible so animations retarget.
**Animations:** see each role's README.
**Orientation and scale:** 1 unit = 1 metre, feet at Y = 0, model faces -Z (Godot forward), about 1.8 m tall for an adult male.

**Existing legacy folders (empty, kept, not deleted):**
- `player/`  -> superseded by `protagonist/` (do not put new files here).
- `enemies/` -> superseded by `antagonists/`, `police/`, `security/`.
Note: `scripts/enemies/enemy.gd` reads `$Visual/Body`. Any replacement enemy visual must keep a node at that path (or the script must be updated deliberately).

**Record keeping:** for every file added, record source, author, licence and date in `docs/ASSET_LICENSES.md`, status in `docs/ASSET_CATALOGUE.md`, and a dated line in `docs/ASSET_PRODUCTION_LOG.md`.

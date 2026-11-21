# characters/protagonist  (Kabelo)

**What belongs here:** the playable main character: adult male, modern South African urban streetwear (black hoodie with a BLACKLINE-style emblem, cargo trousers, sneakers), natural proportions.

**Sub-folders**
- `model/`      the character GLB/FBX (one primary file, e.g. `kabelo.glb`).
- `textures/`   its textures if they are not embedded (albedo, normal, ORM). Max 1024 px per map unless approved.
- `animations/` animation files (see list below).

**Format:** GLB preferred (FBX accepted).
**Skeleton:** REQUIRED. Must be a rigged humanoid (Mixamo-compatible or UE-style humanoid) that maps to Godot's `SkeletonProfileHumanoid` via a BoneMap, or come with a documented rigging workflow. Static, unrigged meshes are rejected.
**Animations required (names matter, the adapter matches them loosely):** Idle, Walk, Run, Sprint, Jump, Fall, Crouch Idle, Crouch Walk. Later: aim, fire, reload, hit reaction, death. Locomotion clips should be **in place** (no root motion): the CharacterBody3D moves the character.
**Orientation and scale:** T-pose preferred, faces -Z, feet at Y = 0, about 1.8 m (check against the red marker in `scenes/test/character_visual_test.tscn`), 1 unit = 1 m. Budget about 8,000 to 12,000 triangles.
**Test first in:** `scenes/test/character_visual_test.tscn`. Do NOT change `scenes/player/player.tscn` until approved.

**Record keeping:** source, author, licence, date in `docs/ASSET_LICENSES.md`; status in `docs/ASSET_CATALOGUE.md`.

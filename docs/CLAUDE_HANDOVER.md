# CLAUDE HANDOVER — BLACKLINE

## CURRENT STATE: Phase 5A prep (2026-11-05, Claude Desktop)

**Done and verified:** the isolated character visual test scene and animation adapter work (all 8 roles selected correctly with synthetic animations). Mission 01 and all gameplay scripts untouched. Validation 0/0.

**Not done:** no realistic character exists yet. The project contains no `.fbx/.glb/.gltf` at all, and `assets/characters/*` are empty. The player is still the blue capsule.

**Launch:** open `res://scenes/test/character_visual_test.tscn` in Godot, press F6 (Run Current Scene). WASD/Shift/C/Space move; Esc pauses. Top-left overlay shows model + current animation.

**Files created:** `scripts/visual/character_visual.gd`, `scripts/visual/character_visual_test.gd`, `scenes/test/character_visual_test.tscn`. **Docs edited:** this file, `DEVLOG.md`.

**Decisions:**
- Recommended first source: Mixamo (Adobe FAQ: royalty-free incl. commercial games, Adobe ID needed, no standalone redistribution). Character look must be chosen by the user in Mixamo's library (behind login; not verified which one best fits "Kabelo"). The BLACKLINE hoodie emblem will be a custom texture added later.
- Fallback (CC0, stylized): Quaternius Universal Base Characters + Universal Animation Library (quaternius.com).
- The model attaches under `Player/Visual` via `CharacterVisual`; `player.tscn` is not modified until the test scene passes with a real model. Enemy.gd needs `$Visual/Body`; keep that node when replacing enemy visuals.

**Exact next steps (user):**
1. mixamo.com, sign in with an Adobe ID. Pick ONE adult male character. Download: Format FBX Binary (.fbx), Pose T-pose, WITH skin. Save as `kabelo.fbx`.
2. With that character selected, download these animations (FBX Binary, 30 fps, WITHOUT skin, tick **In Place** for locomotion): Idle, Walking, Running, Sprint (or a fast run), Jump, Falling Idle, Crouch Idle, Crouched Walking.
3. Copy all files into `C:\Development\BLACKLINE\Game\blackline\assets\characters\player\`. Expected size: well under 100 MB total.
4. Tell Claude. Claude then configures import (BoneMap/humanoid retarget via MCP import tools; exact editor clicks will be given if a dialog is required), builds the AnimationLibrary and re-runs the test scene.

**Known risks:** Mixamo clip names are generic (rename files Idle.fbx, Run.fbx etc. so the adapter can match); FBX scale/orientation may need a model_scale tweak (use the 1.8 m red marker); retargeting from non-T-pose sources can twist hands; real-model path is untested.

---

# Previous session: Mission 01 Pickup Fix

**Date:** 2026-11-01  
**Session:** Forensic investigation + approved minimal fix for vertical alignment of pickups

---

## Summary

Fixed vertical alignment of three pickups in `mission_01.tscn` that were floating 8.3m above the floor (visually buried/unreachable) after the NavRegion3D offset was removed in Phase 4A.

---

## Files Changed

| File | Change Type | Lines |
|------|-------------|-------|
| `scenes/levels/mission_01.tscn` | Modified | 3 pickup transforms (Y: 0 → -0.7) |
| `scenes/levels/backups/mission_01_BACKUP_20261101_before_pickup_fix.tscn.bak` | Created | Dated backup before fix |
| `docs/DEVLOG.md` | Updated | Added Phase 4B section |

---

## The Fix (3 lines in mission_01.tscn)

```diff
- transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -12, 0, -6.5)   # Keycard
+ transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -12, -0.7, -6.5)

- transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 11, 0, -4)      # Medkit
+ transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 11, -0.7, -4)

- transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -9, 0, 7)       # AmmoBox
+ transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -9, -0.7, 7)
```

**Why -0.7?**  
- Pickup `Area3D` root at Y=-0.7
- Child `MeshInstance3D` at local Y=0 → **world Y=0** (mesh bottom sits on floor)
- Child `Reach` CollisionShape3D at local Y=0.6 → **world Y=-0.1** (sphere radius 0.6 reaches up to Y=0.5, overlapping player capsule at Y≈0.9)

---

## What Was NOT Changed (Correct Already)

| Object | Y Position | Status |
|--------|------------|--------|
| VaultDoor | 0 | ✅ Correct — collision bottom at floor |
| DataTerminal | 0 | ✅ Correct — body at Y=0.6, screen at Y=0.8 |
| ExtractionZone | 0 | ✅ Correct — marker at Y=1.5 (visual only) |
| NavigationMesh | Y=0.4 | ✅ Correct — floor_top(0) + agent_radius(0.4) |
| Floor Mesh | Y=-0.2 | ✅ Correct — top face at Y=0 |
| Player/Guards | Y=0 | ✅ Correct — capsule bottom at Y=0 |

---

## Backups Available

```
scenes/levels/backups/
├── mission_01_BACKUP_20261101_before_navregion_fix.tscn      # Original with NavRegion Y≈8.3
├── mission_01_SNAPSHOT_20261101_AFTER_navregion_fix.tscn     # After NavRegion fix, pickups at Y=0 (BROKEN)
└── mission_01_BACKUP_20261101_before_pickup_fix.tscn.bak     # Before THIS fix (pickups at Y=0)
```

---

## Verification Results

**Automated playthrough (run_id: 7c749dac):**
1. ✅ Player spawns on floor at Y=0
2. ✅ Keycard visible on floor at (-12, 0, -6.5) — mesh bottom Y=0
3. ✅ Keycard interaction works — reach sphere at Y=-0.1 overlaps player
4. ✅ Keycard collected → inventory updated → objective "[x] Find the vault keycard"
5. ✅ Vault door opens sideways (slide X+3.1) — Phase 4A fix intact
6. ✅ Data terminal interaction works — "[E] Download Data"
7. ✅ Extraction reached → MISSION COMPLETE

**No regressions:** All Phase 4A systems (weapon, enemy AI, objectives, vault door, etc.) remain functional.

---

## Known Issues (Pre-existing, Unchanged)

- Integer-division warning in `mission_manager.gd:96` (non-blocking)
- No automated test framework installed (GUT/GdUnit4 not in project)
- Visual polish items: muzzle flash, hit markers, enemy hit reactions, lighting pass

---

## Next Steps (If Continuing)

1. Install GUT or GdUnit4 for automated regression testing
2. Add noise meter HUD for stealth depth
3. Implement silent takedowns
4. Configure vault door slide direction per-instance
5. Add enemy patrol routes
6. Lighting/material pass
7. Human play-test on target hardware (8GB RAM, integrated graphics)

---

## Git Status

```
M scenes/levels/mission_01.tscn
M scenes/props/block.tscn
M docs/DEVLOG.md
?? docs/CLAUDE_HANDOVER.md
?? scenes/levels/backups/mission_01_BACKUP_20261101_before_pickup_fix.tscn.bak
```

Commit when ready:
```bash
git add scenes/levels/mission_01.tscn scenes/props/block.tscn docs/DEVLOG.md \
        scenes/levels/backups/mission_01_BACKUP_20261101_before_pickup_fix.tscn.bak \
        docs/CLAUDE_HANDOVER.md
git commit -m "fix: Mission 01 pickup vertical alignment + ground collision repair

- Three pickups (Keycard, Medkit, AmmoBox): Area3D Y 0 → -0.7 so mesh
  bottom sits at floor Y=0 and reach sphere overlaps player capsule
- block.tscn: added inline BoxShape3D + BoxMesh resources (Phase 2 fix)
- Mission now fully playable: keycard → vault → terminal → extract

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
```
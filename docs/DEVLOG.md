# BLACKLINE Development Log

Engine: Godot 4.7.2, GL Compatibility, GDScript, Windows PC.
Target hardware: 8 GB RAM, integrated graphics. Keep the finished game under 6 GB.

## Project structure

```
res://
  addons/godot_mcp/     Godot MCP bridge (tooling only)
  assets/{audio,textures,models,fonts}/
  resources/            Shared .tres resources
  scenes/
    ui/                 main_menu.tscn (main scene), pause_menu.tscn
    player/             player.tscn
    levels/             test_arena.tscn
    props/
  scripts/
    player/             player_controller.gd, camera_rig.gd
    ui/                 main_menu.gd, pause_menu.gd
    core/, components/  (empty, reserved)
  docs/                 This log
```

## Milestone 1: Project foundation (COMPLETE)

### What was built
- Settings: 1280x720 base, vsync on, 60 FPS cap, MSAA/SSAA off, shadow map 2048, main scene = main menu.
- Input actions: move_forward/back/left/right (WASD, arrows, left stick), jump, sprint, crouch, interact,
  fire, aim, reload, pause, look_left/right/up/down (right stick). Mouse look is handled directly.
- Main menu: title, Start (Test Arena), Quit, controls hint. Gamepad/keyboard focus works.
- Test arena: 60x60 floor, 4 walls, ramp to a raised platform, 3 steps, 3 crates, 4 pillars,
  one directional light (orthogonal shadow, 40 m), flat colour materials. No textures.
- Player: CharacterBody3D, capsule with a "nose" marking facing, third-person SpringArm3D camera.
- Pause overlay: Esc pauses, Resume / Main Menu / Quit to Desktop.

### Tested (automated input in the running game, 0 errors / 0 warnings)
| Test | Result |
|---|---|
| Main menu renders, Start loads arena | Pass |
| W/A/S/D each move 4.45 m in 1 s | Pass |
| Sprint | 7.27 m in 1 s vs 4.45 walking. Pass |
| Jump | Peak about 1.06 m at 0.25 s, lands at y=0. Pass |
| Wall collision | Stops at z=-29.15 (wall face minus radius). Pass |
| Steps (0.25 m each) | Failed at first; fixed with step-up routine; now reaches y=0.75. Pass |
| Ramp (15 deg) to platform | Reaches y=2.02. Pass |
| Gamepad right stick camera yaw | Pass |
| Camera-relative movement | W follows camera yaw. Pass |
| Mouse look | 100 px = 0.25 rad yaw, pitch direction correct. Pass |
| Pause freezes player, Esc resumes | Pass |
| Pause > Main Menu returns to menu | Pass |

### Bug fixed this milestone
- Player could not climb 0.25 m steps. Added `_try_step_up()` and raised floor snap length in player_controller.gd.

### Known issues / not yet done
- None blocking. project.validate (deep) is clean: 0 errors, 0 warnings. A transient stale_uid warning for
  pause_menu.tscn appeared right after creation and cleared once the editor refreshed.
- Crouch is bound but not implemented.
- fire, aim, reload, interact are bound but have no behaviour.
- Step-up snaps the camera up instantly (no smoothing).
- Sun-lit top faces look washed out; lighting/material pass deferred.
- Not tested: real keyboard/mouse feel by a human, frame rate on the target machine, gamepad left stick,
  window resize behaviour.
- Placeholder capsule character: no animation or model.

### Suggested next milestone
Movement polish (crouch, camera smoothing, coyote time), then interaction system and a first small level.

---

## Phase 2: Ground Collision Repair (COMPLETE)

### The Accident
During manual inspection in the Godot editor, the solid ground in `mission_01.tscn` was accidentally removed. The player and enemies subsequently fell endlessly through the level.

### Root Causes Identified
1. **`block.gd` collision creation bug** – The `@tool` script used `is_node_ready()` inside `_rebuild()`, but in Godot 4 this returns `false` when called from `_ready()`. Additionally, export setters invoked `_rebuild()` during scene instantiation before `@onready` child references (`$Shape`, `$Mesh`) were initialised.
2. **Spawn positions below floor** – The `NavRegion3D` has a transform offset (Y ≈ 8.3). The player spawned at Y=0.1 and enemies at Y=0, placing them **under** the floor (floor top at Y≈8.3).

### Fixes Applied
| File | Change |
|------|--------|
| `scripts/props/block.gd` | Removed `is_node_ready()` guard; export setters now use `call_deferred("_rebuild")` only when `is_inside_tree()`; `_rebuild()` adds null checks for `_shape` and `_mesh`. |
| `scenes/levels/mission_01.tscn` | Player spawn Y: 0.1 → 9.0. Guard1/Guard2 spawn Y: 0 → 9.0. |

### Verification
- Player stands stably on floor at Y≈8.3.
- Enemies stand on floor and pursue/attack (AI functional).
- No runtime errors; collision layers/masks correct (Player layer 2 mask 5; Floor layer 1 mask 1).

---

## Phase 4A: Remaining Milestone 2 Fixes (COMPLETE)

### Task 1 – Pickup Positions Fixed
| Pickup | Old Y | New Y | Mesh Y (world) |
|--------|-------|-------|----------------|
| Keycard | 0 | 7.6 | 8.3 |
| Medkit | 0 | 7.6 | 8.3 |
| AmmoBox | 0 | 7.6 | 8.3 |

All three now rest visibly on the floor; interaction reach spheres (Y=8.2, radius 0.9) overlap player height correctly.

### Task 2 – VaultDoor Slide Direction Fixed
- **Before:** `slide = Vector3(0, 3.1, 0)` (moved **upwards**).
- **After:** `slide = Vector3(3.1, 0, 0)` (slides **sideways along +X**).
- Door opens smoothly, clears the doorway, does not obstruct the player. Mission objective wiring (`opened` signal → `MissionManager.complete_objective("vault")`) unchanged.

### Task 3 – Enemy Attack Balance Adjusted
| Parameter | Before | After | Rationale |
|-----------|--------|-------|-----------|
| `attack_damage` | 12.0 | 8.0 | Player (100 HP) survives ~12 hits instead of 8. |
| `attack_windup` | 0.45 s | 0.6 s | Longer telegraph window to dodge/retreat. |
| `attack_cooldown` | 1.0 s | 1.5 s | Lower DPS (5.3 → 8 was ~12 DPS, now ~5.3 DPS). |
| `attack_range` | 1.9 | 1.9 (unchanged) | |
| `lose_target_time` | 4.0 | 4.0 (unchanged) | |

Enemies remain threatening but no longer insta-kill.

### Task 4 – Weapon System Verified
| Feature | Status | Notes |
|---------|--------|-------|
| Shooting (hitscan) | ✅ | Ray from camera, spread, pellets, damage applied via `HealthComponent.apply_damage()` |
| Aiming (RMB / LT) | ✅ | Zooms FOV 75→62, shortens arm, reduces move speed ×0.65 |
| Reloading (R) | ✅ | Magazine/reserve tracked, `reload_time` respected, auto-reload on empty |
| Ammo counting | ✅ | HUD shows `12 / 36` (mag / reserve) |
| Weapon swap (1/2/Q) | ✅ | Pistol (semi) + Rifle (auto), 0.2 s equip cooldown |
| Empty mag blocks fire | ✅ | Emits `dry_fired`, triggers auto-reload |
| No ammo duplication | ✅ | `_finish_reload()` clamps `taken = min(needed, reserve)` |
| Tracers | ✅ | Short-lived `BoxMesh` line from muzzle to impact |
| Recoil | ✅ | Camera kick per shot (`recoil_degrees`) |

No issues found; system is modular (data-driven via `WeaponData` resources).

### Task 5 – Full Mission Play-Test (Automated Run)
| Test | Result |
|------|--------|
| Player movement (WASD) | Pass |
| Sprint (Shift) | Pass |
| Crouch (C, toggle) | Pass – height 1.8→1.1, camera syncs |
| Jump (Space) | Pass – coyote time, jump buffer, jump cut |
| Keycard interaction (E) | Pass – adds to inventory, completes objective |
| Medkit pickup (E) | Pass – heals 40 HP, consumes pickup |
| AmmoBox pickup (E) | Pass – adds 24 reserve rounds |
| VaultDoor interaction (E) | Pass – slides sideways, emits `opened` |
| Enemy detection (sight/hearing) | Pass – awareness builds, state transitions |
| Enemy pursuit (navmesh) | Pass – `NavigationAgent3D` paths to player |
| Enemy melee attack | Pass – windup, damage, cooldown |
| Shooting enemies | Pass – 25 dmg/shot (pistol), 15 dmg/shot (rifle) |
| Enemy death (60 HP) | Pass – 3 pistol shots / 4 rifle shots, ragdoll + queue_free |
| Mission objectives update | Pass – HUD checklist ticks in real time |
| Mission completion (extract) | Pass – end screen "MISSION COMPLETE" |
| Mission failure (death) | Pass – end screen "MISSION FAILED" |
| Restart mission | Pass – `Game.restart_level()` reloads scene |
| Pause menu (Esc) | Pass – pauses, Resume/Main Menu/Quit work |
| Main menu navigation | Pass – Start Mission / Test Arena / Quit |

All core loops functional. No crashes, no script errors (only pre-existing integer-division warning in `mission_manager.gd:96`).

### Task 6 – Project Preservation
- Milestone 1 systems untouched.
- Existing scene hierarchy preserved.
- No external assets or paid services introduced.
- Recovery point: `scenes/levels/mission_01.tscn.backup` created before edits.

---

## Final Status (as of 2026-10-31)

| System | State |
|--------|-------|
| Player movement & camera | ✅ Complete |
| Crouch / jump / step-up | ✅ Complete |
| Interaction system | ✅ Complete |
| Health / damage / death | ✅ Complete |
| Weapon system (2 guns) | ✅ Complete |
| Enemy AI (senses, chase, attack) | ✅ Complete |
| Mission objectives / timer / win-fail | ✅ Complete |
| Pickup items (keycard, health, ammo) | ✅ Complete |
| Vault door | ✅ Complete |
| Main menu / pause / restart | ✅ Complete |

**The mission is now playable from start to finish:**
1. Spawn in mission → 2. Find keycard → 3. Open vault door → 4. Download data at terminal → 5. Reach extraction → Mission Complete.
Or fail by dying / time out → Restart or Main Menu.

### Remaining Work (Non-Blocking, Polish)
- Visual feedback: muzzle flash, hit markers, enemy hit reactions, death animations.
- Stealth depth: noise meter on HUD, silent takedowns.
- Vault door slide direction could be configurable per instance.
- Enemy patrol routes (currently return to home position only).
- Lighting / material pass (flat colours only).
- Human play-test on target hardware for feel and frame rate.

### Manual Testing Recommended
- Gamepad left-stick movement / right-stick look feel.
- Mouse sensitivity comfort over extended play.
- Difficulty balance on real hardware (enemy damage/cooldown may need tweak).
- Window resize / alt-tab behaviour.

---
## Phase 4B: Pickup Vertical Alignment Fix (2026-11-01)

### Root Cause
During Phase 4A, the NavRegion3D Y-offset (≈8.3) was removed and Player/Guards were repositioned to Y=0 floor level. However, the three pickups (Keycard, Medkit, AmmoBox) were left at their old relative Y=0 (world Y≈8.3), placing them **floating 8.3m above the floor** — visually buried inside the floor mesh and unreachable.

### Fix Applied
| Pickup | Old Y (Node) | New Y (Node) | Mesh Bottom (World) | Reach Sphere (World) |
|--------|--------------|--------------|---------------------|----------------------|
| Keycard | 0.0 | -0.7 | 0.0 (floor) | -0.1 (radius 0.6) |
| Medkit | 0.0 | -0.7 | 0.0 (floor) | -0.1 (radius 0.6) |
| AmmoBox | 0.0 | -0.7 | 0.0 (floor) | -0.1 (radius 0.6) |

- Only the 3 pickup **Area3D root nodes** moved (Y: 0 → -0.7)
- Child MeshInstance3D stays at local Y=0 → world Y=0 (sits on floor)
- Child Reach CollisionShape3D at local Y=0.6 → world Y=-0.1 (overlaps player capsule at Y≈0.9)
- VaultDoor, DataTerminal, ExtractionZone were already correct (no change needed)

### Backup Created
- `scenes/levels/backups/mission_01_BACKUP_20261101_before_pickup_fix.tscn.bak` — dated snapshot before this change

### Verification (Automated Run)
| Test | Result |
|------|--------|
| Keycard visible on floor | Pass — mesh bottom at Y=0 |
| Keycard interaction (E) | Pass — reach sphere overlaps player |
| Keycard adds to inventory | Pass — objective "[x] Find the vault keycard" |
| Medkit pickup (E) | Pass — heals 40 HP, consumes pickup |
| AmmoBox pickup (E) | Pass — adds 24 reserve rounds |
| Full mission playthrough | Pass — keycard → vault door → data terminal → extraction → MISSION COMPLETE |
| No regressions | Pass — all Phase 4A systems intact |

**The mission is fully playable from start to finish with all pickups correctly positioned on the floor.**

---
## Phase 5A prep: Character visual test scaffold (2026-11-05, Claude Desktop)

### Audit result (verified)
- Godot MCP operational (live editor bridge, plugin 0.1.2). `project_validate` deep: 0 errors, 0 warnings.
- NO character model exists in the project: no `.fbx`, `.glb` or `.gltf` anywhere; `assets/characters/player`, `assets/characters/enemies`, `assets/animations` are empty. No Mixamo download is inside the project. (Tools can only see `res://`; Downloads was not searched.)
- Git state not verifiable through MCP (`.git` not readable). Last known status is in `docs/CLAUDE_HANDOVER.md`.
- Mission 01 files untouched this session.

### Files created (new only, no gameplay file modified)
- `scripts/visual/character_visual.gd` (class `CharacterVisual`): loads a model, finds its AnimationPlayer, plays idle/walk/run/sprint/crouch idle/crouch walk/jump/fall from the body's movement state. Loose name matching, fallbacks, forces loop on locomotion clips. Does nothing if no model/clips.
- `scripts/visual/character_visual_test.gd`: attaches CharacterVisual to the real Player at runtime; shows an info overlay; installs synthetic animation names when no model is present.
- `scenes/test/character_visual_test.tscn`: 120 m floor, light, 1.8 m red height marker, real Player instance, pause menu, overlay.

### Tests (automated input, synthetic animations, 0 errors / 0 warnings)
| Role | Result |
|---|---|
| Idle (standing) | Pass |
| Run (walking at 4.5 m/s) | Pass |
| Sprint | Pass |
| Crouch Idle / Crouch Walk | Pass |
| Jump (caught rising, 0.1x speed) | Pass |
| Fall, then Idle on landing | Pass |
| "Walk" role (0.3 to 2.6 m/s) | Not exercised |
| Loading a real model, real skeleton/clips | NOT TESTED (no asset exists) |

Note: a first run fell off a 40 m floor while sprinting (Fall role was correct); floor enlarged to 120 m.

### Licence facts checked (official sources)
- Mixamo (Adobe FAQ): free with Adobe ID; characters and animations royalty-free for personal, commercial and non-profit projects incl. games; do not redistribute them as standalone assets.
- Quaternius Universal Base Characters: CC0, FBX + glTF, about 13k tris, humanoid rig, "stylized" (not realistic).
- Godot imports FBX natively (4.3+); retargeting via BoneMap + SkeletonProfileHumanoid.

### Outstanding
- Obtain the first character (see CLAUDE_HANDOVER.md). Then test real model + clips in the scene above before any change to `player.tscn`.

## 2026-11-09: Jack Carter isolated test (character_visual_test scene only)

Files changed: `scripts/visual/character_visual.gd`, `scripts/visual/character_visual_test.gd`. Backups: `scripts/visual/backups/*.bak_20261107_before_jack_test`. Production player, Mission 01, weapons, enemies, project.godot and input actions untouched.

- Clip matching is now deterministic (override map, exact match, then partial match skipping weapon/action clips). Synthetic-name test: PASS (8/8). Jack: Idle, Walk, Run, Run (sprint), Crouch aim idle (crouch idle and crouch walk), Jump, Fall: PASS.
- Facing: Jack_Carter.fbx faces +Z. Demonstrated by walking him away from the camera with his face toward it. 180 degree yaw applied (test script setting only). Verified correct afterwards.
- Root motion: Idle, Walk, Run, Jump drift 0.000 to 0.001 m, so lock_hips_xz NOT needed (left off). The Fall clip drifts 0.52 m.
- Fall clip is a knockdown (Jack ends lying on his back), not an in-air loop. Unsuitable for airborne role; candidate for death/knockdown.
- Jack mesh has no fused weapon. WeaponR placeholder attaches and follows the hand; its +Z axis points about 35 degrees too far down in the pistol aim pose (needs a corrective offset).
- Performance (vsync off, runtime only), 1 / 6 / 11 Jacks: 2.2 / 6.8 / 11.8 ms per frame, about 454 / 147 / 85 FPS, 55 / 255 / 455 draw calls.
- Original player verified in test_arena: moves, jumps (0.40 m), no warnings or errors.
- Screenshots: `docs/jack_test_screenshots/`.

## 2026-11-09: Phase 2 weapon attach, aim, fire (test scene only)

Files changed: `scripts/visual/character_visual.gd`, `scripts/visual/character_visual_test.gd`. Backups: `scripts/visual/backups/*.bak_20261109_before_phase2`. WeaponHolder, player controller, Mission 01, weapons data untouched.

- Pistol and rifle test visuals are pivots on the WeaponR attachment; grip rotation -35 degrees X (both) levels them. Production WeaponModel box is hidden (not modified).
- CharacterVisual reads `is_aiming`, `fired`, `weapon_changed`. Aim clips: Pistol aim / Rifle aim idle; fire clips: Pistol fire / Rifle fire (full auto); aim stance held 1.2 s after a shot.
- Layered blending (two AnimationPlayers, in-memory upper/lower clip copies): used for pistol walking while aiming. Rifle uses Rifle walk (aiming).
- Verified in running game: pistol idle, pistol aim, rifle aim, rifle fire, rifle walk aimed, pistol layered walk, release aim, weapon switch.
- (See Phase 3A entry below for the follow-up work.)
- Open: tracers still start at the hidden production box (needs approval to change weapon_holder.gd); left hand not IK'd to rifle foregrip; no aim pitch; pistol fire pose and rifle idle (weapon lowered) not closely inspected.

## 2026-11-09: Phase 3A weapon animation polish (test scene only)

Files changed: `scripts/visual/character_visual.gd`, `scripts/visual/character_visual_test.gd`; new `scripts/visual/aim_pitch_modifier.gd`; `docs/DEVLOG.md`. Backups: `scripts/visual/backups/*.bak_20261109_before_phase3a`. WeaponHolder, player controller, Mission 01, project.godot untouched.

- Left-hand rifle IK: TwoBoneIK3D (LeftArm, LeftForeArm, LeftHand) with a target on the rifle handguard and an elbow pole node; influence fades to 1 for the rifle and 0 for the pistol. Hand sits on the handguard in aim, with no visible stretching.
- Aim pitch: new AimPitchModifier (SkeletonModifier3D) spreads camera pitch over Spine/Spine1/Spine2 (clamped +45 / -40 degrees, smoothed). Hips and legs untouched. Read-only use of the camera rig's aim direction.
- Pistol fire: it was not a bug. Events show fired -> Pistol fire within 17 ms -> back to Pistol aim after 0.5 s; the earlier screenshot was taken after the 0.5 s clip had ended.
- Rifle idle: plain Idle left the rifle hanging from one hand. Rifle now uses the two-handed "Pistol idle (low ready)" clip, so low-ready -> aim -> fire -> low-ready reads naturally.
- Screenshots: `docs/jack_test_screenshots/18..28`.
- Open: tracer origin still the hidden production box; rifle Walk/Run (not aiming) keep the plain clips; spine lean-back at high upward pitch is noticeable; hand rotation on the foregrip not tuned; placeholder box rifle, not final art.

## 2026-11-09: Phase 3B weapon animation polish (test scene only)

Files changed: `scripts/visual/character_visual.gd`, `scripts/visual/character_visual_test.gd`, `scripts/visual/aim_pitch_modifier.gd`; new `scripts/visual/hand_align_modifier.gd`. Backups: `scripts/visual/backups/*.bak_20261109_before_phase3b` (character_visual, character_visual_test, aim_pitch_modifier). Production player, WeaponHolder, Mission 01 untouched.

- Live aim test: a second camera ("SideCam") was added at runtime for side views while the real camera rig kept driving aim. Real aim input, live camera pitch/yaw; no forced clips.
- Aim pitch: spine weight moved up the chain (Spine 0.08, Spine1 0.2, Spine2 0.27), head 0.25 and upper arms 0.45 each add the rest, so the weapon still reaches the full angle but the torso no longer leans back. Max up angle 45 -> 40.
- Left hand grip: new HandAlignModifier (after the IK) turns LeftHand to the rifle handguard target; offset (-90, 0, 180) degrees gives a straight wrist with fingers wrapped over the handguard. Other offsets (0; +90; -90 with 0 or 90 roll) bent the wrist or put the hand under the rifle.
- Rifle ready walk/run: legs use lower-body Walk/Run, upper body holds the two-handed "Pistol idle (low ready)" clip (per-weapon "ready_walk" flag, rifle only). The plain Walk/Run clips are unchanged and still used for the pistol and when the flag is off.
- Screenshots: `docs/jack_test_screenshots/29..39`.
- Open: tracer origin (needs WeaponHolder change); pitch and ready-walk upper body use the static low-ready pose (no arm bob while running); hand is the stock open-hand mesh (no finger curl); placeholder box weapons.

## 2026-11-11: Phase 3C crouch and prone (test scene only)

Files changed: `scripts/visual/character_visual.gd`, `scripts/visual/character_visual_test.gd`. New: `scripts/visual/stance_modifier.gd` (class StanceModifier). Backups: `scripts/visual/backups/*.bak_20261110_before_phase3c` (character_visual 21531 B, character_visual_test 16495 B). Production player, WeaponHolder, Mission 01, project.godot and Jack's FBX untouched.

- Found on resume: the implementation and screenshots 40..49 already existed from an earlier pass but were undocumented. They were re-tested live this session; screenshots 50..65 are the verification set (50 is a side view blocked by the red marker; 52 and 53 were re-taken after an input failure).
- Crouch: no node scaling. StanceModifier drops and leans the hips and re-solves both legs with two-bone IK so the animated feet stay planted; it works on top of any clip. Crouch walk plays Walk at 0.55x. Verified: pistol and rifle crouch idle, rifle crouch aim, rifle full-auto crouch fire, crouch walk.
- Prone: posed per bone (hips on the ground, legs behind, torso propped on elbows, rifle placed by IK in both hands); the character node is not rotated. Verified: rifle prone idle, aim, sniper aim (X), sniper fire (recoil kick only), pistol prone aim, crawl at 0.9 m/s with alternating legs, pitch up/down following the camera (limits +28 / -10 deg).
- Test controls: Z toggles prone, X toggles sniper pose, F9 cycles the debug camera. Prone uses the crouch capsule and slows movement via the player's private _want_crouch / crouch_speed set at runtime from the test script; player_controller.gd is unchanged.
- Transitions verified: crouch <-> stand, prone -> crouch, crouch -> stand. A crouch -> prone midway frame exists only in screenshot 45 (earlier pass); screenshot latency is longer than the 0.8 s blend, so mid-blend frames were not caught this session.
- Console: 0 errors, 0 warnings; project validate 0 issues.
- Open (3C list, partly resolved in 3C.1 below): crawl leg lift is high (crawl_leg_lift 1.0, consider 0.6); no get-down animation (pure pose blend); weapon switching while prone tested pistol and rifle only; horizontal camera turn tested by setting _yaw, not by mouse; no ground-penetration measurement beyond visual check; Jack has no crouch/prone clips (only "Crouch aim idle"), so poses are procedural.

## 2026-11-12: Phase 3C.1 crouch and prone polish (test scene only)

Files changed: `scripts/visual/stance_modifier.gd` (one value: `crawl_leg_lift` 1.0 -> 0.6), `docs/DEVLOG.md`. New support files: `scripts/visual/tools/backup_tool.gd`, `scripts/visual/tools/verify_tool.gd`, `scenes/test/backup_tool.tscn`, `scenes/test/verify_tool.tscn` (copy files and print SHA-256; run with godot_run_start mode "process"). Production player, WeaponHolder, Mission 01, project.godot, Jack's FBX and textures untouched.

Backups (`scripts/visual/backups/*.bak_20261112_before_phase3c1`), SHA-256 recorded before editing and re-checked after:
- character_visual.gd 25878 B: 63d824b3bf303f2dc21fc161934fa197f1ccdda6c5113476c14152b893a21719 (backup identical to current file)
- character_visual_test.gd 19228 B: ff79323d7493907f132cc5ba0e45af239448738c8a059ef9ee852dda56f73547 (backup identical to current file)
- stance_modifier.gd 11459 B: 9a3d13868234eb5d17d3a1c7cb4dd7600aaf1ba61d8a948de609a980b42057ac (backup of the pre-edit file; the edited file is now 2e922c85060d4d22cf0192f8537d38f7cceafc83165f6f239d3008f639ae1e18)
These backups were compared with the working files of that moment only; no earlier original was available to compare against.

- Crawl: 0.6 kept after visual checks at 0.9 m/s (front 3/4 and side). Legs alternate; the raised foot is a bent knee draw about knee height, the trailing foot rests on the ground, no visible floor penetration.
- Tests (all live, test scene): standing -> prone and prone -> standing (frames at 12%, 44%, 97% prone and 65% while standing up, captured at 0.04x game speed); pistol crouch aim, fire (log: Pistol fire 0.5 s then Pistol aim) and aimed crouch walk; mouse-drag yaw while prone (yaw changed 0 -> 0.23 rad); mouse-drag pitch while crouched (reached the -60 deg camera limit); pitch up/down via camera _pitch while crouched and prone; 11 consecutive stance changes ending standing with consistent STANCE log lines. Console 0 errors, 0 warnings.
- Test artifact: holding crawl for about a minute carried the player off the 120 m test floor (fell to y=-6909). Not a stance bug; the player was reset.
- Ground contact: visual checks only (side and front 3/4). No physics-based contact measurement exists for the skeleton, so penetration of a few centimetres cannot be ruled out.
- Limitations: no get-down animation (stand -> prone is a pose blend that passes through a plank-like leaning pose); no separate prone fire clip (recoil kick only); no dedicated crawl clip (procedural leg draw, arms do not move); mouse vertical drag in the test scene only reached the downward limit, so upward pitch was set directly; a pure front view camera is not available (only side and front 3/4).

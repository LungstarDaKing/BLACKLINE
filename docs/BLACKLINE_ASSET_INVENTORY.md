# BLACKLINE Asset Inventory

Last updated: 2026-11-07. Status: Jack Carter VERIFIED. All other characters UNVERIFIED (not currently in the project).
Originals in `C:\Users\mthet\Downloads\Game assets` were never touched.

## Audit status

| Check | Status |
|---|---|
| Original folder listing (14 FBX, 5 empty car folders) | DONE (2026-11-07, from the first copy into `assets/_incoming`) |
| Role mapping | DONE from folder and filenames only |
| Jack Carter mesh / skeleton / skin / animations | VERIFIED (see section below) |
| Other 13 characters: rig, skin, animations | NOT VERIFIED. Their FBX files are no longer in the project. |
| Weapons | NO weapon files supplied |
| Vehicles | All 5 vehicle folders were EMPTY in the copy. Originals not checked. |
| Map assets | NONE found |

## Current project state (2026-11-07)

`res://assets/_incoming/` now holds only Jack Carter:

```
Jack_Carter.fbx          13,020,076 B   (+ .import)
Jack_Carter_0.png ... Jack_Carter_10.png   (11 textures auto-extracted from the FBX, about 8.5 MB total on disk)
```

The other 13 character FBX files and the CARS/PEOPLE sub-folders are no longer under `res://`. They remain in Downloads (not verified here).

## Original folder structure (first copy, for reference)

```
CARS/  BMW/ GTI/ HILUX/ MERCEDES/ RAPTOR/        (all 5 EMPTY)
PEOPLE/
  ANTAGONIST/                    Crime_Thriller_Antagonist.fbx            14,940,508 B
  ARMED RESPONSE OFFICER/        Armed_Response_Officer.fbx               19,685,164 B
  CIVILIAN 1- YOUNG MAN/         Cape_Town_Urban_Male.fbx                 15,826,732 B
  CIVILIAN 2- YOUNG WOMAN/       Realistic_Casual_City_Woman.fbx          15,519,148 B
  CIVILIAN 3- BUSINESS MAN/      Business_Commuter.fbx                    13,477,884 B
  CIVILIAN 4-MATURE WOMAN/       Mature_City_Pedestrian.fbx               15,530,172 B
  CIVILIAN 5- OLDER PEDESTRIAN/  Realistic_Elderly_Civilian_Male.fbx      13,938,764 B
  CIVILIAN 6- SHOPCAFE WORKER/   Cafe_Worker.fbx                          14,111,100 B
  CORRUPT PATROL OFFICER/        Patrol_Officer.fbx                       16,581,100 B
  CORRUPT SENIOR POLICE OFFICER/ Corrupt_Senior_Police_Officer.fbx        16,559,404 B
  CRIMINAL GANG MEMBER/          Cape_Town_Street_Criminal.fbx            14,969,948 B
  CRIMINAL LIEUTENANT/           Cape_Town_Criminal_Lieutenant.fbx        17,632,828 B
  JACK/                          Jack_Carter.fbx                          13,020,076 B
  PRIVATE SECURITY GUARD/        Cape_Town_Private_Security_Guard.fbx     19,835,868 B
```

14 files, all `.fbx`, about 221.6 MB. No `.glb`, `.gltf`, `.obj`, separate texture or animation files.

## Character-to-role mapping

| Role | File | Confidence |
|---|---|---|
| Jack Carter (protagonist) | Jack_Carter.fbx | Certain, VERIFIED |
| Main antagonist | Crime_Thriller_Antagonist.fbx | Certain (folder name) |
| Corrupt senior police officer | Corrupt_Senior_Police_Officer.fbx | Certain |
| Corrupt patrol officer | Patrol_Officer.fbx | Certain |
| Armed response officer | Armed_Response_Officer.fbx | Certain |
| Private security guard | Cape_Town_Private_Security_Guard.fbx | Certain |
| Criminal gang member | Cape_Town_Street_Criminal.fbx | Certain |
| Criminal lieutenant | Cape_Town_Criminal_Lieutenant.fbx | Certain |
| Civilian 1 (young man) | Cape_Town_Urban_Male.fbx | Certain |
| Civilian 2 (young woman) | Realistic_Casual_City_Woman.fbx | Certain |
| Civilian 3 (business man) | Business_Commuter.fbx | Certain |
| Civilian 4 (mature woman) | Mature_City_Pedestrian.fbx | Certain |
| Civilian 5 (older pedestrian) | Realistic_Elderly_Civilian_Male.fbx | Certain |
| Civilian 6 (shop/cafe worker) | Cafe_Worker.fbx | Certain |
| Police/security supervisor | NO FILE | MISSING / AMBIGUOUS: reuse the senior officer, or not supplied. Decision needed. |

Mapping is by folder and filename only (except Jack).

## Jack Carter: verified findings (imported scene `res://assets/_incoming/Jack_Carter.fbx`)

Method: read the imported `.scn` through the Godot MCP tools. No in-game code evaluation was available (disabled on the MCP server), so per-vertex data was not read.

**Hierarchy (5 nodes):** `Jack_Carter` (Node3D) > `Armature` (Node3D) > `Skeleton3D` > `Jack_Carter` (MeshInstance3D); plus `AnimationPlayer`. Scale 1.0, metres, no weapon node.

**Skinning:** the mesh is a child of Skeleton3D with an embedded Skin of 53 named binds. The 16 unbound bones are the 10 fingertips, HeadTop_End, 4 toe bones and WeaponR. Per-vertex weights NOT directly read.

**Bones: 69.** 65 standard Mixamo-named bones (no `mixamorig:` prefix): Hips, Spine, Spine1, Spine2, Neck, Head, HeadTop_End, Left/Right Shoulder, Arm, ForeArm, Hand, Thumb/Index/Middle/Ring/Pinky 1-4, UpLeg, Leg, Foot, ToeBase, Toe_End. Plus Jaw, LeftEye, RightEye and WeaponR (child of RightHand, a weapon attachment point). Rest pose is not a clean T-pose (large rest rotations on hips, spine, legs): humanoid retargeting would need rest fixing.

**Blend shapes:** 33 (visemes, brows, blinks, jaw, mouth, nose).

**Animations (18 clips, embedded in the FBX, one default library, 91 tracks each = 57 bone + 34 blend-shape):**

| Clip | Length (s) | Loop |
|---|---|---|
| Crouch aim idle | 2.5 | none |
| Drive car | 4.0 | none |
| Fall | 1.9 | none |
| Idle | 3.2 | none |
| Jump | 2.1 | none |
| Low punch | 1.55 | none |
| Pistol aim | 2.5 | none |
| Pistol fire | 0.5 | none |
| Pistol idle (low ready) | 3.0 | none |
| Punch | 0.9 | none |
| Ride bicycle | 1.0 | linear |
| Rifle aim idle | 2.5 | none |
| Rifle fire (full auto) | 0.4 | none |
| Rifle strafe left (aiming) | 0.9 | none |
| Rifle walk (aiming) | 1.1 | none |
| Run | 0.7333 | none |
| Throw grenade | 1.5 | none |
| Walk | 1.0667 | none |

**Missing for a third-person action game:** crouch walk, sprint, strafe right and backward, reload, hit reaction, death, interact, vault, roll.

**Not verified:** per-vertex weights, triangle and material counts, texture pixel sizes, root-motion drift in Walk/Run, facing direction (-Z vs +Z), clip loop seams.

**Compatibility notes with the current player:** see `docs/DEVLOG.md` and the Jack integration test plan. Key points: the player script binds `$Visual/Body` and `$Visual/Nose` on ready and resizes them on crouch; the current `CharacterVisual` keyword matching picks `Rifle walk (aiming)` for the walk role (alphabetical first match); crouch walk has no clip.

## Weapons

No weapon files supplied. Jack has no weapon node; fusion of a gun into the mesh is not visually verified (animations show pistol and rifle poses, so a separate weapon model must be attached to `WeaponR`).

## Vehicles

BMW, GTI, HILUX, MERCEDES, RAPTOR folders were empty in the copy. Originals not checked.

## Missing textures

Jack: none missing (11 embedded textures extracted, all present, no missing dependencies). Others: unverified.

## Import problems

- Earlier headless import attempts (2026-11-07 morning) hung. Once the editor was connected, Jack imported cleanly.
- The other 13 FBX have not been imported in this project, so their import behaviour is unknown.

## Which characters need Mixamo

Jack: rig exists, so no auto-rig. He needs extra clips (crouch walk, strafe, reload, death, hit reaction), obtainable from Mixamo through retargeting. Others: cannot be determined until their FBX files are imported.

## Recommended integration order

1. Jack Carter, in the isolated `character_visual_test` scene only.
2. Re-import and inspect the Private Security Guard and Armed Response Officer (Mission 01 enemies).
3. Patrol Officer, Senior Police Officer.
4. Gang Member, Lieutenant, Antagonist.
5. Six civilians.
6. Vehicles, once files are supplied.

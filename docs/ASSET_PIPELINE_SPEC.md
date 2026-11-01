# BLACKLINE Asset Pipeline Technical Specification

**Version:** 1.0
**Date:** 2026-11-01
**Target:** Godot 4.7.2, GL Compatibility Renderer, Windows PC (8 GB RAM, Intel iGPU)

---

## 1. Folder Structure

```
res://assets/
├── characters/
│   ├── player/
│   │   ├── meshes/           # GLB models (LOD0, LOD1, LOD2)
│   │   ├── textures/         # 1K PBR sets (albedo, normal, ORM, emissive)
│   │   ├── animations/       # GLB animation clips
│   │   └── source/           # Blender source files
│   └── enemies/
│       ├── meshes/
│       ├── textures/
│       ├── animations/
│       └── variants/         # Clothing/gear variants
├── weapons/
│   ├── pistol/
│   ├── rifle/
│   ├── attachments/
│   └── source/
├── environment/
│   ├── buildings/
│   │   ├── modular/          # Wall, floor, ceiling, door, window modules
│   │   ├── hero/             # Unique landmark buildings
│   │   └── props/
│   ├── materials/
│   │   ├── concrete/
│   │   ├── metal/
│   │   ├── glass/
│   │   ├── brick/
│   │   └── road/
│   └── vegetation/
├── animations/
│   ├── locomotion/           # Shared: idle, walk, run, sprint, crouch
│   ├── combat/               # Aim, shoot, reload, melee
│   └── reactions/            # Hit, death, stumble
├── audio/
│   ├── footsteps/
│   ├── weapons/
│   ├── ambience/
│   ├── voice/
│   └── ui/
└── vfx/
    ├── muzzle/
    ├── impacts/
    ├── shells/
    └── particles/
```

---

## 2. Asset Naming Conventions

### General Format
```
{category}_{name}_{variant}_{lod}.{ext}
```

### Examples
- `char_player_jack_carter_lod0.glb`
- `char_enemy_guard_tactical_v01_lod0.glb`
- `weap_pistol_glock19_lod0.glb`
- `env_wall_concrete_3x3_lod0.glb`
- `mat_concrete_worn_albedo_1k.png`
- `anim_locomotion_walk.glb`

### Rules
- Lowercase only, underscores as separators
- No spaces, no special characters
- LOD suffix: `_lod0` (high), `_lod1` (med), `_lod2` (low)
- Variant suffix: `_v01`, `_v02`, etc.
- Texture suffixes: `_albedo`, `_normal`, `_orm`, `_emissive`, `_height`

---

## 3. Import Standards (Godot 4.7.2)

### GLB/glTF Settings
| Setting | Value | Notes |
|---------|-------|-------|
| **Format** | GLB (binary glTF 2.0) | Single file, embedded resources |
| **Mesh Compression** | Draco (quantization: 14) | Enable in import dialog |
| **Texture Compression** | Basis Universal (ETC2/ASTC) | VRAM-friendly |
| **Tangents** | Generate (if missing) | Required for normal mapping |
| **Animation** | Import all clips | Loop mode per clip |
| **Skin** | Import bone weights | Max 4 influences/vertex |
| **Materials** | Use GLTF PBR | Metal/Rough workflow |

### Texture Import
| Property | Value |
|----------|-------|
| **Compress** | VRAM (BasisU) |
| **Mipmaps** | Enabled |
| **Filter** | Nearest (pixel art) / Linear (PBR) |
| **Repeat** | Enabled (tiling materials) |
| **sRGB** | Albedo/Emissive only; Normal/ORM = Linear |

### Material Standards
- **Shader:** `StandardMaterial3D` (Godot PBR)
- **Workflow:** Metallic/Roughness (ORM packed: R=Occlusion, G=Roughness, B=Metalness)
- **Shared Materials:** Create `.tres` resources in `assets/environment/materials/`
- **No unique materials per mesh** — reuse material resources

---

## 4. Polygon & Texture Budgets

### Character (Player)
| LOD | Triangles | Texture Resolution | Distance |
|-----|-----------|-------------------|----------|
| LOD0 | 10,000 | 1K (1024²) | 0–15m |
| LOD1 | 4,000 | 512² | 15–30m |
| LOD2 | 1,000 | 256² | 30m+ |

### Enemies (Shared Skeleton)
| LOD | Triangles | Texture Resolution |
|-----|-----------|-------------------|
| LOD0 | 8,000 | 1K |
| LOD1 | 3,000 | 512² |
| LOD2 | 800 | 256² |

### Weapons
| Type | LOD0 Tris | Texture |
|------|-----------|---------|
| Pistol | 4,000 | 512² |
| Rifle | 6,000 | 512² |
| Attachment | 500–1,500 | 256² |

### Environment Modules
| Module | LOD0 Tris | Texture |
|--------|-----------|---------|
| Wall 3×3m | 800 | 512² (tiling) |
| Floor 3×3m | 400 | 512² (tiling) |
| Door | 1,500 | 512² |
| Prop (crate) | 600 | 256² |
| Hero Building | 15,000 | 1K (atlas) |

---

## 5. Skeleton & Animation Standards

### Skeleton Hierarchy (Mixamo-Compatible)
```
Hips
├── Spine
│   ├── Spine1
│   │   ├── Spine2
│   │   │   ├── Neck
│   │   │   │   └── Head
│   │   │   ├── LeftShoulder
│   │   │   │   ├── LeftArm
│   │   │   │   │   ├── LeftForeArm
│   │   │   │   │   │   └── LeftHand
│   │   │   │   │   │       └── LeftHand* (fingers)
│   │   │   │   └── RightShoulder
│   │   │   │       ├── RightArm
│   │   │   │       │   ├── RightForeArm
│   │   │   │       │   │   └── RightHand
│   │   │   │       │   │       └── RightHand* (fingers)
├── LeftUpLeg
│   ├── LeftLeg
│   │   ├── LeftFoot
│   │   │   └── LeftToeBase
└── RightUpLeg
    ├── RightLeg
        ├── RightFoot
            └── RightToeBase
```

### Required Animation Clips (Player)
| Clip | Duration | Loop | Notes |
|------|----------|------|-------|
| `idle` | 3–5s | Yes | Breathing, weight shifts |
| `idle_aim` | 3–5s | Yes | Weapon raised |
| `walk` | 1s | Yes | 1.4 m/s |
| `walk_aim` | 1s | Yes | Weapon raised |
| `run` | 0.8s | Yes | 3.5 m/s |
| `sprint` | 0.6s | Yes | 6.0 m/s |
| `crouch_idle` | 3s | Yes | |
| `crouch_walk` | 1.2s | Yes | |
| `crouch_aim` | 3s | Yes | |
| `jump_start` | 0.3s | No | |
| `jump_air` | 1s | No | |
| `jump_land` | 0.5s | No | |
| `reload_pistol` | 2.5s | No | Root motion optional |
| `reload_rifle` | 3.0s | No | |
| `fire_pistol` | 0.3s | No | Additive upper body |
| `fire_rifle` | 0.2s | No | Additive upper body |
| `melee` | 0.8s | No | |
| `death` | 2s | No | Ragdoll transition at end |

### Animation Import
- **Root Motion:** Disable for locomotion (code-driven), enable for cinematic clips
- **Compression:** Enabled (optimal)
- **Loop:** Set per clip in import dialog

---

## 6. Weapon Integration Architecture

### Extended WeaponData Resource
```gdscript
# res://scripts/weapons/weapon_data.gd (additions)
@export_group("External Model")
@export_file("*.glb") var model_path: String = ""
@export var magazine_bone: StringName = &"magazine"
@export var slide_bone: StringName = &"slide"
@export var muzzle_socket: NodePath = &"muzzle_socket"
@export var ejection_socket: NodePath = &"ejection_socket"
@export var left_hand_ik_target: NodePath = &"left_hand_ik"
@export var right_hand_ik_target: NodePath = &"right_hand_ik"
```

### WeaponHolder Changes (Minimal)
- Load GLB at `model_path` instead of procedural BoxMesh
- Find bones/sockets by name for magazine, slide, muzzle, ejection
- Play animation clips on reload/fire via `AnimationPlayer`
- Keep all existing logic: ammo, spread, recoil, damage, switching

---

## 7. Environment Modular Kit Specification

### Core Modules (Grid: 3m × 3m)
| Module | Dimensions | Variants | Collision |
|--------|------------|----------|-----------|
| `wall_straight` | 3×3×0.3m | Plain, window, door_frame, vent | Box |
| `wall_corner_90` | 3×3×0.3m | Convex, concave | Box |
| `wall_corner_45` | 3×3×0.3m | Convex, concave | Box |
| `floor_tile` | 3×3×0.2m | Concrete, tile, grate, raised | Box |
| `ceiling_tile` | 3×3×0.2m | Plain, vent, light_mount | Box |
| `door_sliding` | 3×3.5×0.1m | Single, double, airlock | Box (animated) |
| `door_hinged` | 1.2×2.5×0.1m | Left, right, double | Box (animated) |
| `column` | 0.6×0.6×3m | Round, square, pilaster | Cylinder/Box |
| `beam` | 6×0.4×0.4m | Steel, concrete, wood | Box |

### Hero Buildings (Unique)
- `castle_good_hope` — Pentagonal fort, 5 bastions
- `city_hall` — Edwardian, clock tower, colonnade
- `greenmarket_square` — Historic market building
- `long_street_facade` — Victorian commercial row

### Material Sharing Strategy
- **Concrete:** 3 variants (clean, worn, damaged) → shared by walls, floors, columns
- **Metal:** 2 variants (painted, rusted) → doors, beams, railings
- **Glass:** 2 variants (clear, reflective) → windows, storefronts
- **Brick/Stone:** 2 variants → heritage buildings, pavements
- **Road/Asphalt:** 2 variants (new, worn) → roads, parking

---

## 8. Performance Budgets (Target: 60 FPS on Intel iGPU)

| Metric | Budget | Measurement |
|--------|--------|-------------|
| **Draw Calls** | < 150 | `RenderInfo` in debug |
| **Triangles/Frame** | < 500k | LOD critical |
| **Texture Memory** | < 512 MB | Compressed VRAM |
| **Shader Changes** | < 50 | Material sharing |
| **Dynamic Lights** | ≤ 4 | Shadow-casting |
| **Shadow Map** | 1024² (sun) | Directional only |
| **Post-Process** | Minimal | Bloom off, DOF off |
| **Physics Objects** | < 200 active | Static preferred |

### Optimization Rules
1. **Static geometry** → `StaticBody3D` (not RigidBody)
2. **Occlusion** → Use `Portal`/`Room` system for interiors
3. **LOD** → Mandatory on all meshes > 1k tris
4. **Instancing** → `MultiMeshInstance3D` for repeated props (streetlights, signs)
5. **Texture Atlases** → Pack multiple albedo/ORM into 1K/2K atlases
6. **Baked Lighting** → `LightmapGI` for static interiors, no real-time GI

---

## 9. Cape Town Geographic Coordinate System

### Local Scene Origin
- **Scene (0,0,0)** = Intersection of **Long Street** & **Strand Street**
- **X+** = East (towards Wale Street, Bo-Kaap)
- **Z+** = South (away from Table Mountain, towards Buitengracht)
- **Y+** = Up (meters above street level)

### WGS84 → Scene Conversion (Approximate)
```
scene_x = (lon - 18.4195) * 111_320 * cos(-33.92°)  # ~92,000 m/degree
scene_z = (lat - (-33.9185)) * 111_320               # ~111,320 m/degree
```

### Key Reference Points (Scene Coordinates)
| Landmark | Scene (X, Z) | WGS84 (Lat, Lon) |
|----------|--------------|------------------|
| Long & Strand | (0, 0) | -33.9185, 18.4195 |
| Long & Buitengracht | (0, 200) | -33.9205, 18.4195 |
| Wale & Strand | (180, 0) | -33.9185, 18.4215 |
| Wale & Buitengracht | (180, 200) | -33.9205, 18.4215 |
| Castle of Good Hope | (900, 800) | -33.9265, 18.4285 |
| City Hall | (-700, 800) | -33.9245, 18.4245 |
| Grand Parade | (-400, 800) | -33.9245, 18.4245 |
| Greenmarket Square | (-400, -400) | -33.9205, 18.4185 |
| Table Mountain peak | (0, -10000+) | -33.9628, 18.4098 |

---

## 10. Data Sources & Licensing

| Source | Data Type | License | Attribution |
|--------|-----------|---------|-------------|
| City of Cape Town ODP | GIS, zoning, building footprints | CC BY 4.0 | "Contains information from City of Cape Town Open Data Portal" |
| OpenStreetMap | Street geometry, POIs | ODbL v1.0 | "Contains data from OpenStreetMap contributors" |
| Wikipedia | Landmark descriptions, history | CC BY-SA 3.0 | Per-page attribution |
| Cape Town Tourism | Photography, visitor info | © Cape Town Tourism | Reference only, no asset reuse |

**Compliance:** All derived game assets are transformative works. No raw GIS data distributed with game.

---

## 11. Implementation Checklist

### Phase A: Foundation ✓
- [x] Asset folder structure created
- [x] Naming conventions documented
- [x] Import standards defined
- [x] Polygon/texture budgets set
- [x] Coordinate system documented

### Phase B: Cape Town CBD Blockout ✓
- [x] Scene created: `cape_town_cbd_blockout.tscn`
- [x] Real street grid implemented (8 streets)
- [x] Building massing placed
- [x] Pavements, streetlights, traffic lights, signs added
- [x] Landmark silhouettes (Castle, City Hall, Grand Parade, Greenmarket, Table Mountain)
- [x] Navigation mesh covering playable area
- [x] Player spawn at Long & Strand intersection
- [x] GeoReference node with full documentation

### Phase C: Integration Architecture (Next)
- [ ] Player character integration prep
- [ ] Enemy character integration prep
- [ ] Weapon model integration prep
- [ ] AnimationTree setup for player/enemy

### Phase D: Testing (Next)
- [ ] Open scene in Godot
- [ ] Verify player movement & collisions
- [ ] Check performance (FPS, draw calls, memory)
- [ ] Fix any errors
- [ ] Document results

---

## 12. Recovery & Safety

- **No Git repo** — Manual backup created via file copy before changes
- **Mission 01 untouched** — `mission_01.tscn` and `mission_01.backup` preserved
- **Existing player/enemy/weapon scenes unmodified** — New architecture is additive
- **Blockout uses existing `Block.tscn`** — No new primitive dependencies

---

*End of Specification*
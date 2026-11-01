class_name WeaponData
extends Resource
## Describes one weapon. Create a .tres of this resource per weapon and add it
## to a WeaponHolder; no code changes are needed to add new weapons.

@export var display_name: String = "Pistol"
@export var damage: float = 25.0
## Seconds between shots.
@export var fire_interval: float = 0.3
## true: hold to keep firing. false: one shot per click.
@export var automatic: bool = false
@export var magazine_size: int = 12
@export var starting_reserve: int = 36
@export var max_reserve: int = 120
@export var reload_time: float = 1.3
@export var max_range: float = 80.0
## Random cone half-angle in degrees (0 = perfectly accurate).
@export var spread_degrees: float = 0.6
## Rays per shot (more than 1 gives a shotgun-style pattern).
@export var pellets: int = 1
## Camera kick per shot in degrees.
@export var recoil_degrees: float = 1.2

@export_group("Placeholder model")
@export var model_size: Vector3 = Vector3(0.08, 0.13, 0.4)
@export var model_color: Color = Color(0.12, 0.12, 0.14)

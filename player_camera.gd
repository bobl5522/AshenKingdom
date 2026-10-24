extends Node3D

## Настройки камеры игрока.
@export var mouse_sensitivity: float = 0.0025
@export var min_pitch: float = -0.8
@export var max_pitch: float = 0.45
@export var initial_pitch: float = -0.12
@export var camera_distance: float = 4.5
@export var camera_height: float = 0.5
@export var pivot_height: float = 1.5
@export var camera_fov: float = 75.0

var camera: Camera3D


func _ready() -> void:
    name = "CameraController"
    position.y = pivot_height
    rotation.x = clampf(initial_pitch, min_pitch, max_pitch)
    _create_camera()


func _create_camera() -> void:
    camera = Camera3D.new()
    camera.name = "PlayerCamera"
    camera.position = Vector3(0.0, camera_height, camera_distance)
    camera.fov = camera_fov
    camera.current = true
    add_child(camera)


func _unhandled_input(event: InputEvent) -> void:
    if not event is InputEventMouseMotion:
        return

    if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
        return

    var player := get_parent() as CharacterBody3D
    if player == null:
        return

    player.rotate_y(-event.relative.x * mouse_sensitivity)

    rotation.x = clampf(
        rotation.x - event.relative.y * mouse_sensitivity,
        min_pitch,
        max_pitch
    )
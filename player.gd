extends CharacterBody3D

const PLAYER_CAMERA_SCRIPT = preload("res://player_camera.gd")

const PLAYER_DEBUG_UI_SCRIPT = preload("res://player_debug_ui.gd")

@export var movement_config: PlayerConfig = preload("res://player_config.tres")
var debug_ui: CanvasLayer
var jump_requested: bool = false


func _ready() -> void:
    name = "Player"
    _create_collision()
    _create_visuals()
    _create_camera_controller()
    _create_debug_ui()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _create_collision() -> void:
    var collision := CollisionShape3D.new()
    collision.name = "PlayerCollision"

    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.4
    capsule.height = 1.8

    collision.shape = capsule
    collision.position.y = 0.9
    add_child(collision)


func _create_visuals() -> void:
    var body := MeshInstance3D.new()
    body.name = "BodyMesh"

    var body_mesh := CapsuleMesh.new()
    body_mesh.radius = 0.4
    body_mesh.height = 1.8
    body.mesh = body_mesh
    body.position.y = 0.9
    body.material_override = _make_material(Color(0.20, 0.22, 0.24))
    add_child(body)

    var head := MeshInstance3D.new()
    head.name = "HeadMesh"

    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.24
    head_mesh.height = 0.48
    head.mesh = head_mesh
    head.position.y = 1.65
    head.material_override = _make_material(Color(0.55, 0.42, 0.32))
    add_child(head)


func _make_material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.85
    return material


func _create_camera_controller() -> void:
    var camera_controller := Node3D.new()
    camera_controller.name = "CameraController"
    camera_controller.set_script(PLAYER_CAMERA_SCRIPT)
    add_child(camera_controller)


func _create_debug_ui() -> void:
    debug_ui = CanvasLayer.new()
    debug_ui.set_script(PLAYER_DEBUG_UI_SCRIPT)
    add_child(debug_ui)


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("jump", false):
        jump_requested = true

    if event.is_action_pressed("toggle_mouse_capture", false):
        if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        else:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
    _apply_gravity(delta)
    _handle_jump()
    _handle_horizontal_movement(delta)
    move_and_slide()

    if is_instance_valid(debug_ui):
        debug_ui.update_debug(self)


func _apply_gravity(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= movement_config.gravity * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0


func _handle_jump() -> void:
    if jump_requested and is_on_floor():
        velocity.y = movement_config.jump_velocity

    jump_requested = false


func _handle_horizontal_movement(delta: float) -> void:
    var input_vector := Input.get_vector(
        "move_left",
        "move_right",
        "move_forward",
        "move_backward"
    )
    var sprinting := Input.is_action_pressed("sprint")

    var move_direction := (
        transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)
    ).normalized()

    var target_speed: float = (
        movement_config.sprint_speed
        if sprinting
        else movement_config.walk_speed
    )
    var acceleration_rate: float = (
        movement_config.acceleration
        if input_vector.length_squared() > 0.0
        else movement_config.deceleration
    )

    var target_x := move_direction.x * target_speed
    var target_z := move_direction.z * target_speed

    velocity.x = move_toward(velocity.x, target_x, acceleration_rate * delta)
    velocity.z = move_toward(velocity.z, target_z, acceleration_rate * delta)
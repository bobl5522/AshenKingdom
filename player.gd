extends CharacterBody3D

const PLAYER_CAMERA_SCRIPT = preload("res://player_camera.gd")
const PLAYER_DEBUG_UI_SCRIPT = preload("res://player_debug_ui.gd")
const PLAYER_INTERACTION_SCRIPT = preload("res://interaction_controller.gd")

@export var movement_config: PlayerConfig = preload("res://player_config.tres")

@export_group("Jump")
@export_range(0.0, 0.3, 0.01) var jump_buffer_duration: float = 0.12
@export_range(0.0, 0.3, 0.01) var coyote_time_duration: float = 0.10
@export_range(0.1, 1.0, 0.05) var jump_release_multiplier: float = 0.45

@export_group("Air Control")
@export_range(0.0, 1.0, 0.05) var air_control_multiplier: float = 0.45

var debug_ui: CanvasLayer
var jump_buffer_remaining: float = 0.0
var coyote_time_remaining: float = 0.0


func _ready() -> void:
    name = "Player"
    _create_collision()
    _create_visuals()
    _create_camera_controller()
    _create_debug_ui()
    _create_player_stats()
    _create_interaction_controller()
    _create_interaction_test_object()
    _create_combat_controller()
    _create_combat_test_target()
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


func _create_interaction_controller() -> void:
    var interaction_controller := Node3D.new()
    interaction_controller.name = "InteractionController"
    interaction_controller.set_script(PLAYER_INTERACTION_SCRIPT)
    add_child(interaction_controller)

func _create_interaction_test_object() -> void:
    var world := get_tree().current_scene

    if world == null:
        push_warning("Interaction test object: current_scene РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚.")
        return

    if world.get_node_or_null("InteractionTestObject") != null:
        return

    var target := StaticBody3D.new()
    target.name = "InteractionTestObject"
    target.set_script(preload("res://interactable_object.gd"))
    target.collision_layer = 1
    target.collision_mask = 1
    target.add_to_group("interactable")

    var collision := CollisionShape3D.new()
    collision.name = "CollisionShape3D"

    var box_shape := BoxShape3D.new()
    box_shape.size = Vector3(1.2, 1.8, 0.6)
    collision.shape = box_shape
    collision.position.y = 0.9
    target.add_child(collision)

    var mesh := MeshInstance3D.new()
    mesh.name = "MeshInstance3D"

    var box_mesh := BoxMesh.new()
    box_mesh.size = Vector3(1.2, 1.8, 0.6)
    mesh.mesh = box_mesh

    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.45, 0.25, 0.12)
    material.roughness = 0.75
    mesh.material_override = material
    mesh.position.y = 0.9
    target.add_child(mesh)

    var target_position: Vector3 = (
        global_position - global_transform.basis.z * 3.0
    )

    # Р”РѕР±Р°РІР»СЏРµРј РѕР±СЉРµРєС‚ РїРѕСЃР»Рµ Р·Р°РІРµСЂС€РµРЅРёСЏ РЅР°СЃС‚СЂРѕР№РєРё РґРµСЂРµРІР° СЃС†РµРЅС‹.
    call_deferred(
        "_attach_interaction_test_object",
        world,
        target,
        target_position
    )


func _attach_interaction_test_object(
    world: Node,
    target: StaticBody3D,
    target_position: Vector3
) -> void:
    if not is_instance_valid(world) or not is_instance_valid(target):
        return

    if target.is_inside_tree():
        return

    world.add_child(target)
    target.global_position = target_position
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("jump", false):
        jump_buffer_remaining = jump_buffer_duration

    if event.is_action_released("jump"):
        if velocity.y > 0.0:
            velocity.y *= jump_release_multiplier

    if event.is_action_pressed("toggle_mouse_capture", false):
        if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        else:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
    _update_jump_timers(delta)
    _apply_gravity(delta)
    _handle_jump(delta)
    _handle_horizontal_movement(delta)

    move_and_slide()

    if is_instance_valid(debug_ui):
        debug_ui.update_debug(self)


func _update_jump_timers(delta: float) -> void:
    if is_on_floor():
        coyote_time_remaining = coyote_time_duration
    else:
        coyote_time_remaining = maxf(
            coyote_time_remaining - delta,
            0.0
        )

    if jump_buffer_remaining > 0.0:
        jump_buffer_remaining = maxf(
            jump_buffer_remaining - delta,
            0.0
        )


func _apply_gravity(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= movement_config.gravity * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0


func _handle_jump(_delta: float) -> void:
    if jump_buffer_remaining <= 0.0:
        return

    var can_jump := is_on_floor() or coyote_time_remaining > 0.0
    if not can_jump:
        return

    velocity.y = movement_config.jump_velocity
    jump_buffer_remaining = 0.0
    coyote_time_remaining = 0.0


func _handle_horizontal_movement(delta: float) -> void:
    var input_vector := Input.get_vector(
        "move_left",
        "move_right",
        "move_forward",
        "move_backward"
    )

    var sprinting := Input.is_action_pressed("sprint")
    var stats := get_node_or_null("PlayerStats")
    if stats != null and not stats.is_alive():
        velocity.x = 0.0
        velocity.z = 0.0
        stats.set_sprinting(false)
        return
    if sprinting and stats != null:
        sprinting = stats.try_consume_stamina(22.0 * delta)
    if stats != null:
        stats.set_sprinting(sprinting)
    var move_direction := (
        transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)
    ).normalized()

    var target_speed: float = (
        movement_config.sprint_speed
        if sprinting
        else movement_config.walk_speed
    )

    var has_input := input_vector.length_squared() > 0.0
    var acceleration_rate: float = (
        movement_config.acceleration
        if has_input
        else movement_config.deceleration
    )

    if not is_on_floor():
        acceleration_rate *= air_control_multiplier

    var target_x := move_direction.x * target_speed
    var target_z := move_direction.z * target_speed

    velocity.x = move_toward(
        velocity.x,
        target_x,
        acceleration_rate * delta
    )
    velocity.z = move_toward(
        velocity.z,
        target_z,
        acceleration_rate * delta
    )


func _create_player_stats() -> void:
    if get_node_or_null("PlayerStats") != null:
        return

    var stats := Node.new()
    stats.name = "PlayerStats"
    stats.set_script(preload("res://player_stats.gd"))
    add_child(stats)


# ------------------------------------------------------------------
# Combat system bootstrap
# ------------------------------------------------------------------

func _create_combat_controller() -> void:
    if get_node_or_null("CombatController") != null:
        return

    var controller := Node.new()
    controller.name = "CombatController"
    controller.set_script(preload("res://combat_controller.gd"))
    add_child(controller)


func _create_combat_test_target() -> void:
    if get_tree().get_first_node_in_group("combat_test_target") != null:
        return

    call_deferred("_spawn_combat_test_target")


func _spawn_combat_test_target() -> void:
    if not is_inside_tree():
        return

    if get_tree().get_first_node_in_group("combat_test_target") != null:
        return

    var scene_root: Node = get_tree().current_scene
    if scene_root == null:
        push_warning("Combat test target: scene root not found.")
        return

    var target := Node3D.new()
    target.name = "CombatTestTarget"
    target.set_script(preload("res://combat_test_target.gd"))

    var forward := -global_transform.basis.z.normalized()
    var spawn_global := global_position + forward * 2.2
    target.position = scene_root.to_local(spawn_global)

    scene_root.call_deferred("add_child", target)

extends CharacterBody3D

const WALK_SPEED: float = 4.0
const SPRINT_SPEED: float = 7.0
const JUMP_VELOCITY: float = 4.5
const GRAVITY: float = 12.0
const MOUSE_SENSITIVITY: float = 0.0025

var pitch: float = -0.12
var camera_pivot: Node3D
var debug_label: Label


func _ready() -> void:
    name = "Player"

    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.4
    capsule.height = 1.8
    collision.shape = capsule
    collision.position.y = 0.9
    add_child(collision)

    var body := MeshInstance3D.new()
    var body_mesh := CapsuleMesh.new()
    body_mesh.radius = 0.4
    body_mesh.height = 1.8
    body.mesh = body_mesh
    body.position.y = 0.9
    body.material_override = _make_material(Color(0.20, 0.22, 0.24))
    add_child(body)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.24
    head_mesh.height = 0.48
    head.mesh = head_mesh
    head.position.y = 1.65
    head.material_override = _make_material(Color(0.55, 0.42, 0.32))
    add_child(head)

    camera_pivot = Node3D.new()
    camera_pivot.position.y = 1.5
    add_child(camera_pivot)

    var camera := Camera3D.new()
    camera.position = Vector3(0.0, 0.5, 4.5)
    camera.rotation.x = pitch
    camera.fov = 75.0
    camera.current = true
    camera_pivot.add_child(camera)

    var ui := CanvasLayer.new()
    add_child(ui)

    debug_label = Label.new()
    debug_label.position = Vector2(16, 16)
    debug_label.add_theme_font_size_override("font_size", 18)
    debug_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))
    ui.add_child(debug_label)

    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _make_material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    return material


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
        pitch = clampf(pitch - event.relative.y * MOUSE_SENSITIVITY, -0.8, 0.45)
        camera_pivot.rotation.x = pitch

    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE:
            if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
                Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
            else:
                Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
    var forward := Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
    var backward := Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
    var left := Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
    var right := Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
    var sprinting := Input.is_physical_key_pressed(KEY_SHIFT)

    var x_input := float(right) - float(left)
    var z_input := float(backward) - float(forward)
    var input_dir := Vector2(x_input, z_input).normalized()

    if not is_on_floor():
        velocity.y -= GRAVITY * delta

    if Input.is_physical_key_pressed(KEY_SPACE) and is_on_floor():
        velocity.y = JUMP_VELOCITY

    var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
    var speed := SPRINT_SPEED if sprinting else WALK_SPEED

    if direction.length_squared() > 0.0:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * 2.0)
        velocity.z = move_toward(velocity.z, 0.0, WALK_SPEED * 2.0)

    move_and_slide()

    if is_instance_valid(debug_label):
        var keys := ""
        if forward:
            keys += " W"
        if backward:
            keys += " S"
        if left:
            keys += " A"
        if right:
            keys += " D"
        if sprinting:
            keys += " Shift"
        if Input.is_physical_key_pressed(KEY_SPACE):
            keys += " Space"
        if keys.is_empty():
            keys = " — нет"

        var horizontal_speed := Vector2(velocity.x, velocity.z).length()
        debug_label.text = "ASHEN KINGDOM — ДИАГНОСТИКА\nWASD / стрелки: ходьба | Shift: бег | Space: прыжок | Esc: мышь\nНажатые клавиши:" + keys + "\nСкорость: %.2f" % horizontal_speed + " | На земле: " + str(is_on_floor()) + "\nПозиция: %.2f, %.2f, %.2f" % [global_position.x, global_position.y, global_position.z]
extends CanvasLayer

var debug_label: Label


func _ready() -> void:
    name = "DebugLayer"
    _create_label()


func _create_label() -> void:
    debug_label = Label.new()
    debug_label.name = "DebugLabel"
    debug_label.position = Vector2(16.0, 16.0)
    debug_label.add_theme_font_size_override("font_size", 16)
    debug_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))
    add_child(debug_label)


func update_debug(player: CharacterBody3D) -> void:
    if not is_instance_valid(debug_label):
        return

    var horizontal_speed := Vector2(player.velocity.x, player.velocity.z).length()
    var mouse_state := (
        "Captured"
        if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
        else "Visible"
    )

    debug_label.text = (
        "ASHEN KINGDOM | CONTROLLER DEBUG\n"
        + "WASD / Arrows: Move | Shift: Sprint | Space: Jump\n"
        + "Esc: Toggle Mouse Capture\n"
        + "Horizontal speed: %.2f\n" % horizontal_speed
        + "Grounded: %s\n" % str(player.is_on_floor())
        + "Mouse: %s\n" % mouse_state
        + "Position: %.2f, %.2f, %.2f" % [
            player.global_position.x,
            player.global_position.y,
            player.global_position.z
        ]
    )
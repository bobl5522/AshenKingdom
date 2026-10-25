extends Node3D

@export_range(1.0, 10.0, 0.5) var interaction_distance: float = 4.0
@export_flags_3d_physics var collision_mask: int = 1

var actor: CharacterBody3D
var prompt_label: Label
var current_target: Object

func _ready() -> void:
    actor = get_parent() as CharacterBody3D
    _ensure_interaction_input()
    _create_prompt_ui()

func _ensure_interaction_input() -> void:
    if not InputMap.has_action("interact"):
        InputMap.add_action("interact")

    var has_e_key := false

    for event in InputMap.action_get_events("interact"):
        if event is InputEventKey:
            if event.physical_keycode == KEY_E:
                has_e_key = true
                break

    if not has_e_key:
        var key_event := InputEventKey.new()
        key_event.physical_keycode = KEY_E
        InputMap.action_add_event("interact", key_event)

func _create_prompt_ui() -> void:
    var layer := CanvasLayer.new()
    layer.name = "InteractionUI"
    add_child(layer)

    prompt_label = Label.new()
    prompt_label.name = "InteractionPrompt"
    prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    prompt_label.position = Vector2(-220.0, -115.0)
    prompt_label.size = Vector2(440.0, 42.0)
    prompt_label.add_theme_font_size_override("font_size", 18)
    prompt_label.add_theme_color_override(
        "font_color",
        Color(0.95, 0.88, 0.68)
    )
    prompt_label.visible = false
    layer.add_child(prompt_label)

func _physics_process(_delta: float) -> void:
    _update_target()

func _update_target() -> void:
    current_target = null

    if actor == null or not is_instance_valid(actor):
        _hide_prompt()
        return

    var camera := get_viewport().get_camera_3d()
    if camera == null:
        _hide_prompt()
        return

    var ray_origin: Vector3 = camera.global_position
    var ray_direction: Vector3 = -camera.global_transform.basis.z
    var ray_end: Vector3 = ray_origin + ray_direction * interaction_distance

    var query := PhysicsRayQueryParameters3D.create(
        ray_origin,
        ray_end,
        collision_mask
    )
    query.exclude = [actor.get_rid()]
    query.collide_with_bodies = true
    query.collide_with_areas = true

    var hit := get_world_3d().direct_space_state.intersect_ray(query)

    if hit.is_empty():
        _hide_prompt()
        return

    var collider: Object = hit.get("collider")

    if collider == null:
        _hide_prompt()
        return

    if not collider.has_method("get_interaction_prompt"):
        _hide_prompt()
        return

    if not collider.has_method("interact"):
        _hide_prompt()
        return

    current_target = collider
    prompt_label.text = "[E] " + str(
        collider.call("get_interaction_prompt")
    )
    prompt_label.visible = true

func _unhandled_input(event: InputEvent) -> void:
    if not event.is_action_pressed("interact"):
        return

    if event.is_echo():
        return

    if current_target == null or not is_instance_valid(current_target):
        return

    if not current_target.has_method("interact"):
        return

    current_target.call("interact", actor)

func _hide_prompt() -> void:
    current_target = null

    if is_instance_valid(prompt_label):
        prompt_label.visible = false
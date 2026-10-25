extends Node

## Базовая система ближнего боя.
## ЛКМ — быстрая атака, ПКМ — тяжёлая атака, Q — блок.

@export var light_damage: float = 12.0
@export var heavy_damage: float = 28.0
@export var light_stamina_cost: float = 8.0
@export var heavy_stamina_cost: float = 20.0
@export var attack_range: float = 2.6
@export var attack_radius: float = 1.0
@export var attack_cooldown: float = 0.38

var _player: CharacterBody3D
var _stats: Node
var _cooldown_remaining: float = 0.0
var _blocking: bool = false


func _ready() -> void:
    _player = get_parent() as CharacterBody3D

    if _player == null:
        push_error("CombatController должен быть дочерним узлом CharacterBody3D.")
        set_process_unhandled_input(false)
        set_physics_process(false)
        return

    _stats = _player.get_node_or_null("PlayerStats")

    if _stats == null:
        push_warning("CombatController: узел PlayerStats пока не найден.")


func _physics_process(delta: float) -> void:
    _cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)


func _unhandled_input(event: InputEvent) -> void:
    if _player == null:
        return

    if event is InputEventMouseButton:
        var mouse_event := event as InputEventMouseButton

        if not mouse_event.pressed:
            return

        if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
            return

        match mouse_event.button_index:
            MOUSE_BUTTON_LEFT:
                _try_attack(false)
                get_viewport().set_input_as_handled()
            MOUSE_BUTTON_RIGHT:
                _try_attack(true)
                get_viewport().set_input_as_handled()

    elif event is InputEventKey:
        var key_event := event as InputEventKey

        if key_event.keycode == KEY_Q:
            _blocking = key_event.pressed and not key_event.echo
            get_viewport().set_input_as_handled()


func _try_attack(is_heavy: bool) -> void:
    if _cooldown_remaining > 0.0:
        return

    if _stats != null and _stats.has_method("is_alive"):
        if not bool(_stats.call("is_alive")):
            return

    var stamina_cost := heavy_stamina_cost if is_heavy else light_stamina_cost

    if _stats != null and _stats.has_method("try_consume_stamina"):
        var consumed: bool = bool(
            _stats.call("try_consume_stamina", stamina_cost)
        )

        if not consumed:
            print("[БОЙ] Недостаточно выносливости.")
            return

    _cooldown_remaining = attack_cooldown

    var damage := heavy_damage if is_heavy else light_damage
    var attack_name := "тяжёлая" if is_heavy else "быстрая"

    print("[БОЙ] ", attack_name, " атака. Урон: ", damage)
    _perform_hit(damage)


func _perform_hit(damage: float) -> void:
    var space_state := _player.get_world_3d().direct_space_state
    var forward := -_player.global_transform.basis.z.normalized()
    var hit_center := (
        _player.global_position
        + Vector3.UP
        + forward * attack_range * 0.65
    )

    var sphere := SphereShape3D.new()
    sphere.radius = attack_radius

    var query := PhysicsShapeQueryParameters3D.new()
    query.shape = sphere
    query.transform = Transform3D(Basis.IDENTITY, hit_center)
    query.collision_mask = 0xFFFFFFFF
    query.exclude = [_player.get_rid()]
    query.collide_with_bodies = true
    query.collide_with_areas = true

    var results := space_state.intersect_shape(query, 32)
    var damaged_targets: Array[Node] = []

    for result in results:
        var collider: Object = result.get("collider")

        if not collider is Node:
            continue

        var target := _find_enemy_root(collider as Node)

        if target == null or damaged_targets.has(target):
            continue

        if target.has_method("apply_damage"):
            damaged_targets.append(target)
            target.call("apply_damage", damage)


func _find_enemy_root(node: Node) -> Node:
    var current: Node = node

    while current != null and current != _player:
        if current.is_in_group("enemies"):
            return current
        current = current.get_parent()

    return null


func is_blocking() -> bool:
    return Input.is_key_pressed(KEY_Q)

func get_incoming_damage_multiplier() -> float:
    return 0.35 if is_blocking() else 1.0


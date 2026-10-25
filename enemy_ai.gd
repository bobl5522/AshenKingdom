extends CharacterBody3D

signal health_changed(current_health: float, maximum_health: float)
signal enemy_defeated

enum State { IDLE, CHASE, WINDUP, DEAD }

@export_category("Характеристики")
@export var max_health: float = 80.0
@export var move_speed: float = 2.8
@export var detection_range: float = 12.0
@export var attack_range: float = 1.65
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.4
@export var attack_windup: float = 0.45
@export var gravity_strength: float = 18.0
@export var stopping_distance: float = 1.25
@export var despawn_delay: float = 2.5

var health: float = 80.0
var state: State = State.IDLE
var attack_timer: float = 0.0
var windup_timer: float = 0.0
var player: Node3D
var player_stats: Node
var combat_controller: Node
var body_mesh: MeshInstance3D
var health_label: Label3D
var original_material: StandardMaterial3D


func _ready() -> void:
    add_to_group("enemy")
    max_health = maxf(1.0, max_health)
    health = max_health
    _ensure_visuals()
    _refresh_health_label()
    _acquire_player()
    health_changed.emit(health, max_health)
    print("[enemy] ИИ готов. HP %.0f/%.0f" % [health, max_health])


func _physics_process(delta: float) -> void:
    if state == State.DEAD:
        return

    attack_timer = maxf(0.0, attack_timer - delta)

    if not is_instance_valid(player):
        _acquire_player()

    if not is_instance_valid(player):
        state = State.IDLE
        _stop_movement(delta)
        return

    if _is_player_dead():
        state = State.IDLE
        _stop_movement(delta)
        return

    var distance := global_position.distance_to(player.global_position)

    if state == State.WINDUP:
        _process_windup(delta, distance)
        return

    if distance > detection_range:
        state = State.IDLE
        _stop_movement(delta)
        return

    if distance <= attack_range and attack_timer <= 0.0:
        state = State.WINDUP
        windup_timer = maxf(0.05, attack_windup)
        _stop_movement(delta)
        _face_player()
        _set_windup_visual(true)
        return

    if distance > stopping_distance:
        state = State.CHASE
        _move_toward_player(delta)
    else:
        state = State.IDLE
        _stop_movement(delta)
        _face_player()


func _process_windup(delta: float, distance: float) -> void:
    _stop_movement(delta)
    _face_player()
    windup_timer -= delta

    if windup_timer > 0.0:
        return

    _set_windup_visual(false)

    if distance <= attack_range * 1.2 and not _is_player_dead():
        _attack_player()

    attack_timer = maxf(0.1, attack_cooldown)
    state = State.IDLE


func _move_toward_player(delta: float) -> void:
    var direction := player.global_position - global_position
    direction.y = 0.0

    if direction.length_squared() > 0.001:
        direction = direction.normalized()
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
        _face_direction(direction)
    else:
        velocity.x = move_toward(velocity.x, 0.0, move_speed * 4.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, move_speed * 4.0 * delta)

    _apply_gravity(delta)
    move_and_slide()


func _stop_movement(delta: float) -> void:
    velocity.x = move_toward(velocity.x, 0.0, move_speed * 5.0 * delta)
    velocity.z = move_toward(velocity.z, 0.0, move_speed * 5.0 * delta)
    _apply_gravity(delta)
    move_and_slide()


func _apply_gravity(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity_strength * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0


func _face_player() -> void:
    if not is_instance_valid(player):
        return

    var direction := player.global_position - global_position
    direction.y = 0.0
    if direction.length_squared() > 0.001:
        _face_direction(direction.normalized())


func _face_direction(direction: Vector3) -> void:
    if direction.length_squared() > 0.001:
        look_at(global_position + direction, Vector3.UP)


func _attack_player() -> void:
    _resolve_player_components()

    if not is_instance_valid(player_stats):
        push_warning("Enemy AI: узел PlayerStats не найден.")
        return

    if _is_player_dead():
        return

    var multiplier := 1.0
    if is_instance_valid(combat_controller):
        if combat_controller.has_method("get_incoming_damage_multiplier"):
            multiplier = float(
                combat_controller.call("get_incoming_damage_multiplier")
            )

    multiplier = clampf(multiplier, 0.0, 1.0)
    var final_damage := maxf(0.0, attack_damage) * multiplier

    if final_damage > 0.0 and player_stats.has_method("apply_damage"):
        player_stats.call("apply_damage", final_damage)
        print("[enemy] Урон игроку: %.1f (множитель %.2f)." % [
            final_damage, multiplier
        ])
    elif not player_stats.has_method("apply_damage"):
        push_warning("Enemy AI: PlayerStats не содержит apply_damage().")


func take_damage(amount: float) -> void:
    if state == State.DEAD or amount <= 0.0:
        return

    health = maxf(0.0, health - amount)
    health_changed.emit(health, max_health)
    _refresh_health_label()
    _flash_damage()
    print("[enemy] HP %.1f/%.1f" % [health, max_health])

    if health <= 0.0:
        _die()


func apply_damage(amount: float) -> void:
    take_damage(amount)


func _die() -> void:
    if state == State.DEAD:
        return

    state = State.DEAD
    velocity = Vector3.ZERO
    _set_windup_visual(false)
    collision_layer = 0
    collision_mask = 0

    var shape := get_node_or_null("CollisionShape3D")
    if shape is CollisionShape3D:
        shape.set_deferred("disabled", true)

    if is_instance_valid(original_material):
        original_material.albedo_color = Color(0.12, 0.10, 0.10, 1.0)

    if is_instance_valid(health_label):
        health_label.text = "Повержен"

    enemy_defeated.emit()
    print("[enemy] Противник побеждён.")
    _remove_after_delay()


func _remove_after_delay() -> void:
    await get_tree().create_timer(maxf(0.1, despawn_delay)).timeout
    if is_inside_tree():
        queue_free()


func _is_player_dead() -> bool:
    if not is_instance_valid(player_stats):
        return false
    return bool(player_stats.get("dead"))


func _acquire_player() -> void:
    player = get_tree().get_first_node_in_group("player") as Node3D
    _resolve_player_components()


func _resolve_player_components() -> void:
    player_stats = null
    combat_controller = null

    if not is_instance_valid(player):
        return

    player_stats = _find_descendant(player, "PlayerStats")
    combat_controller = _find_descendant(player, "CombatController")


func _find_descendant(root: Node, target_name: String) -> Node:
    if root.name == target_name:
        return root

    for child in root.get_children():
        var result := _find_descendant(child, target_name)
        if is_instance_valid(result):
            return result

    return null


func _ensure_visuals() -> void:
    var shape := get_node_or_null("CollisionShape3D")
    if not shape:
        shape = CollisionShape3D.new()
        shape.name = "CollisionShape3D"
        var capsule := CapsuleShape3D.new()
        capsule.radius = 0.42
        capsule.height = 1.8
        shape.shape = capsule
        shape.position.y = 0.9
        add_child(shape)

    body_mesh = get_node_or_null("BodyMesh") as MeshInstance3D
    if not is_instance_valid(body_mesh):
        body_mesh = MeshInstance3D.new()
        body_mesh.name = "BodyMesh"
        var capsule_mesh := CapsuleMesh.new()
        capsule_mesh.radius = 0.42
        capsule_mesh.height = 1.8
        body_mesh.mesh = capsule_mesh
        body_mesh.position.y = 0.9
        add_child(body_mesh)

    original_material = StandardMaterial3D.new()
    original_material.albedo_color = Color(0.38, 0.16, 0.12, 1.0)
    original_material.roughness = 0.85
    body_mesh.material_override = original_material

    health_label = get_node_or_null("HealthLabel") as Label3D
    if not is_instance_valid(health_label):
        health_label = Label3D.new()
        health_label.name = "HealthLabel"
        health_label.position = Vector3(0.0, 2.15, 0.0)
        health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        health_label.font_size = 32
        health_label.pixel_size = 0.005
        add_child(health_label)


func _refresh_health_label() -> void:
    if is_instance_valid(health_label):
        health_label.text = "Враг  %.0f / %.0f" % [health, max_health]


func _set_windup_visual(enabled: bool) -> void:
    if not is_instance_valid(original_material):
        return

    if enabled:
        original_material.albedo_color = Color(0.85, 0.32, 0.08, 1.0)
    elif state != State.DEAD:
        original_material.albedo_color = Color(0.38, 0.16, 0.12, 1.0)


func _flash_damage() -> void:
    if not is_instance_valid(original_material) or state == State.DEAD:
        return

    original_material.albedo_color = Color(1.0, 0.75, 0.65, 1.0)
    _restore_material_color()


func _restore_material_color() -> void:
    await get_tree().create_timer(0.12).timeout
    if not is_instance_valid(original_material) or state == State.DEAD:
        return
    if state == State.WINDUP:
        original_material.albedo_color = Color(0.85, 0.32, 0.08, 1.0)
    else:
        original_material.albedo_color = Color(0.38, 0.16, 0.12, 1.0)
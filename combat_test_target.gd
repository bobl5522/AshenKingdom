extends Node3D

@export var max_health: float = 100.0

var health: float = 100.0
var _health_label: Label3D


func _ready() -> void:
    add_to_group("enemies")
    add_to_group("combat_test_target")

    health = max_health
    _create_visuals()
    _create_collision()
    _update_label()

    print("[БОЙ] Тренировочная мишень создана. Здоровье: ", health)


func _create_visuals() -> void:
    var mesh_instance := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.45
    capsule.height = 1.8
    mesh_instance.mesh = capsule
    mesh_instance.position = Vector3(0.0, 0.9, 0.0)

    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.45, 0.16, 0.12)
    material.roughness = 0.9
    capsule.material = material

    add_child(mesh_instance)

    _health_label = Label3D.new()
    _health_label.position = Vector3(0.0, 2.0, 0.0)
    _health_label.font_size = 32
    _health_label.pixel_size = 0.01
    add_child(_health_label)


func _create_collision() -> void:
    var body := StaticBody3D.new()
    body.name = "TargetBody"
    body.collision_layer = 1
    body.collision_mask = 1
    add_child(body)

    var collision := CollisionShape3D.new()
    var capsule_shape := CapsuleShape3D.new()
    capsule_shape.radius = 0.45
    capsule_shape.height = 1.8
    collision.shape = capsule_shape
    collision.position = Vector3(0.0, 0.9, 0.0)
    body.add_child(collision)


func apply_damage(amount: float) -> void:
    if health <= 0.0:
        return

    health = maxf(0.0, health - amount)
    _update_label()

    print("[БОЙ] Мишень получила ", amount, " урона. Осталось HP: ", health)

    if health <= 0.0:
        print("[БОЙ] Мишень уничтожена.")
        queue_free()


func _update_label() -> void:
    if _health_label != null:
        _health_label.text = "Мишень\nHP: %d / %d" % [
            int(health),
            int(max_health)
        ]

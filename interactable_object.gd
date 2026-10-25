extends StaticBody3D

var activated: bool = false

func get_interaction_prompt() -> String:
    if activated:
        return "Объект уже активирован"
    return "Осмотреть древний артефакт"

func interact(_actor: Node) -> void:
    if activated:
        print("[Interaction] Артефакт уже активирован.")
        return

    activated = true

    var mesh := get_node_or_null("MeshInstance3D") as MeshInstance3D
    if mesh != null:
        var material := StandardMaterial3D.new()
        material.albedo_color = Color(0.20, 0.80, 0.35)
        material.roughness = 0.65
        mesh.material_override = material

    print("[Interaction] Древний артефакт активирован!")
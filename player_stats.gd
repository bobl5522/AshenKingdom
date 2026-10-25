extends Node

signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal died
signal revived

@export_range(1.0, 1000.0, 1.0) var max_health: float = 100.0
@export_range(1.0, 1000.0, 1.0) var max_stamina: float = 100.0
@export_range(1.0, 200.0, 1.0) var stamina_regen_per_second: float = 20.0

var health: float
var stamina: float
var dead: bool = false
var sprinting: bool = false

var health_label: Label
var stamina_label: Label
var health_bar: ProgressBar
var stamina_bar: ProgressBar
var status_label: Label


func _ready() -> void:
    health = max_health
    stamina = max_stamina
    _create_hud()
    _refresh_hud()
    health_changed.emit(health, max_health)
    stamina_changed.emit(stamina, max_stamina)


func _process(delta: float) -> void:
    if dead:
        return

    if not sprinting and stamina < max_stamina:
        stamina = minf(
            max_stamina,
            stamina + stamina_regen_per_second * delta
        )
        stamina_changed.emit(stamina, max_stamina)
        _refresh_hud()


func is_alive() -> bool:
    return not dead


func set_sprinting(value: bool) -> void:
    sprinting = value and not dead


func try_consume_stamina(amount: float) -> bool:
    if dead or amount <= 0.0:
        sprinting = false
        return false

    if stamina < amount:
        sprinting = false
        return false

    stamina = maxf(0.0, stamina - amount)
    sprinting = true
    stamina_changed.emit(stamina, max_stamina)
    _refresh_hud()
    return true


func apply_damage(amount: float) -> void:
    if dead or amount <= 0.0:
        return

    health = maxf(0.0, health - amount)
    health_changed.emit(health, max_health)
    _refresh_hud()

    if health <= 0.0:
        dead = true
        sprinting = false
        status_label.text = "ВЫ ПОГИБЛИ — нажмите R для возрождения"
        died.emit()


func heal(amount: float) -> void:
    if dead or amount <= 0.0:
        return

    health = minf(max_health, health + amount)
    health_changed.emit(health, max_health)
    _refresh_hud()


func revive() -> void:
    if not dead:
        return

    dead = false
    health = max_health
    stamina = max_stamina
    sprinting = false

    health_changed.emit(health, max_health)
    stamina_changed.emit(stamina, max_stamina)
    _refresh_hud()
    revived.emit()


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        return

    if event is InputEventKey:
        if event.pressed and not event.echo:
            if event.keycode == KEY_R and dead:
                revive()


func _create_hud() -> void:
    var layer := CanvasLayer.new()
    layer.name = "PlayerStatsHUD"
    add_child(layer)

    var panel := VBoxContainer.new()
    panel.name = "StatsPanel"
    panel.position = Vector2(24.0, 24.0)
    panel.custom_minimum_size = Vector2(280.0, 0.0)
    panel.add_theme_constant_override("separation", 6)
    layer.add_child(panel)

    health_label = Label.new()
    health_label.name = "HealthLabel"
    health_label.text = "Здоровье"
    panel.add_child(health_label)

    health_bar = ProgressBar.new()
    health_bar.name = "HealthBar"
    health_bar.custom_minimum_size = Vector2(280.0, 18.0)
    health_bar.show_percentage = false
    panel.add_child(health_bar)

    stamina_label = Label.new()
    stamina_label.name = "StaminaLabel"
    stamina_label.text = "Выносливость"
    panel.add_child(stamina_label)

    stamina_bar = ProgressBar.new()
    stamina_bar.name = "StaminaBar"
    stamina_bar.custom_minimum_size = Vector2(280.0, 18.0)
    stamina_bar.show_percentage = false
    panel.add_child(stamina_bar)

    status_label = Label.new()
    status_label.name = "StatusLabel"
    status_label.text = ""
    status_label.add_theme_color_override(
        "font_color",
        Color(1.0, 0.35, 0.25)
    )
    status_label.add_theme_font_size_override("font_size", 18)
    panel.add_child(status_label)


func _refresh_hud() -> void:
    if not is_instance_valid(health_bar):
        return

    health_bar.max_value = max_health
    health_bar.value = health
    health_label.text = "Здоровье: %d / %d" % [
        roundi(health),
        roundi(max_health)
    ]

    stamina_bar.max_value = max_stamina
    stamina_bar.value = stamina
    stamina_label.text = "Выносливость: %d / %d" % [
        roundi(stamina),
        roundi(max_stamina)
    ]

    if not dead:
        status_label.text = ""
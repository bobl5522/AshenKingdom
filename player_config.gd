extends Resource
class_name PlayerConfig

## Настройки движения персонажа.
## Изменяйте значения здесь, не затрагивая логику контроллера.

@export_group("Скорость")
@export_range(0.1, 20.0, 0.1) var walk_speed: float = 4.0
@export_range(0.1, 30.0, 0.1) var sprint_speed: float = 7.0

@export_group("Прыжок и гравитация")
@export_range(0.1, 15.0, 0.1) var jump_velocity: float = 4.5
@export_range(0.1, 40.0, 0.1) var gravity: float = 12.0

@export_group("Управление разгоном")
@export_range(0.1, 60.0, 0.1) var acceleration: float = 18.0
@export_range(0.1, 60.0, 0.1) var deceleration: float = 22.0
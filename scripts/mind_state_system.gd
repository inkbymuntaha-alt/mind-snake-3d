extends Node

signal mind_changed(value: float)

var overload: float = 0.18
const MIN_OVERLOAD: float = 0.0
const MAX_OVERLOAD: float = 1.0
const PASSIVE_DECAY: float = 0.012

func _process(delta: float) -> void:
    if GameManager.state == GameManager.GameState.PLAYING:
        set_overload(overload - PASSIVE_DECAY * delta)

func reset() -> void:
    overload = 0.18
    mind_changed.emit(overload)

func add_clarity() -> void:
    set_overload(overload - 0.24)

func add_impulse() -> void:
    set_overload(overload + 0.30)

func set_overload(value: float) -> void:
    var next_value: float = clampf(value, MIN_OVERLOAD, MAX_OVERLOAD)
    if not is_equal_approx(next_value, overload):
        overload = next_value
        mind_changed.emit(overload)

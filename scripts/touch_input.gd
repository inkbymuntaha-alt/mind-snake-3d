extends Node

signal direction_requested(direction: Vector2i)

const SWIPE_THRESHOLD: float = 24.0
var swipe_start: Vector2 = Vector2.ZERO
var tracking_swipe: bool = false
var active_touch_index: int = -1

func _input(event: InputEvent) -> void:
    if GameManager.state != GameManager.GameState.PLAYING:
        _cancel_swipe()
        return
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            if active_touch_index == -1:
                active_touch_index = touch.index
                swipe_start = touch.position
                tracking_swipe = true
        elif touch.index == active_touch_index:
            _finish_swipe(touch.position)
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if tracking_swipe and drag.index == active_touch_index:
            if swipe_start.distance_to(drag.position) >= SWIPE_THRESHOLD:
                _finish_swipe(drag.position)
    elif event is InputEventMouseButton:
        var mouse := event as InputEventMouseButton
        if mouse.button_index == MOUSE_BUTTON_LEFT:
            if mouse.pressed and not tracking_swipe:
                swipe_start = mouse.position
                tracking_swipe = true
            elif not mouse.pressed and tracking_swipe and active_touch_index == -1:
                _finish_swipe(mouse.position)

func request_direction(direction: Vector2i) -> void:
    if direction != Vector2i.ZERO:
        direction_requested.emit(direction)

func _finish_swipe(end_position: Vector2) -> void:
    var delta: Vector2 = end_position - swipe_start
    tracking_swipe = false
    active_touch_index = -1
    if delta.length() < SWIPE_THRESHOLD:
        return
    if absf(delta.x) > absf(delta.y):
        request_direction(Vector2i.RIGHT if delta.x > 0.0 else Vector2i.LEFT)
    else:
        request_direction(Vector2i.DOWN if delta.y > 0.0 else Vector2i.UP)

func _cancel_swipe() -> void:
    tracking_swipe = false
    active_touch_index = -1

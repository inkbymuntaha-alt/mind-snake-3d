extends Node

signal direction_requested(direction: Vector2i)

var swipe_start: Vector2 = Vector2.ZERO
var tracking_swipe: bool = false
const SWIPE_THRESHOLD: float = 28.0

func _unhandled_input(event: InputEvent) -> void:
    if GameManager.state != GameManager.GameState.PLAYING:
        return
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            swipe_start = touch.position
            tracking_swipe = true
        elif tracking_swipe:
            _finish_swipe(touch.position)
    elif event is InputEventScreenDrag and tracking_swipe:
        var drag := event as InputEventScreenDrag
        if swipe_start.distance_to(drag.position) >= SWIPE_THRESHOLD:
            _finish_swipe(drag.position)

func request_direction(direction: Vector2i) -> void:
    if direction != Vector2i.ZERO:
        direction_requested.emit(direction)

func _finish_swipe(end_position: Vector2) -> void:
    tracking_swipe = false
    var delta: Vector2 = end_position - swipe_start
    if delta.length() < SWIPE_THRESHOLD:
        return
    if absf(delta.x) > absf(delta.y):
        request_direction(Vector2i.RIGHT if delta.x > 0.0 else Vector2i.LEFT)
    else:
        request_direction(Vector2i.DOWN if delta.y > 0.0 else Vector2i.UP)

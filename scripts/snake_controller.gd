extends Node3D
class_name SnakeController

const GRID_SIZE: int = 18
const CELL_SIZE: float = 0.82
const MOVE_INTERVAL: float = 0.17

var direction: Vector2i = Vector2i.RIGHT
var queued_direction: Vector2i = Vector2i.RIGHT
var cells: Array[Vector2i] = []
var segment_nodes: Array[MeshInstance3D] = []
var move_timer: float = 0.0
var visual_positions: Array[Vector3] = []
var alive: bool = false

func _ready() -> void:
    TouchInput.direction_requested.connect(set_direction)
    GameManager.game_started.connect(reset_snake)
    reset_snake()

func reset_snake() -> void:
    for node in segment_nodes:
        if is_instance_valid(node):
            node.queue_free()
    segment_nodes.clear()
    cells.clear()
    visual_positions.clear()
    direction = Vector2i.RIGHT
    queued_direction = direction
    move_timer = 0.0
    alive = true
    for i in range(4):
        var cell := Vector2i(7 - i, 9)
        cells.append(cell)
        var mesh := _make_segment(i == 0)
        add_child(mesh)
        segment_nodes.append(mesh)
        var pos := _cell_to_world(cell)
        mesh.position = pos
        visual_positions.append(pos)

func set_direction(value: Vector2i) -> void:
    if not alive or value == Vector2i.ZERO:
        return
    var candidate := value
    if candidate == -direction:
        return
    queued_direction = candidate

func _process(delta: float) -> void:
    if not alive or GameManager.state != GameManager.GameState.PLAYING:
        return
    move_timer += delta
    var interval: float = maxf(0.075, MOVE_INTERVAL * (4.0 / GameManager.run_speed))
    while move_timer >= interval:
        move_timer -= interval
        _step()
        if not alive:
            return
    _smooth_visuals(delta)

func _step() -> void:
    direction = queued_direction
    var next_cell: Vector2i = cells[0] + direction
    if next_cell.x < 0 or next_cell.x >= GRID_SIZE or next_cell.y < 0 or next_cell.y >= GRID_SIZE:
        die()
        return
    var will_grow: bool = ArenaSpawner.consume_at(next_cell)
    var body_limit: int = cells.size() if will_grow else cells.size() - 1
    for i in range(body_limit):
        if cells[i] == next_cell:
            die()
            return
    if ArenaSpawner.is_hazard_at(next_cell):
        die()
        return
    cells.push_front(next_cell)
    if not will_grow:
        cells.pop_back()
    _sync_segment_count()
    for i in range(cells.size()):
        if i < segment_nodes.size():
            var target := _cell_to_world(cells[i])
            if i >= visual_positions.size():
                visual_positions.append(target)
            else:
                visual_positions[i] = target

func _sync_segment_count() -> void:
    while segment_nodes.size() < cells.size():
        var segment := _make_segment(false)
        add_child(segment)
        segment_nodes.append(segment)
        visual_positions.append(segment.position)
    while segment_nodes.size() > cells.size():
        var last: MeshInstance3D = segment_nodes.pop_back()
        visual_positions.pop_back()
        last.queue_free()

func _smooth_visuals(delta: float) -> void:
    var weight: float = clampf(delta * 13.0, 0.0, 1.0)
    for i in range(mini(segment_nodes.size(), visual_positions.size())):
        var node: MeshInstance3D = segment_nodes[i]
        node.position = node.position.lerp(visual_positions[i], weight)

func die() -> void:
    alive = false
    GameManager.finish_game()

func _cell_to_world(cell: Vector2i) -> Vector3:
    var half: float = float(GRID_SIZE - 1) * CELL_SIZE * 0.5
    return Vector3(float(cell.x) * CELL_SIZE - half, 0.45, float(cell.y) * CELL_SIZE - half)

func _make_segment(is_head: bool) -> MeshInstance3D:
    var mesh_node := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.34 if is_head else 0.29
    sphere.height = 0.68 if is_head else 0.58
    mesh_node.mesh = sphere
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.12, 0.95, 0.86) if is_head else Color(0.18, 0.48, 0.82)
    material.emission_enabled = true
    material.emission = material.albedo_color
    material.emission_energy_multiplier = 0.65
    mesh_node.material_override = material
    return mesh_node

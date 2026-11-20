extends Node3D
class_name ArenaSpawner

static var active: ArenaSpawner
const GRID_SIZE: int = 18
const CELL_SIZE: float = 0.82

var collectible_cell: Vector2i = Vector2i(-1, -1)
var collectible_type: int = 0
var collectible_node: MeshInstance3D
var hazard_cells: Array[Vector2i] = []
var hazard_nodes: Array[MeshInstance3D] = []
var hazard_refresh: float = 0.0

func _ready() -> void:
    active = self
    GameManager.game_started.connect(reset_arena)
    reset_arena()

func _exit_tree() -> void:
    if active == self:
        active = null

func _process(delta: float) -> void:
    if GameManager.state != GameManager.GameState.PLAYING:
        return
    hazard_refresh += delta
    if hazard_refresh >= 3.0:
        hazard_refresh = 0.0
        _update_hazards()

func reset_arena() -> void:
    hazard_cells.clear()
    for node in hazard_nodes:
        if is_instance_valid(node):
            node.queue_free()
    hazard_nodes.clear()
    if is_instance_valid(collectible_node):
        collectible_node.queue_free()
    collectible_node = null
    hazard_refresh = 0.0
    _spawn_collectible()
    _update_hazards()

static func consume_at(cell: Vector2i) -> bool:
    if active == null or cell != active.collectible_cell:
        return false
    active._collect_collectible()
    return true

static func is_hazard_at(cell: Vector2i) -> bool:
    return active != null and active.hazard_cells.has(cell)

func _collect_collectible() -> void:
    if collectible_type == 0:
        GameManager.add_score(10)
        MindStateSystem.add_clarity()
        GameManager.set_speed(GameManager.run_speed + 0.08)
    else:
        GameManager.add_score(25)
        MindStateSystem.add_impulse()
        GameManager.set_speed(GameManager.run_speed + 0.32)
    _spawn_collectible()

func _spawn_collectible() -> void:
    if is_instance_valid(collectible_node):
        collectible_node.queue_free()
    var candidate := Vector2i.ZERO
    var attempts: int = 0
    var snake: Node = get_tree().current_scene.get_node_or_null("Snake")
    while attempts < 300:
        candidate = Vector2i(randi_range(1, GRID_SIZE - 2), randi_range(1, GRID_SIZE - 2))
        var occupied: bool = false
        if snake is SnakeController:
            occupied = (snake as SnakeController).cells.has(candidate)
        if not occupied and not hazard_cells.has(candidate):
            break
        attempts += 1
    collectible_cell = candidate
    collectible_type = 1 if randf() < clampf(MindStateSystem.overload, 0.12, 0.72) else 0
    collectible_node = MeshInstance3D.new()
    var orb := SphereMesh.new()
    orb.radius = 0.24
    orb.height = 0.48
    collectible_node.mesh = orb
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(1.0, 0.28, 0.65) if collectible_type == 1 else Color(0.35, 1.0, 0.68)
    mat.emission_enabled = true
    mat.emission = mat.albedo_color
    mat.emission_energy_multiplier = 2.0
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    collectible_node.material_override = mat
    add_child(collectible_node)
    collectible_node.position = _cell_to_world(candidate) + Vector3.UP * 0.1

func _update_hazards() -> void:
    var desired: int = 0
    if MindStateSystem.overload > 0.42:
        desired = 1
    if MindStateSystem.overload > 0.72:
        desired = 2
    while hazard_nodes.size() > desired:
        hazard_nodes.pop_back().queue_free()
        hazard_cells.pop_back()
    while hazard_nodes.size() < desired:
        var cell := Vector2i(randi_range(2, GRID_SIZE - 3), randi_range(2, GRID_SIZE - 3))
        var snake: Node = get_tree().current_scene.get_node_or_null("Snake")
        var safe: bool = not hazard_cells.has(cell)
        if snake is SnakeController:
            safe = safe and not (snake as SnakeController).cells.has(cell)
        if cell == collectible_cell:
            safe = false
        if not safe:
            continue
        hazard_cells.append(cell)
        var node := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = Vector3(0.52, 0.9, 0.52)
        node.mesh = box
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color(0.65, 0.18, 0.95, 0.85)
        mat.emission_enabled = true
        mat.emission = Color(0.55, 0.12, 0.9)
        mat.emission_energy_multiplier = 1.4
        node.material_override = mat
        add_child(node)
        node.position = _cell_to_world(cell) + Vector3.UP * 0.45
        hazard_nodes.append(node)

func _cell_to_world(cell: Vector2i) -> Vector3:
    var half: float = float(GRID_SIZE - 1) * CELL_SIZE * 0.5
    return Vector3(float(cell.x) * CELL_SIZE - half, 0.45, float(cell.y) * CELL_SIZE - half)

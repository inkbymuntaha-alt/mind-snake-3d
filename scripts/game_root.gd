extends Node3D

@onready var arena: ArenaSpawner = $Arena
@onready var snake: SnakeController = $Snake
@onready var camera: Camera3D = $Camera3D

var base_fov: float = 58.0
var shake_time: float = 0.0
var floor_material: StandardMaterial3D

func _ready() -> void:
    _build_arena_visuals()
    MindStateSystem.mind_changed.connect(_on_mind_changed)
    GameManager.game_started.connect(_reset_camera)
    _on_mind_changed(MindStateSystem.overload)

func _process(delta: float) -> void:
    if GameManager.state == GameManager.GameState.PLAYING:
        var target_fov: float = lerpf(64.0, 51.0, MindStateSystem.overload)
        camera.fov = lerpf(camera.fov, target_fov, delta * 2.0)
        if MindStateSystem.overload > 0.7:
            shake_time += delta
            camera.position.x = sin(shake_time * 27.0) * 0.025 * MindStateSystem.overload
            camera.position.y = 14.0 + cos(shake_time * 21.0) * 0.018 * MindStateSystem.overload
        else:
            camera.position.x = lerpf(camera.position.x, 0.0, delta * 5.0)
            camera.position.y = lerpf(camera.position.y, 14.0, delta * 5.0)

func _reset_camera() -> void:
    camera.fov = 58.0
    camera.position = Vector3(0.0, 14.0, 12.0)

func _on_mind_changed(value: float) -> void:
    if floor_material == null:
        return
    var calm_color := Color(0.035, 0.12, 0.18)
    var stress_color := Color(0.18, 0.035, 0.15)
    floor_material.albedo_color = calm_color.lerp(stress_color, value)

func _build_arena_visuals() -> void:
    var floor := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(15.0, 15.0)
    floor.mesh = plane
    floor_material = StandardMaterial3D.new()
    floor_material.albedo_color = Color(0.035, 0.12, 0.18)
    floor_material.metallic = 0.35
    floor_material.roughness = 0.5
    floor.material_override = floor_material
    floor.position.y = 0.0
    add_child(floor)
    var grid_mesh := GridMesh.new()
    grid_mesh.size = Vector2(14.8, 14.8)
    grid_mesh.cell_size = Vector2(0.82, 0.82)
    var grid := MeshInstance3D.new()
    grid.mesh = grid_mesh
    var grid_mat := StandardMaterial3D.new()
    grid_mat.albedo_color = Color(0.12, 0.4, 0.48, 0.35)
    grid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    grid.material_override = grid_mat
    grid.position.y = 0.012
    add_child(grid)
    _add_boundary_walls()

func _add_boundary_walls() -> void:
    for i in range(4):
        var wall := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = Vector3(15.0, 0.8, 0.18) if i < 2 else Vector3(0.18, 0.8, 15.0)
        wall.mesh = box
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color(0.08, 0.45, 0.58)
        mat.emission_enabled = true
        mat.emission = Color(0.02, 0.24, 0.36)
        wall.material_override = mat
        if i == 0:
            wall.position = Vector3(0, 0.4, -7.5)
        elif i == 1:
            wall.position = Vector3(0, 0.4, 7.5)
        elif i == 2:
            wall.position = Vector3(-7.5, 0.4, 0)
        else:
            wall.position = Vector3(7.5, 0.4, 0)
        add_child(wall)

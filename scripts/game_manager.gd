extends Node

signal score_changed(value: int)
signal best_changed(value: int)
signal game_started
signal game_over
signal pause_changed(paused: bool)

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }

var state: GameState = GameState.MENU
var score: int = 0
var best_score: int = 0
var run_speed: float = 4.0

const SAVE_PATH: String = "user://mind_snake_save.cfg"

func _ready() -> void:
    _load_best()

func start_game() -> void:
    score = 0
    run_speed = 4.0
    state = GameState.PLAYING
    score_changed.emit(score)
    game_started.emit()

func add_score(amount: int) -> void:
    if state != GameState.PLAYING:
        return
    score = maxi(0, score + amount)
    score_changed.emit(score)
    if score > best_score:
        best_score = score
        best_changed.emit(best_score)
        _save_best()

func set_speed(value: float) -> void:
    run_speed = clampf(value, 2.5, 9.0)

func finish_game() -> void:
    if state != GameState.PLAYING:
        return
    state = GameState.GAME_OVER
    _save_best()
    game_over.emit()

func toggle_pause() -> void:
    if state == GameState.PLAYING:
        state = GameState.PAUSED
        pause_changed.emit(true)
    elif state == GameState.PAUSED:
        state = GameState.PLAYING
        pause_changed.emit(false)

func return_to_menu() -> void:
    state = GameState.MENU
    get_tree().paused = false

func _load_best() -> void:
    var config := ConfigFile.new()
    var err: Error = config.load(SAVE_PATH)
    if err == OK:
        best_score = int(config.get_value("scores", "best", 0))

func _save_best() -> void:
    var config := ConfigFile.new()
    config.set_value("scores", "best", best_score)
    config.save(SAVE_PATH)

extends CanvasLayer
class_name UIController

var score_label: Label
var best_label: Label
var mind_label: Label
var mind_bar: ProgressBar
var menu_panel: Control
var pause_panel: Control
var game_over_panel: Control
var hud: Control

func _ready() -> void:
    _build_ui()
    GameManager.score_changed.connect(_on_score_changed)
    GameManager.best_changed.connect(_on_best_changed)
    GameManager.game_started.connect(_show_game)
    GameManager.game_over.connect(_show_game_over)
    GameManager.pause_changed.connect(_on_pause_changed)
    MindStateSystem.mind_changed.connect(_on_mind_changed)
    _refresh_labels()
    _show_menu()

func _build_ui() -> void:
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(root)
    hud = Control.new()
    hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_child(hud)
    score_label = _label("SCORE  0", 28, Vector2(24, 22), Vector2(300, 65))
    best_label = _label("BEST  0", 19, Vector2(24, 76), Vector2(250, 45))
    mind_label = _label("MIND  CALM", 18, Vector2(24, 128), Vector2(260, 38))
    hud.add_child(score_label)
    hud.add_child(best_label)
    hud.add_child(mind_label)
    mind_bar = ProgressBar.new()
    mind_bar.position = Vector2(24, 169)
    mind_bar.size = Vector2(250, 14)
    mind_bar.max_value = 1.0
    mind_bar.show_percentage = false
    hud.add_child(mind_bar)
    var pause_button := _button("Ⅱ", Vector2(-86, 24), Vector2(62, 62))
    pause_button.anchor_left = 1.0
    pause_button.anchor_right = 1.0
    hud.add_child(pause_button)
    pause_button.pressed.connect(_pause_game)
    _add_dpad(hud)
    menu_panel = _panel(root)
    _add_title(menu_panel, "MIND SNAKE", "CONTROL YOUR MIND.\nSURVIVE THE NOISE.")
    _add_button_center(menu_panel, "PLAY", 0.58, _start_game)
    _add_small_text(menu_panel, "SWIPE ANYWHERE TO STEER  •  CLARITY CALMS YOU", 0.73)
    pause_panel = _panel(root)
    _add_title(pause_panel, "PAUSED", "TAKE A BREATH.")
    _add_button_center(pause_panel, "RESUME", 0.58, _pause_game)
    _add_button_center(pause_panel, "RESTART", 0.69, _start_game)
    game_over_panel = _panel(root)
    _add_title(game_over_panel, "MIND OVERLOADED", "THE ECHOES CAUGHT YOU.")
    _add_button_center(game_over_panel, "TRY AGAIN", 0.59, _start_game)
    _add_button_center(game_over_panel, "MAIN MENU", 0.70, _show_menu)
    _set_panel_visibility(false, false, false)

func _label(text_value: String, font_size: int, pos: Vector2, box_size: Vector2) -> Label:
    var label := Label.new()
    label.text = text_value
    label.position = pos
    label.size = box_size
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color(0.82, 0.96, 1.0))
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return label

func _panel(parent: Control) -> Control:
    var panel := ColorRect.new()
    panel.color = Color(0.015, 0.025, 0.065, 0.84)
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    parent.add_child(panel)
    return panel

func _add_title(panel: Control, title_text: String, subtitle: String) -> void:
    var title_size := 32 if title_text == "MIND OVERLOADED" else 38
    var title := _label(title_text, title_size, Vector2.ZERO, Vector2.ZERO)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.anchor_left = 0.0
    title.anchor_right = 1.0
    title.offset_left = 12
    title.offset_right = -12
    title.offset_top = 230
    title.offset_bottom = 320
    panel.add_child(title)
    var sub := _label(subtitle, 17, Vector2.ZERO, Vector2.ZERO)
    sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    sub.anchor_left = 0.0
    sub.anchor_right = 1.0
    sub.offset_left = 16
    sub.offset_right = -16
    sub.offset_top = 330
    sub.offset_bottom = 410
    panel.add_child(sub)

func _button(text_value: String, pos: Vector2, box_size: Vector2) -> Button:
    var button := Button.new()
    button.text = text_value
    button.position = pos
    button.size = box_size
    button.add_theme_font_size_override("font_size", 22)
    button.add_theme_color_override("font_color", Color.WHITE)
    button.add_theme_stylebox_override("normal", _button_style(Color(0.08, 0.34, 0.42, 0.95)))
    button.add_theme_stylebox_override("hover", _button_style(Color(0.12, 0.52, 0.58, 1.0)))
    return button

func _button_style(color_value: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color_value
    style.corner_radius_top_left = 14
    style.corner_radius_top_right = 14
    style.corner_radius_bottom_left = 14
    style.corner_radius_bottom_right = 14
    style.content_margin_left = 18
    style.content_margin_right = 18
    return style

func _add_button_center(panel: Control, caption: String, y_ratio: float, callback: Callable) -> void:
    var button := _button(caption, Vector2.ZERO, Vector2(280, 64))
    button.anchor_left = 0.5
    button.anchor_right = 0.5
    button.offset_left = -140
    button.offset_right = 140
    button.anchor_top = y_ratio
    button.anchor_bottom = y_ratio
    button.offset_top = 0
    button.offset_bottom = 64
    panel.add_child(button)
    button.pressed.connect(callback)

func _add_small_text(panel: Control, text_value: String, y_ratio: float) -> void:
    var label := _label(text_value, 13, Vector2.ZERO, Vector2.ZERO)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.anchor_left = 0.0
    label.anchor_right = 1.0
    label.offset_left = 12
    label.offset_right = -12
    label.anchor_top = y_ratio
    label.anchor_bottom = y_ratio
    label.offset_bottom = 35
    panel.add_child(label)

func _add_dpad(parent: Control) -> void:
    var entries: Array[Dictionary] = [
        {"text":"↑", "x":0.84, "y":0.81, "dir":Vector2i.UP},
        {"text":"↓", "x":0.84, "y":0.94, "dir":Vector2i.DOWN},
        {"text":"←", "x":0.75, "y":0.875, "dir":Vector2i.LEFT},
        {"text":"→", "x":0.93, "y":0.875, "dir":Vector2i.RIGHT}
    ]
    for entry in entries:
        var button := _button(str(entry["text"]), Vector2.ZERO, Vector2(60, 60))
        var x_anchor: float = float(entry["x"])
        var y_anchor: float = float(entry["y"])
        button.anchor_left = x_anchor
        button.anchor_right = x_anchor
        button.anchor_top = y_anchor
        button.anchor_bottom = y_anchor
        button.offset_left = -30
        button.offset_right = 30
        button.offset_top = -30
        button.offset_bottom = 30
        parent.add_child(button)
        var direction_value: Vector2i = entry["dir"]
        button.pressed.connect(func() -> void: TouchInput.request_direction(direction_value))

func _set_panel_visibility(menu_visible: bool, pause_visible: bool, over_visible: bool) -> void:
    menu_panel.visible = menu_visible
    pause_panel.visible = pause_visible
    game_over_panel.visible = over_visible
    hud.visible = not menu_visible

func _show_menu() -> void:
    GameManager.return_to_menu()
    _set_panel_visibility(true, false, false)

func _start_game() -> void:
    MindStateSystem.reset()
    GameManager.start_game()

func _show_game() -> void:
    _set_panel_visibility(false, false, false)

func _show_game_over() -> void:
    _set_panel_visibility(false, false, true)

func _pause_game() -> void:
    GameManager.toggle_pause()

func _on_pause_changed(paused: bool) -> void:
    _set_panel_visibility(false, paused, false)

func _on_score_changed(value: int) -> void:
    score_label.text = "SCORE  %d" % value

func _on_best_changed(value: int) -> void:
    best_label.text = "BEST  %d" % value

func _on_mind_changed(value: float) -> void:
    mind_bar.value = value
    var mood: String = "CALM" if value < 0.34 else ("UNSTEADY" if value < 0.68 else "OVERLOAD")
    mind_label.text = "MIND  %s" % mood

func _refresh_labels() -> void:
    score_label.text = "SCORE  %d" % GameManager.score
    best_label.text = "BEST  %d" % GameManager.best_score
    _on_mind_changed(MindStateSystem.overload)

extends AudioStreamPlayer

var generator: AudioStreamGenerator
var playback: AudioStreamGeneratorPlayback
var phase: float = 0.0
var phase_two: float = 0.0
var current_frequency: float = 68.0

func _ready() -> void:
    generator = AudioStreamGenerator.new()
    generator.mix_rate = 22050.0
    generator.buffer_length = 0.35
    stream = generator
    volume_db = -22.0
    play()
    playback = get_stream_playback() as AudioStreamGeneratorPlayback

func _process(delta: float) -> void:
    if playback == null:
        return
    var target_frequency: float = lerpf(68.0, 178.0, MindStateSystem.overload)
    current_frequency = lerpf(current_frequency, target_frequency, clampf(delta * 1.8, 0.0, 1.0))
    var frames: int = playback.get_frames_available()
    for i in range(frames):
        phase += TAU * current_frequency / generator.mix_rate
        phase_two += TAU * (current_frequency * 1.51) / generator.mix_rate
        if phase >= TAU:
            phase -= TAU
        if phase_two >= TAU:
            phase_two -= TAU
        var calm_tone: float = sin(phase) * 0.62
        var overtone: float = sin(phase_two) * 0.18
        var sample: float = (calm_tone + overtone) * 0.035
        playback.push_frame(Vector2(sample, sample))

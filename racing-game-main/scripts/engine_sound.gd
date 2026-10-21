extends AudioStreamPlayer

## Procedural engine sound — pitch scales with car speed.

var generator: AudioStreamGenerator
var playback: AudioStreamGeneratorPlayback
var phase: float = 0.0
var target_freq: float = 80.0
var current_freq: float = 80.0

const IDLE_FREQ := 80.0
const MAX_FREQ := 400.0
const SAMPLE_RATE := 22050.0
const VOLUME := 0.15


func _ready() -> void:
	generator = AudioStreamGenerator.new()
	generator.mix_rate = SAMPLE_RATE
	generator.buffer_length = 0.1
	stream = generator
	volume_db = linear_to_db(VOLUME)
	bus = "Master"
	play()
	playback = get_stream_playback()


func update_speed(speed_ratio: float) -> void:
	# speed_ratio: 0.0 (idle) to 1.0 (top speed)
	target_freq = IDLE_FREQ + (MAX_FREQ - IDLE_FREQ) * clampf(speed_ratio, 0.0, 1.0)


func _process(_delta: float) -> void:
	if not playback:
		return
	current_freq = lerp(current_freq, target_freq, 0.1)

	var frames := playback.get_frames_available()
	for i in range(frames):
		phase += current_freq / SAMPLE_RATE
		if phase > 1.0:
			phase -= 1.0
		# Mix saw + square for engine-like buzz
		var saw := phase * 2.0 - 1.0
		var square := 1.0 if phase < 0.5 else -1.0
		var sample := (saw * 0.6 + square * 0.4)
		# Add harmonics
		var harmonic := sin(phase * TAU * 2.0) * 0.2
		sample += harmonic
		playback.push_frame(Vector2(sample, sample) * 0.3)

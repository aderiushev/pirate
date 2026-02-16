extends AudioStreamPlayer

# Chiptune "He's a Pirate" — the iconic Pirates of the Caribbean theme
# Procedurally generated square + triangle wave arrangement in D minor, 6/8 feel

const SAMPLE_RATE = 22050.0
const MASTER_VOLUME = 0.25

# Note frequencies (Hz)
const NOTE = {
	"REST": 0.0,
	"A2": 110.00, "Bb2": 116.54, "C3": 130.81, "D3": 146.83, "E3": 164.81,
	"F3": 174.61, "G3": 196.00, "A3": 220.00, "Bb3": 233.08, "C4": 261.63,
	"D4": 293.66, "E4": 329.63, "F4": 349.23, "G4": 392.00, "A4": 440.00,
	"Bb4": 466.16, "C5": 523.25, "D5": 587.33, "E5": 659.25, "F5": 698.46,
}

# 6/8 feel: eighth note = 0.5 beats, dotted quarter = 1.5, measure = 3 beats
# Each entry = [note_name, duration_in_beats]

var melody: Array = [
	# === Section A1: The iconic opening triplet motif ===
	# m1: da da da, da-da DAH da
	["D4", 0.5], ["D4", 0.5], ["D4", 0.5], ["E4", 0.5], ["F4", 0.5], ["REST", 0.5],
	# m2: da da DAH da, da .
	["F4", 0.5], ["F4", 0.5], ["G4", 0.5], ["E4", 0.5], ["E4", 0.5], ["REST", 0.5],
	# m3: da da DAH . da da
	["E4", 0.5], ["D4", 0.5], ["C4", 0.5], ["REST", 0.5], ["C4", 0.5], ["D4", 0.5],
	# m4: DAHHHHH
	["D4", 3.0],

	# === Section A2: Same motif, ascending variation ===
	# m5
	["D4", 0.5], ["D4", 0.5], ["D4", 0.5], ["E4", 0.5], ["F4", 0.5], ["REST", 0.5],
	# m6: up to A and Bb
	["F4", 0.5], ["G4", 0.5], ["A4", 0.5], ["REST", 0.5], ["Bb4", 0.5], ["REST", 0.5],
	# m7: resolve on A
	["A4", 2.5], ["REST", 0.5],
	# m8: breath
	["REST", 3.0],

	# === Section B: The famous dramatic ascending part ===
	# m9: A A A Bb A .
	["A4", 0.5], ["A4", 0.5], ["A4", 0.5], ["Bb4", 0.5], ["A4", 0.5], ["REST", 0.5],
	# m10: G A DAHH .
	["G4", 0.5], ["A4", 0.5], ["D5", 1.5], ["REST", 0.5],
	# m11: D E D C A .
	["D5", 0.5], ["E5", 0.5], ["D5", 0.5], ["C5", 0.5], ["A4", 0.5], ["REST", 0.5],
	# m12: A G FAHH .
	["A4", 0.5], ["G4", 0.5], ["F4", 1.5], ["REST", 0.5],

	# === Section B2: Grand resolution ===
	# m13: G . A . Bb-
	["G4", 0.5], ["REST", 0.5], ["A4", 0.5], ["REST", 0.5], ["Bb4", 1.0],
	# m14: Bb A G A D .
	["Bb4", 0.5], ["A4", 0.5], ["G4", 0.5], ["A4", 0.5], ["D5", 0.5], ["REST", 0.5],
	# m15: DAHHHHHH
	["D5", 3.0],
	# m16: rest before loop
	["REST", 3.0],
]

# Bass line following the Dm - Bb - A - Dm chord progression
var bass: Array = [
	# Section A1 (m1-4): Dm, Dm, Bb→A, Dm
	["D3", 3.0], ["D3", 3.0], ["Bb3", 1.5], ["A3", 1.5], ["D3", 3.0],
	# Section A2 (m5-8): Dm, F, Bb→A, Dm
	["D3", 3.0], ["F3", 3.0], ["Bb3", 1.5], ["A3", 1.5], ["D3", 3.0],
	# Section B (m9-12): F, Bb, A, Dm
	["F3", 3.0], ["Bb3", 3.0], ["A3", 3.0], ["D3", 3.0],
	# Section B2 (m13-16): Gm, Bb→A, Dm, Dm
	["G3", 3.0], ["Bb3", 1.5], ["A3", 1.5], ["D3", 3.0], ["D3", 3.0],
]

var BPM = 170.0
var level_bpm = {1: 170.0, 2: 180.0, 3: 195.0}
var beat_duration: float
var playback: AudioStreamGeneratorPlayback
var phase_melody: float = 0.0
var phase_bass: float = 0.0
var melody_index: int = 0
var bass_index: int = 0
var melody_beat_timer: float = 0.0
var bass_beat_timer: float = 0.0
var current_melody_freq: float = 0.0
var current_bass_freq: float = 0.0
var current_melody_duration: float = 0.0
var current_bass_duration: float = 0.0
var total_time: float = 0.0

func _ready() -> void:
	if GameState and GameState.current_level in level_bpm:
		BPM = level_bpm[GameState.current_level]
	beat_duration = 60.0 / BPM
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = SAMPLE_RATE
	gen.buffer_length = 0.1
	stream = gen
	volume_db = -6.0
	play()
	playback = get_stream_playback()
	_advance_melody()
	_advance_bass()

func _process(delta: float) -> void:
	if not playback:
		return
	_fill_buffer()

func _fill_buffer() -> void:
	var frames_available = playback.get_frames_available()
	if frames_available == 0:
		return

	for i in range(frames_available):
		var t = 1.0 / SAMPLE_RATE
		total_time += t

		# Advance melody sequence
		melody_beat_timer -= t
		if melody_beat_timer <= 0.0:
			_advance_melody()

		# Advance bass sequence
		bass_beat_timer -= t
		if bass_beat_timer <= 0.0:
			_advance_bass()

		var sample = 0.0

		# Melody voice: 25% pulse wave (classic chiptune character)
		if current_melody_freq > 0.0:
			phase_melody += current_melody_freq * t
			if phase_melody > 1.0:
				phase_melody -= 1.0
			var melody_sample = 1.0 if phase_melody < 0.25 else -1.0
			# Envelope: attack/release to avoid clicks, slight decay on longer notes
			var note_elapsed = current_melody_duration * beat_duration - melody_beat_timer
			var attack = clampf(note_elapsed * 20.0, 0.0, 1.0)
			var release = clampf(melody_beat_timer * 15.0, 0.0, 1.0)
			var env = attack * release
			sample += melody_sample * 0.35 * env

		# Bass voice: triangle wave for warmth and depth
		if current_bass_freq > 0.0:
			phase_bass += current_bass_freq * t
			if phase_bass > 1.0:
				phase_bass -= 1.0
			var bass_sample = 4.0 * absf(phase_bass - 0.5) - 1.0
			var bass_env = clampf(bass_beat_timer * 10.0, 0.0, 1.0)
			sample += bass_sample * 0.3 * bass_env

		sample *= MASTER_VOLUME
		sample = clampf(sample, -1.0, 1.0)
		playback.push_frame(Vector2(sample, sample))

func _advance_melody() -> void:
	var entry = melody[melody_index]
	current_melody_freq = NOTE[entry[0]]
	current_melody_duration = entry[1]
	melody_beat_timer = entry[1] * beat_duration
	melody_index = (melody_index + 1) % melody.size()

func _advance_bass() -> void:
	var entry = bass[bass_index]
	current_bass_freq = NOTE[entry[0]]
	current_bass_duration = entry[1]
	bass_beat_timer = entry[1] * beat_duration
	bass_index = (bass_index + 1) % bass.size()

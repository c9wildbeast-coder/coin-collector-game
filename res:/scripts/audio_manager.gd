
extends Node

var coin_sound_player: AudioStreamPlayer
var button_sound_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var music_enabled = true


func _ready():
	setup_audio()


func setup_audio():
	coin_sound_player = AudioStreamPlayer.new()
	button_sound_player = AudioStreamPlayer.new()
	music_player = AudioStreamPlayer.new()

	add_child(coin_sound_player)
	add_child(button_sound_player)
	add_child(music_player)

	coin_sound_player.stream = make_tone(0.20, 850.0, 1450.0, 0.35)
	button_sound_player.stream = make_tone(0.09, 520.0, 330.0, 0.25)

	music_player.stream = make_music()
	music_player.volume_db = -15.0

	if music_enabled:
		music_player.play()


func make_tone(duration: float, start_frequency: float, end_frequency: float, volume: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var sample_count = int(duration * sample_rate)
	var audio_data = PackedByteArray()
	audio_data.resize(sample_count * 2)
	var phase = 0.0

	for i in range(sample_count):
		var progress = float(i) / sample_count
		var frequency = lerpf(start_frequency, end_frequency, progress)
		phase += TAU * frequency / sample_rate

		var envelope = 1.0 - progress
		envelope *= minf(progress * 15.0, 1.0)

		var sample = sin(phase) * volume * envelope
		audio_data.encode_s16(i * 2, int(sample * 32767.0))

	var sound = AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = sample_rate
	sound.stereo = false
	sound.data = audio_data
	return sound


func make_music() -> AudioStreamWAV:
	var sample_rate = 22050
	var note_duration = 0.32

	var notes = [
		523.25, 659.25, 783.99, 659.25,
		587.33, 698.46, 880.00, 698.46,
		523.25, 659.25, 783.99, 1046.50,
		880.00, 783.99, 659.25, 523.25
	]

	var samples_per_note = int(note_duration * sample_rate)
	var total_samples = samples_per_note * notes.size()
	var audio_data = PackedByteArray()
	audio_data.resize(total_samples * 2)
	var phase = 0.0

	for i in range(total_samples):
		var note_index = int(i / samples_per_note)
		var local_sample = i % samples_per_note
		var frequency = notes[note_index]

		phase += TAU * frequency / sample_rate

		var progress = float(local_sample) / samples_per_note
		var envelope = minf(progress * 15.0, 1.0)
		envelope *= minf((1.0 - progress) * 8.0, 1.0)

		var main_tone = sin(phase)
		var soft_harmony = sin(phase * 2.0) * 0.20
		var sample = (main_tone + soft_harmony) * 0.12 * envelope

		audio_data.encode_s16(i * 2, int(sample * 32767.0))

	var music = AudioStreamWAV.new()
	music.format = AudioStreamWAV.FORMAT_16_BITS
	music.mix_rate = sample_rate
	music.stereo = false
	music.data = audio_data
	music.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music.loop_begin = 0
	music.loop_end = total_samples
	return music


func play_coin_sound():
	if coin_sound_player:
		coin_sound_player.play()


func play_button_sound():
	if button_sound_player:
		button_sound_player.play()


func toggle_music():
	music_enabled = not music_enabled

	if music_enabled:
		if not music_player.playing:
			music_player.play()
	else:
		music_player.stop()

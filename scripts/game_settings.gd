extends Node

signal changed(key: String)

const DEFAULTS = {"music_volume": 1, "sound_volume": 1, "voice_volume": 1, "text_speed": 1, "fullscreen": false}
const VOLUME_LEVELS = [0.0, 0.25, 0.6, 1.0]
const TEXT_SPEEDS = [90.0, 40.0, 15.0]
const AUDIO_BUSES = {"music_volume": "Music", "sound_volume": "SFX", "voice_volume": "Voice"}

var values: Dictionary = DEFAULTS.duplicate()
var config_path: String = "user://settings.cfg"
var music_player: AudioStreamPlayer
var sound_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var click_sound: AudioStreamWAV
var windowed_size: Vector2i
var windowed_position: Vector2i

func _ready() -> void:
	for bus_name in AUDIO_BUSES.values():
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	music_player = CreatePlayer("Music")
	sound_player = CreatePlayer("SFX")
	voice_player = CreatePlayer("Voice")
	click_sound = CreateClickSound()
	if DisplayServer.get_name() != "headless":
		windowed_size = DisplayServer.window_get_size()
		windowed_position = DisplayServer.window_get_position()
	LoadSettings()
	get_tree().node_added.connect(ConnectButtonSound)

func CreatePlayer(bus_name: String) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.bus = bus_name
	add_child(player)
	return player

func IsValidValue(key: String, value: Variant) -> bool:
	if key == "fullscreen":
		return value is bool
	if key not in DEFAULTS or not value is int:
		return false
	return value >= 0 and value < (3 if key == "text_speed" else 4)

func GetValue(key: String) -> Variant:
	return values.get(key)

func SetValue(key: String, value: Variant) -> Error:
	if not IsValidValue(key, value):
		return ERR_INVALID_PARAMETER
	values[key] = value
	ApplyValue(key)
	changed.emit(key)
	return SaveSettings()

func LoadSettings() -> void:
	values = DEFAULTS.duplicate()
	var config = ConfigFile.new()
	if config.load(config_path) == OK:
		for key in DEFAULTS:
			var value = config.get_value("settings", key, DEFAULTS[key])
			if IsValidValue(key, value):
				values[key] = value
	for key in DEFAULTS:
		ApplyValue(key)
	changed.emit("")

func SaveSettings() -> Error:
	var config = ConfigFile.new()
	for key in DEFAULTS:
		config.set_value("settings", key, values[key])
	return config.save(config_path)

func ApplyValue(key: String) -> void:
	if AUDIO_BUSES.has(key):
		var index = AudioServer.get_bus_index(AUDIO_BUSES[key])
		var volume = VOLUME_LEVELS[int(values[key])]
		AudioServer.set_bus_mute(index, volume == 0.0)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.001)))
	elif key == "fullscreen" and DisplayServer.get_name() != "headless":
		if values[key]:
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
				windowed_size = DisplayServer.window_get_size()
				windowed_position = DisplayServer.window_get_position()
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			if windowed_size.x > 0 and windowed_size.y > 0:
				DisplayServer.window_set_size(windowed_size)
				DisplayServer.window_set_position(windowed_position)

func GetTextSpeed() -> float:
	return TEXT_SPEEDS[int(values["text_speed"])]

func PlayMusic(stream: AudioStream) -> void:
	if music_player.stream == stream and music_player.playing:
		return
	music_player.stream = stream
	music_player.play()

func PlaySound(stream: AudioStream) -> void:
	sound_player.stream = stream
	sound_player.play()

func PlayVoice(stream: AudioStream) -> void:
	voice_player.stream = stream
	voice_player.play()

func PlayVoiceId(identifier: String) -> void:
	voice_player.stop()
	if identifier.is_empty():
		return
	var paths: Array[String] = []
	if identifier.begins_with("res://"):
		paths.append(identifier)
	else:
		for directory in ["res://audio/voice/", "res://assets/audio/voice/"]:
			for extension in [".ogg", ".wav", ".mp3"]:
				paths.append(directory + identifier + extension)
	for path in paths:
		if ResourceLoader.exists(path):
			var stream = load(path)
			if stream is AudioStream:
				PlayVoice(stream)
				return

func ConnectButtonSound(node: Node) -> void:
	if node is BaseButton and not node.button_down.is_connected(PlayClick):
		node.button_down.connect(PlayClick)

func PlayClick() -> void:
	PlaySound(click_sound)

func CreateClickSound() -> AudioStreamWAV:
	# A quiet menu click; game music and voice use their own supplied streams.
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var samples = 882
	var data = PackedByteArray()
	data.resize(samples * 2)
	for index in range(samples):
		var envelope = pow(1.0 - float(index) / samples, 3.0)
		var sample = sin(TAU * 1000.0 * index / stream.mix_rate) * envelope * 0.12
		data.encode_s16(index * 2, int(sample * 32767.0))
	stream.data = data
	return stream

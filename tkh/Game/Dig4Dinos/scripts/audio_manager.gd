extends Node

# AudioManager - Global singleton for handling all game audio
# This handles background music, sound effects, and audio settings

@onready var music_player: AudioStreamPlayer
@onready var sfx_player: AudioStreamPlayer
@onready var ui_player: AudioStreamPlayer

# Audio resources
var audio_resources = {}

# Digging sound management
var current_dig_sound = ""
var dig_sound_timer = 0.0
var dig_sound_interval = 0.3  # Play dig sound every 0.3 seconds for smooth looping
var is_digging = false

# Volume settings
var master_volume = 1.0
var music_volume = 1.0  # Increased to full volume
var sfx_volume = 0.8
var ui_volume = 0.9

func _ready():
	# Create audio players
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Master"
	add_child(music_player)
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.bus = "Master"
	add_child(sfx_player)
	
	ui_player = AudioStreamPlayer.new()
	ui_player.name = "UIPlayer"
	ui_player.bus = "Master"
	add_child(ui_player)
	
	# Load all audio resources
	_load_audio_resources()
	
	# Apply volume settings
	_update_volumes()
	
	# Music will be started by main menu when ready

func _load_audio_resources():
	print("Loading audio resources...")
	
	# Background music with error checking
	var bg_music_path = "res://assets/audio/bg_main_background.wav"
	var bg_music_resource = load(bg_music_path)
	if bg_music_resource:
		audio_resources["bg_music"] = bg_music_resource
		print("✓ Background music loaded successfully: ", bg_music_path)
	else:
		print("✗ ERROR: Could not load background music from: ", bg_music_path)
	
	# Digging sounds for different geological layers
	audio_resources["dig_dirt"] = load("res://assets/audio/dig_dirt.wav")
	audio_resources["dig_sand"] = load("res://assets/audio/dig_sand.wav")
	audio_resources["dig_gravel"] = load("res://assets/audio/dig_gravel.wav")
	audio_resources["dig_rock"] = load("res://assets/audio/dig_rock.mp3")
	
	# Discovery and reward sounds
	audio_resources["find_bone"] = load("res://assets/audio/find_bone.mp3")
	audio_resources["coin"] = load("res://assets/audio/coin.wav")
	
	# UI sounds
	audio_resources["button"] = load("res://assets/audio/button.wav")
	
	print("Audio resources loaded: ", audio_resources.keys())

func _update_volumes():
	# Simplified volume calculation - using direct db values
	music_player.volume_db = 0.0  # Full volume for music
	sfx_player.volume_db = linear_to_db(master_volume * sfx_volume)
	ui_player.volume_db = linear_to_db(master_volume * ui_volume)
	print("🔊 Volumes updated - Music: ", music_player.volume_db, "db, SFX: ", sfx_player.volume_db, "db")

# Music control
func play_background_music():
	print("🎵 Attempting to start background music...")
	if audio_resources.has("bg_music") and audio_resources["bg_music"] != null:
		var music_stream = audio_resources["bg_music"]
		print("✓ Music loaded: ", music_stream.resource_path)
		
		# Configure looping BEFORE assigning to player
		if music_stream is AudioStreamWAV:
			music_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			print("✓ WAV looping configured")
		elif music_stream is AudioStreamOggVorbis:
			music_stream.loop = true
			print("✓ OGG looping configured")
		
		# Now assign the properly configured stream
		music_player.stream = music_stream
		# Set volume to 0db (full volume) for testing
		music_player.volume_db = 0.0
		music_player.play()
		print("🎵 Background music started - Volume: ", music_player.volume_db, "db, Playing: ", music_player.playing)
		print("🎵 Music player bus: ", music_player.bus)
		print("🎵 Stream length: ", music_stream.get_length() if music_stream.has_method("get_length") else "unknown")
	else:
		print("✗ ERROR: Background music resource not found")
		print("Available resources: ", audio_resources.keys())

func stop_background_music():
	music_player.stop()

func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	_update_volumes()

# Sound effects - Smart digging sound system
func start_digging_sound(geological_layer: String):
	var sound_key = ""
	
	# Map geological layers to appropriate dig sounds
	match geological_layer.to_lower():
		"grass", "topsoil":
			sound_key = "dig_dirt"
		"sand", "clay":
			sound_key = "dig_sand"
		"gravel", "loose_rock":
			sound_key = "dig_gravel"
		"solid_rock", "limestone", "sandstone", "shale", "granite", "bedrock":
			sound_key = "dig_rock"
		_:
			sound_key = "dig_dirt"  # Default fallback
	
	# Only start new sound if different material or not currently digging
	if sound_key != current_dig_sound or not is_digging:
		current_dig_sound = sound_key
		is_digging = true
		dig_sound_timer = 0.0
		
		# Play the sound immediately for responsiveness
		if audio_resources.has(sound_key):
			sfx_player.stream = audio_resources[sound_key]
			sfx_player.play()

func stop_digging_sound():
	is_digging = false
	current_dig_sound = ""
	dig_sound_timer = 0.0
	# Let current sound finish naturally for smooth transition

# Removed problematic _on_music_finished - native looping should handle this

func _process(delta):
	# Handle continuous digging sound looping
	if is_digging and current_dig_sound != "":
		dig_sound_timer += delta
		
		# Play sound at intervals to create smooth loop without stacking
		if dig_sound_timer >= dig_sound_interval:
			if audio_resources.has(current_dig_sound):
				# Only play if previous sound finished or almost finished
				if not sfx_player.playing or sfx_player.get_playback_position() > (sfx_player.stream.get_length() * 0.7):
					sfx_player.stream = audio_resources[current_dig_sound]
					sfx_player.play()
			dig_sound_timer = 0.0

# Legacy function for compatibility - redirects to new system
func play_dig_sound(geological_layer: String):
	start_digging_sound(geological_layer)

func play_bone_discovery_sound(bone_size: String = ""):
	# Use find_bone for bone discoveries
	if audio_resources.has("find_bone"):
		sfx_player.stream = audio_resources["find_bone"]
		sfx_player.play()
		print("Played bone discovery sound")

func play_coin_sound():
	if audio_resources.has("coin"):
		sfx_player.stream = audio_resources["coin"]
		sfx_player.play()

func play_ui_sound(sound_type: String = "button"):
	var sound_key = sound_type
	if audio_resources.has(sound_key):
		ui_player.stream = audio_resources[sound_key]
		ui_player.play()

# Volume controls
func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	_update_volumes()

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
	_update_volumes()

func set_ui_volume(volume: float):
	ui_volume = clamp(volume, 0.0, 1.0)
	_update_volumes()

# Utility functions
func stop_all_sounds():
	sfx_player.stop()
	ui_player.stop()

func is_music_playing() -> bool:
	return music_player.playing
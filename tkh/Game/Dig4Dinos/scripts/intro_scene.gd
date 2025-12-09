extends Control

@onready var video_player = $VideoStreamPlayer
@onready var skip_button = $SkipButton  
@onready var skip_label = $SkipLabel
@onready var background = $Background

var intro_finished = false
var video_timeout_timer: Timer

func _ready():
	print("Intro scene starting...")
	
	# Setup timeout timer as fallback
	video_timeout_timer = Timer.new()
	video_timeout_timer.wait_time = 10.0  # 10 second timeout
	video_timeout_timer.one_shot = true
	video_timeout_timer.timeout.connect(_on_video_timeout)
	add_child(video_timeout_timer)
	video_timeout_timer.start()
	
	# Ensure video player is properly configured
	if video_player:
		print("Video player found, configuring...")
		
		# Connect signals
		video_player.finished.connect(_on_video_finished)
		
		# Force video properties for better display
		video_player.expand = true
		video_player.volume_db = 0.0
		
		# Check if stream is loaded
		if video_player.stream == null:
			print("Warning: Video stream not loaded, trying to load manually")
			# Try to load video manually - try OGV first, then MP4 as fallback
			var video_stream = load("res://assets/video/AstromoIntro.ogv")
			if not video_stream:
				print("OGV not found, trying MP4 fallback...")
				video_stream = load("res://assets/video/AstromoIntro.mp4")
			
			if video_stream:
				print("✓ Video stream loaded successfully: ", video_stream.resource_path)
				print("✓ Video type: ", video_stream.get_class())
				if video_stream.has_method("get_length"):
					print("✓ Video length: ", video_stream.get_length(), " seconds")
				video_player.stream = video_stream
				# Small delay then play
				await get_tree().process_frame
				video_player.play()
				print("✓ Video playback started - Updated OGV file should be playing")
			else:
				print("❌ Error: Could not load video file - no supported formats found")
				_handle_video_error()
		else:
			# Video loaded successfully from scene, ensure it plays
			print("✓ Video stream already loaded from scene: ", video_player.stream.resource_path)
			print("✓ Video type: ", video_player.stream.get_class())
			if video_player.stream.has_method("get_length"):
				print("✓ Video length: ", video_player.stream.get_length(), " seconds")
			video_player.play()
			print("✓ Updated OGV file should be playing from scene configuration")
			
		# Debug video player state
		print("Video player state - Playing: ", video_player.is_playing())
		print("Video stream: ", video_player.stream)
	else:
		print("Error: Video player not found!")
		_skip_intro()
	
	# Connect skip button
	if skip_button:
		skip_button.pressed.connect(_skip_intro)
	
	# Auto-hide skip elements initially, show after 2 seconds
	if skip_button and skip_label:
		skip_button.modulate.a = 0.0
		skip_label.modulate.a = 0.0
		# Fade in skip elements after 2 seconds
		await get_tree().create_timer(2.0).timeout
		if not intro_finished:
			var tween = create_tween()
			tween.parallel().tween_property(skip_button, "modulate:a", 0.8, 1.0)
			tween.parallel().tween_property(skip_label, "modulate:a", 0.8, 1.0)

func _input(event):
	# Skip on any key press or mouse click after 1 second
	if not intro_finished and get_tree().get_frame() > 60:  # After ~1 second at 60fps
		if event is InputEventKey and event.pressed:
			_skip_intro()
		elif event is InputEventMouseButton and event.pressed:
			_skip_intro()
		elif event is InputEventScreenTouch and event.pressed:
			_skip_intro()

func _skip_intro():
	if not intro_finished:
		intro_finished = true
		# Play UI sound for skip action
		if AudioManager:
			AudioManager.play_ui_sound("button")
		# Stop video if playing
		if video_player and video_player.is_playing():
			video_player.stop()
		_transition_to_main_menu()

func _on_video_finished():
	if not intro_finished:
		intro_finished = true
		# Small delay before transitioning
		await get_tree().create_timer(0.5).timeout
		_transition_to_main_menu()

func _handle_video_error():
	print("Handling video error - will skip to main menu in 2 seconds")
	# Show error message briefly
	if skip_label:
		skip_label.text = "Video not found - loading game..."
		skip_label.modulate.a = 1.0
	
	# Auto-skip after 2 seconds
	await get_tree().create_timer(2.0).timeout
	_skip_intro()

func _on_video_timeout():
	print("Video timeout reached - skipping intro")
	if not intro_finished:
		_skip_intro()

func _transition_to_main_menu():
	print("Transitioning to main menu...")
	# Stop timeout timer
	if video_timeout_timer:
		video_timeout_timer.stop()
		
	# Smooth fade out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	
	# Change to main menu
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
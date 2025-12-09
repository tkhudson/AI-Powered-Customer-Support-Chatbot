extends Control

var play_button: Button
var shop_button: Button
var quit_button: Button
var title_label: Label
var version_label: Label

func _ready():
	# Create UI elements if they don't exist
	create_menu_ui()
	
	# Connect button signals
	if play_button:
		play_button.pressed.connect(_on_start_pressed)
	if shop_button:
		shop_button.pressed.connect(_on_shop_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	
	# Add menu background
	add_menu_background()
	
	# Setup UI elements
	setup_menu_ui()
	
	# Start background music
	if AudioManager and not AudioManager.is_music_playing():
		AudioManager.play_background_music()

func create_menu_ui():
	# Get existing VBoxContainer from scene
	var vbox = get_node_or_null("VBoxContainer")
	if not vbox:
		return  # Scene structure not as expected
	
	# Get existing scene nodes (use StartButton from scene, not PlayButton)
	play_button = vbox.get_node_or_null("StartButton")  # Use existing StartButton
	shop_button = vbox.get_node_or_null("ShopButton")
	quit_button = vbox.get_node_or_null("QuitButton")
	title_label = vbox.get_node_or_null("TitleLabel")
	
	# Create version label if it doesn't exist
	version_label = vbox.get_node_or_null("VersionLabel")
	if not version_label:
		version_label = Label.new()
		version_label.name = "VersionLabel"
		vbox.add_child(version_label)
		# Move version label to after title
		if title_label:
			vbox.move_child(version_label, title_label.get_index() + 1)

func setup_menu_ui():
	# Setup title label
	if title_label:
		title_label.text = "🦕 DIG 4 DINOS 🦴"
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.add_theme_font_size_override("font_size", 32)
	
	# Setup version label
	if version_label:
		version_label.text = "MVP v1.0 - Archaeological Adventure"
		version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		version_label.add_theme_font_size_override("font_size", 14)
		version_label.modulate = Color(0.7, 0.7, 0.7, 1.0)
	
	# Setup button texts and styling
	if play_button:
		play_button.text = "🎮 START DIGGING"
		play_button.custom_minimum_size = Vector2(200, 50)
	
	if shop_button:
		shop_button.text = "🛒 SHOP"
		shop_button.custom_minimum_size = Vector2(200, 50)
	
	if quit_button:
		quit_button.text = "❌ EXIT"
		quit_button.custom_minimum_size = Vector2(200, 50)

func add_menu_background():
	# Load and add menu background
	var bg_texture = load("res://assets/ui/MenuBG.png")
	if bg_texture:
		var bg_sprite = TextureRect.new()
		bg_sprite.texture = bg_texture
		bg_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		bg_sprite.z_index = -1
		add_child(bg_sprite)
		move_child(bg_sprite, 0)  # Move to back

func _on_start_pressed():
	# Play UI sound
	if AudioManager:
		AudioManager.play_ui_sound("button")
	# Set flag for showing loading screen in game
	GameState.show_loading = true
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_shop_pressed():
	# Play UI sound
	if AudioManager:
		AudioManager.play_ui_sound("button")
	get_tree().change_scene_to_file("res://scenes/shop.tscn")

func _on_quit_pressed():
	# Play UI sound
	if AudioManager:
		AudioManager.play_ui_sound("button")
	get_tree().quit()

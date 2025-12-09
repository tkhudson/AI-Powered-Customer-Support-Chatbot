extends Control

@onready var coins_label = $StaticUI/CoinsLabel
@onready var bones_label = $StaticUI/BonesLabel
@onready var depth_label = $StaticUI/DepthLabel
@onready var menu_button = $SlideMenu/MenuButton
@onready var slide_menu = $SlideMenu
@onready var menu_panel = $SlideMenu/MenuPanel
@onready var shop_button = $SlideMenu/MenuPanel/VBoxContainer/ShopButton
@onready var leave_site_button = $SlideMenu/MenuPanel/VBoxContainer/LeaveSiteButton

var menu_open = false

func _ready():
	setup_ui()
	update_display()

func setup_ui():
	# Create static UI elements if they don't exist
	if not has_node("StaticUI"):
		create_static_ui()
	
	# Create slide menu if it doesn't exist
	if not has_node("SlideMenu"):
		create_slide_menu()
	
	# Setup connections
	if menu_button:
		menu_button.pressed.connect(_on_menu_button_pressed)
	if shop_button:
		shop_button.pressed.connect(_on_shop_pressed)
	if leave_site_button:
		leave_site_button.pressed.connect(_on_leave_site_pressed)

func create_static_ui():
	# Create static UI container
	var static_ui = VBoxContainer.new()
	static_ui.name = "StaticUI"
	static_ui.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	static_ui.position = Vector2(10, 10)
	add_child(static_ui)
	
	# Create labels
	if not coins_label:
		coins_label = Label.new()
		coins_label.name = "CoinsLabel"
		coins_label.text = "Coins: 0"
		static_ui.add_child(coins_label)
	
	if not bones_label:
		bones_label = Label.new()
		bones_label.name = "BonesLabel"
		bones_label.text = "Bones: 0"
		static_ui.add_child(bones_label)
	
	if not depth_label:
		depth_label = Label.new()
		depth_label.name = "DepthLabel"
		depth_label.text = "Depth: 0% (SURFACE) - Start digging!"
		static_ui.add_child(depth_label)
	


func create_slide_menu():
	# Create slide menu container
	slide_menu = Control.new()
	slide_menu.name = "SlideMenu"
	slide_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slide_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(slide_menu)
	
	# Create pull-out tab
	if not menu_button:
		menu_button = Button.new()
		menu_button.name = "MenuButton"
		menu_button.text = "☰"
		menu_button.size = Vector2(25, 60)
		menu_button.position = Vector2(0, get_viewport().get_visible_rect().size.y / 2 - 30)  # Center vertically on left edge
		slide_menu.add_child(menu_button)
	
	# Create menu panel
	menu_panel = Panel.new()
	menu_panel.name = "MenuPanel"
	menu_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	menu_panel.size = Vector2(150, 110)
	menu_panel.position = Vector2(-150, get_viewport().get_visible_rect().size.y / 2 - 55)  # Start off-screen, centered vertically
	slide_menu.add_child(menu_panel)
	
	# Create button container
	var button_container = VBoxContainer.new()
	button_container.name = "VBoxContainer"
	button_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button_container.add_theme_constant_override("separation", 5)
	menu_panel.add_child(button_container)
	
	# Create menu buttons
	if not shop_button:
		shop_button = Button.new()
		shop_button.name = "ShopButton"
		shop_button.text = "Shop"
		button_container.add_child(shop_button)
	
	if not leave_site_button:
		leave_site_button = Button.new()
		leave_site_button.name = "LeaveSiteButton"
		leave_site_button.text = "Leave Site"
		button_container.add_child(leave_site_button)

func update_display():
	if GameState:
		coins_label.text = "💰 " + str(GameState.player_data["coins"])
		
		var total_bones = 0
		for bone_type in GameState.player_data["bones"]:
			total_bones += GameState.player_data["bones"][bone_type]
		
		bones_label.text = "🦴 " + str(total_bones)
		
		# Update depth display
		update_depth_display()

func update_depth_display():
	# Get current maximum depth from digging mechanic
	var digging_mechanic = get_parent().get_node("DiggingMechanic")
	if digging_mechanic and digging_mechanic.has_method("get_current_max_depth"):
		var max_depth = digging_mechanic.get_current_max_depth()
		var depth_percent = int(max_depth * 100)
		
		# Get layer name and guidance
		var layer_name = ""
		var guidance = ""
		
		if depth_percent < 25:
			layer_name = "SURFACE"
			guidance = "Keep digging to find medium bones!"
		elif depth_percent < 60:
			layer_name = "MIDDLE"  
			guidance = "Dig deeper for large bones!"
		elif depth_percent < 85:
			layer_name = "DEEP"
			guidance = "LARGE BONE TERRITORY!"
		else:
			layer_name = "BEDROCK"
			guidance = "Maximum depth reached!"
		
		# Color-coded depth display with warnings
		if depth_percent >= 60:
			depth_label.text = "Depth: " + str(depth_percent) + "% (" + layer_name + ") - " + guidance
			depth_label.modulate = Color.YELLOW
		elif depth_percent >= 55:
			depth_label.text = "Depth: " + str(depth_percent) + "% (" + layer_name + ") - " + guidance
			depth_label.modulate = Color.ORANGE
		elif depth_percent >= 25:
			depth_label.text = "Depth: " + str(depth_percent) + "% (" + layer_name + ") - " + guidance
			depth_label.modulate = Color.LIGHT_BLUE
		else:
			depth_label.text = "Depth: " + str(depth_percent) + "% (" + layer_name + ") - " + guidance
			depth_label.modulate = Color.WHITE
	else:
		depth_label.text = "Depth: 0% (SURFACE) - Start digging!"

func _on_menu_button_pressed():
	# Play UI sound
	if AudioManager:
		AudioManager.play_ui_sound("button")
	toggle_menu()

func toggle_menu():
	menu_open = !menu_open
	var tween = create_tween()
	var target_x = 25 if menu_open else -150  # Position next to the tab when open
	
	if menu_panel:
		tween.tween_property(menu_panel, "position:x", target_x, 0.3)
		# Enable/disable mouse filter for menu interaction
		if menu_open:
			slide_menu.mouse_filter = Control.MOUSE_FILTER_PASS
		else:
			slide_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_shop_pressed():
	# Play UI sound
	if AudioManager:
		AudioManager.play_ui_sound("button")
	toggle_menu()  # Close menu
	# Show shop overlay instead of changing scenes
	get_parent().show_shop_overlay()

func _on_leave_site_pressed():
	# Play UI sound
	if AudioManager:
		AudioManager.play_ui_sound("button")
	toggle_menu()  # Close menu
	# Clear dig site preservation and return to main menu
	GameState.preserve_dig_site = false
	GameState.returning_to_site = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
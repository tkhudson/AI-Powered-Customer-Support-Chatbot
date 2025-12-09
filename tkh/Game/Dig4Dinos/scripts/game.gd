extends Control

@onready var digging_mechanic = $DiggingMechanic
@onready var hud = $HUD
var shop_overlay: Control = null

func _ready():
	# Connect to digging events
	digging_mechanic.bone_collected.connect(_on_bone_collected)
	digging_mechanic.bone_revealed.connect(_on_bone_revealed)
	
	# Initialize HUD
	update_hud()

func _on_bone_collected(bone_type: String, position: Vector2):
	print("Collected: ", bone_type)
	update_hud()

func _on_bone_revealed(bone_type: String, position: Vector2):
	print("Revealed: ", bone_type)

func update_hud():
	if hud and hud.has_method("update_display"):
		hud.update_display()
	else:
		# Update HUD labels directly
		var coins_label = hud.get_node_or_null("VBoxContainer/CoinsLabel")
		var bones_label = hud.get_node_or_null("VBoxContainer/BonesLabel")
		
		if coins_label and GameState:
			coins_label.text = "Coins: " + str(GameState.player_data["coins"])
		
		if bones_label and GameState:
			var total_bones = 0
			for bone_type in GameState.player_data["bones"]:
				total_bones += GameState.player_data["bones"][bone_type]
			bones_label.text = "Bones: " + str(total_bones)

func show_shop_overlay():
	if shop_overlay:
		return  # Already showing
	
	# Create shop overlay with high z-index to appear above everything
	shop_overlay = Control.new()
	shop_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shop_overlay.z_index = 100  # Very high z-index to be above HUD
	
	# Full-screen shop background (same as main menu)
	var shop_bg_texture = load("res://assets/ui/ShopBG.png")
	if shop_bg_texture:
		var shop_bg = TextureRect.new()
		shop_bg.texture = shop_bg_texture
		shop_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		shop_bg.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		shop_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shop_overlay.add_child(shop_bg)
	
	# Shop content container - properly centered for any screen size
	var shop_container = VBoxContainer.new()
	shop_container.add_theme_constant_override("separation", 25)
	# Set anchors to center
	shop_container.anchor_left = 0.5
	shop_container.anchor_top = 0.5
	shop_container.anchor_right = 0.5
	shop_container.anchor_bottom = 0.5
	# Set size and center it properly
	shop_container.custom_minimum_size = Vector2(320, 280)
	shop_container.size = Vector2(320, 280)
	# Offset by half the size to truly center
	shop_container.offset_left = -160  # Half of 320
	shop_container.offset_top = -140   # Half of 280
	shop_container.offset_right = 160
	shop_container.offset_bottom = 140
	
	# Shop title with heavy stroke
	var title = Label.new()
	title.text = "SHOP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.WHITE)
	# Heavy stroke/outline
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 6)
	shop_container.add_child(title)
	
	# Coins display with heavy stroke
	var coins_label = Label.new()
	coins_label.name = "CoinsLabel"
	coins_label.text = "Coins: " + str(GameState.player_data["coins"])
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coins_label.add_theme_font_size_override("font_size", 20)
	coins_label.add_theme_color_override("font_color", Color.YELLOW)
	# Heavy stroke/outline
	coins_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	coins_label.add_theme_constant_override("shadow_offset_x", 2)
	coins_label.add_theme_constant_override("shadow_offset_y", 2)
	coins_label.add_theme_color_override("font_outline_color", Color.BLACK)
	coins_label.add_theme_constant_override("outline_size", 4)
	shop_container.add_child(coins_label)
	
	# Tool buttons with better styling
	var pickaxe_button = Button.new()
	pickaxe_button.name = "PickaxeButton"
	pickaxe_button.custom_minimum_size = Vector2(280, 40)
	var brush_button = Button.new()
	brush_button.name = "BrushButton"
	brush_button.custom_minimum_size = Vector2(280, 40)
	
	# Setup tool buttons
	update_shop_buttons(pickaxe_button, brush_button, coins_label)
	
	shop_container.add_child(pickaxe_button)
	shop_container.add_child(brush_button)
	
	# Close button with better styling
	var close_button = Button.new()
	close_button.text = "Close Shop"
	close_button.custom_minimum_size = Vector2(280, 40)
	close_button.pressed.connect(hide_shop_overlay)
	shop_container.add_child(close_button)
	
	# Connect tool buttons
	pickaxe_button.pressed.connect(_on_shop_pickaxe_pressed.bind(pickaxe_button, brush_button, coins_label))
	brush_button.pressed.connect(_on_shop_brush_pressed.bind(pickaxe_button, brush_button, coins_label))
	
	shop_overlay.add_child(shop_container)
	add_child(shop_overlay)
	
	# Pause digging while shop is open
	digging_mechanic.set_process_input(false)

func hide_shop_overlay():
	if shop_overlay:
		shop_overlay.queue_free()
		shop_overlay = null
		
		# Resume digging
		digging_mechanic.set_process_input(true)
		
		# Update HUD
		update_hud()

func update_shop_buttons(pickaxe_button: Button, brush_button: Button, coins_label: Label):
	var tool_prices = {"pickaxe": 500, "brush": 200}
	
	coins_label.text = "Coins: " + str(GameState.player_data["coins"])
	
	if GameState.has_tool("pickaxe"):
		pickaxe_button.text = "Pickaxe - OWNED"
		pickaxe_button.disabled = true
	else:
		pickaxe_button.text = "Pickaxe - " + str(tool_prices["pickaxe"]) + " coins"
		pickaxe_button.disabled = GameState.player_data["coins"] < tool_prices["pickaxe"]
	
	if GameState.has_tool("brush"):
		brush_button.text = "Brush - OWNED"
		brush_button.disabled = true
	else:
		brush_button.text = "Brush - " + str(tool_prices["brush"]) + " coins"
		brush_button.disabled = GameState.player_data["coins"] < tool_prices["brush"]

func _on_shop_pickaxe_pressed(pickaxe_button: Button, brush_button: Button, coins_label: Label):
	# Play UI sound
	if AudioManager:
		AudioManager.play_ui_sound("button")
	if GameState.purchase_tool("pickaxe", 500):
		# Play coin sound for successful purchase
		if AudioManager:
			AudioManager.play_coin_sound()
		update_shop_buttons(pickaxe_button, brush_button, coins_label)

func _on_shop_brush_pressed(pickaxe_button: Button, brush_button: Button, coins_label: Label):
	# Play UI sound
	if AudioManager:
		AudioManager.play_ui_sound("button")
	if GameState.purchase_tool("brush", 200):
		# Play coin sound for successful purchase
		if AudioManager:
			AudioManager.play_coin_sound()
		update_shop_buttons(pickaxe_button, brush_button, coins_label)

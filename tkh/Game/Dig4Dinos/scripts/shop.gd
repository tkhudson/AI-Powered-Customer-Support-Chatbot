extends Control

@onready var coins_label = $VBoxContainer/CoinsLabel
@onready var pickaxe_button = $VBoxContainer/PickaxeButton
@onready var brush_button = $VBoxContainer/BrushButton
@onready var back_button = $VBoxContainer/BackButton

var tool_prices = {
	"pickaxe": 300,  # Reduced price for faster access
	"brush": 100,   # More affordable
	"drill": 800     # Advanced tool for deepest layers
}

var upgrade_prices = {
	"dig_speed": 150,
	"bone_detector": 400
}

func _ready():
	pickaxe_button.pressed.connect(_on_pickaxe_pressed)
	brush_button.pressed.connect(_on_brush_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Add shop background
	add_shop_background()
	
	# Apply proper centering and styling
	setup_shop_styling()
	
	update_shop()

func add_shop_background():
	# Load and add shop background
	var bg_texture = load("res://assets/ui/ShopBG.png")
	if bg_texture:
		var bg_sprite = TextureRect.new()
		bg_sprite.texture = bg_texture
		bg_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		bg_sprite.z_index = -1
		add_child(bg_sprite)
		move_child(bg_sprite, 0)  # Move to back

func setup_shop_styling():
	# Get the VBoxContainer
	var vbox = $VBoxContainer
	if vbox:
		# Apply proper centering like in-game shop overlay
		vbox.anchor_left = 0.5
		vbox.anchor_top = 0.5
		vbox.anchor_right = 0.5
		vbox.anchor_bottom = 0.5
		# Set size and center it properly
		vbox.custom_minimum_size = Vector2(320, 280)
		vbox.size = Vector2(320, 280)
		# Offset by half the size to truly center
		vbox.offset_left = -160  # Half of 320
		vbox.offset_top = -140   # Half of 280
		vbox.offset_right = 160
		vbox.offset_bottom = 140
		# Adjust separation
		vbox.add_theme_constant_override("separation", 25)
	
	# Add heavy text strokes to labels and improve styling
	if coins_label:
		coins_label.add_theme_font_size_override("font_size", 20)
		coins_label.add_theme_color_override("font_color", Color.YELLOW)
		# Heavy stroke/outline
		coins_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		coins_label.add_theme_constant_override("shadow_offset_x", 2)
		coins_label.add_theme_constant_override("shadow_offset_y", 2)
		coins_label.add_theme_color_override("font_outline_color", Color.BLACK)
		coins_label.add_theme_constant_override("outline_size", 4)
		coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Add title label if it doesn't exist
	var vbox_container = $VBoxContainer
	if vbox_container and not vbox_container.get_node_or_null("TitleLabel"):
		var title_label = Label.new()
		title_label.name = "TitleLabel"
		title_label.text = "SHOP"
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.add_theme_font_size_override("font_size", 32)
		title_label.add_theme_color_override("font_color", Color.WHITE)
		# Heavy stroke/outline
		title_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		title_label.add_theme_constant_override("shadow_offset_x", 3)
		title_label.add_theme_constant_override("shadow_offset_y", 3)
		title_label.add_theme_color_override("font_outline_color", Color.BLACK)
		title_label.add_theme_constant_override("outline_size", 6)
		# Add as first child
		vbox_container.add_child(title_label)
		vbox_container.move_child(title_label, 0)
	
	# Style buttons to match in-game shop
	if pickaxe_button:
		pickaxe_button.custom_minimum_size = Vector2(280, 40)
	if brush_button:
		brush_button.custom_minimum_size = Vector2(280, 40)
	if back_button:
		back_button.custom_minimum_size = Vector2(280, 40)
		back_button.text = "Back"

func update_shop():
	if GameState:
		coins_label.text = "💰 Coins: " + str(GameState.player_data["coins"])
		
		# Update tool buttons based on ownership
		update_tool_button(pickaxe_button, "pickaxe", "⛏️ Pickaxe", "Dig deeper layers!")
		update_tool_button(brush_button, "brush", "🖌️ Brush", "Reveal bones faster!")
		
		# Add drill button dynamically if pickaxe owned
		if GameState.has_tool("pickaxe") and not has_node("VBoxContainer/DrillButton"):
			add_drill_button()

func update_tool_button(button: Button, tool_name: String, display_name: String, description: String):
	if GameState.has_tool(tool_name):
		button.text = display_name + " - ✅ OWNED"
		button.disabled = true
		button.modulate = Color(0.7, 0.9, 0.7, 1.0)  # Green tint
	else:
		button.text = display_name + " - $" + str(tool_prices[tool_name])
		if GameState.player_data["coins"] < tool_prices[tool_name]:
			button.disabled = true
			button.modulate = Color(0.7, 0.7, 0.7, 1.0)  # Gray tint
		else:
			button.disabled = false
			button.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Normal

func add_drill_button():
	var vbox = $VBoxContainer
	var drill_button = Button.new()
	drill_button.name = "DrillButton"
	drill_button.text = "🔧 Drill - $" + str(tool_prices["drill"])
	drill_button.pressed.connect(_on_drill_pressed)
	vbox.add_child(drill_button)
	vbox.move_child(drill_button, vbox.get_child_count() - 2)  # Before back button
	update_tool_button(drill_button, "drill", "🔧 Drill", "Access bedrock layers!")

func _on_pickaxe_pressed():
	# Play UI sound
	if AudioManager:
		AudioManager.play_ui_sound("button")
	if GameState.purchase_tool("pickaxe", tool_prices["pickaxe"]):
		# Play coin sound for successful purchase
		if AudioManager:
			AudioManager.play_coin_sound()
		update_shop()

func _on_brush_pressed():
	# Play UI sound
	if AudioManager:
		AudioManager.play_ui_sound("button")
	if GameState.purchase_tool("brush", tool_prices["brush"]):
		# Play coin sound for successful purchase
		if AudioManager:
			AudioManager.play_coin_sound()
		update_shop()

func _on_drill_pressed():
	# Play UI sound
	if AudioManager:
		AudioManager.play_ui_sound("button")
	if GameState.purchase_tool("drill", tool_prices["drill"]):
		# Play coin sound for successful purchase
		if AudioManager:
			AudioManager.play_coin_sound()
		update_shop()

func _on_back_pressed():
	# Play UI sound
	if AudioManager:
		AudioManager.play_ui_sound("button")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

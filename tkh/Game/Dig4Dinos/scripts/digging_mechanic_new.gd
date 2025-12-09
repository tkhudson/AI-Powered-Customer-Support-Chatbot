extends Node2D

class_name DiggingMechanic

signal bone_revealed(bone_type: String, position: Vector2)
signal dig_started
signal dig_ended
signal bone_collected(bone_type: String, position: Vector2)

var sand_image: Image
var material_map: Image
var image_texture: ImageTexture
var dig_radius: int = 40
var dig_power: float = 5.0  # Increased for faster, more satisfying digging
var max_dig_radius: int = 80

# 10-tier realistic geological system
const MATERIAL_IDS = {
	"grass": 0,
	"topsoil": 1, 
	"dirt": 2,
	"sand": 3,
	"gravel": 4,
	"compacted": 5,
	"clay": 6,
	"soft_rock": 7,
	"hard_rock": 8,
	"bedrock": 9
}
var material_hardness = {
	0: 0.5,  # grass
	1: 0.8,  # topsoil
	2: 1.2,  # dirt
	3: 1.5,  # sand
	4: 2.5,  # gravel
	5: 3.0,  # compacted
	6: 4.0,  # clay
	7: 1.0,  # soft_rock (made much easier for testing)
	8: 1.5,  # hard_rock (made much easier for testing)
	9: 2.0   # bedrock (made much easier for testing)
}
var material_colors = {
	0: Color(0.15, 0.5, 0.18, 1.0),  # Grass - darker green
	1: Color(0.4, 0.3, 0.2, 1.0),  # Topsoil - dark brown
	2: Color(0.7, 0.5, 0.3, 1.0),  # Dirt - brown
	3: Color(0.9, 0.8, 0.6, 1.0),  # Sand - beige
	4: Color(0.6, 0.6, 0.5, 1.0),  # Gravel - gray-brown
	5: Color(0.8, 0.7, 0.5, 1.0),  # Compacted - darker beige
	6: Color(0.6, 0.4, 0.2, 1.0),  # Clay - dark brown
	7: Color(0.7, 0.7, 0.6, 1.0),  # Soft rock - light gray
	8: Color(0.5, 0.5, 0.5, 1.0),  # Hard rock - gray
	9: Color(0.3, 0.3, 0.3, 1.0)   # Bedrock - dark gray
}

var is_digging: bool = false
var dig_hold_time: float = 0.0
var dig_timer: float = 0.0
var current_touch_position: Vector2 = Vector2.ZERO
var sand_width: int = 480
var sand_height: int = 14400  # 9x deeper dig site - massive archaeological site

# Professional multi-layer geological system for scalable game architecture
enum GEOLOGICAL_LAYER {
	SURFACE = 0,    # 0-30% depth - grass, topsoil, dirt
	MIDDLE = 1,     # 30-60% depth - sand, clay, gravel  
	DEEP = 2,       # 60-85% depth - soft rock, hard rock (PICKAXE LAYER)
	BEDROCK = 3     # 85-100% depth - bedrock (FUTURE LAYER 3)
}

# Scalable layer configuration system for future expansion
var layer_config = {
	GEOLOGICAL_LAYER.SURFACE: {
		"depth_range": [0.0, 0.3],
		"bone_types": ["small"],
		"bone_count": 15,
		"tools_required": [],
		"material_types": ["grass", "topsoil", "dirt"]
	},
	GEOLOGICAL_LAYER.MIDDLE: {
		"depth_range": [0.3, 0.6], 
		"bone_types": ["small", "medium"],
		"bone_count": 20,
		"tools_required": [],  # Make middle layer always accessible
		"material_types": ["sand", "clay", "gravel"]
	},
	GEOLOGICAL_LAYER.DEEP: {
		"depth_range": [0.6, 0.85],
		"bone_types": ["large"],
		"bone_count": 10,
		"tools_required": ["pickaxe"],
		"material_types": ["soft_rock", "hard_rock"]
	},
	GEOLOGICAL_LAYER.BEDROCK: {
		"depth_range": [0.85, 1.0],
		"bone_types": ["legendary"],  # Future expansion
		"bone_count": 5,
		"tools_required": ["drill"],  # Future tool
		"material_types": ["bedrock"]
	}
}

# Procedural generation with FastNoiseLite
var surface_noise: FastNoiseLite
var layer_noise: FastNoiseLite

# Simple particle feedback
var particle_texture: ImageTexture
var particle_nodes := []
var particle_velocities := []
var particle_lifetimes := []
var max_particles: int = 80

# Bone spawning and collection
var bones_data = {}  # Position -> bone_type
var revealed_bones = {}  # Positions of revealed bones
var bone_collectibles = {}  # Position -> Area2D collectible nodes
# Progressive bone revelation - no fixed threshold needed
var bone_hover_scale: float = 1.2

# Track dig depth at each position for top-down digging
var dig_depths = {}  # Vector2i -> float (0.0 to 1.0, where 1.0 is deepest)

# Progress signals for loading screen
signal terrain_progress(progress: float)
signal bone_progress(progress: float)
signal generation_complete()

func _ready():
	# Initialize procedural noise
	setup_noise()
	
	# Check if we should show loading screen
	if GameState.show_loading:
		GameState.show_loading = false  # Reset flag
		show_loading_screen()
		await start_generation()
		hide_loading_screen()
	else:
		# Standard generation for testing/debugging
		await start_generation()

func start_generation():
	# Initialize sand texture with procedural generation
	await create_procedural_terrain_async()
	await generate_bones_async()
	# Ensure we have guaranteed content for MVP
	ensure_guaranteed_bones()
	create_particle_pool()
	generation_complete.emit()

func ensure_guaranteed_bones():
	# Guarantee some easy-to-find bones for immediate satisfaction
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Add guaranteed small bones near surface
	for i in range(5):
		var x = rng.randi_range(100, sand_width - 100)
		var y = rng.randi_range(100, int(sand_height * 0.3))  # Surface area
		var bone_pos = Vector2i(x, y)
		
		if not bones_data.has(bone_pos):
			var small_assets = GameState.bone_assets.get("small", ["smallbone.png"])
			var asset_file = small_assets[0] if small_assets.size() > 0 else "smallbone.png"
			
			bones_data[bone_pos] = {
				"asset_path": "res://assets/bones/" + asset_file,
				"size": "small",
				"type": asset_file.get_basename(),
				"depth": float(y) / float(sand_height),
				"color": Color(0.8, 0.9, 0.8, 1.0),
				"value_multiplier": 1.0
			}
	
	# Add guaranteed large bones if pickaxe owned
	if GameState.has_tool("pickaxe"):
		for i in range(3):
			var x = rng.randi_range(100, sand_width - 100)
			var y = rng.randi_range(int(sand_height * 0.6), int(sand_height * 0.8))  # Deep area
			var bone_pos = Vector2i(x, y)
			
			if not bones_data.has(bone_pos):
				var large_assets = GameState.bone_assets.get("large", ["largebone.png"])
				var asset_file = large_assets[0] if large_assets.size() > 0 else "largebone.png"
				
				bones_data[bone_pos] = {
					"asset_path": "res://assets/bones/" + asset_file,
					"size": "large",
					"type": asset_file.get_basename(),
					"depth": float(y) / float(sand_height),
					"color": Color(1.0, 0.9, 0.3, 1.0),
					"value_multiplier": 8.0
				}
				print("Added guaranteed large bone at (", x, ", ", y, ") - ", int(float(y)/sand_height * 100), "% depth")
	
	print("Guaranteed content added: ", bones_data.size(), " total bones")

func setup_noise():
	# Surface variation noise for sand/dirt patches
	surface_noise = FastNoiseLite.new()
	surface_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	surface_noise.frequency = 0.1
	surface_noise.fractal_octaves = 3
	surface_noise.fractal_lacunarity = 2.0
	surface_noise.fractal_gain = 0.5
	surface_noise.seed = randi()
	
	# Layer boundary noise for more natural transitions
	layer_noise = FastNoiseLite.new()
	layer_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	layer_noise.frequency = 0.05
	layer_noise.fractal_octaves = 2
	layer_noise.fractal_lacunarity = 2.0
	layer_noise.fractal_gain = 0.6
	layer_noise.seed = randi() + 1000

func create_procedural_terrain_async():
	sand_image = Image.create(sand_width, sand_height, false, Image.FORMAT_RGBA8)
	material_map = Image.create(sand_width, sand_height, false, Image.FORMAT_R8)

	# Generate top-down view - surface starts as grass/topsoil everywhere
	for y in range(sand_height):
		# Update progress every 100 rows
		if y % 100 == 0:
			var progress = float(y) / float(sand_height)
			terrain_progress.emit(progress)
			await get_tree().process_frame  # Allow UI to update
		
		for x in range(sand_width):
			# Surface material varies between grass and topsoil (more grass, less sand)
			var surface_noise_val = surface_noise.get_noise_2d(x, y)
			var surface_material_id: int
			if surface_noise_val > -0.1:  # More grass coverage
				surface_material_id = MATERIAL_IDS["grass"]
			else:
				surface_material_id = MATERIAL_IDS["topsoil"]
			
			# Store the underground geological layers in material_map for when we dig
			var underground_material_id = get_underground_material(x, y)
			material_map.set_pixel(x, y, Color(underground_material_id / 255.0, 0, 0, 1))
			
			# Visual surface starts as grass/topsoil
			sand_image.set_pixel(x, y, material_colors[surface_material_id])
	
	image_texture = ImageTexture.create_from_image(sand_image)
	
	# Create sprite to display the texture
	var sprite = Sprite2D.new()
	sprite.texture = image_texture
	sprite.centered = false
	sprite.position = Vector2.ZERO
	add_child(sprite)
	sprite.z_index = 0

func get_underground_material(x: int, y: int) -> int:
	# Create underground geological variation using noise
	var geological_noise = layer_noise.get_noise_2d(x * 0.1, y * 0.1)
	var surface_variation = surface_noise.get_noise_2d(x * 0.05, y * 0.05)
	
	# Different geological patterns across the area
	# Some areas have different underground composition
	if geological_noise > 0.4:
		# Rocky underground area
		if surface_variation > 0.2:
			return MATERIAL_IDS["gravel"]
		else:
			return MATERIAL_IDS["soft_rock"]
	elif geological_noise > 0.0:
		# Sandy/clay area  
		if surface_variation > 0.3:
			return MATERIAL_IDS["sand"]
		else:
			return MATERIAL_IDS["clay"]
	elif geological_noise > -0.3:
		# Standard dirt/compacted area
		if surface_variation > 0.1:
			return MATERIAL_IDS["dirt"]
		else:
			return MATERIAL_IDS["compacted"]
	else:
		# Deep rock area
		if surface_variation > 0.0:
			return MATERIAL_IDS["hard_rock"]
		else:
			return MATERIAL_IDS["bedrock"]

func get_material_at_depth(x: int, y: int, depth: float) -> int:
	# Get the base underground material for this location
	var base_material = get_underground_material(x, y)
	
	# At surface (depth 0.0), show grass/topsoil
	if depth < 0.1:
		var surface_noise_val = surface_noise.get_noise_2d(x, y)
		if surface_noise_val > 0.2:
			return MATERIAL_IDS["grass"]
		else:
			return MATERIAL_IDS["topsoil"]
	
	# Shallow digging (depth 0.1-0.3), show dirt transitioning to underground material
	elif depth < 0.3:
		return MATERIAL_IDS["dirt"]
	
	# Medium depth (0.3-0.5), transition to base underground material
	elif depth < 0.5:
		# Gradually transition from dirt to underground material
		if depth < 0.4:
			return MATERIAL_IDS["dirt"] 
		else:
			return base_material
	
	# Deep digging (0.5-0.7), show base material (accessible with basic tools)
	elif depth < 0.7:
		return base_material
	
	# Very deep (0.7+), show harder materials that may require pickaxe
	else:
		# Only show hard rock/bedrock if the area naturally has it
		if base_material == MATERIAL_IDS["hard_rock"] or base_material == MATERIAL_IDS["bedrock"]:
			return base_material
		elif base_material == MATERIAL_IDS["soft_rock"]:
			# Soft rock can become hard rock at very deep levels
			if depth > 0.85:
				return MATERIAL_IDS["hard_rock"]
			else:
				return MATERIAL_IDS["soft_rock"]
		else:
			# Softer materials stay diggable even at depth
			return base_material

func generate_bones_async():
	# Professional multi-layer bone generation system
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	print("=== MULTI-LAYER BONE GENERATION START ===")
	
	await generate_bones_by_layers()
	print("=== MULTI-LAYER GENERATION COMPLETE ===")

func generate_bones_by_layers():
	"""Professional layer-based bone generation for scalable game architecture"""
	print("=== STARTING LAYER-BASED GENERATION ===")
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var total_bones_generated = 0
	var total_possible_bones = 0
	
	# Calculate total possible bones for progress tracking
	for layer in layer_config.keys():
		var config = layer_config[layer]
		if can_access_layer(layer):
			total_possible_bones += config["bone_count"]
	
	# Generate bones for each accessible layer
	print("Player tools: ", GameState.player_data["tools"])
	for layer in layer_config.keys():
		var config = layer_config[layer]
		
		if not can_access_layer(layer):
			print("*** SKIPPING LAYER ", layer, " - MISSING TOOLS: ", config["tools_required"], " ***")
			continue
		
		print("*** GENERATING LAYER ", layer, " WITH ", config["bone_count"], " BONES OF TYPES: ", config["bone_types"], " ***")
		
		# Generate bones for this layer
		for i in range(config["bone_count"]):
			# Update progress
			var progress = float(total_bones_generated) / float(max(total_possible_bones, 1))
			bone_progress.emit(progress)
			
			if i % 3 == 0:
				await get_tree().process_frame
			
			# Generate position within layer depth range
			var x = rng.randi_range(100, sand_width - 100)
			var depth_min = config["depth_range"][0]
			var depth_max = config["depth_range"][1]
			var y = rng.randi_range(int(sand_height * depth_min), int(sand_height * depth_max))
			
			var depth_percent = float(y) / float(sand_height)
			
			# Generate bone data for this layer
			var bone_data = generate_layer_bone(layer, depth_percent, rng)
			
			if bone_data:
				bones_data[Vector2i(x, y)] = bone_data
				print("Layer ", layer, ": Generated ", bone_data["size"], " bone '", bone_data["type"], "' at (", x, ", ", y, ") - depth: ", int(depth_percent * 100), "%")
				
				# Don't create collectibles yet - they'll be created when revealed by digging
				# This ensures bones are completely hidden until discovered
				
				total_bones_generated += 1
	
	print("=== GENERATED ", total_bones_generated, " BONES ACROSS ALL ACCESSIBLE LAYERS ===")
	
	# Debug: Count bones by type
	var bone_counts = {}
	for bone_data in bones_data.values():
		if bone_data is Dictionary and bone_data.has("size"):
			var size = bone_data["size"]
			bone_counts[size] = bone_counts.get(size, 0) + 1
	print("BONE COUNTS BY SIZE: ", bone_counts)

func can_access_layer(layer: GEOLOGICAL_LAYER) -> bool:
	"""Check if player has tools required to access this geological layer"""
	var config = layer_config[layer]
	var has_access = true
	for required_tool in config["tools_required"]:
		if not GameState.has_tool(required_tool):
			has_access = false
			break
	print("Layer ", layer, " access: ", has_access, " (tools required: ", config["tools_required"], ", player has: ", GameState.player_data["tools"], ")")
	return has_access

func generate_layer_bone(layer: GEOLOGICAL_LAYER, depth_percent: float, rng: RandomNumberGenerator) -> Dictionary:
	"""Generate appropriate bone for the given geological layer"""
	var config = layer_config[layer]
	var available_types = config["bone_types"]
	
	# Select bone type for this layer
	var selected_type = available_types[rng.randi() % available_types.size()]
	
	# Get appropriate assets for this bone type
	var assets = GameState.bone_assets.get(selected_type, [])
	if assets.is_empty():
		print("WARNING: No assets found for ", selected_type, " bones")
		return {}
	
	var bone_file = assets[rng.randi() % assets.size()]
	var bone_name = bone_file.get_basename()
	
	# Get color and multiplier based on type
	var bone_color = GameState.size_rarity_system.get(selected_type, {}).get("color", Color.WHITE)
	var multiplier = GameState.size_rarity_system.get(selected_type, {}).get("multiplier", 1.0)
	
	return {
		"asset_path": "res://assets/bones/" + bone_file,
		"size": selected_type,
		"type": bone_name,
		"color": bone_color,
		"value_multiplier": multiplier,
		"layer": layer
	}

func get_layer_base_revelation(layer: GEOLOGICAL_LAYER) -> float:
	"""Get base revelation level for bones in each layer - ALL START HIDDEN"""
	# ALL bones should start completely hidden and only be revealed by digging
	return 0.0  # All bones start completely buried

func show_loading_screen():
	# Hide HUD during loading
	var hud = get_parent().get_node_or_null("HUD")
	if hud:
		hud.visible = false
	
	# Create loading screen overlay
	var loading_overlay = Control.new()
	loading_overlay.name = "LoadingOverlay"
	loading_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loading_overlay.z_index = 1000  # Very high z-index to be above everything
	loading_overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # Block input to underlying elements
	
	# Add travel background with ResourceLoader for better reliability
	var travel_bg_texture: Texture2D
	if ResourceLoader.exists("res://assets/ui/TravelBG.png"):
		travel_bg_texture = ResourceLoader.load("res://assets/ui/TravelBG.png")
		print("Travel background loaded successfully")
	else:
		print("Travel background file not found at path")
	
	if travel_bg_texture:
		var travel_bg = TextureRect.new()
		travel_bg.texture = travel_bg_texture
		travel_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		travel_bg.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		travel_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		travel_bg.z_index = -1  # Behind all content
		loading_overlay.add_child(travel_bg)
		print("Travel background added to overlay with z_index -1")
	else:
		print("Using fallback dark background")
		# Fallback dark background
		var dark_bg = ColorRect.new()
		dark_bg.color = Color(0.1, 0.1, 0.1, 0.9)
		dark_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dark_bg.z_index = -1  # Behind all content
		loading_overlay.add_child(dark_bg)
	
	# Loading container - properly centered for any screen size
	var loading_container = VBoxContainer.new()
	loading_container.add_theme_constant_override("separation", 15)
	loading_container.z_index = 5  # Above background
	# Set anchors to center
	loading_container.anchor_left = 0.5
	loading_container.anchor_top = 0.5
	loading_container.anchor_right = 0.5
	loading_container.anchor_bottom = 0.5
	# Set size and center it properly
	loading_container.custom_minimum_size = Vector2(280, 100)
	loading_container.size = Vector2(280, 100)
	# Offset by half the size to truly center
	loading_container.offset_left = -140  # Half of 280
	loading_container.offset_top = -50   # Half of 100
	loading_container.offset_right = 140
	loading_container.offset_bottom = 50
	
	# Loading title with heavy stroke - compact
	var loading_title = Label.new()
	loading_title.text = "Traveling to Dig Site..."
	loading_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_title.add_theme_font_size_override("font_size", 20)
	loading_title.add_theme_color_override("font_color", Color.WHITE)
	# Heavy stroke/outline
	loading_title.add_theme_color_override("font_shadow_color", Color.BLACK)
	loading_title.add_theme_constant_override("shadow_offset_x", 2)
	loading_title.add_theme_constant_override("shadow_offset_y", 2)
	loading_title.add_theme_color_override("font_outline_color", Color.BLACK)
	loading_title.add_theme_constant_override("outline_size", 4)
	loading_container.add_child(loading_title)
	
	# Progress bar container - compact size
	var progress_container = Control.new()
	progress_container.name = "ProgressContainer"
	progress_container.custom_minimum_size = Vector2(250, 30)
	
	# Progress bar background - compact
	var progress_bg = Panel.new()
	progress_bg.name = "ProgressBG"
	progress_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	progress_bg.add_theme_stylebox_override("panel", create_progress_style(Color(0.2, 0.2, 0.2, 0.9)))
	progress_container.add_child(progress_bg)
	
	# Progress bar fill - compact green bar
	var progress_fill = Panel.new()
	progress_fill.name = "ProgressFill"
	progress_fill.custom_minimum_size = Vector2(0, 30)
	progress_fill.add_theme_stylebox_override("panel", create_progress_style(Color(0.2, 0.8, 0.3, 1.0)))  # Bright green
	progress_container.add_child(progress_fill)
	
	loading_container.add_child(progress_container)
	
	# Status label with heavy stroke - smaller size
	var status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Initializing..."
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color.WHITE)
	# Heavy stroke/outline
	status_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	status_label.add_theme_constant_override("shadow_offset_x", 1)
	status_label.add_theme_constant_override("shadow_offset_y", 1)
	status_label.add_theme_color_override("font_outline_color", Color.BLACK)
	status_label.add_theme_constant_override("outline_size", 3)
	loading_container.add_child(status_label)
	
	loading_overlay.add_child(loading_container)
	add_child(loading_overlay)
	
	print("Loading overlay created and added to scene")
	print("Loading overlay size: ", loading_overlay.size)
	print("Loading overlay position: ", loading_overlay.position)
	print("Loading overlay visible: ", loading_overlay.visible)
	print("Number of children in loading overlay: ", loading_overlay.get_child_count())
	
	# Force the overlay to be visible and properly sized
	loading_overlay.visible = true
	loading_overlay.size = get_viewport().get_visible_rect().size
	
	# Connect progress signals
	terrain_progress.connect(_on_terrain_progress_update)
	bone_progress.connect(_on_bone_progress_update)

func create_progress_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	return style

func _on_terrain_progress_update(progress: float):
	update_loading_progress(progress * 0.6, "Surveying the terrain...")

func _on_bone_progress_update(progress: float):
	update_loading_progress(0.6 + (progress * 0.4), "Scanning for fossil deposits...")

func update_loading_progress(progress: float, status: String):
	var loading_overlay = get_node_or_null("LoadingOverlay")
	if loading_overlay:
		var progress_fill = loading_overlay.get_node_or_null("VBoxContainer/ProgressContainer/ProgressFill")
		var status_label = loading_overlay.get_node_or_null("VBoxContainer/StatusLabel")
		
		if progress_fill:
			progress_fill.custom_minimum_size.x = 500 * clamp(progress, 0.0, 1.0)
		if status_label:
			status_label.text = status

func hide_loading_screen():
	update_loading_progress(1.0, "Complete!")
	await get_tree().create_timer(0.8).timeout
	
	var loading_overlay = get_node_or_null("LoadingOverlay")
	if loading_overlay:
		# Fade out
		var tween = create_tween()
		tween.tween_property(loading_overlay, "modulate:a", 0.0, 0.5)
		await tween.finished
		loading_overlay.queue_free()
	
	# Show HUD after loading is complete
	var hud = get_parent().get_node_or_null("HUD")
	if hud:
		hud.visible = true

func create_particle_pool():
	# Create a simple particle texture
	var particle_image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	for y in range(4):
		for x in range(4):
			particle_image.set_pixel(x, y, Color(0.8, 0.7, 0.5, 1.0))
	particle_texture = ImageTexture.create_from_image(particle_image)
	
	# Pre-create particle nodes
	for i in range(max_particles):
		var particle = Sprite2D.new()
		particle.texture = particle_texture
		particle.visible = false
		particle.z_index = 5
		add_child(particle)
		particle_nodes.append(particle)
		particle_velocities.append(Vector2.ZERO)
		particle_lifetimes.append(0.0)

func spawn_particles_at(pos: Vector2, intensity: float):
	# Find an unused particle (only if arrays are initialized)
	if particle_nodes.size() >= max_particles and particle_lifetimes.size() >= max_particles:
		for i in range(max_particles):
			if particle_lifetimes[i] <= 0.0:
				var particle = particle_nodes[i]
				particle.position = pos
				particle.visible = true
				particle.modulate = Color(1, 1, 1, 1)
				particle.scale = Vector2(randf_range(0.5, 1.5) * intensity, randf_range(0.5, 1.5) * intensity)
				
				var angle = randf() * 2.0 * PI
				var speed = randf_range(10, 30) * intensity
				particle_velocities[i] = Vector2(cos(angle), sin(angle)) * speed
				particle_lifetimes[i] = randf_range(0.5, 1.2)
				break

func _process(delta):
	# Update particles (only if arrays are initialized)
	if particle_nodes.size() >= max_particles and particle_lifetimes.size() >= max_particles:
		for i in range(max_particles):
			if particle_lifetimes[i] > 0.0:
				particle_lifetimes[i] -= delta
				var particle = particle_nodes[i]
				
				# Update position
				particle.position += particle_velocities[i] * delta
				
				# Apply gravity
				particle_velocities[i].y += 50 * delta
				
				# Fade out
				var alpha = particle_lifetimes[i] / 1.2
				particle.modulate = Color(1, 1, 1, alpha)
				
				if particle_lifetimes[i] <= 0.0:
					particle.visible = false

func _input(event):
	# Check for bone clicks first
	# Production ready - debug keys removed for clean experience
	
	if (event is InputEventMouseButton and event.pressed and event.button_index == 1) or \
	   (event is InputEventScreenTouch and event.pressed):
		var click_pos = event.position
		
		# Check if click is on a bone
		for bone_pos in bone_collectibles.keys():
			var bone_area = bone_collectibles[bone_pos]
			var distance = bone_area.global_position.distance_to(click_pos)
			if distance <= 50:  # Within bone radius
				print("Direct bone click detected at ", bone_pos)
				collect_bone(bone_pos, bones_data[bone_pos])
				return  # Don't process as dig
	
	# Regular digging input
	if event is InputEventScreenTouch:
		if event.pressed:
			current_touch_position = event.position
			is_digging = true
			dig_started.emit()
			# Start digging sound based on current material
			var dig_sound_depth = dig_depths.get(Vector2i(int(current_touch_position.x), int(current_touch_position.y)), 0.0)
			var dig_sound_material = get_material_at_depth(int(current_touch_position.x), int(current_touch_position.y), dig_sound_depth)
			var material_name = get_material_name_from_id(dig_sound_material)
			if AudioManager:
				AudioManager.start_digging_sound(material_name)
		else:
			is_digging = false
			dig_ended.emit()
			# Stop digging sound
			if AudioManager:
				AudioManager.stop_digging_sound()
	elif event is InputEventScreenDrag:
		current_touch_position = event.position
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == 1:
			current_touch_position = event.position
			is_digging = true
			dig_started.emit()
			# Start digging sound based on current material
			var dig_sound_depth = dig_depths.get(Vector2i(int(current_touch_position.x), int(current_touch_position.y)), 0.0)
			var dig_sound_material = get_material_at_depth(int(current_touch_position.x), int(current_touch_position.y), dig_sound_depth)
			var material_name = get_material_name_from_id(dig_sound_material)
			if AudioManager:
				AudioManager.start_digging_sound(material_name)
		elif not event.pressed and event.button_index == 1:
			is_digging = false
			dig_ended.emit()
			# Stop digging sound
			if AudioManager:
				AudioManager.stop_digging_sound()
	elif event is InputEventMouseMotion and is_digging:
		current_touch_position = event.position

func _physics_process(delta):
	if is_digging:
		dig_timer += delta
		if dig_timer >= 0.05:  # Dig every 50ms for smooth digging
			apply_dig(current_touch_position, dig_radius)
			check_for_revealed_bones(int(current_touch_position.x), int(current_touch_position.y), dig_radius)
			image_texture.update(sand_image)
			
			# Update HUD depth display
			var hud = get_parent().get_node("HUD")
			if hud and hud.has_method("update_depth_display"):
				hud.update_depth_display()
			
			dig_timer = 0.0

func get_material_name_from_id(material_id: int) -> String:
	# Convert material ID back to name for audio system
	for material_name in MATERIAL_IDS.keys():
		if MATERIAL_IDS[material_name] == material_id:
			return material_name
	return "dirt"  # Default fallback

func apply_dig(position: Vector2, radius: int):
	var x = int(position.x)
	var y = int(position.y)

	# Calculate effective dig power including tools
	var base_power = dig_power
	var pickaxe_power = GameState.get_tool_power("pickaxe")
	var upgrade_power = GameState.player_data["upgrades"]["dig_speed"] * 0.25
	var effective_dig_power = base_power + pickaxe_power + upgrade_power
	
	# Audio is now handled at dig start/stop for smooth looping
	
	# Production version - debug output removed

	# Apply feathered digging with distance-based falloff
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var distance = sqrt(dx * dx + dy * dy)
			if distance <= radius:
				var px = x + dx
				var py = y + dy
				
				if px >= 0 and px < sand_width and py >= 0 and py < sand_height:
					# Calculate distance-based falloff for soft edges
					var falloff = 1.0 - (distance / radius)
					falloff = smoothstep(0.0, 1.0, falloff)  # Smooth falloff curve
					
					# Get current dig depth at this position
					var pos_key = Vector2i(px, py)
					var current_depth = dig_depths.get(pos_key, 0.0)
					
					# Get material at current dig depth
					var material_id = get_material_at_depth(px, py, current_depth)
					var required_hardness = material_hardness.get(material_id, 1.0)
					
					# Check if we can dig this material (only bedrock absolutely requires pickaxe)
					if material_id == MATERIAL_IDS["bedrock"] and not GameState.has_tool("pickaxe"):
						continue  # Can't dig bedrock without pickaxe
					# Hard rock is just slower without pickaxe, but still diggable
					
					var current_pixel = sand_image.get_pixel(px, py)
					if current_pixel.a <= 0.1:
						continue  # Already cleared
					
					# Calculate dig effectiveness with falloff
					var dig_effectiveness = (effective_dig_power / required_hardness) * falloff
					
					# Increase dig depth at this position (optimized for MVP satisfaction)
					var depth_increase = 0.05 * dig_effectiveness  # Fast, satisfying progression
					var new_depth = min(1.0, current_depth + depth_increase)
					
					# Production ready - smooth depth progression
					dig_depths[pos_key] = new_depth
					
					# Update visual to show material at new depth
					var new_material_id = get_material_at_depth(px, py, new_depth)
					var material_color = material_colors[new_material_id]
					
					# Reduce alpha gradually for clearing effect
					var reduce_amount = 0.05 * dig_effectiveness
					var new_a = max(0.0, current_pixel.a - reduce_amount)
					
					# Show the geological layer at this depth
					var new_r = lerp(material_color.r, 0.4, (1.0 - new_a))
					var new_g = lerp(material_color.g, 0.3, (1.0 - new_a))
					var new_b = lerp(material_color.b, 0.2, (1.0 - new_a))
					sand_image.set_pixel(px, py, Color(new_r, new_g, new_b, new_a))

					# Spawn particles occasionally when eroding (with falloff consideration)
					if falloff > 0.3 and randi() % 12 == 0:
						spawn_particles_at(Vector2(px, py), dig_effectiveness)

func check_for_revealed_bones(x: int, y: int, radius: int):
	# Check all bones for progressive revelation with larger detection range
	for bone_pos in bones_data.keys():
		var bone_data = bones_data[bone_pos]
		var detection_range = radius + 50
		# Larger detection range for large bones
		if bone_data.get("size") == "large":
			detection_range = radius + 100  # Much larger range for large bones
			
		if bone_pos.distance_to(Vector2i(x, y)) <= detection_range:
			update_bone_visibility(bone_pos)
	
	# Check for nearby large bones and give hints
	var current_depth = float(y) / float(sand_height)
	if current_depth > 0.55:  # Approaching large bone territory
		var large_bones_nearby = 0
		for bone_pos in bones_data.keys():
			var bone_data = bones_data[bone_pos]
			if bone_data.get("size") == "large" and bone_pos.distance_to(Vector2i(x, y)) <= 200:
				large_bones_nearby += 1
		
		if large_bones_nearby > 0 and randi() % 100 == 0:  # Rare hint
			print("🦴 METAL DETECTOR BEEPING: ", large_bones_nearby, " large bones detected nearby! Keep digging! 🦴")
			# Play special detection sound for large bones nearby
			if AudioManager:
				AudioManager.play_ui_sound("button")  # Use button sound as metal detector beep

func update_bone_visibility(bone_pos: Vector2i):
	# Calculate bone's required depth for revelation
	var bone_depth_percent = float(bone_pos.y) / float(sand_height)
	
	# Check if we've dug deep enough at this location to reveal the bone
	var check_radius = 30  # Increased radius for better detection
	var max_dig_depth_in_area = 0.0
	var total_pixels_checked = 0
	
	# Check dig depths in the area around the bone
	for dy in range(-check_radius, check_radius + 1):
		for dx in range(-check_radius, check_radius + 1):
			var distance = sqrt(dx * dx + dy * dy)
			if distance <= check_radius:
				var px = bone_pos.x + dx
				var py = bone_pos.y + dy
				
				if px >= 0 and px < sand_width and py >= 0 and py < sand_height:
					var pos_key = Vector2i(px, py)
					var dig_depth = dig_depths.get(pos_key, 0.0)
					max_dig_depth_in_area = max(max_dig_depth_in_area, dig_depth)
					total_pixels_checked += 1
	
	# Simplified bone revelation - more forgiving for better gameplay
	var revelation_percent = 0.0
	var bone_data = bones_data[bone_pos]
	var required_depth_ratio = 0.3 if bone_data.get("size") == "large" else 0.5
	
	# Much more forgiving - if you're digging deep enough, bones should appear
	if max_dig_depth_in_area >= required_depth_ratio:
		revelation_percent = min(1.0, max_dig_depth_in_area / required_depth_ratio)
		# Force revelation if you're at 60%+ depth and it's a large bone
		if max_dig_depth_in_area >= 0.6 and bone_data.get("size") == "large":
			revelation_percent = 1.0  # Always reveal large bones at deep depths
		
	# Production version - clean bone revelation system
	
	# Create or update bone collectible based on revelation
	if revelation_percent > 0.05:  # Start showing bone at 5% cleared (easier to find)
		if not bone_pos in bone_collectibles:
			# First time revealing - create the bone (reuse existing bone_data variable)
			var depth_percent = float(bone_pos.y) / float(sand_height)
			var size_indicator = "*** LARGE BONE! ***" if bone_data.get("size") == "large" else bone_data.get("size", "unknown")
			print("Starting to reveal ", size_indicator, " bone at ", bone_pos, " (", int(revelation_percent * 100), "% cleared, ", int(depth_percent * 100), "% deep)")
			create_progressive_bone_collectible(bone_pos, bone_data, revelation_percent)
			revealed_bones[bone_pos] = true
			
			# Emit signal for first revelation
			var bone_type = bone_data["type"] if bone_data is Dictionary else str(bone_data)
			bone_revealed.emit(bone_type, Vector2(bone_pos))
			
			# Play bone discovery sound
			if AudioManager:
				AudioManager.play_bone_discovery_sound(bone_data.get("size", "medium"))
			
			# Small particle effect for first revelation
			for i in range(6):
				spawn_particles_at(Vector2(bone_pos.x + randi_range(-4,4), bone_pos.y + randi_range(-4,4)), 1.0)
		else:
			# Update existing bone visibility
			update_bone_collectible_visibility(bone_pos, revelation_percent)
	elif bone_pos in bone_collectibles:
		# Bone got buried again, hide it
		var area = bone_collectibles[bone_pos]
		area.queue_free()
		bone_collectibles.erase(bone_pos)
		revealed_bones.erase(bone_pos)

func create_progressive_bone_collectible(bone_pos: Vector2i, bone_data, revelation_percent: float):
	# Create bone that gradually becomes visible
	var bone_type: String
	var bone_color: Color
	
	# Handle both old string format and new dictionary format
	if bone_data is Dictionary:
		bone_type = bone_data["type"]
		bone_color = bone_data["color"]
	else:
		bone_type = str(bone_data)
		bone_color = Color(0.95, 0.9, 0.8, 1.0)  # Default bone white
	
	# Create Area2D for clickable bone collection
	var area = Area2D.new()
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 50  # Larger radius for easier clicking
	
	collision_shape.shape = circle_shape
	area.add_child(collision_shape)
	
	# Enable input detection
	area.input_pickable = true
	area.monitoring = true
	area.monitorable = true
	
	# Create visual representation using actual bone assets
	var bone_sprite = Sprite2D.new()
	
	# Load bone asset with special handling for large bones
	if bone_data is Dictionary and bone_data.has("asset_path") and bone_data["asset_path"] != "":
		print("Loading bone: ", bone_data["asset_path"], " (", bone_data["size"], ")")
		var texture = load(bone_data["asset_path"])
		if texture:
			bone_sprite.texture = texture
			# Special handling for large bones - make them very obvious
			if bone_data["size"] == "large":
				bone_sprite.scale = Vector2(3.0, 3.0)  # Triple size!
				bone_sprite.modulate = Color(1.0, 0.8, 0.0, 1.0)  # Bright gold
				bone_sprite.z_index = 20  # Very high z-index
				print("*** LARGE BONE CREATED - TRIPLE SIZE GOLDEN ***")
			else:
				bone_sprite.modulate = bone_color  # Normal tint
		else:
			print("FAILED to load: ", bone_data["asset_path"])
			bone_sprite.texture = create_fallback_bone_texture(bone_color)
	else:
		bone_sprite.texture = create_fallback_bone_texture(bone_color)
	
	# Set initial visibility based on revelation percentage
	var visibility_alpha = clamp(revelation_percent * 2.0, 0.3, 1.0)  # Min 30% visible when first revealed
	bone_sprite.modulate.a = visibility_alpha
	bone_sprite.z_index = 10  # Above sand layer for visibility and interaction
	
	# Make large bones extra visible and glowing
	if bone_data is Dictionary and bone_data["size"] == "large":
		bone_sprite.z_index = 15  # Even higher z-index
		# Add a glow effect for large bones
		var glow = bone_sprite.duplicate()
		glow.modulate = Color(1.0, 1.0, 0.0, 0.5)  # Yellow glow
		glow.scale = Vector2(1.2, 1.2)
		glow.z_index = 14  # Behind the main sprite but above sand
		area.add_child(glow)
		print("Added glow effect to large bone")
	
	# Make bones immediately interactive if they're visible
	collision_shape.disabled = false  # Always interactive when visible
	
	area.add_child(bone_sprite)
	area.position = Vector2(bone_pos.x, bone_pos.y)
	area.z_index = 10  # Above sand layer for input detection
	add_child(area)
	
	# Store reference
	bone_collectibles[bone_pos] = area
	
	# Connect signals for interaction
	area.input_event.connect(_on_bone_input_event.bind(bone_pos, bone_data))
	area.mouse_entered.connect(_on_bone_hover_enter.bind(area))
	area.mouse_exited.connect(_on_bone_hover_exit.bind(area))

func update_bone_collectible_visibility(bone_pos: Vector2i, revelation_percent: float):
	if bone_pos in bone_collectibles:
		var area = bone_collectibles[bone_pos]
		var bone_sprite = area.get_child(1)  # Sprite is second child after collision shape
		
		# Update visibility - bones become more opaque as more is revealed
		var visibility_alpha = clamp(revelation_percent * 1.5, 0.3, 1.0)
		bone_sprite.modulate.a = visibility_alpha
		
		# Always enable interaction when bone is visible
		var collision_shape = area.get_child(0)
		collision_shape.disabled = false
		
		# Debug output for interaction state
		if randi() % 100 == 0:  # Occasional debug
			print("Bone at ", bone_pos, " - ", int(revelation_percent * 100), "% revealed, interactive: ", not collision_shape.disabled)

func create_bone_collectible(bone_pos: Vector2i, bone_data):
	var bone_type: String
	var bone_color: Color
	
	# Handle both old string format and new dictionary format
	if bone_data is Dictionary:
		bone_type = bone_data["type"]
		bone_color = bone_data["color"]
	else:
		bone_type = str(bone_data)
		bone_color = Color(0.95, 0.9, 0.8, 1.0)  # Default bone white
	
	# Create Area2D for clickable bone collection
	var area = Area2D.new()
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 50  # Larger radius for easier clicking
	
	collision_shape.shape = circle_shape
	area.add_child(collision_shape)
	
	# Enable input detection
	area.input_pickable = true
	area.monitoring = true
	area.monitorable = true
	
	# Create visual representation using actual bone assets
	var bone_sprite = Sprite2D.new()
	
	# Try to load actual bone asset
	if bone_data is Dictionary and bone_data.has("asset_path") and bone_data["asset_path"] != "":
		var texture = load(bone_data["asset_path"])
		if texture:
			bone_sprite.texture = texture
			bone_sprite.modulate = bone_color  # Tint with rarity color
		else:
			# Fallback to generated texture if asset fails to load
			bone_sprite.texture = create_fallback_bone_texture(bone_color)
	else:
		# Fallback for old format or missing assets
		bone_sprite.texture = create_fallback_bone_texture(bone_color)
	
	bone_sprite.z_index = 10  # Above sand layer for visibility and interaction
	
	area.add_child(bone_sprite)
	area.position = Vector2(bone_pos.x, bone_pos.y)
	area.z_index = 10  # Above sand layer for input detection
	add_child(area)
	
	# Store reference
	bone_collectibles[bone_pos] = area
	
	# Connect signals for interaction
	area.input_event.connect(_on_bone_input_event.bind(bone_pos, bone_data))
	area.mouse_entered.connect(_on_bone_hover_enter.bind(area))
	area.mouse_exited.connect(_on_bone_hover_exit.bind(area))

func create_fallback_bone_texture(bone_color: Color) -> ImageTexture:
	var bone_img = Image.create(40, 40, false, Image.FORMAT_RGBA8)
	var center = 20
	
	for yy in range(40):
		for xx in range(40):
			var dist = Vector2(xx - center, yy - center).length()
			if dist <= 18:
				bone_img.set_pixel(xx, yy, bone_color)
	
	return ImageTexture.create_from_image(bone_img)

func get_bone_size(bone_type: String) -> int:
	# Different sizes based on bone type
	match bone_type:
		"small_bone", "tooth", "bone_chip":
			return 16
		"medium_bone", "vertebra", "rib_bone":
			return 24
		"large_bone", "leg_bone", "jaw_fragment":
			return 32
		"skull_fragment", "complete_fossil", "ancient_tooth":
			return 40
		_:
			return 24

func _on_bone_input_event(bone_pos: Vector2i, bone_data, viewport: Node, event: InputEvent, shape_idx: int):
	print("Bone input event detected at ", bone_pos, " - Event type: ", event.get_class())
	if event is InputEventScreenTouch and event.pressed:
		print("Touch event - collecting bone")
		collect_bone(bone_pos, bone_data)
	elif event is InputEventMouseButton and event.pressed and event.button_index == 1:
		print("Mouse click - collecting bone")
		collect_bone(bone_pos, bone_data)
	else:
		print("Unhandled input event: ", event.get_class(), " pressed: ", event.pressed if event.has_method("pressed") else "N/A")

func _on_bone_hover_enter(area: Area2D):
	# Scale up on hover
	var tween = create_tween()
	tween.tween_property(area, "scale", Vector2(bone_hover_scale, bone_hover_scale), 0.2)

func _on_bone_hover_exit(area: Area2D):
	# Scale back to normal
	var tween = create_tween()
	tween.tween_property(area, "scale", Vector2(1.0, 1.0), 0.2)

func collect_bone(bone_pos: Vector2i, bone_data):
	if bone_pos in bone_collectibles:
		var area = bone_collectibles[bone_pos]
		
		var bone_type: String
		var rarity_multiplier: float = 1.0
		
		# Handle both old string format and new dictionary format
		if bone_data is Dictionary:
			bone_type = bone_data.get("type", "unknown_bone")
			rarity_multiplier = bone_data.get("value_multiplier", 1.0)
			var bone_size = bone_data.get("size", "medium")
			print("Collected ", bone_size, " ", bone_type, " (x", rarity_multiplier, " value)")
		else:
			bone_type = str(bone_data)
			print("Collected ", bone_type)
		
		# Particle feedback on collection
		for i in range(15):
			spawn_particles_at(Vector2(bone_pos.x + randi_range(-10,10), bone_pos.y + randi_range(-10,10)), 2.0)
		
		# Add bone to GameState with rarity multiplier
		GameState.add_bone(bone_type, rarity_multiplier)
		
		# Emit collection signal
		bone_collected.emit(bone_type, Vector2(bone_pos))
		
		# Play coin collection sound for bone pickup
		if AudioManager:
			AudioManager.play_coin_sound()
		
		# Remove collectible
		area.queue_free()
		bone_collectibles.erase(bone_pos)
		bones_data.erase(bone_pos)
		
		# Update UI
		get_tree().call_group("ui", "update_hud")

var last_depth_milestone = 0  # Track depth milestones for notifications

func get_current_max_depth() -> float:
	# Return the maximum depth achieved so far
	var max_depth = 0.0
	for depth_value in dig_depths.values():
		max_depth = max(max_depth, depth_value)
		
	# Check for depth milestones and notify player
	var depth_percent = int(max_depth * 100)
	if depth_percent >= 60 and last_depth_milestone < 60:
		print("*** ENTERED DEEP LAYER - LARGE BONES AVAILABLE! ***")
		last_depth_milestone = 60
	elif depth_percent >= 55 and last_depth_milestone < 55:
		print("*** APPROACHING LARGE BONE TERRITORY - Keep digging! ***")
		last_depth_milestone = 55
	elif depth_percent >= 25 and last_depth_milestone < 25:
		print("*** ENTERED MIDDLE LAYER - Medium bones available! ***")
		last_depth_milestone = 25
		
	return max_depth

# Debug function to manually check current bones and spawn test large bones
func debug_check_bones():
	print("\\n=== BONE DEBUG CHECK ===")
	print("Total bones in bones_data: ", bones_data.size())
	print("Pickaxe owned: ", GameState.has_tool("pickaxe"))
	print("Depth access: ", GameState.player_data["upgrades"]["depth_access"])
	print("Current max depth: ", get_current_max_depth() * 100, "%")
	
	# Show large bone locations specifically
	var large_bone_count = 0
	print("\\n=== LARGE BONE LOCATIONS ===")
	for bone_pos in bones_data.keys():
		var bone_data = bones_data[bone_pos]
		if bone_data.size == "large":
			large_bone_count += 1
			var depth_percent = int(bone_data.depth * 100)
			print("Large bone #", large_bone_count, ": Position (", bone_pos.x, ", ", bone_pos.y, ") at ", depth_percent, "% depth")
			
	if large_bone_count == 0:
		print("No large bones found! This might indicate a generation issue.")
	else:
		print("Total large bones: ", large_bone_count)
		print("\\n*** To find large bones, dig to 60%+ depth! ***")
	
	var total_large_bones = 0
	var total_medium_bones = 0
	var total_small_bones = 0
	
	for pos in bones_data.keys():
		var bone = bones_data[pos]
		if bone["size"] == "large":
			total_large_bones += 1
			print("LARGE BONE at ", pos, ": ", bone["type"], " - ", bone["asset_path"])
		elif bone["size"] == "medium":
			total_medium_bones += 1
		elif bone["size"] == "small":
			total_small_bones += 1
	
	print("Bone counts: Large=", total_large_bones, ", Medium=", total_medium_bones, ", Small=", total_small_bones)
	
	# If no large bones and pickaxe owned, force spawn some
	if total_large_bones == 0 and GameState.has_tool("pickaxe"):
		print("NO LARGE BONES FOUND - FORCE SPAWNING 3 TEST BONES")
		for i in range(3):
			var x = randi_range(100, sand_width - 100)
			var y = randi_range(int(sand_height * 0.7), sand_height - 100)
			var bone_pos = Vector2i(x, y)
			
			# Use actual large bone asset
			var large_assets = GameState.bone_assets["large"]
			var asset_file = large_assets[0] if large_assets.size() > 0 else "largebone.png"
			
			var large_bone_data = {
				"asset_path": "res://assets/bones/" + asset_file,
				"size": "large",
				"type": asset_file.get_basename(),
				"color": Color(1.0, 0.9, 0.3, 1.0),
				"value_multiplier": 8.0
			}
			
			bones_data[bone_pos] = large_bone_data
			create_progressive_bone_collectible(bone_pos, large_bone_data, 1.0)  # Fully revealed
			
			print("FORCE SPAWNED large bone at (", x, ", ", y, ") using asset: ", asset_file)
	
	print("=== DEBUG CHECK COMPLETE ===")

# Removed - using integrated generation system

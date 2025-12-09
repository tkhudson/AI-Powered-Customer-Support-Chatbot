extends Node

# Global game state and data management
class_name GameStateClass

# Loading screen control
var show_loading: bool = false

# Dig site preservation
var preserve_dig_site: bool = false
var returning_to_site: bool = false

var player_data = {
	"bones": {},
	"coins": 0,
	"upgrades": {
		"dig_speed": 0,
		"dig_power": 0,
		"bone_detection": 0,
		"depth_access": 2  # Start with level 2 for large bone access
	},
	"tools": {
		"shovel": true,
		"pickaxe": false,
		"brush": false,
		"drill": false
	}
}

# Bone rarity and geological distribution system
var bone_rarity_tiers = {
	"common": {
		"color": Color(0.8, 0.9, 0.8, 1.0),  # Light green
		"multiplier": 1.0,
		"types": ["small_bone", "tooth", "bone_chip"]
	},
	"uncommon": {
		"color": Color(0.7, 0.8, 1.0, 1.0),  # Light blue  
		"multiplier": 2.0,
		"types": ["medium_bone", "vertebra", "rib_bone"]
	},
	"rare": {
		"color": Color(0.9, 0.7, 1.0, 1.0),  # Purple
		"multiplier": 4.0,
		"types": ["large_bone", "leg_bone", "jaw_fragment"]
	},
	"legendary": {
		"color": Color(1.0, 0.9, 0.3, 1.0),  # Gold
		"multiplier": 10.0,
		"types": ["skull_fragment", "complete_fossil", "ancient_tooth"]
	}
}

# Geological depth distribution for bones
var geological_bone_distribution = {
	"shallow": {  # 0-30% depth (grass/topsoil/dirt)
		"common": 60,
		"uncommon": 30,
		"rare": 8,
		"legendary": 2
	},
	"medium": {   # 30-60% depth (sand/gravel/compacted)
		"common": 40,
		"uncommon": 40,
		"rare": 15,
		"legendary": 5
	},
	"deep": {     # 60-85% depth (clay/soft_rock)
		"common": 20,
		"uncommon": 35,
		"rare": 30,
		"legendary": 15
	},
	"bedrock": {  # 85%+ depth (hard_rock/bedrock)
		"common": 5,
		"uncommon": 15,
		"rare": 40,
		"legendary": 40
	}
}

# Bone assets organized by size (matches assets/bones directory)
var bone_assets = {
	"small": [],
	"medium": [],
	"large": []
}

# Size-based rarity with depth progression
var size_rarity_system = {
	"small": {
		"color": Color(0.8, 0.9, 0.8, 1.0),
		"multiplier": 1.0,
		"min_depth": 0.0,
		"max_depth": 0.5,
		"unlock_level": 0
	},
	"medium": {
		"color": Color(0.7, 0.8, 1.0, 1.0),
		"multiplier": 3.0,
		"min_depth": 0.3,
		"max_depth": 0.8,
		"unlock_level": 1
	},
	"large": {
		"color": Color(1.0, 0.9, 0.3, 1.0),
		"multiplier": 8.0,
		"min_depth": 0.4,  # Make available earlier for testing
		"max_depth": 1.0,
		"unlock_level": 1   # Lower unlock level for easier testing
	}
}

func _ready():
	load_bone_assets()
	load_game_data()

func load_bone_assets():
	var dir = DirAccess.open("res://assets/bones/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".png"):
				if "small" in file_name.to_lower():
					bone_assets["small"].append(file_name)
				elif "medium" in file_name.to_lower():
					bone_assets["medium"].append(file_name)
				elif "large" in file_name.to_lower():
					bone_assets["large"].append(file_name)
				else:
					bone_assets["small"].append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	print("Loaded bone assets: ", bone_assets)

func get_random_bone_type() -> String:
	# Get random bone from any available size category
	var all_bones = []
	for size in bone_assets.keys():
		for bone in bone_assets[size]:
			all_bones.append(bone.get_basename())
	
	if all_bones.is_empty():
		return "fallback_bone"
	
	return all_bones[randi() % all_bones.size()]

func get_bone_for_depth(depth_percent: float) -> Dictionary:
	var available_sizes = []
	var player_level = player_data["upgrades"].get("depth_access", 0)
	var has_pickaxe = has_tool("pickaxe")
	
	print("=== BONE SPAWNING DEBUG ===")
	print("Depth: ", depth_percent, " | Player level: ", player_level, " | Has pickaxe: ", has_pickaxe)
	print("Tools owned: ", player_data["tools"])
	
	# Check which sizes are available at this depth and unlock level
	for size in size_rarity_system.keys():
		var size_data = size_rarity_system[size]
		var depth_ok = (depth_percent >= size_data["min_depth"] and depth_percent <= size_data["max_depth"])
		# Skip unlock level check if pickaxe is owned for large bones
		var level_ok = (player_level >= size_data["unlock_level"]) or (has_tool("pickaxe") and size == "large")
		print("Size ", size, ": depth_ok=", depth_ok, ", level_ok=", level_ok, " (min:", size_data["min_depth"], ", max:", size_data["max_depth"], ", unlock:", size_data["unlock_level"], ", pickaxe_override:", has_tool("pickaxe") and size == "large", ")")
		if depth_ok and level_ok:
			available_sizes.append(size)
	
	# Force large bones if pickaxe owned and deep enough
	if has_tool("pickaxe") and depth_percent >= 0.4 and not available_sizes.has("large"):
		print("FORCING large bone availability due to pickaxe ownership")
		available_sizes.append("large")
	
	# Add large bones if pickaxe owned and deep enough
	if has_tool("pickaxe") and depth_percent >= 0.5:
		if not available_sizes.has("large"):
			available_sizes.append("large")
		print("Pickaxe owned - large bones available at depth ", int(depth_percent * 100), "%")
	
	# Default to small if nothing available
	if available_sizes.is_empty():
		print("No bones available at this depth/level, defaulting to small")
		available_sizes.append("small")
	
	print("Available sizes: ", available_sizes)
	
	# Bias toward large bones in deep areas with pickaxe
	var selected_size: String
	if has_tool("pickaxe") and depth_percent >= 0.6 and available_sizes.has("large"):
		# 60% chance for large bones in very deep areas
		if randf() < 0.6:
			selected_size = "large"
		else:
			selected_size = available_sizes[randi() % available_sizes.size()]
	else:
		selected_size = available_sizes[randi() % available_sizes.size()]
	var size_assets = bone_assets[selected_size]
	
	if size_assets.is_empty():
		# Fallback if no assets loaded
		return {
			"asset_path": "",
			"size": selected_size,
			"type": "fallback_bone",
			"color": size_rarity_system[selected_size]["color"],
			"value_multiplier": size_rarity_system[selected_size]["multiplier"]
		}
	
	# Select random bone asset
	var bone_file = size_assets[randi() % size_assets.size()]
	var bone_name = bone_file.get_basename()
	var asset_path = "res://assets/bones/" + bone_file
	
	print("Creating bone data: size=", selected_size, ", type=", bone_name, ", path=", asset_path)
	
	return {
		"asset_path": asset_path,
		"size": selected_size,
		"type": bone_name,
		"color": size_rarity_system[selected_size]["color"],
		"value_multiplier": size_rarity_system[selected_size]["multiplier"]
	}

func get_bone_by_depth_and_rarity(depth_percent: float) -> Dictionary:
	# Determine geological zone
	var zone: String
	if depth_percent < 0.3:
		zone = "shallow"
	elif depth_percent < 0.6:
		zone = "medium"
	elif depth_percent < 0.85:
		zone = "deep"
	else:
		zone = "bedrock"
	
	# Roll for rarity based on geological zone
	var roll = randi() % 100
	var rarity: String
	var zone_data = geological_bone_distribution[zone]
	
	if roll < zone_data["common"]:
		rarity = "common"
	elif roll < zone_data["common"] + zone_data["uncommon"]:
		rarity = "uncommon"
	elif roll < zone_data["common"] + zone_data["uncommon"] + zone_data["rare"]:
		rarity = "rare"
	else:
		rarity = "legendary"
	
	# Select random bone type from rarity tier
	var rarity_data = bone_rarity_tiers[rarity]
	var bone_type = rarity_data["types"][randi() % rarity_data["types"].size()]
	
	return {
		"type": bone_type,
		"rarity": rarity,
		"color": rarity_data["color"],
		"value_multiplier": rarity_data["multiplier"]
	}

func get_bone_rarity(bone_type: String) -> String:
	for rarity in bone_rarity_tiers.keys():
		if bone_type in bone_rarity_tiers[rarity]["types"]:
			return rarity
	return "common"

func add_bone(bone_type: String, rarity_multiplier: float = 1.0):
	if not player_data["bones"].has(bone_type):
		player_data["bones"][bone_type] = 0
	player_data["bones"][bone_type] += 1
	
	# Award coins based on bone rarity
	var coin_value = get_bone_value(bone_type, rarity_multiplier)
	player_data["coins"] += coin_value
	
	save_game_data()

func get_bone_value(bone_type: String, rarity_multiplier: float = 1.0) -> int:
	var base_value: int = 20  # Increased base value
	
	# Determine value based on bone type with better rewards
	if bone_type.contains("small") or bone_type.length() <= 8:
		base_value = 15  # Small bones
	elif bone_type.contains("medium") or (bone_type.length() > 8 and bone_type.length() <= 12):
		base_value = 40  # Medium bones  
	elif bone_type.contains("large") or bone_type.length() > 12:
		base_value = 100  # Large bones - very valuable!
	else:
		# Fallback based on name patterns
		match bone_type:
			"skull_fragment", "complete_fossil": base_value = 150
			"ancient_tooth", "jaw_fragment": base_value = 80
			"vertebra", "leg_bone": base_value = 60
			_: base_value = 25
	
	return int(base_value * rarity_multiplier)

func has_tool(tool_name: String) -> bool:
	return player_data["tools"].get(tool_name, false)

func get_tool_power(tool_name: String) -> float:
	if not has_tool(tool_name):
		return 0.0
	
	match tool_name:
		"shovel": return 0.5
		"pickaxe": return 2.5  # Increased power
		"brush": return 0.3   # Slightly better
		"drill": return 4.0   # Powerful tool for deepest layers
		_: return 0.0

func purchase_upgrade(upgrade_type: String, cost: int) -> bool:
	if player_data["coins"] >= cost:
		player_data["coins"] -= cost
		player_data["upgrades"][upgrade_type] += 1
		save_game_data()
		return true
	return false

func purchase_tool(tool_name: String, cost: int) -> bool:
	if player_data["coins"] >= cost and not player_data["tools"][tool_name]:
		player_data["coins"] -= cost
		player_data["tools"][tool_name] = true
		
		# Update depth access when getting pickaxe (unlocks large bones)
		if tool_name == "pickaxe":
			player_data["upgrades"]["depth_access"] = 3  # Set to 3 to guarantee access
			print("Pickaxe purchased! Large bones now unlocked at depth access level 3")
			print("Current depth_access: ", player_data["upgrades"]["depth_access"])
		
		save_game_data()
		return true
	return false

func save_game_data():
	var save_file = FileAccess.open("user://savegame.dat", FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(player_data))
		save_file.close()

func load_game_data():
	if FileAccess.file_exists("user://savegame.dat"):
		var save_file = FileAccess.open("user://savegame.dat", FileAccess.READ)
		if save_file:
			var json_string = save_file.get_as_text()
			save_file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				var loaded_data = json.data
				if loaded_data is Dictionary:
					player_data = loaded_data

func reset_game():
	player_data = {
		"bones": {},
		"coins": 0,
		"upgrades": {
			"dig_speed": 0,
			"dig_power": 0,
			"bone_detection": 0
		},
		"tools": {
			"shovel": true,
			"pickaxe": false,
			"brush": false
		}
	}
	save_game_data()

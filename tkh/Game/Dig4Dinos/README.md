# Dig4Dinos - Dino Excavation Mobile Game

A fun archaeological dig game where you excavate dinosaur bones from procedurally generated geological layers.

## Features

### Enhanced Digging Mechanics
- **Procedural terrain generation** using FastNoiseLite
- **10-tier geological system** from grass to bedrock
- **Top-down archaeological perspective** - dig deeper to reveal underground layers
- **Feathered digging circles** with smooth erosion falloff
- **Material hardness system** with realistic digging resistance

### Bone Collection System
- **Clickable bone collection** with Area2D interaction
- **Progressive revelation** based on cleared soil around bones
- **Multiple bone types** with different rarity and value
- **Particle feedback** for visual polish

### Geological Layers
1. **Grass** (surface) - Easy to clear
2. **Topsoil** - Rich organic soil
3. **Dirt** - Standard earth
4. **Sand** - Granular material
5. **Gravel** - Small stones
6. **Compacted** - Compressed soil
7. **Clay** - Dense clay layer
8. **Soft Rock** - Sedimentary stone
9. **Hard Rock** - Requires pickaxe
10. **Bedrock** - Deepest layer, requires pickaxe

### Game Systems
- **Progressive tool unlocks** (shovel, pickaxe, brush)
- **Coin economy** for purchasing tools and upgrades
- **Save/load system** for persistent progress
- **Mobile-optimized** touch controls

## Technical Implementation

- **Godot 4.x** game engine
- **Image-based terrain** with pixel-level digging
- **FastNoiseLite** for procedural generation
- **Depth tracking** system for top-down perspective
- **Area2D collision** for bone interaction

## Development Status

The game features a complete digging system with realistic geological progression and engaging bone collection mechanics. Perfect for mobile deployment with intuitive touch controls.

## Getting Started

1. Open project in Godot 4.x
2. Run the main scene (`scenes/main_menu.tscn`)
3. Start digging and collecting dinosaur bones!

## Testing Mode

Current settings are optimized for testing with:
- Larger dig radius (40px)
- Higher dig power (3.0)
- Faster depth progression (0.06 rate)
- Enhanced particle effects
# Racing Game

3D racing game built with Godot 4.3 — infinite procedural track, boost pads, engine sound, and no speed limit.

## Screenshots

Drive as fast as you can on an endlessly generated race track with random curves, straights, and hairpins.

## Features

- **Infinite procedural track** — road generates ahead of you, old segments disappear behind
- **No speed limit** — the car accelerates forever, how fast can you go?
- **Boost pads** — glowing blue strips on the road give temporary speed boosts
- **Procedural car model** — built from meshes (body, cabin, windshield, spoiler, headlights, wheels)
- **Engine sound** — procedurally generated, pitch scales with speed
- **Dynamic camera** — FOV widens at speed, camera pulls back
- **Pause menu** (ESC) — resume, restart, or quit to menu
- **HUD** — speedometer, distance traveled, race timer
- **3-2-1-GO countdown** with colored numbers
- **Barriers with collision** — concrete walls on both sides of the track
- **Scenery** — trees and buildings alongside the track
- **Lane markings** — dashed dividers, solid edge lines, red/white curbs, shoulder strips

## Controls

| Key | Action |
|-----|--------|
| W / Up Arrow | Accelerate |
| S / Down Arrow | Brake / Reverse |
| A / Left Arrow | Steer left |
| D / Right Arrow | Steer right |
| R | Reset car |
| ESC | Pause menu |

## Requirements

- [Godot 4.3](https://godotengine.org/download/) or newer

## Run

```bash
# Clone
git clone https://github.com/chukfinley/racing-game.git
cd racing-game

# Run directly (no build needed)
godot --path .

# Or open in Godot editor
godot --editor --path .
```

## Project Structure

```
racing-game/
├── project.godot              # Godot project config
├── scenes/
│   ├── main.tscn              # Game scene (track + car + HUD + sky)
│   ├── car.tscn               # Player car (VehicleBody3D + wheels)
│   ├── hud.tscn               # Speed, distance, timer UI
│   ├── menu.tscn              # Main menu
│   └── pause_menu.tscn        # Pause overlay
├── scripts/
│   ├── car_controller.gd      # Car physics, input, camera
│   ├── track_loader.gd        # Infinite procedural track generation
│   ├── car_mesh_builder.gd    # Builds car from primitives
│   ├── engine_sound.gd        # Procedural engine audio
│   ├── boost_pad.gd           # Speed boost trigger
│   ├── checkpoint.gd          # Checkpoint trigger
│   ├── race_manager.gd        # Countdown, timing, HUD updates
│   ├── hud.gd                 # UI display logic
│   ├── pause_menu.gd          # Pause/resume/quit
│   ├── main_menu.gd           # Menu buttons
│   ├── save_manager.gd        # Best times persistence
│   └── minimap.gd             # Track minimap drawing
└── models/                    # GLB assets (scenery)
    ├── barrier.glb
    ├── building.glb
    ├── start_gate.glb
    └── tree.glb
```

## Tech

- **Engine:** Godot 4.3 (Forward+)
- **Language:** GDScript
- **Rendering:** Vulkan, MSAA 2x, SSAO, glow, fog
- **Physics:** VehicleBody3D with 4 wheels, downforce, anti-flip
- **Audio:** Procedural (AudioStreamGenerator)
- **Track:** ImmediateMesh quads, StaticBody3D barriers

## License

MIT

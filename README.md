# chez-gamekit

Raylib bindings, an ECS, and game utilities for Chez Scheme.
Built for personal use — simple 2D games. No package system, no dependencies beyond Chez Scheme and raylib.

## Requirements

- [Chez Scheme](https://cisco.github.io/ChezScheme/)
- [raylib](https://www.raylib.com/) (tested with `libraylib.so` on Linux)

## Usage

Load everything at once:

```scheme
(load "chez-gamekit.ss")
```

Or pick individual modules:

```scheme
(load "lib/raylib.ss")
(load "lib/json.ss")
(load "lib/ecs.ss")
(load "lib/assets.ss")      ; asset cache
(load "lib/animation.ss")   ; sprite animation — requires ecs.ss + assets.ss
(load "lib/game-loop.ss")   ; dt + game-loop — requires ecs.ss + raylib.ss
(load "lib/tilemap.ss")     ; Tiled JSON tilemaps — requires json.ss + assets.ss + raylib.ss
```

Load order matters when loading individually — each module requires the ones listed above it.

## raylib.ss

Covers the basics for 2D games:

- Window management (`init-window`, `close-window`, `window-should-close`, `get-screen-width`, `get-screen-height`, etc.)
- Drawing (`begin-drawing`, `end-drawing`, `clear-background`, `draw-rectangle`, `draw-circle`, `draw-text`, `draw-fps`, etc.)
- Textures (`load-texture`, `draw-texture`, `draw-texture-rec`, `draw-texture-pro`)
- Camera 2D (`begin-mode-2d`, `end-mode-2d`, `make-camera2d`)
- Keyboard and mouse input — full key constants (`key-a` through `key-z`, `key-up/down/left/right`, F-keys, etc.)
- Audio (`load-sound`, `play-sound`, `pause-sound`, `resume-sound`, `is-sound-playing`)
- Timing (`get-frame-time`, `get-time`, `get-fps`)

Foreign memory (`make-vec2`, `make-rect`, `make-color`, `make-camera2d`) is managed automatically via a guardian and a background GC thread — no manual `free-ptr` calls needed in normal use. `free-ptr` remains available for explicit early release if needed.

Camera 2D, audio, and `draw-texture-pro` are included but **untested** — they were mapped manually from raylib's internal struct layout and may not work correctly across raylib versions.

## json.ss

A self-contained JSON parser. No dependencies.

```scheme
(json-load "data/level.json")   ; parses a file, returns an alist
(json-parse "{\"x\": 1}")       ; parses a string
(json-get obj "key")            ; looks up a key in a parsed object
```

JSON `null` is represented as the symbol `'null` (not `#f`) to distinguish it from missing keys. Use the provided predicates to check values:

```scheme
(json-null?  v)   ; #t if v is JSON null
(json-false? v)   ; #t if v is JSON false
(json-value? v)   ; #t if v is anything other than #f (i.e. key was present)
```

## ecs.ss

A minimal ECS with a DSL. Entities and components are stored in hashtables.

### Basic example

```scheme
(load "lib/ecs.ss")

(component position (x y))
(component velocity (dx dy))
(component health (hp))
(component dead)              ; tag — no fields

(entity player (position 0 0) (velocity 1 2) (health 100))

(system movement ((pos : position) (vel : velocity)) not (dead)
  (put! pos x (+ (get pos x) (get vel dx)))
  (put! pos y (+ (get pos y) (get vel dy))))

(event hit (target damage))

(on-global hit (target damage)
  (put! target health hp (- (get target health hp) damage)))

(emit hit (target player) (damage 30))

(run)
```

### Scene example

```scheme
(load "lib/ecs.ss")

(component position (x y))
(component velocity (dx dy))
(component persistent)        ; survives scene transitions

;;; player is defined here so it can be set! inside on-enter
(define player #f)

(event hit (target damage))

;;; on-global handlers are cleared on go-to — register them outside scenes
(on-global hit (target damage)
  (display (list 'hit player 'damage damage)) (newline))

(scene main-menu
  (on-enter
    (spawn (position 10 0))
    (system render-menu ((pos : position))
      (display (list 'menu-item entity-id)) (newline)))
  (on-exit
    (display "leaving menu") (newline)))

(scene gameplay
  (on-enter
    (set! player (spawn (position 0 0) (velocity 1 2)))
    (add-component player persistent)
    (system movement ((pos : position) (vel : velocity))
      (put! pos x (+ (get pos x) (get vel dx)))
      (put! pos y (+ (get pos y) (get vel dy))))
    (system render ((pos : position))
      (display (list 'entity entity-id 'pos (get pos x) (get pos y))) (newline)))
  (on-exit
    (display "leaving gameplay") (newline)))

(go-to main-menu)
(run)

(go-to gameplay)
(run)
(run)
```

### ECS API

| Form | Description |
|---|---|
| `(component name (field ...))` | Declares a component type with fields |
| `(component tag)` | Declares a tag component (no fields) |
| `(entity name (comp val ...) ...)` | Creates a named entity at top level |
| `(spawn (comp val ...) ...)` | Creates a dynamic entity, returns id |
| `(despawn id)` | Removes an entity |
| `(get comp field)` | Reads a field inside a system |
| `(get id comp field)` | Reads a field outside a system |
| `(put! comp field expr)` | Writes a field inside a system |
| `(put! id comp field expr)` | Writes a field outside a system |
| `(add-component id comp)` | Adds a tag component to an entity |
| `(add-component id comp (field val) ...)` | Adds a component with fields |
| `(remove-component id comp)` | Removes a component from an entity |
| `(has-component? id comp)` | Returns `#t` if entity has component |
| `(system name ((var : comp) ...) body ...)` | Defines and registers a system |
| `(system name ((var : comp) ...) not (excl ...) body ...)` | Same, with exclusions |
| `(global-system name body ...)` | Registers a system that runs once per frame, without iterating entities |
| `(event name (field ...))` | Declares an event type and validates `emit` calls against it |
| `(emit name (field val) ...)` | Enqueues an event |
| `(on name (field ...) body ...)` | Registers a scene-local event handler |
| `(on-global name (field ...) body ...)` | Registers a persistent event handler |
| `(scene name (on-enter body ...) (on-exit body ...))` | Declares a scene |
| `(go-to name)` | Switches to a scene |
| `(run)` | Runs all systems, then dispatches events |

Inside a system, `entity-id` is always bound to the current entity's id.

`entity` only works at the top level — use `define` + `set!` + `spawn` inside `on-enter`.

Systems and handlers run in registration order (the order they were defined inside `on-enter`).

Events emitted during dispatch are enqueued and processed on the next `(run)` call, not the current one.

`go-to` clears systems, global systems, event handlers (local and global), and the event queue, then removes all non-`persistent` entities. Register `on-global` handlers outside scenes if they need to survive transitions.

## assets.ss

An asset cache keyed by symbol. Each entry stores the asset value alongside its unloader, so `unload-asset` always calls the right cleanup function automatically.

```scheme
(load-asset player-idle "assets/idle.png")                        ; loads and caches a texture
(load-asset shoot-sfx "assets/shoot.wav" load-sound unload-sound) ; custom loader + unloader
(load-asset! tex-name path)                                        ; dynamic symbol — same as above
(get-asset player-idle)                                            ; retrieves by literal name
(asset-ref name)                                                   ; retrieves by runtime symbol
(unload-asset player-idle)                                         ; calls unloader and removes from cache
```

`load-asset` is a macro and requires a literal symbol. Use `load-asset!` when the name is a runtime value (e.g. inside a loop or when loading tilemaps). The default loader is `load-texture` and the default unloader is `unload-texture`.

## animation.ss

Sprite sheet animation built on top of the ECS.

```scheme
(make-animation-system)         ; registers the frame-advance system
(make-render-animation-system)  ; registers the draw system
```

Both must be called inside `on-enter` to register for the current scene. The render system expects a `position` component on the same entity.

The `animation` component fields are: `texture` (asset name symbol), `frame-w`, `frame-h`, `frames`, `speed` (fps), `frame` (current, starts at 0), `elapsed` (starts at 0.0).

## game-loop.ss

Delta time and the main loop.

| Form | Description |
|---|---|
| `dt` | Seconds elapsed since the last frame — updated every frame |
| `(game-loop title w h fps)` | Opens a window and runs the main loop |
| `(game-loop title w h fps init)` | Same, calls `init` thunk once before the loop starts |

The window and audio device are always closed cleanly on exit, even if an error is raised during the loop.

### Example

```scheme
(load "chez-gamekit.ss")

(define player #f)

(scene gameplay
  (on-enter
    (load-asset hero "assets/hero.png")
    (make-animation-system)
    (make-render-animation-system)
    (set! player (spawn
      (position 100 100)
      (animation hero 32 32 4 8 0 0.0)))
    (system input ((pos : position))
      (when (is-key-down key-right) (put! pos x (+ (get pos x) 2)))
      (when (is-key-down key-left)  (put! pos x (- (get pos x) 2)))
      (when (is-key-down key-down)  (put! pos y (+ (get pos y) 2)))
      (when (is-key-down key-up)    (put! pos y (- (get pos y) 2))))
    (global-system render-bg
      (render-tilemap world)))
  (on-exit #f))

(game-loop "my game" 800 600 60
  (lambda ()
    (load-tilemap world "assets/world.json")
    (go-to gameplay)))
```

## tilemap.ss

Loads and renders [Tiled](https://www.mapeditor.org/) maps exported as JSON. Supports tile layers and object layers.

```scheme
(load-tilemap level1 "assets/level1.json")    ; loads map and all referenced tilesets
(render-tilemap level1)                        ; draws all visible tile layers
(render-tilemap level1 camera)                 ; same, wrapped in begin-mode-2d

(tilemap-width  level1)    ; total pixel width
(tilemap-height level1)    ; total pixel height

(tilemap-objects level1)               ; all objects from all object layers
(tilemap-objects level1 "spawns")      ; objects from a named layer only
```

Object accessors: `obj-x`, `obj-y`, `obj-width`, `obj-height`, `obj-name`, `obj-type`, `obj-id`.

## License

MIT

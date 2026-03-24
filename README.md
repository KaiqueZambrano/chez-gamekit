# chez-4games

Raylib bindings and an ECS implementation for Chez Scheme.

Built for personal use — simple 2D games. No package system, no dependencies beyond Chez Scheme and raylib.

## Requirements

- [Chez Scheme](https://cisco.github.io/ChezScheme/)
- [raylib](https://www.raylib.com/) (tested with `libraylib.so` on Linux)

## Usage

```scheme
(load "lib/raylib.ss")
(load "lib/ecs.ss")
```

## raylib.ss

Covers the basics for 2D games:

- Window management (`init-window`, `close-window`, `window-should-close`)
- Drawing (`begin-drawing`, `end-drawing`, `clear-background`, `draw-rectangle`, `draw-circle`, `draw-text`, etc.)
- Textures (`load-texture`, `draw-texture`, `draw-texture-rec`, `draw-texture-pro`)
- Keyboard and mouse input
- Collision (`check-collision-recs`)
- Camera 2D and audio bindings are included but **untested** — they were mapped manually from raylib's internal struct layout and may not work correctly across raylib versions.

## ecs.ss

A minimal ECS built on association lists.

```scheme
; define components
(define-component position x y)
(define-component velocity dx dy)
(define-component health hp)
(define-component frozen dummy)

; spawn entities
(define player
  (spawn (position 0 0)
         (velocity 1 1)
         (health 100)))

; define systems
(define-system movement (position velocity) not (frozen) (id pos vel)
  (comp-set! pos 'x (+ (comp-get pos 'x) (comp-get vel 'dx)))
  (comp-set! pos 'y (+ (comp-get pos 'y) (comp-get vel 'dy))))

; run all systems
(run-systems)
```

### API

| Function | Description |
|---|---|
| `(define-component name field ...)` | Declares a component type |
| `(spawn (comp val ...) ...)` | Creates an entity with components |
| `(despawn id)` | Removes an entity |
| `(get-field id comp field)` | Reads a field by entity id |
| `(set-field! id comp field val)` | Writes a field by entity id |
| `(add-component id comp values)` | Adds a component to an existing entity |
| `(remove-component id comp)` | Removes a component from an entity |
| `(comp-get comp field)` | Reads a field inside a system |
| `(comp-set! comp field val)` | Writes a field inside a system |
| `(query '(comp ...))` | Returns all matching entities |
| `(query '(comp ...) '(excl ...))` | Same, excluding entities with `excl` |
| `(define-system name (comp ...) (id arg ...) body ...)` | Defines and registers a system |
| `(define-system name (comp ...) not (excl ...) (id arg ...) body ...)` | Same, with exclusions |
| `(run-systems)` | Runs all registered systems |

## Binding status

| Module | Tested |
|---|---|
| Window, drawing, input | ✅ |
| Textures (`draw-texture`, `draw-texture-rec`) | ✅ |
| `draw-texture-pro` | ⚠️ untested |
| Collision | ✅ |
| Camera2D | ⚠️ untested |
| Audio / Sound | ⚠️ untested |

## License

MIT

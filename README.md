# chez-gamekit

Minimal 2D ECS game framework for Chez Scheme, built on raylib.

## Requirements

- [Chez Scheme](https://cisco.github.io/ChezScheme/)
- [raylib](https://www.raylib.com/) (`libraylib.so` on Linux)

## Usage

```scheme
(load "chez-gamekit.ss")
```

## Example

A small platformer covering the main features — ECS, sprites, physics, input, camera, tilemaps, and scenes.

```scheme
(load "chez-gamekit.ss")

(define screen-w   400)
(define screen-h   240)
(define gravity    800.0)
(define jump-force -400.0)
(define walk-speed 120.0)
(define floor-y    160.0)

(component velocity (vx vy))
(component grounded)
(component player)

(scene gameplay
  (on-enter
    (load-asset player-idle "idle.png")
    (load-asset player-run  "running.png")
    (load-tilemap level "level.json")

    (let ((cam (make-camera 48 100 (/ screen-w 2.0) (/ screen-h 2.0))))
      (set-camera! cam)

      (spawn
        (position 48 100)
        (velocity 0.0 0.0)
        (player)
        (sprite player-idle 16 16 0 12 12 1.0 1.0))

      (with-camera cam
        (render-tilemap level)
        (render-sprites))

      (system camera-system ((pos : position) (p : player))
        (camera-follow! cam (get pos x) (get pos y) 0.08)
        (camera-clamp!  cam (tilemap-width level) (tilemap-height level)))

      (system physics-system ((pos : position) (vel : velocity))
        (let* ((vy-new (+ (get vel vy) (* gravity dt)))
               (x-new  (+ (get pos x) (* (get vel vx) dt)))
               (y-new  (+ (get pos y) (* vy-new dt))))
          (put! vel vy vy-new)
          (put! pos x x-new)
          (if (>= y-new floor-y)
              (begin
                (put! pos y floor-y)
                (put! vel vy 0.0)
                (unless (has-component? entity-id grounded)
                  (add-component entity-id grounded)))
              (begin
                (put! pos y y-new)
                (when (has-component? entity-id grounded)
                  (remove-component entity-id grounded))))))

      (system input-system ((vel : velocity) (spr : sprite) (p : player))
        (let ((vx 0.0))
          (when (or (key-down? key-right) (key-down? key-d))
            (set! vx walk-speed)
            (put! spr scale-x 1.0))
          (when (or (key-down? key-left) (key-down? key-a))
            (set! vx (- walk-speed))
            (put! spr scale-x -1.0))
          (if (= vx 0.0)
              (sprite-texture! spr player-idle)
              (sprite-texture! spr player-run))
          (put! vel vx vx)
          (when (and (or (key-pressed? key-space)
                         (key-pressed? key-up)
                         (key-pressed? key-w))
                     (has-component? entity-id grounded))
            (put! vel vy jump-force)
            (remove-component entity-id grounded))))))

  (on-exit
    (clear-camera!)
    (unload-all-assets!)))

(game-loop "platformer" screen-w screen-h 60
  (lambda () (go-to gameplay)))
```

## ECS

### Components and entities

```scheme
(component position (x y))   ; component with fields
(component grounded)          ; tag — no fields

(spawn (position 0 0) (velocity 1.0 0.0))   ; returns entity id
(despawn id)
```

`spawn` can bind a name at the top level: `(spawn player (position 0 0))` expands to `(define player (spawn ...))`. Inside `on-enter`, use `(define player #f)` + `(set! player (spawn ...))`.

### Systems

```scheme
;;; runs once per entity that has all listed components
(system name ((var : comp) ...) body ...)

;;; with exclusions
(system name ((var : comp) ...) not (excl ...) body ...)

;;; survives scene transitions
(system name persistent ((var : comp) ...) body ...)

;;; runs once per frame, no entity iteration
(global-system name body ...)
```

Inside a system, `entity-id` is bound to the current entity's id. Systems run in registration order.

### Reading and writing components

```scheme
(get comp field)             ; inside a system — comp is the bound variable
(get id comp field)          ; outside a system — id is the entity id
(put! comp field expr)       ; inside a system
(put! id comp field expr)    ; outside a system
```

### Component membership

```scheme
(add-component id comp)
(add-component id comp (field val) ...)
(remove-component id comp)
(has-component? id comp)
```

### Events

```scheme
(emit name (field val) ...)

(on name (field ...) body ...)           ; scene-local handler
(on-global name (field ...) body ...)    ; persists across scene transitions
```

Events emitted during a frame are dispatched at the end of that frame. `on-global` handlers should be registered outside scenes if they need to persist across `go-to`.

### Scenes

```scheme
(scene name
  (on-enter body ...)
  (on-exit  body ...))

(go-to name)
```

`go-to` clears scene-local systems, handlers, and the event queue, then despawns all entities that don't have a `persistent` component. Systems registered with `persistent` survive transitions.

## Assets

```scheme
(load-asset name "path/to/file.png")                         ; default: load-texture / unload-texture
(load-asset name "path/to/file.wav" load-sound unload-sound) ; custom loader and unloader
(load-asset! sym path)                                        ; same, but name is a runtime symbol

(get-asset name)      ; retrieve by literal name
(unload-asset name)
(unload-all-assets!)
(unload-assets-except! name ...)
```

`load-asset` is idempotent — loading the same name twice is a no-op.

## Camera

```scheme
(make-camera tx ty)                        ; offset centered on screen, zoom 1.0
(make-camera tx ty offset-x offset-y)
(make-camera tx ty offset-x offset-y zoom)

(set-camera! cam)    ; activate for all render systems
(clear-camera!)      ; return to screen-space

(camera-follow! cam x y)         ; snap to position
(camera-follow! cam x y speed)   ; lerp toward position
(camera-clamp!  cam world-w world-h)
(camera-zoom-set! cam z)
(camera-zoom      cam)
```

## Sprites

The `sprite` component fields, in order:

| Field | Description |
|---|---|
| `texture` | Asset name symbol |
| `frame-w` | Frame width in pixels |
| `frame-h` | Frame height in pixels |
| `row` | Spritesheet row (0-indexed) |
| `frames` | Total frames in this animation |
| `speed` | Frames per second |
| `scale-x` | `1.0` normal, `-1.0` flip horizontally |
| `scale-y` | `1.0` normal, `-1.0` flip vertically |

`frame` and `elapsed` are appended automatically if omitted. The animation system is installed by `game-loop` — no setup needed.

```scheme
;;; swap texture, keeping row/frame/speed
(sprite-texture! spr-var asset-name)
```

To render sprites, include `(render-sprites)` inside `with-camera`:

```scheme
(with-camera cam
  (render-tilemap level)
  (render-sprites))
```

## Tilemap

Loads [Tiled](https://www.mapeditor.org/) maps exported as JSON.

```scheme
(load-tilemap name "assets/level.json")
(render-tilemap name)

(tilemap-width  name)
(tilemap-height name)

(tilemap-objects name)            ; all objects from all object layers
(tilemap-objects name "layer")    ; objects from a named layer
```

Object accessors: `obj-x`, `obj-y`, `obj-width`, `obj-height`, `obj-name`, `obj-type`, `obj-id`.

## Input

```scheme
(key-down?     key)
(key-pressed?  key)    ; true only on the frame the key was pressed
(key-released? key)    ; true only on the frame the key was released
```

Key constants: `key-a` through `key-z`, `key-0` through `key-9`, `key-up`, `key-down`, `key-left`, `key-right`, `key-space`, `key-enter`, `key-escape`, `key-backspace`, `key-f1` through `key-f12`, `key-left-shift`, `key-left-control`, `key-left-alt`, and right-side equivalents.

Mouse: `is-mouse-button-pressed`, `is-mouse-button-down`, `is-mouse-button-released`, `is-mouse-button-up`, `get-mouse-x`, `get-mouse-y`. Button constants: `mouse-button-left`, `mouse-button-right`, `mouse-button-middle`.

For text fields, use `text-input` instead of key polling:

```scheme
(system name-entry ()
  (set! buf (string-append buf (text-input)))
  (when (and (key-pressed? key-backspace) (> (string-length buf) 0))
    (set! buf (substring buf 0 (- (string-length buf) 1)))))
```

## Game loop

```scheme
(game-loop title width height fps)
(game-loop title width height fps init-thunk)
```

`dt` is bound to the seconds elapsed since the last frame, updated every frame.

## Drawing

Direct raylib calls, available for custom rendering:

`draw-pixel`, `draw-line`, `draw-circle`, `draw-rectangle`, `draw-rectangle-rec`, `draw-rectangle-lines`, `draw-text`, `draw-text-centered`, `draw-fps`, `draw-texture`, `draw-texture-rec`, `draw-texture-pro`.

Colors: `black`, `white`, `red`, `green`, `blue`, `yellow`, `orange`, `gray`, `darkgray`, `lightgray`, `raywhite`, and more. Custom: `(make-color r g b a)`.

## Audio

```scheme
(load-asset shoot "shoot.wav" load-sound unload-sound)
(play-sound  (get-asset shoot))
(stop-sound  (get-asset shoot))
(pause-sound (get-asset shoot))
(resume-sound (get-asset shoot))
(is-sound-playing (get-asset shoot))
(set-master-volume 0.8)
```

## License

MIT

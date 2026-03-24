;;; raylib.ss

(load-shared-object "libraylib.so")

;;; ============================================================
;;; FTYPES
;;; ============================================================

(define-ftype color
  (struct
    [r unsigned-8]
    [g unsigned-8]
    [b unsigned-8]
    [a unsigned-8]))

(define-ftype texture2d
  (struct
    [id      unsigned-32]
    [width   int]
    [height  int]
    [mipmaps int]
    [format  int]))

(define-ftype rectangle
  (struct
    [x      float]
    [y      float]
    [width  float]
    [height float]))

(define-ftype vector2
  (struct
    [x float]
    [y float]))

(define-ftype camera2d
  (struct
    [offset-x float]
    [offset-y float]
    [target-x float]
    [target-y float]
    [rotation float]
    [zoom     float]))

(define-ftype sound
  (struct
    [stream-buffer void*]
    [stream-format void*]
    [frame-count   unsigned-32]
    [looping       boolean]))

;;; ============================================================
;;; CONSTRUCTORS
;;; ============================================================

(define (make-color r g b a)
  (let ([c (make-ftype-pointer color (foreign-alloc (ftype-sizeof color)))])
    (ftype-set! color (r) c r)
    (ftype-set! color (g) c g)
    (ftype-set! color (b) c b)
    (ftype-set! color (a) c a)
    c))

(define (make-rect x y w h)
  (let ([r (make-ftype-pointer rectangle
             (foreign-alloc (ftype-sizeof rectangle)))])
    (ftype-set! rectangle (x)      r (exact->inexact x))
    (ftype-set! rectangle (y)      r (exact->inexact y))
    (ftype-set! rectangle (width)  r (exact->inexact w))
    (ftype-set! rectangle (height) r (exact->inexact h))
    r))

(define (make-vec2 x y)
  (let ([v (make-ftype-pointer vector2
             (foreign-alloc (ftype-sizeof vector2)))])
    (ftype-set! vector2 (x) v (exact->inexact x))
    (ftype-set! vector2 (y) v (exact->inexact y))
    v))

(define (make-camera2d target-x target-y offset-x offset-y zoom)
  (let ([c (make-ftype-pointer camera2d
             (foreign-alloc (ftype-sizeof camera2d)))])
    (ftype-set! camera2d (target-x) c (exact->inexact target-x))
    (ftype-set! camera2d (target-y) c (exact->inexact target-y))
    (ftype-set! camera2d (offset-x) c (exact->inexact offset-x))
    (ftype-set! camera2d (offset-y) c (exact->inexact offset-y))
    (ftype-set! camera2d (rotation) c 0.0)
    (ftype-set! camera2d (zoom)     c (exact->inexact zoom))
    c))

(define (camera-set-target! cam x y)
  (ftype-set! camera2d (target-x) cam (exact->inexact x))
  (ftype-set! camera2d (target-y) cam (exact->inexact y)))

;;; ============================================================
;;; COLORS
;;; ============================================================

(define black    (make-color   0   0   0 255))
(define white    (make-color 255 255 255 255))
(define red      (make-color 255   0   0 255))
(define green    (make-color   0 228  48 255))
(define blue     (make-color   0 121 241 255))
(define yellow   (make-color 253 249   0 255))
(define raywhite (make-color 245 245 245 255))
(define darkgray (make-color  80  80  80 255))

;;; ============================================================
;;; WINDOW
;;; ============================================================

(define init-window
  (foreign-procedure "InitWindow" (int int string) void))

(define close-window
  (foreign-procedure "CloseWindow" () void))

(define window-should-close
  (foreign-procedure "WindowShouldClose" () boolean))

(define set-target-fps
  (foreign-procedure "SetTargetFPS" (int) void))

(define get-frame-time
  (foreign-procedure "GetFrameTime" () float))

;;; ============================================================
;;; DRAW
;;; ============================================================

(define begin-drawing
  (foreign-procedure "BeginDrawing" () void))

(define end-drawing
  (foreign-procedure "EndDrawing" () void))

(define clear-background
  (foreign-procedure "ClearBackground" ((& color)) void))

(define draw-fps
  (foreign-procedure "DrawFPS" (int int) void))

(define draw-rectangle
  (foreign-procedure "DrawRectangle" (int int int int (& color)) void))

(define draw-circle
  (foreign-procedure "DrawCircle" (int int float (& color)) void))

(define draw-line
  (foreign-procedure "DrawLine" (int int int int (& color)) void))

(define draw-text
  (foreign-procedure "DrawText" (string int int int (& color)) void))

(define measure-text
  (foreign-procedure "MeasureText" (string int) int))

;;; ============================================================
;;; TEXTURES
;;; ============================================================

(define load-texture-ffi
  (foreign-procedure "LoadTexture" (string) (& texture2d)))

(define (load-texture path)
  (let ([tex (make-ftype-pointer texture2d
               (foreign-alloc (ftype-sizeof texture2d)))])
    (load-texture-ffi tex path)
    tex))

(define unload-texture
  (foreign-procedure "UnloadTexture" ((& texture2d)) void))

(define draw-texture
  (foreign-procedure "DrawTexture" ((& texture2d) int int (& color)) void))

(define draw-texture-rec
  (foreign-procedure "DrawTextureRec"
    ((& texture2d) (& rectangle) (& vector2) (& color))
    void))

(define draw-texture-pro
  (foreign-procedure "DrawTexturePro"
    ((& texture2d) (& rectangle) (& rectangle) (& vector2) float (& color))
    void))

;;; ============================================================
;;; 2D CAMERA
;;; ============================================================

(define begin-mode-2d
  (foreign-procedure "BeginMode2D" ((& camera2d)) void))

(define end-mode-2d
  (foreign-procedure "EndMode2D" () void))

;;; ============================================================
;;; COLLISION
;;; ============================================================

(define check-collision-recs
  (foreign-procedure "CheckCollisionRecs"
    ((& rectangle) (& rectangle))
    boolean))

;;; ============================================================
;;; KEYBOARD
;;; ============================================================

(define is-key-down
  (foreign-procedure "IsKeyDown" (int) boolean))

(define is-key-pressed
  (foreign-procedure "IsKeyPressed" (int) boolean))

(define is-key-released
  (foreign-procedure "IsKeyReleased" (int) boolean))

(define key-right  262)
(define key-left   263)
(define key-down   264)
(define key-up     265)
(define key-space   32)
(define key-enter  257)
(define key-escape  27)
(define key-a       65)
(define key-d       68)
(define key-w       87)
(define key-s       83)

;;; ============================================================
;;; MOUSE
;;; ============================================================

(define get-mouse-x
  (foreign-procedure "GetMouseX" () int))

(define get-mouse-y
  (foreign-procedure "GetMouseY" () int))

(define is-mouse-button-pressed
  (foreign-procedure "IsMouseButtonPressed" (int) boolean))

(define is-mouse-button-down
  (foreign-procedure "IsMouseButtonDown" (int) boolean))

(define mouse-button-left   0)
(define mouse-button-right  1)
(define mouse-button-middle 2)

;;; ============================================================
;;; AUDIO
;;; ============================================================

(define init-audio-device
  (foreign-procedure "InitAudioDevice" () void))

(define close-audio-device
  (foreign-procedure "CloseAudioDevice" () void))

(define load-sound
  (foreign-procedure "LoadSound" (string) (& sound)))

(define unload-sound
  (foreign-procedure "UnloadSound" ((& sound)) void))

(define play-sound
  (foreign-procedure "PlaySound" ((& sound)) void))

(define stop-sound
  (foreign-procedure "StopSound" ((& sound)) void))

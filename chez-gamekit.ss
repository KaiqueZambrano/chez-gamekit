;;; ============================================================
;;; Chez GameKit — Lightweight 2D game framework for Chez Scheme
;;;               with raylib bindings and ECS architecture.
;;; ============================================================

(load-shared-object "libraylib.so")

;;;; ============================================================
;;;; 1. FFI TYPE DEFINITIONS
;;;; ============================================================

(define-ftype color     (struct [r unsigned-8] [g unsigned-8] [b unsigned-8] [a unsigned-8]))
(define-ftype vector2   (struct [x float] [y float]))
(define-ftype rectangle (struct [x float] [y float] [width float] [height float]))
(define-ftype texture2d (struct [id unsigned-32] [width int] [height int] [mipmaps int] [format int]))
(define-ftype camera2d  (struct [offset-x float] [offset-y float] [target-x float] [target-y float]
                                [rotation float] [zoom float]))
(define-ftype sound     (struct [stream-buffer void*] [stream-format void*]
                                [frame-count unsigned-32] [looping boolean]))
(define-ftype music     (struct [stream-buffer void*] [stream-format void*]
                                [frame-count unsigned-32] [looping boolean]
                                [ctx-type int] [ctx-data void*]))

;;;; ============================================================
;;;; 2. CONSTRUCTORS
;;;; ============================================================

(define-syntax %ftype-alloc
  (syntax-rules ()
    ((_ type)
     (make-ftype-pointer type (foreign-alloc (ftype-sizeof type))))))

(define (%->f x) (exact->inexact x))

(define (make-color r g b a)
  (let ([c (%ftype-alloc color)])
    (ftype-set! color (r) c r) (ftype-set! color (g) c g)
    (ftype-set! color (b) c b) (ftype-set! color (a) c a)
    c))

(define (make-vec2 x y)
  (let ([v (%ftype-alloc vector2)])
    (ftype-set! vector2 (x) v (%->f x))
    (ftype-set! vector2 (y) v (%->f y))
    v))

(define (make-rect x y w h)
  (let ([r (%ftype-alloc rectangle)])
    (ftype-set! rectangle (x)      r (%->f x))
    (ftype-set! rectangle (y)      r (%->f y))
    (ftype-set! rectangle (width)  r (%->f w))
    (ftype-set! rectangle (height) r (%->f h))
    r))

(define (make-camera2d tx ty ox oy zoom)
  (let ([c (%ftype-alloc camera2d)])
    (ftype-set! camera2d (target-x) c (%->f tx))
    (ftype-set! camera2d (target-y) c (%->f ty))
    (ftype-set! camera2d (offset-x) c (%->f ox))
    (ftype-set! camera2d (offset-y) c (%->f oy))
    (ftype-set! camera2d (rotation) c 0.0)
    (ftype-set! camera2d (zoom)     c (%->f zoom))
    c))

;;;; ============================================================
;;;; 3. PREDEFINED COLORS
;;;; ============================================================

(define lightgray  (make-color 200 200 200 255))
(define gray       (make-color 130 130 130 255))
(define darkgray   (make-color  80  80  80 255))
(define yellow     (make-color 253 249   0 255))
(define gold       (make-color 255 203   0 255))
(define orange     (make-color 255 161   0 255))
(define pink       (make-color 255 109 194 255))
(define red        (make-color 230  41  55 255))
(define maroon     (make-color 190  33  45 255))
(define green      (make-color   0 228  48 255))
(define lime       (make-color   0 158  47 255))
(define darkgreen  (make-color   0 117  44 255))
(define skyblue    (make-color 102 191 255 255))
(define blue       (make-color   0 121 241 255))
(define darkblue   (make-color   0  82 172 255))
(define purple     (make-color 200 122 255 255))
(define violet     (make-color 135  60 190 255))
(define darkpurple (make-color 112  31 126 255))
(define beige      (make-color 211 176 131 255))
(define brown      (make-color 127 106  79 255))
(define darkbrown  (make-color  76  63  47 255))
(define white      (make-color 255 255 255 255))
(define black      (make-color   0   0   0 255))
(define blank      (make-color   0   0   0   0))
(define magenta    (make-color 255   0 255 255))
(define raywhite   (make-color 245 245 245 255))

;;;; ============================================================
;;;; 4. RAYLIB BINDINGS
;;;; ============================================================

(define init-window         (foreign-procedure "InitWindow"        (int int string) void))
(define close-window        (foreign-procedure "CloseWindow"       () void))
(define window-should-close (foreign-procedure "WindowShouldClose" () boolean))
(define set-window-title    (foreign-procedure "SetWindowTitle"    (string) void))
(define set-window-position (foreign-procedure "SetWindowPosition" (int int) void))
(define set-window-size     (foreign-procedure "SetWindowSize"     (int int) void))
(define get-screen-width    (foreign-procedure "GetScreenWidth"    () int))
(define get-screen-height   (foreign-procedure "GetScreenHeight"   () int))
(define set-target-fps      (foreign-procedure "SetTargetFPS"      (int) void))
(define get-fps             (foreign-procedure "GetFPS"            () int))
(define get-frame-time      (foreign-procedure "GetFrameTime"      () float))
(define get-time            (foreign-procedure "GetTime"           () double))

(define clear-background     (foreign-procedure "ClearBackground"     ((& color)) void))
(define begin-drawing        (foreign-procedure "BeginDrawing"        () void))
(define end-drawing          (foreign-procedure "EndDrawing"          () void))
(define begin-mode-2d        (foreign-procedure "BeginMode2D"         ((& camera2d)) void))
(define end-mode-2d          (foreign-procedure "EndMode2D"           () void))
(define draw-pixel           (foreign-procedure "DrawPixel"           (int int (& color)) void))
(define draw-line            (foreign-procedure "DrawLine"            (int int int int (& color)) void))
(define draw-circle          (foreign-procedure "DrawCircle"          (int int float (& color)) void))
(define draw-rectangle       (foreign-procedure "DrawRectangle"       (int int int int (& color)) void))
(define draw-rectangle-rec   (foreign-procedure "DrawRectangleRec"    ((& rectangle) (& color)) void))
(define draw-rectangle-lines (foreign-procedure "DrawRectangleLines"  (int int int int (& color)) void))
(define draw-fps             (foreign-procedure "DrawFPS"             (int int) void))
(define draw-text            (foreign-procedure "DrawText"            (string int int int (& color)) void))
(define measure-text         (foreign-procedure "MeasureText"         (string int) int))

(define %load-texture-ffi (foreign-procedure "LoadTexture"    (string) (& texture2d)))
(define unload-texture   (foreign-procedure "UnloadTexture"  ((& texture2d)) void))
(define draw-texture     (foreign-procedure "DrawTexture"    ((& texture2d) int int (& color)) void))
(define draw-texture-rec (foreign-procedure "DrawTextureRec" ((& texture2d) (& rectangle) (& vector2) (& color)) void))
(define draw-texture-pro (foreign-procedure "DrawTexturePro" ((& texture2d) (& rectangle) (& rectangle) (& vector2) float (& color)) void))

(define (load-texture path)
  (let ([tex (%ftype-alloc texture2d)])
    (%load-texture-ffi tex path)
    tex))

(define is-key-pressed   (foreign-procedure "IsKeyPressed"   (int) boolean))
(define is-key-down      (foreign-procedure "IsKeyDown"      (int) boolean))
(define is-key-released  (foreign-procedure "IsKeyReleased"  (int) boolean))
(define is-key-up        (foreign-procedure "IsKeyUp"        (int) boolean))
(define set-exit-key     (foreign-procedure "SetExitKey"     (int) void))
(define get-key-pressed  (foreign-procedure "GetKeyPressed"  () int))
(define get-char-pressed (foreign-procedure "GetCharPressed" () int))

(define is-mouse-button-pressed  (foreign-procedure "IsMouseButtonPressed"  (int) boolean))
(define is-mouse-button-down     (foreign-procedure "IsMouseButtonDown"     (int) boolean))
(define is-mouse-button-released (foreign-procedure "IsMouseButtonReleased" (int) boolean))
(define is-mouse-button-up       (foreign-procedure "IsMouseButtonUp"       (int) boolean))
(define get-mouse-x              (foreign-procedure "GetMouseX"             () int))
(define get-mouse-y              (foreign-procedure "GetMouseY"             () int))

(define init-audio-device  (foreign-procedure "InitAudioDevice"  () void))
(define close-audio-device (foreign-procedure "CloseAudioDevice" () void))
(define set-master-volume  (foreign-procedure "SetMasterVolume"  (float) void))
(define %load-sound-ffi     (foreign-procedure "LoadSound"        (string) (& sound)))
(define unload-sound       (foreign-procedure "UnloadSound"      ((& sound)) void))
(define play-sound         (foreign-procedure "PlaySound"        ((& sound)) void))
(define stop-sound         (foreign-procedure "StopSound"        ((& sound)) void))
(define pause-sound        (foreign-procedure "PauseSound"       ((& sound)) void))
(define resume-sound       (foreign-procedure "ResumeSound"      ((& sound)) void))
(define is-sound-playing   (foreign-procedure "IsSoundPlaying"   ((& sound)) boolean))

(define (load-sound path)
  (let ([s (%ftype-alloc sound)])
    (%load-sound-ffi s path)
    s))

;;;; ============================================================
;;;; 5. KEY / MOUSE CONSTANTS
;;;; ============================================================

(define key-space  32) (define key-escape 256) (define key-enter  257)
(define key-tab   258) (define key-backspace 259) (define key-insert 260)
(define key-delete 261) (define key-right 262) (define key-left   263)
(define key-down  264) (define key-up    265)

(define key-f1 290) (define key-f2 291) (define key-f3  292) (define key-f4  293)
(define key-f5 294) (define key-f6 295) (define key-f7  296) (define key-f8  297)
(define key-f9 298) (define key-f10 299) (define key-f11 300) (define key-f12 301)

(define key-left-shift   340) (define key-left-control  341) (define key-left-alt    342)
(define key-right-shift  344) (define key-right-control 345) (define key-right-alt   346)

(define key-zero 48) (define key-one   49) (define key-two   50) (define key-three 51)
(define key-four 52) (define key-five  53) (define key-six   54) (define key-seven 55)
(define key-eight 56) (define key-nine 57)

(define key-a 65) (define key-b 66) (define key-c 67) (define key-d 68) (define key-e 69)
(define key-f 70) (define key-g 71) (define key-h 72) (define key-i 73) (define key-j 74)
(define key-k 75) (define key-l 76) (define key-m 77) (define key-n 78) (define key-o 79)
(define key-p 80) (define key-q 81) (define key-r 82) (define key-s 83) (define key-t 84)
(define key-u 85) (define key-v 86) (define key-w 87) (define key-x 88) (define key-y 89)
(define key-z 90)

(define mouse-button-left 0) (define mouse-button-right 1) (define mouse-button-middle 2)

;;;; ============================================================
;;;; 6. JSON PARSER (minimal, used for %tilemaps)
;;;; ============================================================

(define (%json-parse str)
  (let ((pos 0) (len (string-length str)))

    (define (peek)    (and (< pos len) (string-ref str pos)))
    (define (advance!) (set! pos (+ pos 1)))
    (define (consume! ch)
      (unless (eqv? (peek) ch) (error "%json-parse" "expected" ch "at" pos))
      (advance!))
    (define (skip-ws!)
      (let loop () (let ((c (peek))) (when (and c (char-whitespace? c)) (advance!) (loop)))))

    (define (read-string)
      (consume! #\")
      (let loop ((chars '()))
        (let ((c (peek)))
          (cond
            ((not c)       (error "%json-parse" "unterminated string"))
            ((eqv? c #\")  (advance!) (list->string (reverse chars)))
            ((eqv? c #\\)
             (advance!)
             (let ((esc (peek))) (advance!)
               (loop (cons (case esc
                             ((#\") #\") ((#\\) #\\) ((#\/) #\/)
                             ((#\n) #\newline) ((#\r) #\return) ((#\t) #\tab)
                             (else esc))
                           chars))))
            (else (advance!) (loop (cons c chars)))))))

    (define (read-number)
      (let loop ((chars '()))
        (let ((c (peek)))
          (if (and c (or (char-numeric? c) (memv c '(#\- #\+ #\. #\e #\E))))
              (begin (advance!) (loop (cons c chars)))
              (string->number (list->string (reverse chars)))))))

    (define (read-array)
      (consume! #\[) (skip-ws!)
      (if (eqv? (peek) #\]) (begin (advance!) '())
          (let loop ((items (list (read-value))))
            (skip-ws!)
            (cond
              ((eqv? (peek) #\]) (advance!) (reverse items))
              ((eqv? (peek) #\,) (advance!) (skip-ws!) (loop (cons (read-value) items)))
              (else (error "%json-parse" "expected , or ] in array"))))))

    (define (read-object)
      (consume! #\{) (skip-ws!)
      (if (eqv? (peek) #\}) (begin (advance!) '())
          (let loop ((pairs '()))
            (skip-ws!)
            (let* ((key  (read-string))
                   (_    (begin (skip-ws!) (consume! #\:) (skip-ws!)))
                   (pair (cons key (read-value))))
              (skip-ws!)
              (cond
                ((eqv? (peek) #\}) (advance!) (reverse (cons pair pairs)))
                ((eqv? (peek) #\,) (advance!) (loop (cons pair pairs)))
                (else (error "%json-parse" "expected , or } in object")))))))

    (define (read-literal s val)
      (let loop ((i 0))
        (when (< i (string-length s)) (consume! (string-ref s i)) (loop (+ i 1))))
      val)

    (define (read-value)
      (skip-ws!)
      (let ((c (peek)))
        (cond
          ((eqv? c #\")  (read-string))
          ((eqv? c #\{)  (read-object))
          ((eqv? c #\[)  (read-array))
          ((eqv? c #\t)  (read-literal "true"  #t))
          ((eqv? c #\f)  (read-literal "false" #f))
          ((eqv? c #\n)  (read-literal "null"  'null))
          ((or (char-numeric? c) (eqv? c #\-)) (read-number))
          (else (error "%json-parse" "unexpected character" c "at" pos)))))

    (read-value)))

(define (%json-load path)
  (call-with-input-file path (lambda (port) (%json-parse (get-string-all port)))))

(define (%json-get obj key)
  (let ((pair (assoc key obj))) (if pair (cdr pair) #f)))

(define (%json-null? v) (eq? v 'null))

;;;; ============================================================
;;;; 7. ENTITY-COMPONENT SYSTEM (ECS)
;;;; ============================================================

(define %entities       (make-eq-hashtable))
(define %component-defs (make-eq-hashtable))
(define %pipeline       '())
(define %base-%pipeline  '())
(define %event-queue           '())
(define %event-handlers        '())
(define %global-event-handlers '())
(define %scenes         '())
(define %current-scene  #f)
(define %next-id        0)

(define (%hashtable-for-each ht proc)
  (vector-for-each proc (hashtable-keys ht) (hashtable-values ht)))

(define (%entity-ref id)      (hashtable-ref %entities id #f))
(define (%comp-ref id cname)  (let ((e (%entity-ref id))) (and e (hashtable-ref e cname #f))))
(define (%next-id!)            (set! %next-id (+ %next-id 1)) %next-id)

(define-syntax component
  (syntax-rules ()
    ((_ name (field ...)) (hashtable-set! %component-defs 'name '(field ...)))
    ((_ name)             (hashtable-set! %component-defs 'name '()))))

(define %sprite-field-defaults '((frame . 0) (elapsed . 0.0)))

(define (%make-component comp-name field-vals)
  (let* ((fields   (hashtable-ref %component-defs comp-name
                     (lambda () (error "unknown component" comp-name))))
         (ht       (make-eq-hashtable))
         (defaults (if (eq? comp-name 'sprite) %sprite-field-defaults '()))
         (n-given  (length field-vals))
         (n-fields (length fields))
         (n-req    (- n-fields (length defaults))))
    (unless (or (= n-given n-fields) (= n-given n-req))
      (error "%make-component: wrong number of fields" comp-name
             (string-append "expected " (number->string n-fields)
                            " (or " (number->string n-req) " without defaults)"
                            ", got " (number->string n-given))))
    (for-each (lambda (f)
                (let ((given (assq f field-vals)))
                  (hashtable-set! ht f
                    (if given (cadr given)
                        (let ((def (assq f defaults)))
                          (if def (cdr def) #f))))))
              fields)
    ht))

(define (%make-entity comp-list)
  (let ((id (%next-id!)) (ht (make-eq-hashtable)))
    (for-each (lambda (pair) (hashtable-set! ht (car pair) (cdr pair))) comp-list)
    (hashtable-set! %entities id ht)
    id))

(define (%pair-fields name vals)
  (let ((fields (hashtable-ref %component-defs name '())))
    (map list (list-head fields (length vals)) vals)))

(define (%spawn-entity . comp-specs)
  (%make-entity
    (map (lambda (spec) (cons (car spec) (%make-component (car spec) (cdr spec)))) comp-specs)))

(define-syntax %spawn-acc
  (syntax-rules (from sprite)
    ((_ acc)
     (apply %spawn-entity (reverse acc)))
    ((_ acc (comp from expr) rest ...)
     (%spawn-acc (cons (cons 'comp (list expr)) acc) rest ...))
    ((_ acc (sprite tex val ...) rest ...)
     (%spawn-acc (cons (cons 'sprite (%pair-fields 'sprite (list 'tex val ...))) acc) rest ...))
    ((_ acc (comp val ...) rest ...)
     (%spawn-acc (cons (cons 'comp (%pair-fields 'comp (list val ...))) acc) rest ...))))

(define-syntax spawn
  (lambda (stx)
    (syntax-case stx ()
      ((_ name clause ...)
       (identifier? #'name)
       #'(define name (%spawn-acc (list) clause ...)))
      ((_ clause ...)
       #'(%spawn-acc (list) clause ...)))))

(define (despawn id) (hashtable-delete! %entities id))

(define (%has-component? id cname)
  (let ((e (%entity-ref id))) (and e (hashtable-contains? e cname))))

(define-syntax has-component?
  (syntax-rules () ((_ id comp) (%has-component? id 'comp))))

(define-syntax add-component
  (syntax-rules ()
    ((_ id comp)
     (let ((e (%entity-ref id)))
       (if e (hashtable-set! e 'comp (%make-component 'comp '()))
             (error "add-component: entity not found" id))))
    ((_ id comp (field val) ...)
     (let ((e (%entity-ref id)))
       (if e (hashtable-set! e 'comp (%make-component 'comp (list (list 'field val) ...)))
             (error "add-component: entity not found" id))))))

(define-syntax remove-component
  (syntax-rules ()
    ((_ id comp)
     (let ((e (%entity-ref id))) (when e (hashtable-delete! e 'comp))))))

(define (%comp-get  comp-ht field) (hashtable-ref comp-ht field (lambda () (error "%comp-get: unknown field" field))))
(define (%comp-set! comp-ht field val) (hashtable-set! comp-ht field val))

(define (%field-get id cname field)
  (let ((c (%comp-ref id cname)))
    (if c (%comp-get c field) (error "%field-get: component not found" cname id))))

(define (%field-set! id cname field val)
  (let ((c (%comp-ref id cname)))
    (if c (%comp-set! c field val) (error "%field-set!: component not found" cname id))))

(define-syntax get
  (syntax-rules ()
    ((_ comp field)    (%comp-get  comp     'field))
    ((_ id comp field) (%field-get id 'comp 'field))))

(define-syntax put!
  (syntax-rules ()
    ((_ comp field expr)    (%comp-set!  comp     'field expr))
    ((_ id comp field expr) (%field-set! id 'comp 'field expr))))

(define (query required . rest)
  (let ((excluded (if (null? rest) '() (car rest)))
        (acc '()))
    (%hashtable-for-each %entities
      (lambda (id comp-ht)
        (when (and (for-all    (lambda (n) (hashtable-contains? comp-ht n)) required)
                   (not (exists (lambda (n) (hashtable-contains? comp-ht n)) excluded)))
          (set! acc (cons (cons id (map (lambda (n) (hashtable-ref comp-ht n #f)) required)) acc)))))
    acc))

(define-syntax system
  (lambda (stx)
    (syntax-case stx (: not persistent)
      ((_ name persistent ((var : comp) ...) not (excl ...) body ...)
       (with-syntax ([eid (datum->syntax #'name 'entity-id)])
         #'(set! %base-%pipeline (cons (list 'entity 'name '(comp ...) '(excl ...) (lambda (eid var ...) body ...)) %base-%pipeline))))
      ((_ name persistent ((var : comp) ...) body ...)
       (with-syntax ([eid (datum->syntax #'name 'entity-id)])
         #'(set! %base-%pipeline (cons (list 'entity 'name '(comp ...) '() (lambda (eid var ...) body ...)) %base-%pipeline))))
      ((_ name ((var : comp) ...) not (excl ...) body ...)
       (with-syntax ([eid (datum->syntax #'name 'entity-id)])
         #'(set! %pipeline (cons (list 'entity 'name '(comp ...) '(excl ...) (lambda (eid var ...) body ...)) %pipeline))))
      ((_ name ((var : comp) ...) body ...)
       (with-syntax ([eid (datum->syntax #'name 'entity-id)])
         #'(set! %pipeline (cons (list 'entity 'name '(comp ...) '() (lambda (eid var ...) body ...)) %pipeline)))))))

(define-syntax global-system
  (syntax-rules ()
    ((_ name body ...)
     (set! %pipeline (cons (list 'global 'name (lambda () body ...)) %pipeline)))))

(define-syntax emit
  (syntax-rules ()
    ((_ name (field val) ...)
     (set! %event-queue (append %event-queue (list (list 'name (list 'field val) ...)))))))

(define-syntax on
  (syntax-rules ()
    ((_ name (field ...) body ...)
     (set! %event-handlers (cons (cons 'name (lambda (field ...) body ...)) %event-handlers)))))

(define-syntax on-global
  (syntax-rules ()
    ((_ name (field ...) body ...)
     (set! %global-event-handlers (cons (cons 'name (lambda (field ...) body ...)) %global-event-handlers)))))

(define (%dispatch)
  (let ((current-queue %event-queue))
    (set! %event-queue '())
    (for-each
      (lambda (ev)
        (let ((ev-name (car ev)) (args (map cadr (cdr ev))))
          (for-each
            (lambda (h) (when (eq? (car h) ev-name) (apply (cdr h) args)))
            (append (reverse %event-handlers) (reverse %global-event-handlers)))))
      current-queue)))

(define-syntax scene
  (lambda (stx)
    (syntax-case stx (on-enter on-exit)
      ((_ name (on-enter enter-body ...) (on-exit exit-body ...))
       #'(set! %scenes (cons (list 'name (lambda () enter-body ...) (lambda () exit-body ...)) %scenes)))
      ((_ name (on-enter enter-body ...))
       #'(set! %scenes (cons (list 'name (lambda () enter-body ...) (lambda () #f)) %scenes))))))

(define (%go-to name)
  (when %current-scene
    (let ((cur (assq %current-scene %scenes))) (when cur ((caddr cur)))))
  (set! %pipeline       %base-%pipeline)
  (set! %event-handlers '())
  (set! %event-queue    '())
  (let ((to-remove '()))
    (%hashtable-for-each %entities
      (lambda (id comp-ht)
        (unless (hashtable-contains? comp-ht 'persistent)
          (set! to-remove (cons id to-remove)))))
    (for-each despawn to-remove))
  (set! %current-scene name)
  (let ((next (assq name %scenes)))
    (if next ((cadr next)) (error "go-to: scene not found" name))))

(define-syntax go-to (syntax-rules () ((_ name) (%go-to 'name))))

(define (%run-systems)
  (for-each
    (lambda (entry)
      (case (car entry)
        ((entity)
         (let ((proc (list-ref entry 4)))
           (for-each (lambda (e) (apply proc (car e) (cdr e)))
                     (query (list-ref entry 2) (list-ref entry 3)))))
        ((global)
         ((list-ref entry 2)))))
    (reverse %pipeline)))

(define (%run-frame!) (%run-systems) (%dispatch))

;;;; ============================================================
;;;; 8. ASSET CACHE
;;;; ============================================================

(define %assets (make-eq-hashtable))

(define (load-asset! name path . rest)
  (unless (hashtable-contains? %assets name)
    (let* ((loader   (if (null? rest) load-texture (car rest)))
           (unloader (if (or (null? rest) (null? (cdr rest))) unload-texture (cadr rest)))
           (value    (loader path)))
      (hashtable-set! %assets name (cons value unloader)))))

(define-syntax load-asset
  (syntax-rules ()
    ((_ name path)             (load-asset! 'name path))
    ((_ name path loader)      (load-asset! 'name path loader))
    ((_ name path loader unl)  (load-asset! 'name path loader unl))))

(define-syntax get-asset
  (syntax-rules ()
    ((_ name)
     (let ((entry (hashtable-ref %assets 'name (lambda () (error "get-asset: not loaded" 'name)))))
       (car entry)))))

(define (%asset-ref name)
  (car (hashtable-ref %assets name (lambda () (error "%asset-ref: not loaded" name)))))

(define-syntax unload-asset
  (syntax-rules ()
    ((_ name)
     (let ((entry (hashtable-ref %assets 'name #f)))
       (when entry ((cdr entry) (car entry)) (hashtable-delete! %assets 'name))))))

(define (%unload-all-assets!)
  (for-each
    (lambda (k)
      (let ((entry (hashtable-ref %assets k #f)))
        (when entry ((cdr entry) (car entry)) (hashtable-delete! %assets k))))
    (vector->list (hashtable-keys %assets))))

(define-syntax %unload-assets-except!
  (syntax-rules ()
    ((_ keep ...)
     (let ((to-remove '()))
       (%hashtable-for-each %assets
         (lambda (name entry)
           (unless (memq name '(keep ...))
             (set! to-remove (cons (cons name entry) to-remove)))))
       (for-each (lambda (pair)
                   ((cddr pair) (cadr pair))
                   (hashtable-delete! %assets (car pair)))
                 to-remove)))))

;;;; ============================================================
;;;; 9. CAMERA HELPERS
;;;; ============================================================

(define %current-camera #f)
(define (set-camera!  cam) (set! %current-camera cam))
(define (clear-camera!)    (set! %current-camera #f))

(define make-camera
  (case-lambda
    ((tx ty)
     (make-camera2d tx ty
                    (/ (%->f (get-screen-width))  2.0)
                    (/ (%->f (get-screen-height)) 2.0)
                    1.0))
    ((tx ty ox oy)        (make-camera2d tx ty ox oy 1.0))
    ((tx ty ox oy zoom)   (make-camera2d tx ty ox oy zoom))))

(define (camera-follow! cam x y . rest)
  (let ((fx (%->f x)) (fy (%->f y)))
    (if (null? rest)
        (begin (ftype-set! camera2d (target-x) cam fx)
               (ftype-set! camera2d (target-y) cam fy))
        (let* ((speed (car rest))
               (tx    (ftype-ref camera2d (target-x) cam))
               (ty    (ftype-ref camera2d (target-y) cam)))
          (ftype-set! camera2d (target-x) cam (+ tx (* (- fx tx) speed)))
          (ftype-set! camera2d (target-y) cam (+ ty (* (- fy ty) speed)))))))

(define (camera-zoom-set! cam z) (ftype-set! camera2d (zoom) cam (%->f z)))
(define (camera-zoom      cam)   (ftype-ref  camera2d (zoom) cam))

(define (camera-clamp! cam world-w world-h)
  (let* ((zoom  (ftype-ref camera2d (zoom)     cam))
         (hw    (/ (ftype-ref camera2d (offset-x) cam) zoom))
         (hh    (/ (ftype-ref camera2d (offset-y) cam) zoom))
         (tx    (ftype-ref camera2d (target-x) cam))
         (ty    (ftype-ref camera2d (target-y) cam))
         (min-x (%->f hw)) (max-x (%->f (- world-w hw)))
         (min-y (%->f hh)) (max-y (%->f (- world-h hh)))
         (cx    (if (> min-x max-x) (/ (%->f world-w) 2.0) (max min-x (min tx max-x))))
         (cy    (if (> min-y max-y) (/ (%->f world-h) 2.0) (max min-y (min ty max-y)))))
    (ftype-set! camera2d (target-x) cam cx)
    (ftype-set! camera2d (target-y) cam cy)))

(define (%run-sprite-renderer!)
  (for-each
    (lambda (e)
      (let* ((spr    (cadr e)) (pos (caddr e))
             (tex    (%asset-ref (get spr texture)))
             (fw     (get spr frame-w)) (fh (get spr frame-h))
             (frame  (get spr frame))
             (sx     (get spr scale-x)) (sy (get spr scale-y))
             (src    (make-rect (%->f (* frame fw)) (%->f (* (get spr row) fh))
                                (%->f (* sx fw))    (%->f (* sy fh))))
             (dest   (make-rect (%->f (get pos x))  (%->f (get pos y))
                                (%->f (* (abs sx) fw)) (%->f (* (abs sy) fh))))
             (origin (make-vec2 0.0 0.0)))
        (draw-texture-pro tex src dest origin 0.0 white)))
    (query '(sprite position))))

(define-syntax with-camera
  (syntax-rules (render-sprites)
    ((_ cam (render-sprites) rest ...) (with-camera cam (%run-sprite-renderer!) rest ...))
    ((_ cam first rest ...)     (%with-camera/acc cam (first) rest ...))
    ((_ cam)
     (global-system render-world (begin-mode-2d cam) (end-mode-2d)))))

(define-syntax %with-camera/acc
  (syntax-rules (render-sprites)
    ((_ cam (accumulated ...))
     (global-system render-world (begin-mode-2d cam) accumulated ... (end-mode-2d)))
    ((_ cam (accumulated ...) (render-sprites) rest ...)
     (%with-camera/acc cam (accumulated ... (%run-sprite-renderer!)) rest ...))
    ((_ cam (accumulated ...) next rest ...)
     (%with-camera/acc cam (accumulated ... next) rest ...))))

;;;; ============================================================
;;;; 10. INPUT (high-level)
;;;; ============================================================

(define %key-state               (make-eqv-hashtable))
(define %keys-pressed-this-frame  '())
(define %keys-released-this-frame '())

(define (%poll-input!)
  (set! %keys-pressed-this-frame  '())
  (set! %keys-released-this-frame '())
  (for-each
    (lambda (k)
      (when (is-key-released k)
        (hashtable-delete! %key-state k)
        (set! %keys-released-this-frame (cons k %keys-released-this-frame))))
    (vector->list (hashtable-keys %key-state)))
  (let loop ()
    (let ((k (get-key-pressed)))
      (when (> k 0)
        (unless (hashtable-ref %key-state k #f)
          (hashtable-set! %key-state k #t)
          (set! %keys-pressed-this-frame (cons k %keys-pressed-this-frame)))
        (loop)))))

(define (key-down?     k) (hashtable-ref %key-state k #f))
(define (key-pressed?  k) (and (memv k %keys-pressed-this-frame)  #t))
(define (key-released? k) (and (memv k %keys-released-this-frame) #t))

;;;; ============================================================
;;;; 11. SPRITE SYSTEM
;;;; ============================================================

(component sprite (texture frame-w frame-h row frames speed scale-x scale-y frame elapsed))

(define dt 0.0)

(define-syntax sprite-texture!
  (syntax-rules () ((_ spr-comp name) (%comp-set! spr-comp 'texture 'name))))

(define (%install-sprite-system!)
  (system sprite-system persistent
    ((spr : sprite))
    (let* ((elapsed     (get spr elapsed))
           (speed       (get spr speed))
           (new-elapsed (+ elapsed dt)))
      (if (>= new-elapsed (/ 1.0 speed))
          (begin (put! spr frame (modulo (+ (get spr frame) 1) (get spr frames)))
                 (put! spr elapsed 0.0))
          (put! spr elapsed new-elapsed)))))

;;;; ============================================================
;;;; 12. TEXT INPUT
;;;; ============================================================

(define (text-input)
  (let loop ((chars '()))
    (let ((c (get-char-pressed)))
      (if (= c 0) (list->string (reverse chars))
          (loop (cons (integer->char c) chars))))))

;;;; ============================================================
;;;; 13. DRAWING UTILITIES
;;;; ============================================================

(define (draw-text-centered text cx cy size color)
  (let* ((w (measure-text text size))
         (x (- cx (quotient w 2)))
         (y (- cy (quotient size 2))))
    (draw-text text x y size color)))

;;;; ============================================================
;;;; 14. GAME LOOP
;;;; ============================================================

(define (game-loop title width height target-fps . rest)
  (let ((init (if (null? rest) (lambda () #f) (car rest))))
    (init-window width height title)
    (init-audio-device)
    (set-target-fps target-fps)
    (%install-sprite-system!)
    (init)
    (dynamic-wind
      (lambda () #f)
      (lambda ()
        (let loop ()
          (unless (window-should-close)
            (set! dt (get-frame-time))
            (%poll-input!)
            (begin-drawing)
            (clear-background raywhite)
            (%run-frame!)
            (end-drawing)
            (loop))))
      (lambda ()
        (close-audio-device)
        (close-window)))))

;;;; ============================================================
;;;; 15. TILEMAP SUPPORT
;;;; ============================================================

(define %tilemaps (make-eq-hashtable))

(define (%resolve-path map-path rel-path)
  (let* ((dir (let loop ((i (- (string-length map-path) 1)))
                (cond
                  ((< i 0) "")
                  ((or (eqv? (string-ref map-path i) #\/)
                       (eqv? (string-ref map-path i) #\\))
                   (substring map-path 0 (+ i 1)))
                  (else (loop (- i 1))))))
         (rel (if (and (> (string-length rel-path) 2)
                       (string=? (substring rel-path 0 2) "./"))
                  (substring rel-path 2 (string-length rel-path))
                  rel-path)))
    (string-append dir rel)))

(define (%parse-tilesets tilesets-json map-path tw th)
  (map (lambda (ts)
         (let* ((firstgid (%json-get ts "firstgid"))
                (img-path (%resolve-path map-path (%json-get ts "image")))
                (img-tw   (or (%json-get ts "tilewidth")  tw))
                (img-th   (or (%json-get ts "tileheight") th))
                (src-cols (quotient (%json-get ts "imagewidth") img-tw))
                (tex-name (string->symbol img-path)))
           (load-asset! tex-name img-path)
           (list firstgid tex-name img-tw img-th src-cols)))
       tilesets-json))

(define (%parse-layers layers-json)
  (let loop ((ls layers-json) (tile-layers '()) (obj-layers '()))
    (if (null? ls)
        (list (reverse tile-layers) (reverse obj-layers))
        (let* ((l       (car ls))
               (type    (%json-get l "type"))
               (lname   (%json-get l "name"))
               (visible (not (eq? (%json-get l "visible") #f))))
          (cond
            ((string=? type "tilelayer")
             (loop (cdr ls) (cons (list lname (%json-get l "data") visible) tile-layers) obj-layers))
            ((string=? type "objectgroup")
             (loop (cdr ls) tile-layers (cons (list lname (%json-get l "objects") visible) obj-layers)))
            (else
             (loop (cdr ls) tile-layers obj-layers)))))))

(define (%tile-source tilesets gid)
  (let loop ((ts (reverse tilesets)))
    (and (not (null? ts))
         (let* ((t        (car ts))
                (firstgid (car t))
                (local-id (- gid firstgid)))
           (if (>= local-id 0)
               (let ((tw (list-ref t 2)) (th (list-ref t 3)) (cols (list-ref t 4)))
                 (list (cadr t) (* (modulo local-id cols) tw) (* (quotient local-id cols) th) tw th))
               (loop (cdr ts)))))))

(define-syntax load-tilemap
  (syntax-rules ()
    ((_ name path)
     (let* ((json     (%json-load path))
            (tw       (%json-get json "tilewidth"))
            (th       (%json-get json "tileheight"))
            (mw       (%json-get json "width"))
            (mh       (%json-get json "height"))
            (tilesets (%parse-tilesets (%json-get json "tilesets") path tw th))
            (layers   (%parse-layers   (%json-get json "layers")))
            (m        (list (cons 'tile-width  tw) (cons 'tile-height th)
                            (cons 'map-width   mw) (cons 'map-height  mh)
                            (cons 'tilesets    tilesets)
                            (cons 'tile-layers (car layers))
                            (cons 'obj-layers  (cadr layers)))))
       (hashtable-set! %tilemaps 'name m)))))

(define-syntax render-tilemap
  (syntax-rules ()
    ((_ name)     (render-tilemap name #f))
    ((_ name cam)
     (let* ((m      (hashtable-ref %tilemaps 'name (lambda () (error "tilemap not loaded" 'name))))
            (tw     (cdr (assq 'tile-width  m)))
            (th     (cdr (assq 'tile-height m)))
            (mw     (cdr (assq 'map-width   m)))
            (tsets  (cdr (assq 'tilesets    m)))
            (layers (cdr (assq 'tile-layers m))))
       (for-each
         (lambda (layer)
           (when (caddr layer)
             (let loop ((tiles (cadr layer)) (i 0))
               (unless (null? tiles)
                 (let ((gid (car tiles)))
                   (when (> gid 0)
                     (let* ((src  (or (%tile-source tsets gid)
                                      (error "render-tilemap: no tileset for gid" gid)))
                            (tex  (%asset-ref (car src)))
                            (srec (make-rect (cadr src) (caddr src) (list-ref src 3) (list-ref src 4)))
                            (dpos (make-vec2 (%->f (* (modulo   i mw) tw))
                                             (%->f (* (quotient i mw) th)))))
                       (draw-texture-rec tex srec dpos white))))
                 (loop (cdr tiles) (+ i 1))))))
         layers)))))

(define-syntax tilemap-objects
  (syntax-rules ()
    ((_ name)
     (let* ((m (hashtable-ref %tilemaps 'name (lambda () (error "tilemap not loaded" 'name)))))
       (apply append (map cadr (cdr (assq 'obj-layers m))))))
    ((_ name layer)
     (let* ((m  (hashtable-ref %tilemaps 'name (lambda () (error "tilemap not loaded" 'name))))
            (l  (assoc layer (cdr (assq 'obj-layers m)))))
       (if l (cadr l) '())))))

(define (obj-x      obj) (%json-get obj "x"))
(define (obj-y      obj) (%json-get obj "y"))
(define (obj-width  obj) (%json-get obj "width"))
(define (obj-height obj) (%json-get obj "height"))
(define (obj-name   obj) (%json-get obj "name"))
(define (obj-type   obj) (%json-get obj "type"))
(define (obj-id     obj) (%json-get obj "id"))

(define-syntax tilemap-width
  (syntax-rules ()
    ((_ name)
     (let ((m (hashtable-ref %tilemaps 'name (lambda () (error "tilemap not loaded" 'name)))))
       (* (cdr (assq 'map-width m)) (cdr (assq 'tile-width m)))))))

(define-syntax tilemap-height
  (syntax-rules ()
    ((_ name)
     (let ((m (hashtable-ref %tilemaps 'name (lambda () (error "tilemap not loaded" 'name)))))
       (* (cdr (assq 'map-height m)) (cdr (assq 'tile-height m)))))))

;;;; ============================================================
;;;; 16. BUILT-IN COMPONENTS
;;;; ============================================================

(component position (x y))

;;; End of file

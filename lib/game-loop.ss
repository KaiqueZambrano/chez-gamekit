;;; game-loop.ss

;;;; ============================================================
;;;; DELTA TIME
;;;; ============================================================

(define dt 0.0)

;;;; ============================================================
;;;; TEXT INPUT
;;;; ============================================================

(define text-input-buffer "")

(define (flush-text-input!)
  (let loop ((c (get-char-pressed)))
    (when (> c 0)
      (set! text-input-buffer
            (string-append text-input-buffer
                           (string (integer->char c))))
      (loop (get-char-pressed)))))

(define (text-input)
  text-input-buffer)

;;;; ============================================================
;;;; GAME LOOP
;;;; ============================================================

(define (game-loop title width height target-fps . rest)
  (let ((init (if (null? rest) (lambda () #f) (car rest))))
    (init-window width height title)
    (init-audio-device)
    (set-target-fps target-fps)
    (init)
    (dynamic-wind
      (lambda () #f)
      (lambda ()
        (let loop ()
          (unless (window-should-close)
            (set! dt (get-frame-time))
            (flush-text-input!)
            (begin-drawing)
            (clear-background raywhite)
            (run)
            (end-drawing)
            (loop))))
      (lambda ()
        (close-audio-device)
        (close-window)))))

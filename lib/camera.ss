;;; camera.ss

;;;; ============================================================
;;;; GLOBAL CAMERA
;;;; ============================================================

(define current-camera #f)

(define (set-camera! cam)
  (set! current-camera cam))

(define (clear-camera!)
  (set! current-camera #f))

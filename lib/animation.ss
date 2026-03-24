;;; animation.ss

;;;; ============================================================
;;;; COMPONENT
;;;; ============================================================

(component animation (texture frame-w frame-h frames speed frame elapsed))

;;;; ============================================================
;;;; FRAME UPDATE
;;;; ============================================================

(define (make-animation-system)
  (system animation-system
    ((anim : animation))
    (let* ((elapsed     (get anim elapsed))
           (speed       (get anim speed))
           (frames      (get anim frames))
           (frame       (get anim frame))
           (new-elapsed (+ elapsed dt)))
      (if (>= new-elapsed (/ 1.0 speed))
          (begin
            (put! anim frame   (modulo (+ frame 1) frames))
            (put! anim elapsed 0.0))
          (put! anim elapsed new-elapsed)))))

;;;; ============================================================
;;;; RENDERING
;;;; ============================================================

(define (make-render-animation-system)
  (system render-animation-system
    ((anim : animation) (pos : position))
    (let* ((tex   (asset-ref (get anim texture)))
           (fw    (get anim frame-w))
           (fh    (get anim frame-h))
           (frame (get anim frame))
           (src   (make-rect (* frame fw) 0 fw fh))
           (dest  (make-vec2 (exact->inexact (get pos x))
                             (exact->inexact (get pos y)))))
      (draw-texture-rec tex src dest white))))

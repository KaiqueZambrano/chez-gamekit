;;; assets.ss

;;;; ============================================================
;;;; ASSET MANAGER
;;;; ============================================================

(define assets (make-eq-hashtable))

(define (load-asset! name path . rest)
  (unless (hashtable-contains? assets name)
    (let ((loader (if (null? rest) load-texture (car rest))))
      (hashtable-set! assets name (loader path)))))

(define-syntax load-asset
  (syntax-rules ()
    ((_ name path)
     (load-asset! 'name path))
    ((_ name path loader)
     (load-asset! 'name path loader))))

(define-syntax get-asset
  (syntax-rules ()
    ((_ name)
     (hashtable-ref assets 'name
       (lambda () (error "asset not loaded" 'name))))))

(define (asset-ref name)
  (hashtable-ref assets name
    (lambda () (error "asset not loaded" name))))

(define-syntax unload-asset
  (syntax-rules ()
    ((_ name)
     (hashtable-delete! assets 'name))))

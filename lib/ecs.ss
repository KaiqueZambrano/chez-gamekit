;;; ecs.ss

;;;; ============================================================
;;;; ECS CORE
;;;; ============================================================

(define entities '())
(define components '())
(define systems '())

(define next-id 0)

(define (new-id)
  (set! next-id (+ next-id 1))
  next-id)

;;;; ============================================================
;;;; UTIL
;;;; ============================================================

(define (filter pred lst)
  (let loop ((lst lst) (out '()))
    (cond
      ((null? lst) (reverse out))
      ((pred (car lst))
       (loop (cdr lst) (cons (car lst) out)))
      (else
       (loop (cdr lst) out)))))

;;;; ============================================================
;;;; COMPONENTS
;;;; ============================================================

(define-syntax define-component
  (syntax-rules ()
    ((_ name field ...)
     (set! components
           (cons
             (list 'name
                   (list 'field #f) ...)
             components)))))

(define (make-component comp-name field-vals)
  (let ((template (assoc comp-name components)))
    (if (not template)
        (error "Component not found" comp-name)
        (cons
          comp-name
          (map
            (lambda (val pair)
              (list (car pair) val))
            field-vals
            (cdr template))))))

;;;; ============================================================
;;;; ENTITIES
;;;; ============================================================

(define-syntax spawn
  (syntax-rules ()
    ((_ (comp field ...) ...)
     (let ((id (new-id)))
       (set! entities
             (cons
               (cons id
                     (list
                       (make-component 'comp '(field ...))
                       ...))
               entities))
       id))))

(define (despawn entity-id)
  (set! entities
        (filter
          (lambda (e)
            (not (= (car e) entity-id)))
          entities)))

;;;; ============================================================
;;;; COMPONENT ACCESS
;;;; ============================================================

(define (get-field entity-id comp-name field-name)
  (let* ((entity (assoc entity-id entities))
         (comp   (assoc comp-name (cdr entity)))
         (field  (assoc field-name (cdr comp))))
    (cadr field)))

(define (set-field! entity-id comp-name field-name value)
  (let* ((entity (assoc entity-id entities))
         (comp   (assoc comp-name (cdr entity)))
         (field  (assoc field-name (cdr comp))))
    (set-car! (cdr field) value)))

(define (add-component entity-id comp-name values)
  (let* ((entity   (assoc entity-id entities))
         (template (assoc comp-name components))
         (new-comp
           (cons
             comp-name
             (map
               (lambda (pair val)
                 (list (car pair) val))
               (cdr template)
               values))))
    (set-cdr! entity
              (cons new-comp (cdr entity)))))

(define (remove-component entity-id comp-name)
  (let ((entity (assoc entity-id entities)))
    (set-cdr!
      entity
      (filter
        (lambda (c)
          (not (eq? (car c) comp-name)))
        (cdr entity)))))

;;;; ============================================================
;;;; COMPONENT HELPERS
;;;; ============================================================

(define (comp-get comp field)
  (cadr (assoc field (cdr comp))))

(define (comp-set! comp field value)
  (set-car! (cdr (assoc field (cdr comp))) value))

;;;; ============================================================
;;;; QUERY
;;;; ============================================================

(define (query comp-names . rest)
  (let ((excluded (if (null? rest) '() (car rest))))

    (define (has-all? comps names)
      (null? (filter (lambda (x) (not x))
                     (map (lambda (n) (assoc n comps)) names))))

    (define (has-none? comps names)
      (null? (filter (lambda (x) x)
                     (map (lambda (n) (assoc n comps)) names))))

    (let loop ((es entities) (out '()))
      (if (null? es)
          (reverse out)
          (let* ((e     (car es))
                 (id    (car e))
                 (comps (cdr e)))
            (if (and (has-all?  comps comp-names)
                     (has-none? comps excluded))
                (loop (cdr es)
                      (cons (cons id
                                  (map (lambda (n) (assoc n comps))
                                       comp-names))
                            out))
                (loop (cdr es) out)))))))

;;;; ============================================================
;;;; SYSTEMS
;;;; ============================================================

(define-syntax define-system
  (syntax-rules (not)
    ((_ name (comp ...) not (excl ...) (id comp-arg ...) body ...)
     (set! systems
           (append systems
             (list (list 'name
                         '(comp ...)
                         '(excl ...)
                         (lambda (id comp-arg ...) body ...))))))
    ((_ name (comp ...) (id comp-arg ...) body ...)
     (set! systems
           (append systems
             (list (list 'name
                         '(comp ...)
                         '()
                         (lambda (id comp-arg ...) body ...))))))))

(define (run-systems)
  (for-each
    (lambda (sys)
      (let ((comp-names (cadr sys))
            (excluded   (caddr sys))
            (proc       (cadddr sys)))
        (for-each
          (lambda (entity)
            (apply proc
                   (car entity)
                   (cdr entity)))
          (query comp-names excluded))))
    systems))

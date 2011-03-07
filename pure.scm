#lang scheme

(require "curses.scm")
(require mzlib/math)
(require scheme/list)

(provide init-state state->cells state->block block->position process
         board-height board-width)

(define board-height 20)
(define board-width 9)

;;; lookup-object returns a function
(define (lookup-object key)
  (lambda (object)
    (cdr (assoc key object)) ))

;;; composition
(define (compose f g)
  (lambda (x)
    (f (g x)) ))

;;; build-state
(define (build-state cells block)
  (list (cons 'cells cells)
        (cons 'block block) ))

(define state->cells (lookup-object 'cells))
(define state->block (lookup-object 'block))
(define width-range  (build-list board-width values))
(define height-range (build-list board-height values))

;;; init-state
(define (init-state t)
  (build-state '((8 . 1))
               (init-block t) ))

;;; build-block
(define (build-block block-position block-locals block-kind)
  (list (cons 'block-position block-position)
        (cons 'block-locals block-locals)
        (cons 'block-kind block-kind)  ))

(define block->position (lookup-object 'block-position))
(define block->locals (lookup-object 'block-locals))
(define block->kind (lookup-object 'block-kind))

;;; state->block-pos
(define state->block-pos  (compose block->position state->block))

;;; integer->kind
(define (integer->kind t)
  (let ([x (modulo t 7)])
    (cond
      [(equal? x 0) 'Tee]
      [(equal? x 1) 'Bar]
      [(equal? x 2) 'Box]
      [(equal? x 3) 'El]
      [(equal? x 4) 'Jay]
      [(equal? x 5) 'Es]
      [else 'Zee] 
    )))

;;; kind->cells
(define (kind->cells k)
  (cond
    [(equal? k 'Tee) '((0.0 . 0.0) (-1.0 . 0.0) (1.0 . 0.0) (0.0 . 1.0))]
    [(equal? k 'Bar) '((0.0 . -1.5) (0.0 . -0.5) (0.0 . 0.5) (0.0 . 1.5))]
    [(equal? k 'Box) '((-0.5 . 0.5) (0.5 . 0.5) (-0.5 . -0.5) (0.5 . -0.5))]
    [(equal? k 'El) '((0.0 . 0.0) (0.0 . 1.0) (0.0 . -1.0) (1.0 . -1.0))]
    [(equal? k 'Jay) '((0.0 . 0.0) (0.0 . 1.0) (0.0 . -1.0) (-1.0 . -1.0))]
    [(equal? k 'Es) '((-0.5 . 0.0) (0.5 . 0.0) (-0.5 . 1.0) (0.5 . -1.0))]
    [(equal? k 'Zee) '((-0.5 . 0.0) (0.5 . 0.0) (-0.5 . -1.0) (0.5 . 1.0))]
    ))

;;; init-block
(define (init-block t)
  (let ([kind (integer->kind t)])
    (build-block '(5 . 18)
                 (kind->cells kind)
                 kind  )))

;;; block->cells
(define (block->cells block)
  (let ([block-position (block->position block)])
        (map (lambda (local)
               (cons (inexact->exact (floor (+ (car block-position) (car local))))
                     (inexact->exact (floor (+ (cdr block-position) (cdr local)))) ))
             (block->locals block)) ))

;;; load
(define (load block cells)
  (append cells (block->cells block) ))

;;; in-bound?
(define (in-bound? new-block state)
  (andmap (lambda (x)
            (and (>= (car x) 0)
                 (>= (cdr x) 0)
                 (< (car x) board-width)
                 (< (cdr x) board-height))); lambda 
          (block->cells new-block) ))

;;; collides?
(define (collides? new-block cells)
  (ormap (lambda (x)
           (member x cells))
         (block->cells new-block) ))

;;; maybe-load
(define (maybe-load new-block state)
  (cond
      [(not (in-bound? new-block state)) '()]
      [(collides? new-block (state->cells state)) '()]
      [else (list (build-state (load new-block (state->cells state))
                         new-block))]  
    ))

;;; maybe-reload
(define (maybe-reload new-block state)
  (let ([unloaded (unload (state->block state) (state->cells state))])
    (maybe-load new-block
                (build-state unloaded (state->block state))) ))

;;; unload
(define (unload block cells)
  (filter (lambda (x) (not (member x (block->cells block)))) 
          cells))

;;; returns a block transition function
(define (move-by delta)
  (lambda (b)
    (let ([new-block-position (cons (+ (car (block->position b)) (car delta))
            (+ (cdr (block->position b)) (cdr delta)))])
      (build-block new-block-position
                   (block->locals b)
                   (block->kind b) ))))

(define move-left  (move-by '(-1 . 0)))
(define move-right (move-by '(1 . 0)))
(define move-down  (move-by '(0 . -1)))

;;; rotate-pair
(define (rotate-pair x theta)
  (let ([c (cos theta)]
        [s (sin theta)])
    (cons (round-to-half (- (* c (car x)) (* s (cdr x)))) 
          (round-to-half (- (* s (car x)) (* c (cdr x))))) ))

;;; round-to-half
(define (round-to-half x)
  (* (round (* 2 x)) 0.5))

;;; returns a block transition function
(define (rotate-by theta)
  (lambda (b)
    (let ([new-block-locals (map (lambda (x) (rotate-pair x theta))
                              (block->locals b))])
      (build-block (block->position b)
                   new-block-locals
                   (block->kind b) ))))

(define clockwise (rotate-by (- 0 (/ pi 2.0)) ))

;;; converts a block transition to a state transition function
(define (blockf->maybe-statef f)
  (lambda (state)
    (let ([new-block (f (state->block state))])
      (maybe-reload new-block state) )))

;;; converts a block transition to a state transition function
(define (blockf->statef f)
  (lambda (state)
    (let ([reloaded ((blockf->maybe-statef f) state)])
      (if (equal? reloaded '())
          state
          (car reloaded)) )))

;;; load-new-block
(define (load-new-block state t)
  (let ([retval (maybe-load (init-block t) state)])
       (if (equal? retval '())
        state
        (car retval) )))

;;; filled?
(define (filled? row cells)
  (andmap (lambda (x)
            (member (cons x row) cells))
            width-range))

;;; remove-if-filled
(define (remove-if-filled row cells)
  (if (filled? row cells)
    (let* ([lower (filter (lambda (x) (< (cdr x) row)) cells)]
           [higher (filter (lambda (x) (> (cdr x) row)) cells)]
           [higher-lowered (map (lambda (x) (cons (car x) (- (cdr x) 1))) higher)])  
          (append lower higher-lowered) ); let*
    cells
  ))

;;; remove-filled
(define (remove-filled state)
  (let ([new-cells (foldr remove-if-filled (state->cells state) height-range)])
       (build-state new-cells (state->block state)) ))

;;; tick
(define (tick state t)
  (let ([retval ((blockf->maybe-statef move-down) state)])
    (if (equal? retval '())
        (load-new-block (remove-filled state) t)
        (car retval) )))

;;; given a state, a keycode and time t, it returns a new state
(define (process state keycode t)
  (cond
    [(equal? keycode (char->integer #\space)) state]
    [(equal? keycode cur-key-left)   ((blockf->statef move-left) state)]
    [(equal? keycode cur-key-right)  ((blockf->statef move-right) state)]
    [(equal? keycode cur-key-up)     ((blockf->statef clockwise) state)]
    [(equal? keycode cur-key-down)  (tick state t)]
    [(equal? 0 (modulo t 10)) (tick state t)]
    [else state]) )

; (unload (init-block) (load (init-block) '()))
; (process (init-state) cur-key-up 0)
;(state->cells (process (init-state) cur-key-up 0))
; (remove-filled (init-state))
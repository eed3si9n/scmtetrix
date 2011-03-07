#lang scheme

(require "curses.rkt")
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

;;; init-state
(define (init-state)
  (build-state '((8 . 1))
               (init-block) ))

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

;;; init-block
(define (init-block)
  (build-block '(5 . 18)
               '((0.0 . 0.0) (-1.0 . 0.0) (1.0 . 0.0) (0.0 . 1.0))
               'Tee  ))

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
(define (load-new-block state)
  (let ([retval (maybe-load (init-block) state)])
       (if (equal? retval '())
        state
        (car retval) )))

;;; tick
(define (tick state)
  (let ([retval ((blockf->maybe-statef move-down) state)])
    (if (equal? retval '())
        (load-new-block state)
        (car retval) )))

;;; given a state, a keycode and time t, it returns a new state
(define (process state keycode t)
  (cond
    [(equal? keycode (char->integer #\space)) state]
    [(equal? keycode cur-key-left)   ((blockf->statef move-left) state)]
    [(equal? keycode cur-key-right)  ((blockf->statef move-right) state)]
    [(equal? keycode cur-key-up)    state]
    [(equal? keycode cur-key-down)  (tick state)]
    [else state]) )

; (unload (init-block) (load (init-block) '()))
; (state->cells (process (init-state) cur-key-left 0))

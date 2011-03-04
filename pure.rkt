#lang scheme
(require "curses.rkt")

(provide init-state state->cells state->block-pos process)

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
  (build-state '((6 . 6))
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
  (build-block '(6 . 1)
               '((0.0 . 0.0) (-1.0 . 0.0) (1.0 . 0.0) (0.0 . 1.0))
               'Tee  ))

;;; returns a block transition function
(define (move-by delta)
  (lambda (b)
    (let ([block-position (cons (+ (car (block->position b)) (car delta))
            (+ (cdr (block->position b)) (cdr delta)))])
      (build-block block-position
                   (block->locals b)
                   (block->kind b) ))))

(define move-left  (move-by '(-1 . 0)))
(define move-right (move-by '(1 . 0)))

;;; converts a block transition to a state transition function
(define (blockf->statef f)
  (lambda (state)
    (build-state (state->cells state)
                 (f (state->block state)) )))

;;; given a state, a keycode and time t, it returns a new state
(define (process state keycode t)
  (cond
    [(eqv? keycode (char->integer #\space)) state]
    [(eqv? keycode cur-key-left)   ((blockf->statef move-left) state)]
    [(eqv? keycode cur-key-right)  ((blockf->statef move-right) state)]
    [(eqv? keycode cur-key-up)    state]
    [(eqv? keycode cur-key-down)  state]
    [else state]) )

; (process (init-state) cur-key-left 0)

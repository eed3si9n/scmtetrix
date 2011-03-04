#lang scheme
(require "curses.rkt")

(provide init-state state->cells state->block-pos process)

;;; build-state
(define (build-state cells block-pos)
  (list (cons 'cells cells)
        (cons 'block-pos block-pos)
  )
)

;;; init-state
(define (init-state)
  (build-state '((6 . 6))
                '(6 . 1)
  ) 
)

;;; state->cells
(define (state->cells state)
  (cdr (assoc 'cells state))
)

;;; state->block-pos
(define (state->block-pos state)
  (cdr (assoc 'block-pos state))
)

;;; returns a block transition function
(define (move-by delta)
  (lambda (b)
    (cons (+ (car b) (car delta))
          (+ (cdr b) (cdr delta))) 
  )
)

(define move-left  (move-by '(-1 . 0)))
(define move-right (move-by '(1 . 0)))

;;; converts a block transition to a state transition function
(define (blockf->statef f)
  (lambda (state)
    (build-state (state->cells state)
                 (f (state->block-pos state))
    ); build-state
  ); lambda
)

;;; given a state, a keycode and time t, it returns a new state
(define (process state keycode t)
  (cond
    [(eqv? keycode (char->integer #\space)) state]
    [(eqv? keycode cur-key-left)   ((blockf->statef move-left) state)]
    [(eqv? keycode cur-key-right)  ((blockf->statef move-right) state)]
    [(eqv? keycode cur-key-up)    state]
    [(eqv? keycode cur-key-down)  state]
    [else state]); cond 
)

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

;;; state transition function for LEFT
(define (trans-block-left state)
  (let ([block-pos (state->block-pos state)])
    (build-state (state->cells state)
                 (cons (- (car block-pos) 1) (cdr block-pos))
    )
  ); let
)

;;; state transition function for RIGHT
(define (trans-block-right state)
  (let ([block-pos (state->block-pos state)])
    (build-state (state->cells state)
                 (cons (+ (car block-pos) 1) (cdr block-pos))
    )
  ); let
)

;;; given a state, a keycode and time t, it returns a new state
(define (process state keycode t)
  (cond
    [(eqv? keycode (char->integer #\space)) state]
    [(eqv? keycode cur-key-left)   (trans-block-left state)]
    [(eqv? keycode cur-key-right)  (trans-block-right state)]
    [(eqv? keycode cur-key-up)    state]
    [(eqv? keycode cur-key-down)  state]
    [else state]); cond 
)

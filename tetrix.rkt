; export PLTCOLLECTS="`pwd`:"
; mzscheme -r tetrix.rkt

(require "curses.rkt")
(require "pure.rkt")

(define cells-x-offset 1)
(define cells-y-offset 1)

;;; draw-cells
(define (draw-cell cell)
  (let ([x (car cell)]
        [y (cdr cell)])
    (cur-mvaddch (+ (- board-height y) cells-y-offset) (+ x cells-x-offset) #\*) ))

;;; redraw
(define (redraw state)
  (let ([cells (state->cells state)])
    (cur-clear)
    (map draw-cell cells)
    ; (draw-cell (block->position (state->block state)))
    (cur-move 0 0)
    (cur-refresh)  ))

;;; eventloop
(define (eventloop state)
  (let ([keycode (cur-getch)])
    (if (eqv? keycode (char->integer #\q))
       '()
       (begin (redraw state)
              ; (eventloop state)
              (eventloop (process state keycode 0)) 
              ))))

;;; main
(define (main) 
  (dynamic-wind 
    (lambda () 
      (cur-initscr) 
      (cur-cbreak)
      (cur-keypad (stdscr) #t)
      (cur-noecho)
      (cur-timeout 100)
      ) 
      
    (lambda ()
      (eventloop (init-state))
      )
    
    (lambda ()
      (cur-endwin)) 
    )) 

(main)


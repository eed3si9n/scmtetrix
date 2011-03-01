; export PLTCOLLECTS="`pwd`:"
; mzscheme -r tetrix.rkt

(require "curses.rkt") 

(define (eventloop x y)
  (let ([keycode (cur-getch)])    
    (cur-clear)
    (cur-move y x)
    (cur-addch #\*)
    (cur-refresh)
    (cond
      [(eqv? keycode 113) keycode]
      [(eqv? keycode cur-key-left) (eventloop (- x 1) y)]
      [(eqv? keycode cur-key-right) (eventloop (+ x 1) y)]
      [else (eventloop x y)]); cond
  )
); eventloop

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
      (eventloop 10 10)
      )
    
    (lambda ()
      (cur-endwin)) 
    )) 

(main)


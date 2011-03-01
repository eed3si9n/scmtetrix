; export PLTCOLLECTS="`pwd`:"
; mzscheme -r tetrix.rkt

(require "curses.rkt") 

(define (redraw coord)
  (let ([x (car coord)]
        [y (cdr coord)])
    (cur-clear)
    (cur-mvaddch y (- x 1) #\*)
    (cur-mvaddch y x #\*)
    (cur-mvaddch y (+ x 1) #\*)
    (cur-mvaddch (- y 1) x #\*)
    
    (cur-move 0 0)
    (cur-refresh)
  ); let
); redraw

(define (eventloop coord)
  (let ([keycode (cur-getch)])    
    (redraw coord)
    (cond
      [(eqv? keycode (char->integer #\q)) keycode]
      [(eqv? keycode (char->integer #\space)) (eventloop coord)]
      [(eqv? keycode cur-key-left)  (eventloop (cons (- (car coord) 1) (cdr coord)))]
      [(eqv? keycode cur-key-right) (eventloop (cons (+ (car coord) 1) (cdr coord)))]
      [(eqv? keycode cur-key-up)    (eventloop coord)]
      [(eqv? keycode cur-key-down)  (eventloop coord)]
      [else (eventloop coord)]); cond
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
      (eventloop '(10 . 10))
      )
    
    (lambda ()
      (cur-endwin)) 
    )) 

(main)


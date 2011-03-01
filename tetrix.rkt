; export PLTCOLLECTS="`pwd`:"
; mzscheme -r tetrix.rkt

(require "curses.rkt") 

(define (eventloop frame)
  (let ([key (getch)])
    (move 1 1)
    (addch key)
    (refresh)
    (cond
      [(eqv? key #\q) '()]
      [else (eventloop 1)]); cond
  )
); eventloop

(define (main) 
  (dynamic-wind 
    (lambda () 
      (initscr) 
      (cbreak)
      (keypad (stdscr) #t)
      (noecho)
      ) 
      
    (lambda ()
      (eventloop 1))
    
    (lambda ()
      (endwin)) 
    )) 

(main)


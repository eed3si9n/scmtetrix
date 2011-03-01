#lang scheme/base

; http://pubs.opengroup.org/onlinepubs/007908799/xcurses/curses.h.html

(require mzlib/foreign) (unsafe!)

(provide 
 initscr cbreak noecho timeout keypad
 move addch addstr refresh wgetch getch endwin stdscr 
 get-cols get-lines) 

(define libcurses (ffi-lib (if (eq? (system-type) 'windows) "pdcurses" 
"libncurses"))) 

(define initscr 
  (get-ffi-obj "initscr" libcurses (_fun -> _pointer))) 
(define cbreak 
  (get-ffi-obj "cbreak" libcurses (_fun -> _int))) 
(define noecho 
  (get-ffi-obj "noecho" libcurses (_fun -> _int)))
(define timeout
  (get-ffi-obj "timeout" libcurses (_fun _int -> _void)))
(define move 
  (get-ffi-obj "move" libcurses (_fun _int _int -> _int))) 
(define _chtype (make-ctype _int char->integer integer->char)) 
(define addch 
  (get-ffi-obj "addch" libcurses (_fun _chtype -> _int))) 
(define addstr 
  (get-ffi-obj "addstr" libcurses (_fun _string/locale -> _int))) 
(define refresh 
  (get-ffi-obj "refresh" libcurses (_fun -> _int))) 
(define _win (_cpointer "CURSES WINDOW")) 
(define wgetch 
  (get-ffi-obj "wgetch" libcurses (_fun _win -> _chtype))) 
(define stdscr 
  (make-c-parameter "stdscr" libcurses _win)) 
(define (getch) (wgetch (stdscr))) 
(define keypad
  (get-ffi-obj "keypad" libcurses (_fun _win _bool -> _int)))

(define COLS 
  (make-c-parameter "COLS" libcurses _int)) 
(define LINES 
  (make-c-parameter "LINES" libcurses _int)) 
; had trouble exporting these two for some reason... maybe case sensitivity doesn't work across module borders? 
(define (get-cols) (COLS)) 
(define (get-lines) (LINES)) 
(define endwin 
  (get-ffi-obj "endwin" libcurses (_fun -> _int))) 

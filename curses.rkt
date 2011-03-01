#lang scheme/base

; http://pubs.opengroup.org/onlinepubs/007908799/xcurses/curses.h.html

(require mzlib/foreign) (unsafe!)

(provide 
 cur-initscr cur-cbreak cur-noecho  cur-keypad
 cur-move cur-addch cur-addstr cur-refresh cur-wgetch cur-getch cur-endwin stdscr 
 cur-get-cols cur-get-lines
 cur-wtimeout cur-timeout
 cur-wclear cur-clear
 
 
 cur-key-down cur-key-up cur-key-left cur-key-right) 

(define libcurses (ffi-lib (if (eq? (system-type) 'windows) "pdcurses" 
"libncurses"))) 

(define cur-key-down 258)
(define cur-key-up 259)
(define cur-key-left 260)
(define cur-key-right 261)

(define cur-initscr 
  (get-ffi-obj "initscr" libcurses (_fun -> _pointer))) 
(define cur-cbreak 
  (get-ffi-obj "cbreak" libcurses (_fun -> _int))) 
(define cur-noecho 
  (get-ffi-obj "noecho" libcurses (_fun -> _int)))
(define cur-move 
  (get-ffi-obj "move" libcurses (_fun _int _int -> _int))) 
(define _chtype (make-ctype _int char->integer integer->char)) 
(define cur-addch 
  (get-ffi-obj "addch" libcurses (_fun _chtype -> _int))) 
(define cur-addstr 
  (get-ffi-obj "addstr" libcurses (_fun _string/locale -> _int))) 
(define cur-refresh 
  (get-ffi-obj "refresh" libcurses (_fun -> _int))) 
(define _win (_cpointer "CURSES WINDOW")) 
(define cur-wgetch 
  (get-ffi-obj "wgetch" libcurses (_fun _win -> _int))) 
(define stdscr 
  (make-c-parameter "stdscr" libcurses _win)) 
(define (cur-getch) (cur-wgetch (stdscr))) 
(define cur-keypad
  (get-ffi-obj "keypad" libcurses (_fun _win _bool -> _int)))

; timeout
(define cur-wtimeout
  (get-ffi-obj "wtimeout" libcurses (_fun _win _int -> _void)))
(define (cur-timeout delay) (cur-wtimeout (stdscr) delay))

; clear
(define cur-wclear
  (get-ffi-obj "wclear" libcurses (_fun _win -> _void)))
(define (cur-clear) (cur-wclear (stdscr)))

(define COLS 
  (make-c-parameter "COLS" libcurses _int)) 
(define LINES 
  (make-c-parameter "LINES" libcurses _int)) 
; had trouble exporting these two for some reason... maybe case sensitivity doesn't work across module borders? 
(define (cur-get-cols) (COLS)) 
(define (cur-get-lines) (LINES)) 
(define cur-endwin 
  (get-ffi-obj "endwin" libcurses (_fun -> _int))) 

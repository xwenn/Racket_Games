;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname Snake) (read-case-sensitive #t) (teachpacks ((lib "image.rkt" "teachpack" "2htdp") (lib "universe.rkt" "teachpack" "2htdp") (lib "batch-io.rkt" "teachpack" "2htdp"))) (htdp-settings #(#t constructor repeating-decimal #f #t none #f ((lib "image.rkt" "teachpack" "2htdp") (lib "universe.rkt" "teachpack" "2htdp") (lib "batch-io.rkt" "teachpack" "2htdp")) #f)))
;;;; ---------------------------------------------------------------------------
;;;; TEACHPACKS
(require 2htdp/image)
(require 2htdp/universe)



;;;; ---------------------------------------------------------------------------
;;;; DATA DEFINITIONS:

;;; Definition of Constants
(define INIT-SCORE 0)   ; score value when the game starts
(define SCORE-X 22)     ; x-coordinate of score information
(define SCORE-Y 2)      ; y-coordinate of score information
(define SCORE-FONT-SIZE 20)  ; font-size of score information
(define SEG-RADIUS 5)   ; radius of the circle representing a seg
(define GRID-WIDTH (* SEG-RADIUS 2))   ; width of each grid
(define HEIGHT (* 30 GRID-WIDTH))      ; width of background
(define WIDTH (* 30 GRID-WIDTH))       ; height of background
(define BACKGROUND (bitmap "img/background.png"))   ; background image
(define FOOD-IMG    ; image that represents food
  (circle SEG-RADIUS 'solid 'green))
(define SEG-IMG     ; image that represents a snake seg
  (circle SEG-RADIUS 'solid 'red))   
(define GAME-OVER   ; game-over information
  (place-image
  (text "Game Over" 20 'white)
  (/ HEIGHT 2) (/ WIDTH 2) BACKGROUND))
(define DIFFICULTY 10)  ; snake moves faster when DIFFICULTY is greater


;;; Definition of Snake
;; A Snake is a (make-snake Direction LOP)
(define-struct snake (dir segs))

;; Data Examples:
(define snake-segs0 (cons (make-posn 3 18)
                          (cons (make-posn 3 19)
                                (cons (make-posn 3 20) '()))))
(define snake0 (make-snake "up" snake-segs0))


;;; Definition of Food
;; A Food is a (make-posn Number Number)

;; Data Examples:
(define food0 (make-posn 7 15))


;;; Definition of Score
;; A Score if a number

;; Data Example:
(define score0 INIT-SCORE)


;;; Definistion of Direction
;; A Direction is one of:
;; - "left"
;; - "right"
;; - "up"
;; - "down"


;;; Definition of List of Posns
;; A LOP is one of:
;; - '()
;; - (cons Posn LOP)


;;; Definition of World
;; A World is a (make-world Snake Food Score)
(define-struct world (snake food score))

;; Data Examples:
(define world0 (make-world snake0 food0 score0))



;;;; ---------------------------------------------------------------------------
;;;; FUNCTIONS:

;;; Drawing the world

;; draw-world: World -> Image
;; draw the current world
(check-expect (draw-world world0)
              (place-image SEG-IMG
                           (* 3 GRID-WIDTH)
                           (* 18 GRID-WIDTH)
                           (place-image SEG-IMG
                                        (* 3 GRID-WIDTH)
                                        (* 19 GRID-WIDTH)
                                        (place-image SEG-IMG
                                                     (* 3 GRID-WIDTH)
                                                     (* 20 GRID-WIDTH)
                                                     (place-image FOOD-IMG
                                                                  (* 7 GRID-WIDTH)
                                                                  (* 15 GRID-WIDTH)
                                                                  (place-image
                                                                   (text "Score: 0" 20 'green) 220 20
                                                                   BACKGROUND))))))
(define (draw-world w)
  (draw-snake (snake-segs (world-snake w))
              (draw-seg (world-food w)
                        (draw-score (world-score w) BACKGROUND))))

;; draw: Number Number Image Image -> Image
;; draw image1 on image2
(check-expect (draw 1 1 FOOD-IMG BACKGROUND)
              (place-image FOOD-IMG 10 10 BACKGROUND))
(define (draw x y img1 img2)
  (place-image img1 (* GRID-WIDTH x) (* GRID-WIDTH y) img2))

;; draw-seg: Posn Image -> Image
;; draw an image at the posn onto the given image
(check-expect (draw-seg food0 BACKGROUND)
              (place-image
               FOOD-IMG (* 7 GRID-WIDTH) (* 15 GRID-WIDTH) BACKGROUND))
(define (draw-seg aposn img)
  (draw (posn-x aposn) (posn-y aposn) FOOD-IMG img))

;; draw-snake: LOP Image -> Image
;; draw the snake segments onto the given image
(check-expect (draw-snake snake-segs0 BACKGROUND)
              (place-image SEG-IMG (* 3 GRID-WIDTH) (* 18 GRID-WIDTH)
                           (place-image SEG-IMG
                                        (* 3 GRID-WIDTH)
                                        (* 19 GRID-WIDTH)
                                        (place-image SEG-IMG
                                                     (* 3 GRID-WIDTH)
                                                     (* 20 GRID-WIDTH)
                                                     BACKGROUND))))
(define (draw-snake alop img)
  (foldr (λ (p i) (draw (posn-x p) (posn-y p) SEG-IMG i)) img alop))

;; draw-score: Number Image -> Image
;; draw the score information onto the given image
(check-expect (draw-score 10 BACKGROUND)
              (place-image (text "Score: 10" 20 'green) 220 20 BACKGROUND))
(define (draw-score s img)
  (draw SCORE-X SCORE-Y
        (text (string-append "Score: " (number->string s))
              SCORE-FONT-SIZE 'green)
        img))


;;; Key-handler

;; change-dir: World Direction -> World
;; changes the direction of the snake when a key is pressed
(check-expect (change-dir world0 "right")
              (make-world (make-snake "right" snake-segs0)  food0 score0))
(define (change-dir w adir)
  (if (or (string=? adir "left") 
          (string=? adir "right") 
          (string=? adir "up")
          (string=? adir "down"))
      (make-world (make-snake adir (snake-segs (world-snake w)))
                  (world-food w) (world-score w))
      w))


;;; Moving

;; move-world: World -> World
;; move the snake at each tick
(check-expect (move-world world0)
              (make-world
               (make-snake "up" (cons (make-posn 3 17)
                                      (cons (make-posn 3 18)
                                            (cons (make-posn 3 19) '()))))
               food0 0))
(check-expect (move-world (make-world (make-snake "right"
                                                  (cons (make-posn 3 17)
                                                        (cons (make-posn 3 18)
                                                              (cons (make-posn 3 19) '()))))
                                      food0 score0))
              (make-world (make-snake "right"
                                      (cons (make-posn 4 17)
                                            (cons (make-posn 3 17)
                                                  (cons (make-posn 3 18) '()))))
                          food0 0))
(check-random (move-world (make-world snake0 (make-posn 3 18) score0))
              (make-world (make-snake "up" (cons (make-posn 3 17)
                                                 (cons (make-posn 3 18)
                                                       (cons (make-posn 3 19)
                                                             (cons (make-posn 3 20) '())))))
                          (make-posn (add1 (random 29)) (add1 (random 29))) 1)) 
(define (move-world w)
  (if (eating? (first (snake-segs (world-snake w))) (world-food w))
      (make-world   (grow-snake (world-snake w))
                    (make-posn (add1 (random 29)) (add1 (random 29)))
                    (change-score (world-score w)))
      (make-world (make-snake (snake-dir (world-snake w))
                              (move-snake (snake-dir (world-snake w))
                                          (snake-segs (world-snake w))))
                  (world-food w)
                  (world-score w))))

;; move-snake: Direction LOP -> LOP
;; move the snake in the given direction
(check-expect (move-snake "up" snake-segs0)
              (cons (make-posn 3 17)
                    (cons (make-posn 3 18)
                          (cons (make-posn 3 19) '()))))
(define (move-snake adir segs)
  (cons (move-seg (first segs) adir) (all-but-last segs)))

;; move-seg: Posn Direction -> Posn
;; move the posn in the given direction
(check-expect (move-seg food0 "left") (make-posn 6 15))
(define (move-seg aposn adir)
  (cond [(string=? adir "left") (make-posn (sub1 (posn-x aposn)) (posn-y aposn))]
        [(string=? adir "right") (make-posn (add1 (posn-x aposn)) (posn-y aposn))]
        [(string=? adir "up") (make-posn (posn-x aposn) (sub1 (posn-y aposn)))]
        [(string=? adir "down") (make-posn (posn-x aposn) (add1 (posn-y aposn)))]))

;; all-but-last: LOP -> LOP
;; drop the last segment of the snake
(check-expect (all-but-last snake-segs0) (cons (make-posn 3 18)
                                               (cons (make-posn 3 19) '())))
(define (all-but-last alop)
  (cond [(empty? (rest alop)) '()]
        [(cons? alop) (cons (first alop)
                            (all-but-last (rest alop)))]))

;; grow-snake : Snake -> Snake
;; add a new head to the snake in the direction of the snake
(check-expect (grow-snake snake0)
              (make-snake "up"
                          (cons (make-posn 3 17)
                                (cons (make-posn 3 18)
                                      (cons (make-posn 3 19)
                                            (cons (make-posn 3 20) empty))))))
(define (grow-snake s)
  (make-snake (snake-dir s)
              (cons (move-seg (first (snake-segs s)) (snake-dir s))
                    (snake-segs s))))

;; eating? : Posn Posn -> Boolean
;; are the two posns in the same position
(check-expect (eating? (make-posn 30 30) (make-posn 30 30)) true)
(check-expect (eating? (make-posn 30 30) (make-posn 50 30)) false)
(define (eating? p1 p2)
  (and (= (posn-x p1) (posn-x p2)) 
       (= (posn-y p1) (posn-y p2))))

;; change-score: Score -> Score
;; increase score by one at each tick
(check-expect (change-score 10) 11)
(define (change-score s)
  (+ s 1))



;;; Collision detection

;; collision?: World -> Boolean
;; did the snake collide with an edge of the grid or itself?
(check-expect (collision? world0) false)
(check-expect (collision? 
               (make-world 
                (make-snake "left"
                            (list (make-posn 0 19)
                                  (make-posn 1 19)
                                  (make-posn 2 19)
                                  (make-posn 3 19)))
                (make-posn 5 9) score0)) true)
(check-expect (collision?
               (make-world 
                (make-snake "left"
                            (list (make-posn 3 19)
                                  (make-posn 1 19)
                                  (make-posn 2 19)
                                  (make-posn 3 19)))
                (make-posn 5 9) score0)) true)
(define (collision? w)
  (or (wall-collision? (first (snake-segs (world-snake w))))
      (snake-collision? (first (snake-segs (world-snake w)))
                        (rest (snake-segs (world-snake w))))))

;; wall-collision? : Posn -> Boolean
;; is the head of the snake colliding with any of the walls?
(define (wall-collision? aposn)
  (or (>= (posn-x aposn) (/ WIDTH GRID-WIDTH))
      (<= (posn-x aposn) 0)
      (>= (posn-y aposn) (/ HEIGHT GRID-WIDTH))
      (<= (posn-y aposn) 0)))

;; snake-collision? : Posn LOS -> Boolean
;; is the head of the snake colliding with another snake seg?
(define (snake-collision? aposn alos)
  (cond [(empty? alos) false]
        [(cons? alos) (or (eating? aposn (first alos))
                          (snake-collision? aposn (rest alos)))]))

;; show-end: World -> Image
;; show the game-over image
(check-expect (show-end (make-world 
                         (make-snake "left"
                                     (list (make-posn 3 19)
                                           (make-posn 1 19)
                                           (make-posn 2 19)
                                           (make-posn 3 19)))
                         (make-posn 5 9) score0))
              (place-image (text "Your score: 0" 20 'white) 150 180 GAME-OVER))
(define (show-end w)
  (draw (/ (/ WIDTH 2) GRID-WIDTH)
        (/ (+ (/ HEIGHT 2) (* 1.5 SCORE-FONT-SIZE)) GRID-WIDTH)
        (text (string-append "Your score: " (number->string (world-score w)))
              SCORE-FONT-SIZE 'white) GAME-OVER))



;;;; ---------------------------------------------------------------------------
;;;; LAUNCH THE GAME
;; World -> World
;; launches the snake game
(big-bang world0
          [to-draw draw-world]
          [on-tick move-world (/ 1 DIFFICULTY)]
          [on-key change-dir]
          [stop-when collision? show-end])

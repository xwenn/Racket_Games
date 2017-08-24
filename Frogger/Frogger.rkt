;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname Frogger) (read-case-sensitive #t) (teachpacks ((lib "image.rkt" "teachpack" "2htdp") (lib "universe.rkt" "teachpack" "2htdp") (lib "batch-io.rkt" "teachpack" "2htdp"))) (htdp-settings #(#t constructor repeating-decimal #f #t none #f ((lib "image.rkt" "teachpack" "2htdp") (lib "universe.rkt" "teachpack" "2htdp") (lib "batch-io.rkt" "teachpack" "2htdp")) #f)))
;;;; ---------------------------------------------------------------------------
;; Frogger revisited

;;;; Rules for player
;; 1. The player losses if the frog is hit by any vehicle in traffic rows.
;; 2. The player losses if the frog is in the river but not on any plank or
;; turtle.
;; 3. The player losses if the frog leaves the left or right bounds of the
;; screen.
;; 4. The frog is not able to leave the botton bound of the screen.
;; 5. The player wins if the frog reaches the top of the screen.

(require 2htdp/image)
(require 2htdp/universe)

;;;; Data Definitions:

;;; Constants
; Background
(define GRID-WIDTH 10)
(define MAX-X 74)   ; max x coordinate of the background
(define MAX-Y 70)   ; max y coordinate of the background
(define HEIGHT (* GRID-WIDTH MAX-Y))  ; height of the background
(define WIDTH (* GRID-WIDTH MAX-X))   ; width of the background
(define RIVER-MIN 5)  ; min y coordinate of the river area
(define RIVER-MAX 31) ; max y coordinate of the river area
(define RIVER-AREA
  (rectangle (* GRID-WIDTH MAX-X)
             (* GRID-WIDTH (- RIVER-MAX RIVER-MIN))
             'solid 'LightCyan))   ; river area
(define BG (place-image RIVER-AREA
                        (/ (* GRID-WIDTH MAX-X) 2)
                        (* (/ (+ RIVER-MAX RIVER-MIN) 2) GRID-WIDTH)
                        (empty-scene WIDTH HEIGHT)))  ; background

; Frog
(define F-IMG-U (bitmap "img/frog_up.png")) ; frog image when its direction is "up"
(define F-IMG-D (bitmap "img/frog_down.png")) ; frog image when its direction is "down"
(define F-IMG-R (bitmap "img/frog_right.png")) ; frog image when its direction is "right"
(define F-IMG-L (bitmap "img/frog_left.png")) ; frog image when its direction is "left"
(define FROG-STEP 5)  ; length of frog's each step
(define F-LENGTH
  (/ (image-height F-IMG-U) GRID-WIDTH))  ; frog image size

; Vehicle
(define V-IMG-R (bitmap "img/vehicle_right.png")) ; vehicle image when its direction is "right"
(define V-IMG-L (bitmap "img/vehicle_left.png")) ; vehicle image when its direction is "left"
(define V-LENGTH (/ (image-width V-IMG-R) GRID-WIDTH)) ; length of a vehicle
(define V-WIDTH (/ (image-height V-IMG-R) GRID-WIDTH))  ; width of a vehicle
(define DISTANCE-BETWEEN-VS 14)  ; distance bewteen two vehicles
(define V-NUM 4)  ; number of vehicles per row
(define V-TOTAL-L ; total length of all vehicles and gaps in each row
  (* V-NUM (+ V-LENGTH DISTANCE-BETWEEN-VS)))

; Plank
(define P-IMG (bitmap "img/plank.png"))
(define P-LENGTH (/ (image-width P-IMG) GRID-WIDTH)) ; length of a plank
(define P-WIDTH (/ (image-height P-IMG) GRID-WIDTH))   ; width of a plank
(define DISTANCE-BETWEEN-PS 10)  ; distance bwtween two planks
(define P-NUM 4)  ; number of planks per row
(define P-TOTAL-L ; total length of all planks and gaps in each row
  (* P-NUM (+ P-LENGTH DISTANCE-BETWEEN-PS)))

; Turtle
(define T-IMG (bitmap "img/turtle.png"))
(define T-L
  (/ (image-height T-IMG) GRID-WIDTH))   ; turtle image size
(define DISTANCE-BETWEEN-TS 16)  ; distance bewteen two separated turtles
(define T-NUM 3)     ; number of turtles for group
(define T-GROUPS 3)  ; number of turtle groups per row
(define T-TOTAL-L ; total length of all turtles and gaps in each row
  (* T-GROUPS (+ (* T-L T-NUM) DISTANCE-BETWEEN-TS)))

; Information  ; 
(define INIT-LIVES 3)
(define INIT-SCORE 500)
(define INFO-FONT-SIZE 20)
(define SCORE-INIT-X 8)
(define LIVES-INIT-X 20)
(define INFO-Y 68)
(define WIN_FROG (bitmap "img/win_frog.png"))
(define GAME-OVER (place-image (text "Game Over :(" 40 'red)
                               (/ WIDTH 2) (/ HEIGHT 2)
                               (empty-scene WIDTH HEIGHT)))
(define WIN (place-image (text "Win! :)" 40 'green) (/ WIDTH 2) (/ HEIGHT 2)
                         (place-image WIN_FROG 200 200 (empty-scene WIDTH HEIGHT))))
(define DIFFICULTY 3)  ; entities move faster when DIFFICULTY is greater


;;; A Direction is one of:
;; - "left"
;; - "right"
;; - "up"
;; - "down"


;;; A Player is a (make-player Number Number Direction)
;; INTERP: represents the x and y coordinates and the direction of a player
(define-struct player (x y dir))

;; Data Examples:
(define player0 (make-player 37 63 "up"))
(define player1 (make-player 37 63 "down"))
(define player2 (make-player 37 63 "left"))
(define player3 (make-player 37 63 "right"))


;;; A Vehicle is a (make-vehicle Number Number Direction)
(define-struct vehicle (x y dir))

;; Data Examples:
(define v1 (make-vehicle 8 58 "right"))
(define v2 (make-vehicle 28 58 "right"))
(define v3 (make-vehicle 48 58 "right"))
(define v4 (make-vehicle 68 58 "right"))
(define v5 (make-vehicle 6 53 "left"))
(define v6 (make-vehicle 26 53 "left"))
(define v7 (make-vehicle 46 53 "left"))
(define v8 (make-vehicle 66 53 "left"))
(define v9 (make-vehicle 2 48 "right"))
(define v10 (make-vehicle 22 48 "right"))
(define v11 (make-vehicle 42 48 "right"))
(define v12 (make-vehicle 62 48 "right"))
(define v13 (make-vehicle 8 43 "left"))
(define v14 (make-vehicle 28 43 "left"))
(define v15 (make-vehicle 48 43 "left"))
(define v16 (make-vehicle 68 43 "left"))
(define v17 (make-vehicle 4 38 "right"))
(define v18 (make-vehicle 24 38 "right"))
(define v19 (make-vehicle 44 38 "right"))
(define v20 (make-vehicle 64 38 "right"))


;;; [List-of Vehicle]

;; Data Examples:
(define lov0 '())
(define lov1 (list v1 v2 v3 v4 v5 v6 v7 v8 v9 v10
                   v11 v12 v13 v14 v15 v16 v17 v18 v19 v20))
(define lov2 (list v1))


;;; A Plank is a (make-plank Number Number Direction)
(define-struct plank (x y dir))

;; Data Examples:
(define p1 (make-plank -2 28 "right"))
(define p2 (make-plank 20 28 "right"))
(define p3 (make-plank 42 28 "right"))
(define p4 (make-plank 64 28 "right"))
(define p5 (make-plank 5 18 "right"))
(define p6 (make-plank 27 18 "right"))
(define p7 (make-plank 49 18 "right"))
(define p8 (make-plank 71 18 "right"))
(define p9 (make-plank 0 8 "right"))
(define p10 (make-plank 22 8 "right"))
(define p11 (make-plank 44 8 "right"))
(define p12 (make-plank 66 8 "right"))


;;; [List-of Plank]

;; Data Example:
(define lop0 '())
(define lop1 (list p1 p2 p3 p4 p5 p6 p7 p8 p9 p10 p11 p12))
(define lop2 (list p1))


;;; A Turtle is a (make-turtle Number Number Direction)
(define-struct turtle (x y dir))

;; Data Examples:
(define t1 (make-turtle 2 23 "left"))
(define t2 (make-turtle 6 23 "left"))
(define t3 (make-turtle 10 23 "left"))
(define t4 (make-turtle 30 23 "left"))
(define t5 (make-turtle 34 23 "left"))
(define t6 (make-turtle 38 23 "left"))
(define t7 (make-turtle 58 23 "left"))
(define t8 (make-turtle 62 23 "left"))
(define t9 (make-turtle 66 23 "left"))
(define t10 (make-turtle 11 13 "left"))
(define t11 (make-turtle 15 13 "left"))
(define t12 (make-turtle 19 13 "left"))
(define t13 (make-turtle 39 13 "left"))
(define t14 (make-turtle 43 13 "left"))
(define t15 (make-turtle 47 13 "left"))
(define t16 (make-turtle 67 13 "left"))
(define t17 (make-turtle 71 13 "left"))
(define t18 (make-turtle 75 13 "left"))


;;; [List-of Turtle]

;; Data Example:
(define lot0 '())
(define lot1 (list t1 t2 t3 t4 t5 t6 t7 t8 t9 t10
                   t11 t12 t13 t14 t15 t16 t17 t18))
(define lot2 (list t1))


;;; An Info is a (make-info number number)
(define-struct info (score lives))

;; Data Example:
(define info0 (make-info INIT-SCORE INIT-LIVES))


;;; A World is a
;; (make-world Player [List-of Vehicle] [List-of Plank] [List-of Turtles])
(define-struct world (player vehicles planks turtles info))

;; Data Examples:
(define EMPTY-W (make-world player0 lov0 lop0 lot0 info0))
(define W0 (make-world player0 lov1 lop1 lot1 info0))
(define SIMPLE-W (make-world player0 lov2 lop2 lot2 info0))


;;; Drawing the world

;; draw-all: World -> Image
;; draw the world base on condition
(define (draw-all aw)
  (if (dead? aw) (draw-world (reset-world aw)) (draw-world aw)))

;; draw-world: World -> Image
;; draw the current world
(check-expect (draw-world EMPTY-W)
              (place-image F-IMG-U 370 630
                           (place-image (text "Score: 500" 20 'green) 80 680
                                        (place-image (text "Lives: 3" 20 'green) 200 680 BG))))
(check-expect (draw-world SIMPLE-W)
              (place-image F-IMG-U 370 630
                           (place-image V-IMG-R 80 580
                                        (place-image P-IMG -20 280
                                                     (place-image T-IMG 20 230
                                                                  (place-image (text "Score: 500" 20 'green) 80 680
                                                                               (place-image (text "Lives: 3" 20 'green) 200 680    
                                                                                            BG)))))))
(define (draw-world aw)
  (draw-player (world-player aw)
               (draw-vehicles (world-vehicles aw)
                              (draw-planks (world-planks aw)
                                           (draw-turtles (world-turtles aw)
                                                         (draw-score (info-score (world-info aw))
                                                                     (draw-lives (info-lives (world-info aw))
                                                                                 BG)))))))

;; draw-player: Player Image -> Image
;; draw the image of a frog on another image based on the frog's direction
(check-expect (draw-player player0 BG) (place-image F-IMG-U 370 630 BG))
(check-expect (draw-player player1 BG) (place-image F-IMG-D 370 630 BG))
(check-expect (draw-player player2 BG) (place-image F-IMG-L 370 630 BG))
(check-expect (draw-player player3 BG) (place-image F-IMG-R 370 630 BG))
(define (draw-player ap img)
  (cond [(string=? (player-dir ap) "up")
         (draw (player-x ap) (player-y ap) F-IMG-U img)]
        [(string=? (player-dir ap) "down")
         (draw (player-x ap) (player-y ap) F-IMG-D img)]
        [(string=? (player-dir ap) "left")
         (draw (player-x ap) (player-y ap) F-IMG-L img)]
        [(string=? (player-dir ap) "right")
         (draw (player-x ap) (player-y ap) F-IMG-R img)]))

;; draw: Number Number Image Image -> Image
;; draw image1 on image2
(check-expect (draw 1 1 F-IMG-U BG) (place-image F-IMG-U 10 10 BG))
(define (draw x y img1 img2)
  (place-image img1 (* GRID-WIDTH x) (* GRID-WIDTH y) img2))

;; draw-vehicles: [List-of Vehicle] Image -> Image
;; draw the given set of vehicles on an image
(check-expect (draw-vehicles lov0 BG) BG)
(check-expect (draw-vehicles lov2 BG) (place-image V-IMG-R 80 580 BG))
(define (draw-vehicles alov img)
  ;; [Vehicle Image -> Image] Image [List-of Vehicle] -> Image
  (foldr draw-one-v img alov))

;; draw-one-v: Vehicle Image -> Image
;; draw the image of the given vehicle on another image
(check-expect (draw-one-v v1 BG) (place-image V-IMG-R 80 580 BG))
(check-expect (draw-one-v v5 BG) (place-image V-IMG-L 60 530 BG))
(define (draw-one-v av img)
  (cond [(string=? (vehicle-dir av) "left")
         (draw (vehicle-x av) (vehicle-y av) V-IMG-L img)]
        [(string=? (vehicle-dir av) "right")
         (draw (vehicle-x av) (vehicle-y av) V-IMG-R img)]))

;; draw-planks: [List-of Plank] Image -> Image
;; draw the given set of planks on an image
(check-expect (draw-planks lop0 BG) BG)
(check-expect (draw-planks lop2 BG) (place-image P-IMG -20 280 BG))
(define (draw-planks alop img)
  ;; [Plank Image -> Image] Image [List-of Plank] -> Image
  (foldr (λ (p i) (draw (plank-x p) (plank-y p) P-IMG i)) img alop))

;; draw-turtles: [List-of Turtle] Image -> Image
;; draw the given set of turtles on an image
(check-expect (draw-turtles lot0 BG) BG)
(check-expect (draw-turtles lot2 BG) (place-image T-IMG 20 230 BG))
(define (draw-turtles alot img)
  ;; [Turtle Image -> Image] Image [List-of Turtle] -> Image
  (foldr (λ (t i) (draw (turtle-x t) (turtle-y t) T-IMG i)) img alot))

;; draw-info: Info Image -> Image
;; draw the game information on an image
(check-expect (draw-info info0 BG)
              (place-image (text "Score: 500" 20 'green) 80 680
                           (place-image (text "Lives: 3" 20 'green) 200 680 BG)))
(define (draw-info i img)
  (draw-score (info-score i)
              (draw-lives (info-lives i) img)))                   

;; draw-score: Number Image -> Image
;; produce the game score as an image
(check-expect (draw-score 1000 BG)
              (place-image (text "Score: 1000" 20 'green) 80 680 BG))
(define (draw-score score img)
  (draw SCORE-INIT-X INFO-Y
        (text (string-append "Score: " (number->string score)) INFO-FONT-SIZE 'green)
        img))

;; draw-lives: Number Image -> Image
;; produce the currentn number of lives as an image
(check-expect (draw-lives 3 BG)
              (place-image (text "Lives: 3" 20 'green) 200 680 BG))
(define (draw-lives lives img)
  (draw LIVES-INIT-X INFO-Y
        (text (string-append "Lives: " (number->string lives)) INFO-FONT-SIZE 'green)
        img))

;;; Moving

;; move-all: World -> World
;; move the world base on condition
(define (move-all aw)
  (if (dead? aw) (move-world (reset-world aw)) (move-world aw)))

;; move-world: World -> World
;; move the given world at each tick
(check-expect (move-world EMPTY-W)
              (make-world player0 lov0 lop0 lot0 (make-info 499 3)))
(check-expect (move-world SIMPLE-W)
              (make-world player0
                          (list (make-vehicle 9 58 "right"))
                          (list (make-plank -1 28 "right"))
                          (list (make-turtle 1 23 "left"))
                          (make-info 499 3)))
(define (move-world aw)
  (make-world (ride-move (world-player aw) (world-planks aw) (world-turtles aw))
              (move-vehicles (world-vehicles aw))
              (move-planks (world-planks aw))
              (move-turtles (world-turtles aw))
              (make-info (change-score (info-score (world-info aw))) (info-lives (world-info aw)))))

;; move-vehicles: [List-of Vehicle] -> [List-of Vehicle]
;; move the given list of vehicles at each tick
(check-expect (move-vehicles lov0) lov0)
(check-expect (move-vehicles lov2) (list (make-vehicle 9 58 "right")))
(check-expect (move-vehicles (list v5)) (list (make-vehicle 5 53 "left")))
(define (move-vehicles alov)
  ;; [Vehicle -> Vehicle] [List-of Vehicle] -> [List-of Vehicle]
  (map move-a-vehicle alov))

;; move-a-vehicle: Vehicle -> Vehicle
;; move a given vehicle at each tick
(check-expect (move-a-vehicle v1) (make-vehicle 9 58 "right"))
(check-expect (move-a-vehicle (make-vehicle 77 27 "right"))
              (make-vehicle -2 27 "right"))
(check-expect (move-a-vehicle v5) (make-vehicle 5 53 "left"))
(check-expect (move-a-vehicle (make-vehicle -3 22 "left"))
              (make-vehicle 76 22 "left"))
(check-expect (move-a-vehicle (make-vehicle 10 10 "up"))
              (make-vehicle 10 10 "up"))
(check-expect (move-a-vehicle (make-vehicle 20 20 "down"))
              (make-vehicle 20 20 "down"))
(define (move-a-vehicle av)
  (cond [(string=? (vehicle-dir av) "right")
         (make-vehicle (move-right (vehicle-x av) V-LENGTH V-TOTAL-L)
                       (vehicle-y av) (vehicle-dir av))]
        [(string=? (vehicle-dir av) "left")
         (make-vehicle (move-left (vehicle-x av) V-LENGTH V-TOTAL-L)
                       (vehicle-y av) (vehicle-dir av))]
        [else av]))

;; move-right: Number PosReal PosReal-> Number
;; change the x coordinate for an entity that goes right
(check-expect (move-right 8 6 80) 9)
(check-expect (move-right 77 6 80) -2)
(define (move-right x l total-l)
  (if (<= (add1 x) (+ MAX-X (/ l 2)))
      (add1 x)
      (- (add1 x) total-l)))

;; move-left: Number PosReal PosReal -> Number
;; change the x coordinate for an entity that goes left
(check-expect (move-left 8 6 80) 7)
(check-expect (move-left -3 6 80) 76)
(define (move-left x l total-l)
  (if (>= (sub1 x) (- (/ l 2)))
      (sub1 x)
      (+ (sub1 x) total-l)))

;;> decided not to use abstract function for move-right and move-left,
;;> because the abstract function would take 6 parameters: x, l, total-l,
;;> op1 (<= or >=), op2 (add1 or sub1) and op3 (- or +), whick is cumbersome
;;> and not very helpful.

;; move-planks: [List-of Plank] -> [List-of Plank]
(check-expect (move-planks lop2) (list (make-plank -1 28 "right")))
(check-expect (move-planks (list (make-plank 80 28 "right")))
              (list (make-plank -7 28 "right")))
(define (move-planks alop)
  ;; [Plank -> Plank] [List-of Plank] -> [List-of Plank]
  (map (λ (p) (make-plank (move-right (plank-x p) P-LENGTH P-TOTAL-L)
                          (plank-y p) (plank-dir p))) alop))

;; move-turtles: [List-of Turtle] -> [List-of Turtle]
(check-expect (move-turtles lot2) (list (make-turtle 1 23 "left")))
(check-expect (move-turtles (list (make-turtle -2 23 "left")))
              (list (make-turtle 81 23 "left")))
(define (move-turtles alot)
  ;; [Turtle -> Turtle] [List-of Turtle] -> [List-of Turtle]
  (map (λ (t) (make-turtle (move-left (turtle-x t) T-L T-TOTAL-L)
                           (turtle-y t) (turtle-dir t))) alot))

;; ride-move: Player [List-of Plank] [List-of Turtles] -> Plank
;; move the frg if it rides on a plank or a turtle
(check-expect (ride-move player0 lop2 lot2) player0)
(check-expect (ride-move (make-player -2 28 "up") lop2 lot2)
              (make-player -1 28 "up"))
(check-expect (ride-move (make-player 2 23 "up") lop2 lot2)
              (make-player 1 23 "up"))
(define (ride-move ap alop alot)
  (cond [(on-any-p? ap alop)
         (make-player (move-right (player-x ap) F-LENGTH MAX-X)
                      (player-y ap) (player-dir ap))]
        [(on-any-t? ap alot)
         (make-player (move-left (player-x ap) F-LENGTH MAX-X)
                      (player-y ap) (player-dir ap))]
        [else ap]))

;; on-any-p?: Player [List-of Plank] -> Boolean
;; is the player on any plank?
;; (is the center of player within any plank image?)
(check-expect (on-any-p? player0 lop2) #false)
(check-expect (on-any-p? (make-player -2 28 "up") lop2) #true)
(define (on-any-p? ap alop)
  ;; [Plank -> Boolean] [List-of Plank] -> [List-of Plank]
  (ormap (λ (p) (on? ap (plank-x p) (plank-y p) P-LENGTH P-WIDTH)) alop))

;; on-any-t?: Player [List-of Turtle] -> Boolean
;; is the player on any turtle?
;; (is the center of player within any turtle image?)
(check-expect (on-any-t? player0 lot2) #false)
(check-expect (on-any-t? (make-player 2 23 "up") lot2) #true)
(define (on-any-t? ap alot)
  ;; [Turtle -> Boolean] [List-of Turtle] -> [List-of Turtle]
  (ormap (λ (t) (on? ap (turtle-x t) (turtle-y t) T-L T-L)) alot))

;; on?: Player Number Number NonNegReal NonNegReal -> Boolean
;; is the player within x-range and y-range of x-position and y-position?
(check-expect (on? player0 35 61 3 3) #false)
(check-expect (on? player0 35 61 4 4) #true)
(define (on? ap x-position y-position x-range y-range)
  (and (in-range? (player-x ap) x-position (/ (+ x-range 1) 2))
       (in-range? (player-y ap) y-position (/ (+ y-range 1) 2))))

;; in-range?: Number Number Number -> Boolean
;; is n1 within range of n2?
(check-expect (in-range? 3 8 4) #false)
(check-expect (in-range? 3 8 6) #true)
(define (in-range? n1 n2 range)
  (and (< n1 (+ n2 range))
       (> n1 (- n2 range))))

;; change-score: Score -> Score
;; deduct one from score on each tick
(check-expect (change-score INIT-SCORE) 499)
(define (change-score score)
  (- score 1))



;;; Key-handler

;; move-world-player: World Direction -> World
;; change the position of the player in the given world when a key is pressed
(check-expect (move-world-player W0 "up")
              (make-world (make-player 37 58 "up") lov1 lop1 lot1 info0))
(check-expect (move-world-player W0 "down")
              (make-world (make-player 37 68 "down") lov1 lop1 lot1 info0))
(check-expect (move-world-player W0 "left")
              (make-world (make-player 32 63 "left") lov1 lop1 lot1 info0))
(check-expect (move-world-player W0 "right")
              (make-world (make-player 42 63 "right") lov1 lop1 lot1 info0))
(define (move-world-player aw adir)
  (make-world (move-player (world-player aw) adir)
              (world-vehicles aw) (world-planks aw) (world-turtles aw) (world-info aw)))

;; move-player: Player Direction -> Player
;; change the position of the given player when a key is pressed
(check-expect (move-player player0 "up") (make-player 37 58 "up"))
(check-expect (move-player player0 "down") (make-player 37 68 "down"))
(check-expect (move-player player0 "left") (make-player 32 63 "left"))     
(check-expect (move-player player0 "right") (make-player 42 63 "right"))
(define (move-player ap adir)
  (cond [(string=? adir "up")
         (make-player (player-x ap) (- (player-y ap) FROG-STEP) adir)]
        [(string=? adir "down")
         (make-player (player-x ap) (above-bottom (player-y ap)) adir)]
        [(string=? adir "left")
         (make-player (- (player-x ap) FROG-STEP) (player-y ap) adir)]
        [(string=? adir "right")
         (make-player (+ (player-x ap) FROG-STEP) (player-y ap) adir)]))

;; above-bottom: Number -> Number
;; add one step (5 grids) to y if it remains above the bottom of the screen,
;; otherwise keep y
(check-expect (above-bottom 10) 15)
(check-expect (above-bottom 63) 68)
(define (above-bottom y)
  (if (<= (+ y FROG-STEP) (- MAX-Y (/ F-LENGTH 2)))
      (+ y FROG-STEP)
      y))



;;; End detection

;; end?: World -> Boolean
;; does the game over?
(check-expect (end? W0) #false)
(check-expect (end? (make-world player0 lov1 lop1 lot1 (make-info 1000 0))) #true)
(check-expect (end? (make-world player0 lov1 lop1 lot1 (make-info 0 1))) #true)
(define (end? aw)
  (or (<= (info-lives (world-info aw)) 0)
      (<= (info-score (world-info aw)) 0)
      (win? (world-player aw))))

;; reset-world: World -> World
(check-expect (reset-world W0) (make-world player0 lov1 lop1 lot1 (make-info 400 2)))
(define (reset-world aw)
  (make-world player0 lov1 lop1 lot1
              (make-info (- (info-score (world-info aw)) 100)
                         (- (info-lives (world-info aw)) 1))))

;; dead?: World -> Boolean
;; does current player dead?
(check-expect (dead? (make-world (make-player 4 58 "up") lov1 lop1 lot1 info0)) #true)
(check-expect (dead? (make-world (make-player 31 28 "up") lov1 lop1 lot1 info0)) #true)
(check-expect (dead? (make-world (make-player 0 28 "up") lov1 lop1 lot1 info0)) #true)
(check-expect (dead? (make-world player0 lov1 lop1 lot1 (make-info 0 3))) #true)
(check-expect (dead? W0) #false)
(define (dead? aw)
  (or (hit? (world-player aw) (world-vehicles aw))
      (sink? (world-player aw) (world-planks aw) (world-turtles aw))
      (out? (world-player aw))
      (<= (info-score (world-info aw)) 0)))

;; hit?: Player [List-of Vehicle] -> Boolean
;; is the player hit by any vehicle?
(check-expect (hit? (make-player 4 58 "up") lov1) #true)
(check-expect (hit? (make-player 2 53 "up") lov1) #true)
(check-expect (hit? player0 lov1) #false)
(define (hit? ap alov)
  ;; [Vehicle -> Boolean] [List-of Vehicle] -> Boolean 
  (ormap (λ (v) (on? ap (vehicle-x v) (vehicle-y v)
                     (sub1 (+ V-LENGTH F-LENGTH))
                     (sub1 (+ V-WIDTH F-LENGTH))))
         alov))

;; sink?: Player [List-of Plank] [List-of Turtle] -> Boolean
;; is the player sink in the river?
(check-expect (sink? (make-player 10 28 "up") lop1 lot1) #true)
(check-expect (sink? (make-player 20 23 "up") lop1 lot1) #true)
(check-expect (sink? (make-player 20 28 "up") lop1 lot1) #false)
(define (sink? ap alop alot)
  (and (in-river? ap)
       (not (on-any-p? ap alop))
       (not (on-any-t? ap alot))))

;; in-river?: Player -> Boolean
;; is the player in the river area?
(check-expect (in-river? (make-player 10 28 "up")) #true)
(check-expect (in-river? player0) #false)
(define (in-river? ap)
  (and (> (player-y ap) RIVER-MIN)
       (< (player-y ap) RIVER-MAX)))

;; out?: Player -> Boolean
;; is the player out of left or right boundary?
(define (out? ap)
  (or (> (player-x ap) (- MAX-X (/ F-LENGTH 2)))
      (< (player-x ap) (/ F-LENGTH 2))))

;; win?: Player -> Boolean
;; does the player win the game?
(check-expect (win? (make-player 40 3 "up")) #true)
(check-expect (win? player0) #false)
(define (win? ap)
  (<= (player-y ap) (+ (/ F-LENGTH 2) 1)))

;; show-end: World -> Image
;; show the game-over image
(define (show-end aw)
  (cond [(win? (world-player aw))
         (place-image (text (string-append "Score: "
                                           (number->string (info-score (world-info aw))))
                            40 'green) 370 400 WIN)]
        [else (place-image (text (string-append "Score: "
                                                (number->string (info-score (world-info aw))))
                                 40 'green) 370 400 GAME-OVER)]))



;;; World -> World
;; launch the game
(big-bang W0
          [to-draw draw-all]
          [on-tick move-all (/ 1 DIFFICULTY)]
          [on-key move-world-player]
          [stop-when end? show-end])


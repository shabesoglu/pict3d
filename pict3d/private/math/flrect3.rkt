#lang typed/racket/base

(require (for-syntax racket/base)
         racket/match
         racket/list
         math/flonum
         "flv3.rkt"
         "flt3.rkt"
         "../utils.rkt"
         "../types.rkt")

(provide
 ;; Types
 FlRect3
 (rename-out [-Empty-FlRect3     Empty-FlRect3]
             [-Nonempty-FlRect3  Nonempty-FlRect3])
 ;; Predicates
 flrect3?
 empty-flrect3?
 nonempty-flrect3?
 ;; Constructors
 empty-flrect3
 nonempty-flrect3
 (rename-out [make-flrect3  flrect3])
 flv3rect
 ;; Accessors
 nonempty-flrect3-min
 nonempty-flrect3-max
 nonempty-flrect3-values
 flrect3-min
 flrect3-max
 flrect3-values
 ;; Operations
 flrect3-join
 flrect3-meet
 flrect3-separating-plane
 flrect3-center
 flrect3-volume
 flrect3-plane-side
 flrect3-contains-point?
 flrect3-contains-rect?
 flrect3-longest-axis/center
 flrect3-transform
 )

;; ===================================================================================================
;; Types

(struct flrect3 () #:transparent)

(struct Empty-FlRect3 flrect3 () #:transparent)

(struct Nonempty-FlRect3 flrect3 ([min : FlVector]
                                  [max : FlVector])
  #:transparent)

(define-type FlRect3 (U Empty-FlRect3 Nonempty-FlRect3))

(define-type -Empty-FlRect3     Empty-FlRect3)
(define-type -Nonempty-FlRect3  Nonempty-FlRect3)

;; ===================================================================================================
;; Predicates, accessors and constructors

(define empty-flrect3? Empty-FlRect3?)
(define empty-flrect3 (Empty-FlRect3))

(define nonempty-flrect3? Nonempty-FlRect3?)
(define nonempty-flrect3-min Nonempty-FlRect3-min)
(define nonempty-flrect3-max Nonempty-FlRect3-max)

(: nonempty-flrect3 (-> FlVector FlVector Nonempty-FlRect3))
(define (nonempty-flrect3 v1 v2)
  (define-values (x1 y1 z1) (flv3-values v1))
  (define-values (x2 y2 z2) (flv3-values v2))
  (Nonempty-FlRect3 (flvector (min x1 x2) (min y1 y2) (min z1 z2))
                    (flvector (max x1 x2) (max y1 y2) (max z1 z2))))

(: make-flrect3 (-> FlVector FlVector FlRect3))
(define (make-flrect3 mn mx)
  (define-values (xmin ymin zmin) (flv3-values mn))
  (define-values (xmax ymax zmax) (flv3-values mx))
  (if (and (<= xmin xmax) (<= ymin ymax) (<= zmin zmax))
      (Nonempty-FlRect3 mn mx)
      empty-flrect3))

(: flv3rect (-> (Vectorof FlVector) FlRect3))
(define (flv3rect vs)
  (cond [(= 0 (vector-length vs))  empty-flrect3]
        [else  (define-values (xmin ymin zmin xmax ymax zmax) (flv3rect-values vs))
               (Nonempty-FlRect3 (flvector xmin ymin zmin)
                                 (flvector xmax ymax zmax))]))

(: flrect3-min (-> FlRect3 FlVector))
(define (flrect3-min bb)
  (if (empty-flrect3? bb)
      (flvector +inf.0 +inf.0 +inf.0)
      (nonempty-flrect3-min bb)))

(: flrect3-max (-> FlRect3 FlVector))
(define (flrect3-max bb)
  (if (empty-flrect3? bb)
      (flvector -inf.0 -inf.0 -inf.0)
      (nonempty-flrect3-max bb)))

(: nonempty-flrect3-values (-> Nonempty-FlRect3 (Values Flonum Flonum Flonum Flonum Flonum Flonum)))
(define (nonempty-flrect3-values bb)
  (define-values (xmin ymin zmin) (flv3-values (nonempty-flrect3-min bb)))
  (define-values (xmax ymax zmax) (flv3-values (nonempty-flrect3-max bb)))
  (values xmin ymin zmin xmax ymax zmax))

(: flrect3-values (-> FlRect3 (Values Flonum Flonum Flonum Flonum Flonum Flonum)))
(define (flrect3-values bb)
  (define-values (xmin ymin zmin) (flv3-values (flrect3-min bb)))
  (define-values (xmax ymax zmax) (flv3-values (flrect3-max bb)))
  (values xmin ymin zmin xmax ymax zmax))

;; ===================================================================================================
;; Operations

(: flrect3-join (case-> (-> Nonempty-FlRect3 FlRect3 Nonempty-FlRect3)
                        (-> FlRect3 Nonempty-FlRect3 Nonempty-FlRect3)
                        (-> FlRect3 FlRect3 FlRect3)))
(define (flrect3-join bb1 bb2)
  (cond
    [(empty-flrect3? bb1)  bb2]
    [(empty-flrect3? bb2)  bb1]
    [else
     (define-values (xmin1 ymin1 zmin1 xmax1 ymax1 zmax1) (nonempty-flrect3-values bb1))
     (define-values (xmin2 ymin2 zmin2 xmax2 ymax2 zmax2) (nonempty-flrect3-values bb2))
     (Nonempty-FlRect3 (flvector (min xmin1 xmin2) (min ymin1 ymin2) (min zmin1 zmin2))
                       (flvector (max xmax1 xmax2) (max ymax1 ymax2) (max zmax1 zmax2)))]))

(: flrect3-meet (-> FlRect3 FlRect3 FlRect3))
(define (flrect3-meet bb1 bb2)
  (cond
    [(empty-flrect3? bb1)  bb1]
    [(empty-flrect3? bb2)  bb2]
    [else
     (define-values (xmin1 ymin1 zmin1 xmax1 ymax1 zmax1) (nonempty-flrect3-values bb1))
     (define-values (xmin2 ymin2 zmin2 xmax2 ymax2 zmax2) (nonempty-flrect3-values bb2))
     (make-flrect3 (flvector (max xmin1 xmin2) (max ymin1 ymin2) (max zmin1 zmin2))
                   (flvector (min xmax1 xmax2) (min ymax1 ymax2) (min zmax1 zmax2)))]))

(: flrect3-separating-plane (-> FlRect3 FlRect3 (U #f FlPlane3)))
(define (flrect3-separating-plane bb1 bb2)
  (cond
    [(empty-flrect3? bb1)  #f]
    [(empty-flrect3? bb2)  #f]
    [else
     (define-values (xmin1 ymin1 zmin1 xmax1 ymax1 zmax1) (flrect3-values bb1))
     (define-values (xmin2 ymin2 zmin2 xmax2 ymax2 zmax2) (flrect3-values bb2))
     (cond [(<= xmax1 xmin2)  (flplane3 (flvector +1.0 0.0 0.0) (* -0.5 (+ xmax1 xmin2)))]
           [(<= xmax2 xmin1)  (flplane3 (flvector -1.0 0.0 0.0) (* +0.5 (+ xmax2 xmin1)))]
           [(<= ymax1 ymin2)  (flplane3 (flvector 0.0 +1.0 0.0) (* -0.5 (+ ymax1 ymin2)))]
           [(<= ymax2 ymin1)  (flplane3 (flvector 0.0 -1.0 0.0) (* +0.5 (+ ymax2 ymin1)))]
           [(<= zmax1 zmin2)  (flplane3 (flvector 0.0 0.0 +1.0) (* -0.5 (+ zmax1 zmin2)))]
           [(<= zmax2 zmin1)  (flplane3 (flvector 0.0 0.0 -1.0) (* +0.5 (+ zmax2 zmin1)))]
           [else  #f])]))

(: nonempty-flrect3-center (-> Nonempty-FlRect3 FlVector))
(define (nonempty-flrect3-center bb)
  (define-values (xmin ymin zmin xmax ymax zmax) (nonempty-flrect3-values bb))
  (flvector (* 0.5 (+ xmin xmax))
            (* 0.5 (+ ymin ymax))
            (* 0.5 (+ zmin zmax))))

(: flrect3-center (case-> (-> Nonempty-FlRect3 FlVector)
                          (-> FlRect3 (U #f FlVector))))
(define (flrect3-center bb)
  (if (empty-flrect3? bb)
      #f
      (nonempty-flrect3-center bb)))

(: nonempty-flrect3-volume (-> Nonempty-FlRect3 Flonum))
(define (nonempty-flrect3-volume bb)
  (define-values (xmin ymin zmin xmax ymax zmax) (nonempty-flrect3-values bb))
  (* (- xmax xmin)
     (- ymax ymin)
     (- zmax zmin)))

(: flrect3-volume (-> FlRect3 Flonum))
(define (flrect3-volume bb)
  (if (empty-flrect3? bb)
      0.0
      (nonempty-flrect3-volume bb)))

(: nonempty-flrect3-plane-side (-> Nonempty-FlRect3 FlPlane3 Box-Plane-Sides))
(define (nonempty-flrect3-plane-side b p)
  'both)

(: flrect3-plane-side (case-> (-> Nonempty-FlRect3 FlPlane3 Box-Plane-Sides)
                              (-> FlRect3 FlPlane3 (U #f Box-Plane-Sides))))
(define (flrect3-plane-side b p)
  (if (empty-flrect3? b)
      #f
      (nonempty-flrect3-plane-side b p)))

(: flrect3-contains-point? (-> FlRect3 FlVector Boolean))
(define (flrect3-contains-point? bb v)
  (cond
    [(empty-flrect3? bb)  #f]
    [else
     (define-values (xmin ymin zmin xmax ymax zmax) (nonempty-flrect3-values bb))
     (define-values (x y z) (flv3-values v))
     (and (<= xmin x xmax)
          (<= ymin y ymax)
          (<= zmin z zmax))]))

(: flrect3-contains-rect? (-> FlRect3 FlRect3 Boolean))
(define (flrect3-contains-rect? bb1 bb2)
  (cond
    [(empty-flrect3? bb2)  #t]
    [(empty-flrect3? bb1)  #f]
    [else
     (define-values (xmin1 ymin1 zmin1 xmax1 ymax1 zmax1) (nonempty-flrect3-values bb1))
     (define-values (xmin2 ymin2 zmin2 xmax2 ymax2 zmax2) (nonempty-flrect3-values bb2))
     (and (<= xmin1 xmin2) (<= xmax2 xmax1)
          (<= ymin1 ymin2) (<= ymax2 ymax1)
          (<= zmin1 zmin2) (<= zmax2 zmax1))]))

(: flrect3-longest-axis/center (-> Nonempty-FlRect3 (Values Index Flonum)))
(define (flrect3-longest-axis/center b)
  (define-values (xmin ymin zmin xmax ymax zmax) (nonempty-flrect3-values b))
  (define xsize (- xmax xmin))
  (define ysize (- ymax ymin))
  (define zsize (- zmax zmin))
  (cond [(>= xsize (max ysize zsize))  (values 0 (* 0.5 (+ xmin xmax)))]
        [(>= ysize (max xsize zsize))  (values 1 (* 0.5 (+ ymin ymax)))]
        [else                          (values 2 (* 0.5 (+ zmin zmax)))]))

(: nonempty-flrect3-transform (-> Nonempty-FlRect3 FlTransform3 Nonempty-FlRect3))
(define (nonempty-flrect3-transform b t)
  (define-values (xmin ymin zmin xmax ymax zmax) (nonempty-flrect3-values b))
  (assert
   (flv3rect (vector (flv4->pos (flt3apply t (flvector xmin ymin zmin 1.0)))
                     (flv4->pos (flt3apply t (flvector xmin ymin zmax 1.0)))
                     (flv4->pos (flt3apply t (flvector xmin ymax zmin 1.0)))
                     (flv4->pos (flt3apply t (flvector xmin ymax zmax 1.0)))
                     (flv4->pos (flt3apply t (flvector xmax ymin zmin 1.0)))
                     (flv4->pos (flt3apply t (flvector xmax ymin zmax 1.0)))
                     (flv4->pos (flt3apply t (flvector xmax ymax zmin 1.0)))
                     (flv4->pos (flt3apply t (flvector xmax ymax zmax 1.0)))))
   nonempty-flrect3?))

(: flrect3-transform (case-> (-> Nonempty-FlRect3 FlTransform3 Nonempty-FlRect3)
                             (-> FlRect3 FlTransform3 FlRect3)))
(define (flrect3-transform b t)
  (if (empty-flrect3? b)
      b
      (nonempty-flrect3-transform b t)))
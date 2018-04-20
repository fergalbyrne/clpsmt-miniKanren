(define s/declare-bito
  (lambda (b)
    (z/ `(declare-const ,b Bool))))

(define s/declareo
  (lambda (s)
    (z/ `(declare-const ,s (_ BitVec 3)))))

(define s/haso
  (lambda (p)
    (lambda (s b)
      (z/assert `(= ,s (ite ,b (bvor ,s ,p) (bvand ,s (bvnot ,p))))))))

(define s/hasnto
  (lambda (p)
    (lambda (s b)
      (z/assert `(= ,s (ite ,b (bvand ,s (bvnot ,p)) (bvor ,s ,p)))))))

(define s/chaso
  (lambda (p)
    (lambda (s)
      (z/assert `(= ,s (bvor ,s ,p))))))
(define s/chasnto
  (lambda (p)
    (lambda (s)
      (z/assert `(= ,s (bvand ,s (bvnot ,p)))))))

(define vec-neg 'bitvec-001)
(define s/has-nego (s/haso vec-neg))
(define s/hasnt-nego (s/hasnto vec-neg))
(define s/chas-nego (s/chaso vec-neg))
(define s/chasnt-nego (s/chasnto vec-neg))

(define vec-zero 'bitvec-010)
(define s/has-zeroo (s/haso vec-zero))
(define s/hasnt-zeroo (s/hasnto vec-zero))
(define s/chas-zeroo (s/chaso vec-zero))
(define s/chasnt-zeroo (s/chasnto vec-zero))

(define vec-pos 'bitvec-100)
(define s/has-poso (s/haso vec-pos))
(define s/hasnt-poso (s/hasnto vec-pos))
(define s/chas-poso (s/chaso vec-pos))
(define s/chasnt-poso (s/chasnto vec-pos))

(define vecs (list vec-neg vec-zero vec-pos))

(define s/iso
  (lambda (p)
    (lambda (s)
      (z/assert `(= ,s ,p)))))
(define s/is-nego
  (s/iso vec-neg))
(define s/is-zeroo
  (s/iso vec-zero))
(define s/is-poso
  (s/iso vec-pos))

(define s/uniono
  (lambda (s1 s2 so)
    (z/assert `(= (bvor ,s1 ,s2) ,so))))

(define s/is-bito
  (lambda (b)
    (conde
      ((z/assert `(= ,b ,vec-neg)))
      ((z/assert `(= ,b ,vec-zero)))
      ((z/assert `(= ,b ,vec-pos))))))

(define s/membero
  (lambda (s b)
    (fresh ()
      (z/assert `(= (bvand ,s ,b) ,b))
      (s/is-bito b))))

(define s/alphao
  (lambda (n s)
    (fresh ()
      (conde
        ((z/assert `(< ,n 0))
         (s/is-nego  s))
        ((z/assert `(= ,n 0))
         (s/is-zeroo s))
        ((z/assert `(> ,n 0))
         (s/is-poso  s))))))

;; For example,
;; {−,0}⊕{−}={−} and {−}⊕{+}={−,0,+}.
;; {−}⊗{+,0}={−,0} and  {−,+}⊗{0}={0}

(define s/plus-alphao
  (lambda (s1 s2 so)
    (conde
      ((s/is-zeroo s1)
       (z/assert `(= ,so ,s2)))
      ((s/is-zeroo s2)
       (z/assert `(= ,so ,s1)))
      ((s/is-nego s1)
       (s/is-nego s2)
       (s/is-nego so))
      ((s/is-poso s1)
       (s/is-poso s2)
       (s/is-poso so))
      ((s/is-nego s1)
       (s/is-poso s2)
       (z/assert `(= ,so bitvec-111)))
      ((s/is-poso s1)
       (s/is-nego s2)
       (z/assert `(= ,so bitvec-111))))))

(define s/containso
  (lambda (s1 s2)
    (z/assert `(= (bvor ,s1 ,s2) ,s1))))

(define s/pluso
  (lambda (s1 s2 so)
    (fresh ()
      (conde ((s/chas-zeroo s1)
              (s/containso so s2))
             ((s/chasnt-zeroo s1)))
      (conde ((s/chas-zeroo s2)
              (s/containso so s1))
             ((s/chasnt-zeroo s2)))
      (conde ((s/chas-nego s1)
              (s/chas-nego s2)
              (s/chas-nego so))
             ((s/chasnt-nego s1))
             ((s/chasnt-nego s2)))
      (conde ((s/chas-poso s1)
              (s/chas-poso s2)
              (s/chas-poso so))
             ((s/chasnt-poso s1))
             ((s/chasnt-poso s2)))
      (conde ((s/chas-nego s1)
              (s/chas-poso s2)
              (z/assert `(= ,so bitvec-111)))
             ((s/chasnt-nego s1))
             ((s/chasnt-poso s2)))
      (conde ((s/chas-poso s1)
              (s/chas-nego s2)
              (z/assert `(= ,so bitvec-111)))
             ((s/chasnt-poso s1))
             ((s/chasnt-nego s2))))))

(define (plus-alpha s1 s2)
  (define (from a b)
    (and (eq? a s1) (eq? b s2)))
  (define (set . xs)
    xs)
  (cond
    [(from '- '-)  (set '-)]
    [(from '-  0)  (set '-)]
    [(from '- '+)  (set '- '0 '+)]
    [(from '0  s2) (set s2)]
    [(from '+ '-)  (set '- '0 '+)]
    [(from '+  0)  (set '+)]
    [(from '+ '+)  (set '+)]))

(define to-bitvec
  (lambda (s)
    (string->symbol
     (string-append
      "bitvec-"
      (if (memq '+ s) "1" "0")
      (if (memq '0 s) "1" "0")
      (if (memq '- s) "1" "0")))))

(define flatten
  (lambda (xs)
    (cond ((null? xs) xs)
          ((atom? xs) (list xs))
          (else (append (flatten (car xs))
                        (flatten (cdr xs)))))))

(define (plus-abstract s1 s2)
  (to-bitvec
   (flatten
    (map
     (lambda (b1)
       (map
        (lambda (b2)
          (plus-alpha b1 b2))
        s2))
     s1))))

(define (comb xs)
  (if (null? xs) '(())
      (let ((r (comb (cdr xs))))
        (append r (map (lambda (s) (cons (car xs) s)) r)))))

(define (plus-table)
  (let ((r (comb '(- 0 +))))
    (apply
     append
     (map
      (lambda (s1)
        (map
         (lambda (s2)
           (list (to-bitvec s1) (to-bitvec s2)
                 (plus-abstract s1 s2)))
         r))
      r))))

;(plus-table)


(define s/plus-tableo
  (let ((table (plus-table)))
    (lambda (s1 s2 so)
      (define itero
        (lambda (es)
          (if (null? es)
              fail
              (let ((e (car es)))
                (conde
                  ((z/assert `(= ,(car e)   ,s1))
                   (z/assert `(= ,(cadr e)  ,s2))
                   (z/assert `(= ,(caddr e) ,so)))
                  ((z/assert `(or (not (= ,(car e)  ,s1))
                                  (not (= ,(cadr e) ,s2))))
                   (itero (cdr es))))))))
      (itero table))))

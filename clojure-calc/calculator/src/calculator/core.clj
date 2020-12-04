(ns calculator.core
  (:gen-class))
;; *** basic terms ***
;; TVM = time value of money
;; PV = present value of money
;; i = annual interest rate
;; n = number of payment periods per year
;; t = number of years
;; *** compound terms ***
;; r = i / n
;; N = n * t
;; *** financial functions ***
;; TVM = PV x ((1 + r)^N)
;; Discount Factor = (((1 + r)^N) -1) / (r(1 + r)^N)
;; Payments = Amount / Discount Factor
;; Payments = (principal * r) / (1 - (1 + r)^(-1 * N));


;; banker's rounding: <integer>.5 (i.e. 1.5, 14.5, etc) will be rounded up or down to the NEAREST EVEN number
;; this function applies the rounding to the last digit requested with "decimalDigits", decimalDigits = 0 returns a rounded integer
(defn banker-round [number, decimalDigits]
  ; add the required zeros for the user plus one for doing the rounding against
  ; add one extra zero to deal with float error... total of 2 extra zeros 
  (let [addedZeros (Math/pow 10 (+ decimalDigits 2))
  ; remove the extra zero we added to deal with float issues
        trunc (Math/round (* (* number addedZeros) 0.1))
        ; numbers ending in 5 are handled differently
        trunc (case (int (mod trunc 10))
                5 (case (mod (* trunc 0.1) 2)
    ; the last digit is known to be 5
    ; so (num * 0.1) % 2 == 0.5 for an even integer, 1.5 for an odd integer
                    1.5 (Math/ceil (* trunc 0.1)) ; something like 1.5 will always round UP to 2
                    0.5 (Math/floor (* trunc 0.1))) ; while 2.5 would round DOWN to 2
    ; normal up/down rounding for all other numbers
                (Math/round (* trunc 0.1))
  ; send the number back with the correct number of decimal digits
                )]
    (/ trunc (* addedZeros 0.01))))


;; calculate time value of money
(defn tvm [principal, interestRate, periodsPerYear, numberOfYears]
  (let [n (* periodsPerYear numberOfYears)
        r (/ interestRate periodsPerYear)]
    ; (banker-round (with-precision 50 :rounding HALF_EVEN (bigdec (* principal (Math/pow (+ 1 r) n)))) 2)
    (banker-round (* principal (Math/pow (+ 1 r) n)) 2)))


; calculate the balance across the life of a loan
; returns an object array with some data for each payment period
(defn calcBalance [balance payment interestRate periodsPerYear paymentNumber accInterest payTable]
    ; amortize the interest to calculate the payment's interest
  (let [paymentInterest (* (/ interestRate periodsPerYear) balance)
        accInterest (+ accInterest paymentInterest)
           ; calculate the balance after this payment
        endBalance (- balance (- payment paymentInterest))
        payTable (str payTable "{\"paymentNumber\":" paymentNumber ","
                      "\"startBalance\":" (banker-round balance 2) ","
                      "\"endBalance\":" (Math/abs (banker-round endBalance 2)) ","
                      "\"paymentPrincipal\":" (banker-round (- payment paymentInterest) 2) ","
                      "\"paymentInterest\":" (banker-round paymentInterest 2) ","
                      "\"accumulatedInterest\":" (banker-round accInterest 2) ","
                      "\"amountPaidToDate\":" (banker-round (* payment paymentNumber) 2) "}")]
    (if (> (banker-round endBalance 2) 0.0)
      (recur endBalance payment interestRate periodsPerYear (inc paymentNumber) accInterest (str payTable ",")) payTable)))


; calculate the loan amounts and payment table
(defn loan-calc [principal, interestRate, periodsPerYear, numberOfYears]
  ; calculate the periodic payment
  (let [n (* periodsPerYear numberOfYears)
        r (/ interestRate periodsPerYear)
        ;round the payment to induce a small amount of error (reduces full overpayment on final payment)
        payment (banker-round (/ (* principal r) (- 1 (Math/pow (+ 1 r) (* -1 n)))) 8)
        loanTotal (* payment periodsPerYear numberOfYears)
        paymentTable (calcBalance principal payment interestRate periodsPerYear 1 0 "[")]
    (str "{\"periodic payment\":" (banker-round payment 2) ",\"principal\":" (banker-round principal 2) ","
         "\"total paid\":" (banker-round loanTotal 2) ",\"interest paid\":" (banker-round (- loanTotal principal) 2) ","
         "\"payment table\":" paymentTable "]}")))


(defn -main
  ([] ; (println (tvm 100 0.036 12 1))
   (println (loan-calc 27200 0.036 12 1)))
  ([principal interestRate periodsPerYear numberOfYears]
   (let [principal (Float. principal)
         interestRate (Float. interestRate)
         periodsPerYear (Float. periodsPerYear)
         numberOfYears (Float. numberOfYears)]
     ;(println (tvm principal interestRate periodsPerYear numberOfYears))
     (println (loan-calc principal interestRate periodsPerYear numberOfYears)))))

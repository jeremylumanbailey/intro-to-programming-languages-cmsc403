;; run using
;; sbcl --load Assignment6.lisp


;; Inputs: nothing
;; Outputs list
(defun myList ()
    ;; Create list and return
   (list 4 `(7 22) "art" `("math" (8) 99) 100
   )
)

 

;; Inputs: nothing
;; Outputs: list of leapyears from 1800 to 2020
(defun leapYear ()
; Use labels for leap year calculation
(labels 
    ((listBuilder (year myList)

        ;; If year is past 2020, return list of leap years
        (cond ((<= 2021 year) myList)
            ;; Use leap year formula for conditions to check if not leap year
            ;; e.g 2100 is divisible by 4
            ;; and divisible by 100
            ;; but alnotso divisible by 400 
            ;; 2100 is not a leap year
            ((and 
                (= (mod year 4) 0)
                (= (mod year 100) 0)
                (/= (mod year 400) 0) 
                ) 
                (listBuilder (+ 4 year) myList)
            )
            ;; if year fails conditions, it is a leap year and is added to myList
            (1 (listBuilder (+ 4 year) (append myList (list year))))
        )
    ))
;; Build list using special ' operator
(listBuilder 1800 '())
)
)


;; Inputs: two lists
;; Outputs: single combind list with no dublicates
(defun union- (myList1 myList2)
    ;; Concatenate both list using append and remove duplicates using built in functions
   (remove-duplicates (append myList1 myList2)
   )
)


;; EDIT: studying for exam I think I realized that this isn't actually tail recursive but don't
;; have time to fix and study for exam, so I will submit this as is. 
;; Inputs: list that we want average of and optional arguments to assist in calculation
;; Outputs: average of all elements in list 
(defun avg (aList &optional (totalElements (list-length aList)) (sum 0) )
    ;; Check for termination condition for tail recursion 
   (if (/= (list-length aList) 0)
        ;; Continuing incrementing sum based on first element
        (avg (rest aList) totalElements 
            (+ sum (first aList)
            )
        ) 
        ;; Else statement: return average
        (/ sum totalElements)
   )
)

;; Input: any single datatype
;; Output: boolean true or false
(defun isType (dataType)
    ;; Pretty straight forward, just use lambda with the typep to return the data's type
    (lambda (x) (typep x dataType))
)


(defun taxCalculator (limit rate values &optional finalList)
    ;; If value is 0, return the final list
    (cond ((= (length values) 0) finalList)
        ;; Check if the value is more than the limit, appending rate
        ;; multiplied by the value to the final list
        (
            (< limit (first values)) 
                (taxCalculator limit rate (rest values) 
                    (append finalList 
                        (list (* rate (first values))
                        )
                    )
                )
            )
        ;; If the value is less or equal to limit then we call taxCollector and append to finalList
        (1 (taxCalculator limit rate (rest values) (append finalList (list (first values)))
            )
        )
  )
)

;; Input: a function and list
;; Output: list
(defun clean (aFunc aList &optional (stupidList '()))

    (cond 
        ;; Check for an empty list
        (  (= (list-length aList) 0) stupidList)
        ;; If the current element is a list, run clean on the sublist
        ( (listp (car aList) )  (append stupidList(list (clean aFunc (first aList))  )  (clean aFunc (rest aList))   )     )
        ;; Call the function and check it's true, if it is then make another cell
        (  (funcall aFunc (first aList))  (clean aFunc (rest aList) (append stupidList(list (first aList) ) ) )  )
        ;; Continue to other element
        ( 1  (clean aFunc (rest aList) stupidList)   )          
    )
)


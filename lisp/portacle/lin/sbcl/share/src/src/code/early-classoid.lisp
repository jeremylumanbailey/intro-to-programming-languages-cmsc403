;;;; This file contains structures and functions for the maintenance of
;;;; basic information about defined types. Different object systems
;;;; can be supported simultaneously.

;;;; This software is part of the SBCL system. See the README file for
;;;; more information.
;;;;
;;;; This software is derived from the CMU CL system, which was
;;;; written at Carnegie Mellon University and released into the
;;;; public domain. The software is in the public domain and is
;;;; provided with absolutely no warranty. See the COPYING and CREDITS
;;;; files for more information.

(in-package "SB-KERNEL")

;;;; DEFSTRUCT-DESCRIPTION

;;; The DEFSTRUCT-DESCRIPTION structure holds compile-time information
;;; about a structure type.
;;; It is defined prior to LAYOUT because a LAYOUT-INFO slot
;;; is declared to hold a DEFSTRUCT-DESCRIPTION.
(def!struct (defstruct-description
             (:conc-name dd-)
             (:copier nil)
             #-sb-xc-host (:pure t)
             (:constructor make-defstruct-description (null-lexenv-p name)))
  ;; name of the structure
  (name (missing-arg) :type symbol :read-only t)
  ;; documentation on the structure
  (doc nil :type (or string null))
  ;; prefix for slot names. If NIL, none.
  (conc-name nil :type (or string null))
  ;; All the :CONSTRUCTOR specs and posssibly an implied constructor,
  ;; keyword constructors first, then BOA constructors. NIL if none.
  (constructors () :type list)
  ;; True if the DEFSTRUCT appeared in a null lexical environment.
  (null-lexenv-p nil :type boolean :read-only t) ; the safe default is NIL
  ;; name of copying function
  (copier-name nil :type symbol)
  ;; name of type predicate
  (predicate-name nil :type symbol)
  ;; the arguments to the :INCLUDE option, or NIL if no included
  ;; structure
  (include nil :type list)
  ;; properties used to define structure-like classes with an
  ;; arbitrary superclass and that may not have STRUCTURE-CLASS as the
  ;; metaclass. Syntax is:
  ;;    (superclass-name metaclass-name metaclass-constructor)
  (alternate-metaclass nil :type list)
  ;; a list of DEFSTRUCT-SLOT-DESCRIPTION objects for all slots
  ;; (including included ones)
  (slots () :type list)
  ;; a list of (NAME . INDEX) pairs for accessors of included structures
  (inherited-accessor-alist () :type list)
  ;; number of elements including the layout itself (minimum=1)
  (length 0 :type index)
  ;; General kind of implementation.
  (type 'structure :type (member structure vector list
                                 funcallable-structure))

  ;; The next three slots are for :TYPE'd structures (which aren't
  ;; classes, DD-CLASS-P = NIL)
  ;;
  ;; vector element type
  (element-type t)
  ;; T if :NAMED was explicitly specified, NIL otherwise
  (named nil :type boolean)
  ;; any INITIAL-OFFSET option on this direct type
  (offset nil :type (or index null))

  ;; which :PRINT-mumble option was given, if either was.
  (print-option nil :type (member nil :print-function :print-object))
  ;; the argument to the PRINT-FUNCTION or PRINT-OBJECT option.
  ;; NIL if the option was given with no argument.
  (printer-fname nil :type (or cons symbol))

  ;; the value of the :PURE option, used by cheneygc when purifying.
  ;; This is true if objects of this class are never modified to
  ;; contain dynamic pointers in their slots or constant-like
  ;; substructure (and hence can be copied into read-only space by
  ;; PURIFY).
  ;; This is only meaningful if DD-CLASS-P = T.
  (pure nil :type (member t nil)))
#-sb-fluid (declaim (freeze-type defstruct-description))
(!set-load-form-method defstruct-description (:host :xc :target))

;;;; basic LAYOUT stuff

;;; Note: This bound is set somewhat less than MOST-POSITIVE-FIXNUM
;;; in order to guarantee that several hash values can be added without
;;; overflowing into a bignum.
(defconstant layout-clos-hash-limit (1+ (ash sb-xc:most-positive-fixnum -3))
  "the exclusive upper bound on LAYOUT-CLOS-HASH values")
;; This must be DEF!TYPE and not just DEFTYPE because access to slots
;; of a layout occur "before" the structure definition is made in the
;; run-the-xc pass, and the source-transform of a slot accessor
;; wraps (TRULY-THE <type> ...) around %INSTANCE-REF,
;; so <type> had best be defined at that point.
(def!type layout-clos-hash () `(integer 0 ,layout-clos-hash-limit))
(declaim (ftype (sfunction (t) layout-clos-hash) randomish-layout-clos-hash))

;;; Careful here: if you add more bits, then adjust the bit packing for
;;; 64-bit layouts which also store LENGTH + DEPTHOID in the same word.
;;; When testing these, you usually want to use LAYOUT-%BITS rather than
;;; LAYOUT-FLAGS, because the compiler will stupidly "unpack" the
;;; flags by masking out the stuff that aren't the "bits" and then
;;; mask again.
(defconstant +structure-layout-flag+  #b0001)
(defconstant +pcl-object-layout-flag+ #b0010)
(defconstant +condition-layout-flag+  #b0100)
(defconstant +pathname-layout-flag+   #b1000) ; ORed with structure-layout-flag

;;; The LAYOUT structure is pointed to by the first cell of instance
;;; (or structure) objects. It represents what we need to know for
;;; type checking and garbage collection. Whenever a class is
;;; incompatibly redefined, a new layout is allocated. If two object's
;;; layouts are EQ, then they are exactly the same type.
;;;
;;; *** IMPORTANT ***
;;;
;;; If you change the slots of LAYOUT, you need to alter genesis as
;;; well, since the initialization of layout slots is hardcoded there.
;;;
;;; FIXME: ...it would be better to automate this, of course...

;;; 64-bit layout %BITS slot:
;;;
;;; | 4 bytes  | 28 bits | 4 bits |
;;; +----------+---------+--------+
;;;  depthoid    length     flags
;;;
;;; depthoid is stored as a tagged fixnum in its 4 byte field.
;;; I suspect that by further limiting the max depthoid and length
;;; we could shove the random CLOS-HASH into some unused bits while
;;; utilizing the entire 64-bit word as the random bit string for hashing.
;;; Checking for an invalid layout would need to mask out the
;;; length, depthoid, and flags since they have to stay correct at all times.
;;;
;;; 32-bit layout %BITS slot:
;;;
;;; | 2 bytes | 2 bytes |
;;; +---------+---------+
;;;  depthoid    length
;;; (FLAGS will remain as a separate slot)

;;; 32-bit is not done yet. Three slots are still used, instead of two.

(def!struct (layout
             #+64-bit
             ;; Accept a specific subset of keywords
             (:constructor %make-layout (clos-hash classoid %bits
                                         &key inherits bitmap info invalid
                                           depth2-ancestor depth3-ancestor depth4-ancestor))
             #-64-bit
             (:constructor make-layout (clos-hash classoid
                                        &key flags invalid inherits depthoid length info bitmap
                                          depth2-ancestor depth3-ancestor depth4-ancestor))
             (:copier nil))

  ;; A packed field containing the DEPTHOID, LENGTH, and FLAGS
  #+64-bit (%bits 0 :type (signed-byte #.sb-vm:n-word-bits))

  ;; one +something-LAYOUT-FLAG+ bit or none of them
  #-64-bit (flags 0 :type fixnum :read-only nil)

  ;; a pseudo-random hash value for use by CLOS.
  (clos-hash (missing-arg) :type layout-clos-hash) ; this no longer defaults to a random number
  ;; the class that this is a layout for
  (classoid (missing-arg) :type classoid)
  ;; The value of this slot can be:
  ;;   * :UNINITIALIZED if not initialized yet;
  ;;   * NIL if this is the up-to-date layout for a class; or
  ;;   * T if this layout has been invalidated (by being replaced by
  ;;     a new, more-up-to-date LAYOUT).
  ;;   * something else (probably a list) if the class is a PCL wrapper
  ;;     and PCL has made it invalid and made a note to itself about it
  (invalid :uninitialized :type (or cons (member nil t :uninitialized)))
  ;; the layouts for all classes we inherit. If hierarchical, i.e. if
  ;; DEPTHOID >= 0, then these are ordered by ORDER-LAYOUT-INHERITS
  ;; (least to most specific), so that each inherited layout appears
  ;; at its expected depth, i.e. at its LAYOUT-DEPTHOID value.
  ;;
  ;; Remaining elements are filled by the non-hierarchical layouts or,
  ;; if they would otherwise be empty, by copies of succeeding layouts.
  (inherits #() :type simple-vector)
  ;; If inheritance is not hierarchical, this is -1. If inheritance is
  ;; hierarchical, this is the inheritance depth, i.e. (LENGTH INHERITS).
  ;; Note:
  ;;  (1) This turns out to be a handy encoding for arithmetically
  ;;      comparing deepness; it is generally useful to do a bare numeric
  ;;      comparison of these depthoid values, and we hardly ever need to
  ;;      test whether the values are negative or not.
  ;;  (2) This was called INHERITANCE-DEPTH in classic CMU CL. It was
  ;;      renamed because some of us find it confusing to call something
  ;;      a depth when it isn't quite.
  #-64-bit (depthoid -1 :type layout-depthoid)
  ;; the number of top level descriptor cells in each instance
  ;; For [FUNCALLABLE-]STANDARD-OBJECT instances, this is the slot vector
  ;; length, not the primitive object length.
  ;; I tried making a structure of this many slots, and the compiler blew up;
  ;; so it's fair to say this limit is sufficient for practical purposes,
  ;; Let's be consistent here between the two choices of word size.
  #-64-bit (length 0 :type layout-length) ; smaller than SB-INT:INDEX
  ;; If this layout has some kind of compiler meta-info, then this is
  ;; it. If a structure, then we store the DEFSTRUCT-DESCRIPTION here.
  (info nil :type (or null defstruct-description))
  ;; Map of raw slot indices.
  (bitmap +layout-all-tagged+ :type layout-bitmap)
  ;; Per-slot comparator for implementing EQUALP.
  (equalp-tests #() :type simple-vector)
  ;; If this layout is for an object of metatype STANDARD-CLASS,
  ;; these are the EFFECTIVE-SLOT-DEFINITION metaobjects.
  (slot-list nil :type list)
  ;; Information about slots in the class to PCL: this provides fast
  ;; access to slot-definitions and locations by name, etc.
  ;; See MAKE-SLOT-TABLE in pcl/slots-boot.lisp for further details.
  (slot-table #(1 nil) :type simple-vector)
  ;; inherited layouts or 0, only pertinent to structure classoids.
  ;; There is no need to store the layout at depths 0 or 1
  ;; since they're predetermined to be T and STRUCTURE-OBJECT.
  ;; These 3 slots cause the length of a layout to be exactly 16 words
  ;; with compact-instance-header, which avoids having to change some
  ;; logic in 'immobile-space' that assumes this alignment constraint.
  (depth2-ancestor 0)
  (depth3-ancestor 0)
  (depth4-ancestor 0))
(declaim (freeze-type layout))

#+64-bit
(progn
(defmacro pack-layout-bits (depthoid length flags)
  `(logior (ash ,(or depthoid -1) (+ 32 sb-vm:n-fixnum-tag-bits))
           (ash ,(or length 0) 4)
           ,(or flags 0)))
(defmacro unpack-layout-bits (bits field)
  (ecase field
    (:depthoid `(ash ,bits (- -32 sb-vm:n-fixnum-tag-bits)))
    (:length   `(ldb (byte 28 4) ,bits))
    (:flags    `(ldb (byte 4 0) ,bits))))

(defmacro make-layout (clos-hash classoid &rest rest &key depthoid length flags &allow-other-keys)
  (setq rest (copy-list rest))
  (remf rest :depthoid)
  (remf rest :length)
  (remf rest :flags)
  `(%make-layout ,clos-hash ,classoid (pack-layout-bits ,depthoid ,length ,flags) ,@rest))

(declaim (inline layout-length layout-flags))
#+sb-xc-host
(defun layout-depthoid (layout)
  (unpack-layout-bits (layout-%bits layout) :depthoid))
(defun layout-length (layout)
  (unpack-layout-bits (layout-%bits layout) :length))
(defun layout-flags (layout)
  (unpack-layout-bits (layout-%bits layout) :flags))

(declaim (inline (setf layout-depthoid) (setf layout-length) (setf layout-flags)))
(defun (setf layout-depthoid) (val layout)
  (declare (type (integer -1 #x7fff) val))
  (setf (layout-%bits layout) (logior (ash val (+ 32 sb-vm:n-fixnum-tag-bits))
                                      (ldb (byte 32 0) (layout-%bits layout)))))
(defun (setf layout-length) (val layout)
  (setf (unpack-layout-bits (layout-%bits layout) :length) val))
(defun (setf layout-flags) (val layout)
  (setf (unpack-layout-bits (layout-%bits layout) :flags) val))
) ; end PROGN

#-64-bit
(progn
(defmacro layout-%bits (x) `(layout-flags ,x))
)

(declaim (inline layout-for-std-class-p))
(defun layout-for-std-class-p (x)
  (logtest (layout-%bits x) +pcl-object-layout-flag+))

(declaim (inline sb-fasl:dumpable-layout-p))
(defun sb-fasl:dumpable-layout-p (x)
  (and (typep x 'layout) (not (layout-for-std-class-p x))))

;;; The CLASSOID structure is a supertype of all classoid types.  A
;;; CLASSOID is also a CTYPE structure as recognized by the type
;;; system.  (FIXME: It's also a type specifier, though this might go
;;; away as with the merger of SB-PCL:CLASS and CL:CLASS it's no
;;; longer necessary)
(def!struct (classoid
             (:include ctype
                       (class-info (type-class-or-lose 'classoid)))
             (:constructor nil)
             (:copier nil)
             #-no-ansi-print-object
             (:print-object
              (lambda (class stream)
                (let ((name (classoid-name class)))
                  (print-unreadable-object (class stream
                                                  :type t
                                                  :identity (not name))
                    (format stream
                            ;; FIXME: Make sure that this prints
                            ;; reasonably for anonymous classes.
                            "~:[anonymous~;~:*~S~]~@[ (~(~A~))~]"
                            name
                            (classoid-state class))))))
             #-sb-xc-host (:pure nil))
  ;; the value to be returned by CLASSOID-NAME.
  (name nil :type symbol)
  ;; the current layout for this class, or NIL if none assigned yet
  (layout nil :type (or layout null))
  ;; How sure are we that this class won't be redefined?
  ;;   :READ-ONLY = We are committed to not changing the effective
  ;;                slots or superclasses.
  ;;   :SEALED    = We can't even add subclasses.
  ;;   NIL        = Anything could happen.
  (state nil :type (member nil :read-only :sealed))
  ;; direct superclasses of this class. Always NIL for CLOS classes.
  (direct-superclasses () :type list)
  ;; Definition location
  ;; Not used for standard-classoid, because pcl has its own mechanism.
  (source-location nil)
  ;; representation of all of the subclasses (direct or indirect) of
  ;; this class. This is NIL if no subclasses or not initalized yet;
  ;; otherwise, it's an EQ hash-table mapping CLASSOID objects to the
  ;; subclass layout that was in effect at the time the subclass was
  ;; created.
  (subclasses nil :type (or null hash-table))
  ;; the PCL class (= CL:CLASS, but with a view to future flexibility
  ;; we don't just call it the CLASS slot) object for this class, or
  ;; NIL if none assigned yet
  (pcl-class nil))

(defun layout-classoid-name (x)
  (classoid-name (layout-classoid x)))

;;; A helper to make classoid (and named-type) hash values stable.
;;; For other ctypes, generally improve the randomness of the hash.
;;; (The host uses at most 21 bits of randomness. See CTYPE-RANDOM)
#+sb-xc
(defun !improve-ctype-hash (obj type-class-name)
  (let ((hash (case type-class-name
                (named
                 (interned-type-hash (named-type-name obj) 'named))
                (classoid
                 (interned-type-hash (classoid-name obj)))
                (t
                 (interned-type-hash))))
        ;; Preserve the interned-p and type=-optimization bits
        ;; by affecting only bits under the ctype-hash-mask.
        ;; Upper 5 hash bits might be an index into SAETP array
        ;; (if this ctype is exactly a type to which upgrade occurs)
        (nbits (- (integer-length +ctype-hash-mask+)
                  +ctype-saetp-index-bits+)))
    (macrolet ((slot-index ()
                 (let* ((dd (find-defstruct-description 'ctype))
                        (dsd (find 'hash-value (dd-slots dd) :key #'dsd-name)))
                   (dsd-index dsd))))
      (setf (%instance-ref obj (slot-index))
            (dpb hash (byte nbits 0) (type-hash-value obj)))))
  obj)

;;;; object types to represent classes

;;; An UNDEFINED-CLASSOID is a cookie we make up to stick in forward
;;; referenced layouts. Users should never see them.
(def!struct (undefined-classoid
             (:include classoid)
             (:copier nil)
             (:constructor make-undefined-classoid (name))))

;;; BUILT-IN-CLASS is used to represent the standard classes that
;;; aren't defined with DEFSTRUCT and other specially implemented
;;; primitive types whose only attribute is their name.
;;;
;;; Some BUILT-IN-CLASSes have a TRANSLATION, which means that they
;;; are effectively DEFTYPE'd to some other type (usually a union of
;;; other classes or a "primitive" type such as NUMBER, ARRAY, etc.)
;;; This translation is done when type specifiers are parsed. Type
;;; system operations (union, subtypep, etc.) should never encounter
;;; translated classes, only their translation.
(def!struct (built-in-classoid (:include classoid)
                               (:copier nil)
                               (:constructor !make-built-in-classoid))
  ;; the type we translate to on parsing. If NIL, then this class
  ;; stands on its own; or it can be set to :INITIALIZING for a period
  ;; during cold-load.
  (translation nil :type (or ctype (member nil :initializing))))

(def!struct (condition-classoid (:include classoid)
                                (:copier nil)
                                (:constructor %make-condition-classoid
                                    (hash-value name)))
  ;; list of CONDITION-SLOT structures for the direct slots of this
  ;; class
  (slots nil :type list)
  ;; list of CONDITION-SLOT structures for all of the effective class
  ;; slots of this class
  (class-slots nil :type list)
  ;; report function or NIL
  (report nil :type (or function null))
  ;; list of specifications of the form
  ;;
  ;;   (INITARG INITFORM THUNK)
  ;;
  ;; where THUNK, when called without arguments, returns the value for
  ;; INITARG.
  (direct-default-initargs () :type list)
  ;; class precedence list as a list of CLASS objects, with all
  ;; non-CONDITION classes removed
  (cpl () :type list)
  ;; a list of all the effective instance allocation slots of this
  ;; class that have a non-constant initform or default-initarg.
  ;; Values for these slots must be computed in the dynamic
  ;; environment of MAKE-CONDITION.
  (hairy-slots nil :type list))
(defun make-condition-classoid (&key name)
  (%make-condition-classoid (interned-type-hash name) name))

;;;; classoid namespace

;;; We use an indirection to allow forward referencing of class
;;; definitions with load-time resolution.
(def!struct (classoid-cell
             (:copier nil)
             (:constructor make-classoid-cell (name &optional classoid))
             #-no-ansi-print-object
             (:print-object (lambda (s stream)
                              (print-unreadable-object (s stream :type t)
                                (prin1 (classoid-cell-name s) stream)))))
  ;; Name of class we expect to find.
  (name nil :type symbol :read-only t)
  ;; Classoid or NIL if not yet defined.
  (classoid nil :type (or classoid null))
  ;; PCL class, if any
  (pcl-class nil))
(declaim (freeze-type classoid-cell))
(!set-load-form-method classoid-cell (:xc :target)
  (lambda (self env)
    (declare (ignore env))
    `(find-classoid-cell ',(classoid-cell-name self) :create t)))

(defun find-classoid-cell (name &key create)
  (let ((real-name (uncross name)))
    (cond ((info :type :classoid-cell real-name))
          (create
           (get-info-value-initializing :type :classoid-cell real-name
                                        (make-classoid-cell real-name))))))

;;; Return the classoid with the specified NAME. If ERRORP is false,
;;; then NIL is returned when no such class exists.
(defun find-classoid (name &optional (errorp t))
  (declare (type symbol name))
  (let ((cell (find-classoid-cell name)))
    (cond ((and cell (classoid-cell-classoid cell)))
          (errorp
           (error 'simple-type-error
                  :datum nil
                  :expected-type 'class
                  :format-control "Class not yet defined: ~S"
                  :format-arguments (list name))))))

;;;; PCL stuff

;;; the CLASSOID that we use to represent type information for
;;; STANDARD-CLASS and FUNCALLABLE-STANDARD-CLASS.  The type system
;;; side does not need to distinguish between STANDARD-CLASS and
;;; FUNCALLABLE-STANDARD-CLASS.
(def!struct (standard-classoid (:include classoid)
                               (:copier nil)
                               (:constructor make-standard-classoid))
  old-layouts)
;;; a metaclass for classes which aren't standardlike but will never
;;; change either.
(def!struct (static-classoid (:include classoid)
                             (:copier nil)
                             (:constructor make-static-classoid)))

(declaim (freeze-type built-in-classoid condition-classoid
                      standard-classoid static-classoid))

(in-package "SB-C")

;;; layout for this type being used by the compiler
(define-info-type (:type :compiler-layout)
  :type-spec (or layout null)
  :default (lambda (name)
             (awhen (find-classoid name nil) (classoid-layout it))))

(eval-when (#-sb-xc :compile-toplevel :load-toplevel :execute)
(defun ftype-from-fdefn (name)
  (declare (ignorable name))
  ;; Again [as in (DEFINE-INFO-TYPE (:FUNCTION :TYPE) ...)] it's
  ;; not clear how to generalize the FBOUNDP expression to the
  ;; cross-compiler. -- WHN 19990330
  #+sb-xc-host
  (specifier-type 'function)
  #-sb-xc-host
  (let* ((fdefn (sb-kernel::find-fdefn name))
         (fun (and fdefn (fdefn-fun fdefn))))
    (if fun
        (handler-bind ((style-warning #'muffle-warning))
          (specifier-type (sb-impl::%fun-type fun)))
        (specifier-type 'function)))))

;;; The parsed or unparsed type for this function, or the symbol :GENERIC-FUNCTION.
;;; Ordinarily a parsed type is stored. Only if the parsed type contains
;;; an unknown type will the original specifier be stored; we attempt to reparse
;;; on each lookup, in the hope that the type becomes known at some point.
;;; If :GENERIC-FUNCTION, the info is recomputed from methods at the time of lookup
;;; and stored back. Method redefinition resets the value to :GENERIC-FUNCTION.
(define-info-type (:function :type)
  :type-spec (or ctype (cons (eql function)) (member :generic-function))
  :default #'ftype-from-fdefn)

(defun summarize-layouts ()
  (let ((prev -1))
    (dolist (layout (sort (loop for v being each hash-value
                                of (classoid-subclasses (find-classoid 't))
                                collect v)
                          #'< :key #'sb-kernel::layout-flags))
      (let ((flags (sb-kernel::layout-flags layout)))
        (unless (= flags prev)
          (format t "Layout flags = ~d~%" flags)
          (setq prev flags)))
      (format t "  ~a~%" layout))))

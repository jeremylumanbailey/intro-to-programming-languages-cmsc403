;;; This file contains the MIPS specific runtime stuff.
;;;
(in-package "SB-VM")


#-sb-xc-host
(defun machine-type ()
  "Returns a string describing the type of the local machine."
  "MIPS")

;;;; FIXUP-CODE-OBJECT

(defconstant-eqx +fixup-kinds+ #(:absolute :jmp :lui :addi) #'equalp)
(!with-bigvec-or-sap
(defun fixup-code-object (code offset value kind flavor)
  (declare (type index offset))
  (declare (ignore flavor))
  (unless (zerop (rem offset sb-assem:+inst-alignment-bytes+))
    (error "Unaligned instruction?  offset=#x~X." offset))
  (let ((sap (code-instructions code)))
    (ecase kind
       (:absolute
        (setf (sap-ref-32 sap offset) value))
       (:jump
        (aver (zerop (ash value -28)))
        (setf (ldb (byte 26 0) (sap-ref-32 sap offset))
              (ash value -2)))
       (:lui
        (setf (ldb (byte 16 0) (sap-ref-32 sap offset))
              (ash (1+ (ash value -15)) -1)))
       (:addi
        (setf (ldb (byte 16 0) (sap-ref-32 sap offset))
              (ldb (byte 16 0) value)))))
  nil))


#-sb-xc-host (progn

(define-alien-routine ("os_context_bd_cause" context-bd-cause-int)
    unsigned-int
  (context (* os-context-t) :in))

;;; This is like CONTEXT-REGISTER, but returns the value of a float
;;; register. FORMAT is the type of float to return.

;;; FIXME: Whether COERCE actually knows how to make a float out of a
;;; long is another question. This stuff still needs testing.
(define-alien-type os-context-register-t unsigned-long-long)
(define-alien-routine ("os_context_fpregister_addr" context-float-register-addr)
    (* os-context-register-t)
  (context (* os-context-t) :in)
  (index int :in))

(defun context-float-register (context index format)
  (declare (type (alien (* os-context-t)) context))
  (let ((addr (context-float-register-addr context index)))
    (declare (type (alien (* os-context-register-t)) addr))
    (coerce (deref addr) format)))

(defun %set-context-float-register (context index format new)
  (declare (type (alien (* os-context-t)) context))
  (let ((addr (context-float-register-addr context index)))
    (declare (type (alien (* os-context-register-t)) addr))
    (setf (deref addr) (coerce new format))))

(define-alien-routine
    ("arch_get_fp_control" floating-point-modes) unsigned-int)

(define-alien-routine
    ("arch_set_fp_control" %floating-point-modes-setter) void (fp unsigned-int :in))

(defun (setf floating-point-modes) (val) (%floating-point-modes-setter val))

;;; Given a signal context, return the floating point modes word in
;;; the same format as returned by FLOATING-POINT-MODES.
(define-alien-routine ("os_context_fp_control" context-floating-point-modes)
    unsigned-int
  (context (* os-context-t) :in))

(defun internal-error-args (context)
  (declare (type (alien (* os-context-t)) context))
  (let* ((pc (context-pc context))
         (cause (context-bd-cause-int context))
         ;; KLUDGE: This exposure of the branch delay mechanism hurts.
         (offset (if (logbitp 31 cause) 4 0))
         (trap-number (ldb (byte 8 6) (sap-ref-32 pc offset))))
    (declare (type system-area-pointer pc))
    (sb-kernel::decode-internal-error-args (sap+ pc (+ offset 4)) trap-number)))
) ; end PROGN

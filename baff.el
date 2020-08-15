;;; -*- lexical-binding: t; -*-
;;;
;;; baff.el --- Create a byte array from a file

(require 'f)

(defgroup baff nil
  "Make a byte array from a file")

(defcustom baff-header-function '(lambda (filename contents)
                                   (insert "// file   : " filename "\n"
                                           "// sha256 : "
                                           (secure-hash 'sha256 contents)
                                           "\n\nstd::array<uint8_t,"
                                           (number-to-string (length contents))
                                           "> bytes = {\n"))
  "Function to run before any bytes are inserted."
  :group 'baff)

(defcustom baff-footer-function '(lambda (filename contents) (insert "\n};"))
  "Function to run after all bytes have been inserted."
  :group 'baff)

(defcustom baff-indent-function '(lambda () (insert "    "))
  "Function to indent each line."
  :group 'baff)

(defcustom baff-bytes-per-line 16
  "Number of bytes per line before a line break."
  :group 'baff)

(defun baff (arg)
  (interactive "FFile to insert: ")
  (if (not (f-file-p arg))
      (error "File open error"))
  (let* ((unibytes (f-read-bytes arg))
         (bytes (string-to-list unibytes))
         (count 0))
    (switch-to-buffer (get-buffer-create "*baff*"))
    (erase-buffer)
    (funcall baff-header-function arg unibytes)
    (funcall baff-indent-function)
    (cl-loop for i in bytes do
             (setq count (1+ count))
             (insert (format "0x%02x" i) (if (= count (length bytes)) "" ","))
             (when (= (% count baff-bytes-per-line) 0)
               (insert "\n")
               (funcall baff-indent-function)))
  (funcall baff-footer-function arg unibytes))
  t)

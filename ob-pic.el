;;; ob-pic.el --- Org babel functions for pic language

;; Copyright (C) 2024  Daniel E. Doherty

;; Author: Daniel E. Doherty <ded-obpic@ddoherty.net>
;; Keywords: org, babel, pic
;; Version: 1.0.0
;;
;;; Commentary:
;;
;; Org-Babel support for evaluating pic source code.
;;
;; For usage information on this package, see https://github.com/ddoherty03/ob-pic

;; For information on pic see https://pikchr.org/home/uv/pic.pdf and
;;   on gpic at https://pikchr.org/home/uv/gpic.pdf
;;
;; The program actually used to generate the output is pic2plot, which is part
;; of the GNU plotutils collection of programs.  Thus, you must have it
;; installed on your system in order for this to work.
;;
;; On ubuntu, you can install with `apt install plotutils`; on arch linux, do
;; something like `pacman -Sy plotutils`.
;;
;; This means that pic differs from most standard org-babel languages in that
;;
;; 1) there is no such thing as a "session" in pic
;;
;; 2) we are generally only going to return results of type "file"
;;
;; 3) we are adding the "file" and "cmdline" header arguments
;;
;; 4) there are no variables (at least for now)
;;
;; 5) one of the command line arguments is "-T <type>" where <type> is one of
;;    "X", "png", "pnm", "gif", "svg", "ai", "ps", "cgm", "fig", "pcl",
;;    "hpgl", "regis", "tek", and "meta".  By default, this implementation
;;    assumes an output type of "png".  If you use "X", it will pop up an X
;;    window with the graph displayed.
;;
;;; Code:
;;

;; -*- lexical-binding: t; -*-

(require 'ob)
(require 'ob-eval)

(defvar org-babel-default-header-args:pic
  '((:results . "file") (:exports . "results"))
  "Default arguments for evaluating a pic2plot source block.")

(defun org-babel-execute:pic (body params)
  "Execute a block of pic code from BODY with PARAMS from org-babel.
This function is called by `org-babel-execute-src-block'."
  (let* ((user-cmdline (or (cdr (assq :cmdline params)) ""))
         ;; Match "-T" followed by one or more spaces and then "X"
         (is-x-output (string-match-p "-T[[:space:]]+X" user-cmdline))
         (outfile (if is-x-output
                      nil
                    (or (cdr (assq :file params))
                        (error "You must specify a :file header argument for non-X output types"))))
         ;; Ensure -T png is included in the cmdline unless overridden
         (cmdline (if (string-match-p "-T" user-cmdline)
                      user-cmdline
                    (concat "-T png " user-cmdline)))
         (infile (org-babel-temp-file "pic-"))
         (cmd (if is-x-output
                  ;; Append 'read' to keep the process open
                  (format "pic2plot %s %s; read"
                          cmdline
                          (shell-quote-argument infile))
                ;; (format "pic2plot %s %s"
                ;;           cmdline
                ;;           (shell-quote-argument infile))
                  ;; (format "pic2plot %s %s"
                  ;;         cmdline
                  ;;         (shell-quote-argument infile))
                (format "pic2plot %s %s > %s"
                        cmdline
                        (shell-quote-argument infile)
                        (shell-quote-argument outfile)))))
    ;; Write the body with .PS/.PE tags to the input file
    (with-temp-file infile
      (insert (format ".PS\n%s\n.PE\n" body)))
    (message "Running command: %s" cmd)
    ;; Execute the command
    (if is-x-output
        ;; Non-blocking execution for X output
        (start-process-shell-command "pic2plot" nil cmd)
      ;; Blocking execution for file-based outputs
      (org-babel-eval cmd ""))
    ;; Return nil if the output is handled as a side effect
    nil))

(defun org-babel-prep-session:pic (_session _params)
  "Return an error because pic2plot does not support sessions."
  (error "Language 'pic' does not support sessions"))

(add-to-list 'org-babel-tangle-lang-exts '("pic" . "pic"))

(provide 'ob-pic)
;;; ob-pic.el ends here

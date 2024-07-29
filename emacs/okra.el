;;; okra.el --- Generate Tarides Okra reports -*- lexical-binding: t; -*-

;; Authors: Puneeth Chaganti <puneeth@tarides.com>,
;;          Nick Barnes <nick@tarides.com>,
;;          Tim McGilchrist <tim@tarides.com>
;; Keywords: okra
;; Version: 0.1
;; Homepage: https://github.com/tarides/okra
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.

;;; Commentary:
;; Generate Okra reports from Emacs
;;
;; Example configuration using use-package with custom var overrides
;; and keybindings.
;;
;; (require 'okra)
;; (use-package okra
;;   :custom
;;   (okra-tarides-admin-repo "~/projects/tarides/tarides-admin")
;;   (okra-username "tmcgilchrist")
;;   (okra-switch "/Users/tsmc/code/ocaml/okra")
;;   :bind (("C-c C-w" . okra-last-week)))
;;

;;; Code:

(require 'calendar)
(require 'magit)
(require 'flycheck)

(defgroup okra nil
  "Customization group for ‘okra’."
  :group 'okra)

(defcustom okra-tarides-admin-repo "~/projects/tarides/admin"
  "Path to the Tarides admin repo."
  :type 'string
  :group 'okra)

(defcustom okra-username user-login-name
  "User name for weekly reports in the Tarides admin repo."
  :type 'string
  :group 'okra)

(defcustom okra-switch "okra"
  "Opam switch name in which we can run the 'okra' command."
  :type 'string
  :group 'okra)

(defun okra-iso-8601-date (date)
  "Convert a Gregorian DATE `(M D Y) to a string in ISO 8601 format YYYY-MM-DD.
If applied to NIL, converts the current date."
  (let* ((true-date (or date (calendar-current-date)))
         (month (calendar-extract-month true-date))
         (year (calendar-extract-year true-date))
         (day-of-month (calendar-extract-day true-date)))
    (format "%04d-%02d-%02d" year month day-of-month)))

(defun okra-calendar-iso-extract-week (date)
  "Get the week number from the ISO DATE.
Confusingly, cal-iso.el functions use calendar-extract-month for this."
  (car date))

(defun okra-find-weekly (arg)
  "Find my weekly report file, creating it if necessary.

With a prefix ARG: do this for N weeks ago.  Takes a short while because of git
pull and okra.

For example (okra-find-weekly \"do this for 2 weeks ago\") will generate and
fill in last weeks report."
  (interactive "P")
  (let* ((back-weeks (if arg
                         (prefix-numeric-value arg) 0))
         (absolute-date (- (calendar-absolute-from-gregorian
                            (calendar-current-date))
                           (* 7 back-weeks)))
         (date (calendar-gregorian-from-absolute absolute-date))
         (iso-date (calendar-iso-from-absolute absolute-date))
         (iso-week (okra-calendar-iso-extract-week iso-date))
         (iso-year (calendar-extract-year iso-date))
         (month (calendar-extract-month date))
         (dir (file-name-concat okra-tarides-admin-repo "weekly"
                                (format "%04d" iso-year)
                                (format "%02d" iso-week)))
         (filename (file-name-concat dir
                                     (format "%s.md" okra-username))))
    (when (not (file-exists-p filename))
      ;; pull
      (message "Pulling...")
      (when (not (file-directory-p dir))
        (make-directory dir))
      (let ((default-directory dir)
            (magit-save-repository-buffers nil))
        (magit-run-git "pull"))
      (message "Pulling... done."))

    (find-file filename)
    ;; if the file doesn't already exist,
    ;; create it with okra and pre-formatted dates.
    (when (and (bobp) (eobp)) ;; buffer empty
      (message "Creating...")
      (call-process "opam" nil t t
                    "exec" (format "--switch=%s" okra-switch)
                    "--" "okra" "generate" (format "--week=%d" iso-week))
      ;; Emacs ISO week-day numbers run from 0 to 6, but 0 really
      ;; means 7 (Sunday).
      (dotimes (day 7)
               (let* ((iso-date (list iso-week (mod (+ day 1) 7) iso-year))
                      (date (calendar-gregorian-from-absolute
                             (calendar-iso-to-absolute iso-date))))
                 (insert (format "## %s %s:\n\n" (okra-iso-8601-date date)
                                 (calendar-day-name date t)))))
      (message "Creating... done."))
    ;; if it's the current week; navigate to today's date.
    (if (= back-weeks 0)
        (let* ((today (calendar-current-date)))
          (goto-char (point-min))
          (when (search-forward (okra-iso-8601-date (calendar-current-date)) nil t)
            (forward-line))))))

(defun okra-last-week ()
  "Generate okra report for previous calendar week."
  (interactive)
  (okra-find-weekly "do this for 2 weeks ago"))

(flycheck-def-executable-var okra "okra")

(flycheck-define-checker okra
  "A markdown syntax checker using the okra tool."
  :command ("opam" "exec" (eval (format "--switch=%s" okra-switch)) "--"
            ;; Ensure we execute in an opam switch
            "okra" "lint" "--engineer"
            (eval
             (when okra-tarides-admin-repo
               (format "--work-item-db=%s"
                       (expand-file-name "data/db.csv"
                                         okra-tarides-admin-repo))))
            (eval
             (when okra-tarides-admin-repo
               (format "--objective-db=%s"
                       (expand-file-name "data/team-objectives.csv"
                                         okra-tarides-admin-repo))))
            source)
  :error-patterns
  ((error line-start "File \"" (file-name) "\", line " line ":\nError: " (message)))
  :modes (markdown-mode gfm-mode)
  :predicate (lambda ()
               (or (not okra-tarides-admin-repo)
                   (string-prefix-p
                    (expand-file-name "weekly" okra-tarides-admin-repo)
                    (file-name-directory (buffer-file-name))))))

(add-to-list 'flycheck-checkers 'okra)

(provide 'okra)
;;; okra.el ends here
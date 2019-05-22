;;; hy-shell.el --- Shell and Process Support -*- lexical-binding: t -*-

;; Copyright © 2013 Julien Danjou <julien@danjou.info>
;;           © 2017 Eric Kaschalk <ekaschalk@gmail.com>
;;
;; hy-mode is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; hy-mode is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with hy-mode.  If not, see <http://www.gnu.org/licenses/>.

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Shell and process functionality for Hy.

;;; Code:

(require 'hy-base)

;;; Configuration
;;;; Configured

(defvar hy-shell--interpreter "hy"
  "Default Hy interpreter name.")

(defvar hy-shell--interpreter-args '("--spy")
  "Default argument list to pass to the Hy interpreter.")

(defvar hy-shell--startup-internal-process? t
  "Should an internal process startup for use by ide components?")

(defvar hy-shell--enable-font-lock? t
  "Whether the shell should font-lock the current line.")

(defvar hy-shell--notify? t
  "Should Hy message on successful instantiation, shutdown, etc?")

;;;; Managed

(defvar hy-shell--buffer nil
  "The buffer for the current Hy interpreter process we are operating on.")

(defconst hy-shell--name "Hy"
  "The buffer name to use for the Hy interpreter process.")

(defconst hy-shell--name-internal (format "%s Internal" hy-shell--name)
  "The buffer name to use for the internal Hy interpreter process.")

;;; Macros

(defmacro hy-shell--with (&rest body)
  "Run BODY for Hy process, starting up if needed."
  (declare (indent 0))
  `(when (hy-shell--warn-installed?)
     (let ((hy-shell--buffer (get-buffer-create hy-shell--name)))
       (with-current-buffer hy-shell--buffer
         (let ((proc (hy-shell--make-comint)))
           ,@body)))))

(defmacro hy-shell--with-internal (&rest body)
  "Run BODY for internal Hy process, starting up if needed."
  (declare (indent 0))
  `(when (hy-shell--warn-installed?)
     (let ((hy-shell--buffer (get-buffer-create hy-shell--name-internal)))
       (with-current-buffer hy-shell--buffer
         (let ((proc (hy-shell--make-comint-internal)))
           ,@body)))))

;;; Process Management
;;;; Utilities

(defun hy-shell--internal? ()
  "Is current buffer for an internal Hy interpreter process?"
  (s-equals? (buffer-name) hy-shell--name-internal))

;;;; Creation

(defun hy-shell--format-startup-command ()
  "Format Hy shell startup command."
  (let ((prog (shell-quote-argument hy-shell--interpreter))
        (switches (->> hy-shell--interpreter-args
                     (-map #'shell-quote-argument)
                     (s-join " "))))
    (if (hy-shell--internal?)
        prog
      (format "%s %s" prog switches))))

(defun hy-shell--make-comint ()
  "Create Hy shell comint process in current-buffer."
  (unless (process-live-p (current-buffer))
    (-let* (((prog . switches)
             (split-string-and-unquote (hy-shell--format-startup-command))))
      (apply #'make-comint-in-buffer (buffer-name) nil prog nil switches)

      (unless (derived-mode-p 'inferior-hy-mode)
        (inferior-hy-mode))

      (get-buffer-process (buffer-name)))))

(defun hy-shell--make-comint-internal ()
  "Run `hy-shell--make-comint' with additional setup for internal processes."
  (let (proc ((hy-shell--make-comint)))
    (set-process-query-on-exit-flag proc nil)
    proc))

;;; Sending Text - In progress

;; (defun hy-shell--end-of-output? (text)
;;   "Does TEXT contain a prompt, and so, signal end of the output?"
;;   (s-matches? comint-prompt-regexp text))

;; (defun hy-shell--text->comint-text (text)
;;   "Format TEXT before sending to comint."
;;   (if (or (not (string-match "\n\\'" text))
;;           (string-match "\n[ \t].*\n?\\'" text))
;;       (s-concat text "\n")
;;     text))

;; (defun hy-shell--send (text)
;;   "Send TEXT to Hy."
;;   (let ((proc (hy-shell--proc))
;;         (hy-shell--output-in-progress t))
;;     (unless proc
;;       (error "No active Hy process found to send text to."))

;;     (let ((comint-text (hy-shell--text->comint-text text)))
;;       (comint-send-string proc comint-text))))

;;; Jedhy

(defun hy-shell--setup-jedhy ()
  "Stub.")

;;; Notifications

(defun hy-shell--warn-installed? ()
  "Warn if `hy-shell--interpreter' is not found, returning non-nil otherwise."
  (if (executable-find hy-shell--interpreter)
      t
    (message "Hy executable not found. Install or activate a env with Hy.")))

(defun hy-shell--notify-process-success-internal ()
  (when hy-shell--notify?
    (message "Internal Hy shell process successfully started.")))

;;; Commands
;;;; Killing

(defun hy-shell--kill ()
  "Kill the Hy interpreter process."
  (interactive)

  (hy-shell--with (kill-buffer (current-buffer))))

(defun hy-shell--kill-internal ()
  "Kill the internal Hy interpreter process."
  (interactive)

  (hy-shell--with-internal (kill-buffer (current-buffer))))

;;;; Running

(defun run-hy-internal ()
  (interactive)

  (hy-shell--with-internal
    (hy-shell--setup-jedhy)
    (hy-shell--notify-process-success-internal)))

(defun run-hy ()
  (interactive)

  (hy-shell--with (display-buffer hy-shell--buffer)))

;;; Provide:

(provide 'hy-shell)

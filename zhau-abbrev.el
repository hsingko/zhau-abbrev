;;; zhau-abbrev.el --- a simple abbrev made for Chinese input convinence  -*- lexical-binding: t; -*-

;; Copyright (C) 2024  rookie

;; Author: rookie <rookie@onionhat>
;; Keywords: abbrev, local

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; zhau-abbrev = zh(language) automatic abbrev mode

;;; Code:

(defcustom zhau-abbrev--common-prefix "1"
  "quick abbrev prefix")

(defcustom zhau-abbrev--pinyin-program ""
  "go pinyin program location")

(defcustom zhau-abbrev--dir "~/.emacs.d/abbrev/"
  "where do you put those buffer local abbrev tables")

(defcustom zhau-abbrev--table-list nil
  "hold all local abbrev tables")

(defun zhau-abbrev--get-buf-md5 ()
  (substring (md5 (buffer-name)) 0 10))

(defun zhau-abbrev--get-tblsym ()
  (intern (concat (zhau-abbrev--get-buf-md5) "-zhau-abbrev-table")))

(defun zhau-abbrev--get-filename (&optional tblsym)
  (if tblsym
      (expand-file-name (symbol-name tblsym) zhau-abbrev--dir)
    (expand-file-name (zhau-abbrev--get-tblsym) zhau-abbrev--dir)))

(defun zhau-abbrev--dont-insert-expansion-char ()  t)  
(put 'zhau-abbrev--dont-insert-expansion-char 'no-self-insert t)  

(defun zhau-abbrev--get-pinyin-z (str)
  (replace-regexp-in-string
   "[ \t\n]" ""
   (shell-command-to-string
    (format "%s -s z %s" zhau-abbrev--pinyin-program str))))


(defun zhau-abbrev--set-local-abbrevs (abbrevs)
  "Add ABBREVS
to `local-abbrev-table' and make it buffer local.
ABBREVS should be a list of abbrevs as passed to `define-abbrev-table'.
The `local-abbrev-table' will be replaced by a copy with the new abbrevs added,
so that it is not the same as the abbrev table used in other buffers with the
same `major-mode'."
  (let* ((tblsym (zhau-abbrev--get-tblsym)))
    (set tblsym (copy-abbrev-table local-abbrev-table))
    (dolist (abbrev abbrevs)
      (define-abbrev (eval tblsym)
        (cl-first abbrev)
        (cl-second abbrev)
        (cl-third abbrev)))
    (setq-local local-abbrev-table (eval tblsym))))


(defun zhau-abbrev--add-word (str)
  (zhau-abbrev--set-local-abbrevs
   `(
     (,(concat zhau-abbrev--common-prefix (zhau-abbrev--get-pinyin-z str))
      ,str zhau-abbrev--dont-insert-expansion-char))))

(defun zhau-abbrev-add-marked-word (start end)
  (interactive "r")
  (let (str init-str)
    (setq str (buffer-substring start end))
    (zhau-abbrev--add-word str)
    (deactivate-mark)))

(defun zhau-abbrev-add-input ()
  (interactive)
  (let ((str (read-string "Type:")))
    (zhau-abbrev--add-word str)
    (insert str)))


(defun zhau-abbrev--save-abbrev-table (tblsym)
  (with-temp-buffer
    (insert-abbrev-table-description tblsym nil)
    (goto-char (point-min))
    (insert (format ";;-*-coding: %s;-*-\n" 'utf-8))
    (write-region nil nil (zhau-abbrev--get-filename tblsym))))

(defun zhau-abbrev--load-abbrev-table (tblsym)
  (let (abbrev-file)
    (setq abbrev-file (zhau-abbrev--get-filename tblsym))
    (if (file-exists-p abbrev-file)
	(progn (load abbrev-file)
	       (setq-local local-abbrev-table (eval tblsym))))))


(defun zhau-abbrev-save-all-tables ()
  (interactive)
  (dolist (tb zhau-abbrev--table-list)
    (zhau-abbrev--save-abbrev-table tb)))


(defun zhau-abbrev-save-current ()
  (interactive)
  (let (tblsym)
    (setq tblsym (zhau-abbrev--get-tblsym))
    (zhau-abbrev--save-abbrev-table tblsym)))

(defun zhau-abbrev-load-current ()
  (interactive)
  (let (tblsym)
    (setq tblsym (zhau-abbrev--get-tblsym))
    (zhau-abbrev--load-abbrev-table tblsym)))


(define-minor-mode zhau-abbrev-mode
  "My abbrev mode suitable for Chinese input"
  :lighter "ZAU"
  :global nil
  (if zhau-abbrev-mode
      (abbrev-mode 1)
    (abbrev-mode -1))
  (add-to-list 'zhau-abbrev--table-list (zhau-abbrev--get-tblsym))
  (zhau-abbrev-load-current))


(provide 'zhau-abbrev)
;;; zhau-abbrev.el ends here

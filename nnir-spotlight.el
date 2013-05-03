;;; nnir-spotlight.el --- Use MacOSX sportlight as nnir backend

;; Copyright © 2013 Sébastien Gross <seb•ɑƬ•chezwam•ɖɵʈ•org>

;; Author: Sébastien Gross <seb•ɑƬ•chezwam•ɖɵʈ•org>
;; Keywords: emacs, 
;; Created: 2013-05-03
;; Last changed: 2013-05-03 20:07:09
;; Licence: WTFPL, grab your copy here: http://sam.zoy.org/wtfpl/

;; This file is NOT part of GNU Emacs.

;;; Commentary:
;; 


;;; Code:

(eval-when-compile
  (require 'nnir))

;;(defcustom nnir-spotlight-source-dir "~/Library/Mail/Boxes/"
;;  "Base directory where emails resides.")

(defcustom nnir-spotlight-mdfind (executable-find "mdfind")
  "Path to mdfind binary file.")


(defun nnir-spotlight-get-dovecot-uid (path)
  "return dovecot uid from PATH"
  (let ((uids (make-hash-table :test 'equal)))
    (with-temp-buffer
      (insert-file-contents
       (format "%s/dovecot-uidlist" path))
      (loop for l in (split-string (buffer-substring (point-min) (point-max)) "\n")
	    for items = (split-string l ":" )
	    for file = (cadr items)
	    for id =  (car (split-string (car items) " "))
	    when file
	    do (puthash file id uids)))
    uids))

(defun nnir-run-spotlight (query srv &optional groups)
  "Search `gnus-group-make-nnir-group' using MacOSX spotlight feature.

This assume several things:

- You fetch you mail locally using something like offlineimap.
- You read your mail using a local imap process.
- You are using MacOSX.
- spotlight is enabled.


Your `gnus-secondary-select-methods' looks like:

    '((nnimap
       \"Local\"
       (nnir-search-engine spotlight)
       (nnir-spotlight-dir \"~/Library/Mail/Boxes/\")
       (nnimap-stream shell)
       (nnimap-shell-program
        \"MAIL=maildir:~/Library/Mail/Boxes:LAYOUT=fs \"
        \"/usr/local/Cellar/dovecot/2.1.9/libexec/imap\")))"
  (let* ((method (gnus-server-to-method server))
	 (type (car method))
	 (name (cadr method))
	 (directory (expand-file-name (cadr (assoc 'nnir-spotlight-dir method))))
	 ;;(groups (or groups '(".:")))
	 (regexp (cdr (assoc 'query query))))

    ;;(message "M: %S D: %S R: %S" method directory regexp)
    ;;(message "Q: %S S:%S G:%S" query srv groups)
    (let ((ret
	   (loop for group in groups
		 for path = (cadr (split-string group ":" t))
		 for cmd = (format
			    "%s -onlyin '%s%s' %s"
			    nnir-spotlight-mdfind
			    directory
			    path
			    (shell-quote-argument regexp))
		 for uidlist = (nnir-spotlight-get-dovecot-uid
				(format "%s/%s" directory path))
		 nconc (loop for f in (split-string
				       (shell-command-to-string cmd)
				       "\n" t)
			     for file-base = (car
					      (split-string
					       (file-name-nondirectory f)
					       ":" t))
			     for id = (gethash file-base uidlist)
			     collect
			     (vector
			      group
			      (string-to-int id)
			      100)))))
      ret)))

(add-to-list 'nnir-engines '(spotlight nnir-run-spotlight nil))

(provide 'nnir-spotlight)

;; nnir-spotlight.el ends here

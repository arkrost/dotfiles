(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(straight-use-package 'use-package)
(setq straight-use-package-by-default t)

;; Configuration

(use-package emacs
  :config
  (setq initial-scratch-message nil)
  (setq inhibit-startup-message t)
  (setq make-backup-files nil)
  (global-display-line-numbers-mode t)
)

(use-package gruber-darker-theme
  :config
  (load-theme 'gruber-darker t)
  (mapc (lambda (face) (set-face-bold face nil)) (face-list)) ; get rid of bold fonts
  (set-face-attribute 'default nil :font (font-spec :family "IBM Plex Mono" :size 14 :weight 'light)))

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
  (setq vc-follow-symlinks t)
  (global-display-line-numbers-mode)
  (defalias 'yes-or-no-p 'y-or-n-p))

(use-package gruber-darker-theme
  :config
  (load-theme 'gruber-darker t))
  

(use-package dired
  :straight nil
  :init
  (setq dired-create-destination-dirs 'ask)
  (setq dired-recursive-deletes 'top)
  (setq dired-recursive-copies 'always)
  (setq dired-auto-revert-buffer #'dired-buffer-stale-p))

(use-package magit)

(use-package orderless
    :custom
    (completion-styles '(orderless basic))
    (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package vertico
  :config
  (vertico-mode))


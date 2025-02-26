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
  :custom
  (initial-scratch-message nil)
  (inhibit-startup-message t)
  (make-backup-files nil)
  (vc-follow-symlinks t)
  (initial-major-mode 'fundamental-mode)
  (display-line-numbers-width 4)
  (split-width-threshold 120)
  :config
  (defalias 'yes-or-no-p 'y-or-n-p)
  (global-display-line-numbers-mode)
  ;; use symbols font in Private Use Areas
  (dolist (range '((#xe000 . #xf8ff) (#xf0000 . #xfffff)))
    (set-fontset-font t range "Symbols Nerd Font Mono"))
  ;; no bold fonts
  (defun disable-bold-fonts ()
    "Disable bold fonts by setting any face with bold weight to normal."
    (dolist (face (face-list))
      (when (eq (face-attribute face :weight nil 'default) 'bold)
	(set-face-attribute face nil :weight 'regular))))
  (add-hook 'minibuffer-setup-hook 'disable-bold-fonts)
  (add-hook 'change-major-mode-after-body-hook 'disable-bold-fonts))

(use-package whitespace
  :custom
  (whitespace-style '(face trailing empty))
  (whitespace-empty-at-eob-regexp "^[ \t\n]\\([ \t\n]+\\)\\'")
  :hook (before-save . whitespace-cleanup)
  :config
  (global-whitespace-mode))

(use-package gruber-darker-theme
  :config
  (load-theme 'gruber-darker t))

(use-package treesit-auto
  :custom
  (treesit-auto-langs '(go gomod rust java kotlin json))
  :config
  (treesit-auto-add-to-auto-mode-alist 'all))

(use-package dired
  :straight nil
  :custom
  (dired-create-destination-dirs 'ask)
  (dired-recursive-deletes 'top)
  (dired-recursive-copies 'always)
  (dired-auto-revert-buffer #'dired-buffer-stale-p))

(use-package magit
  :defer t)

(use-package orderless
    :custom
    (completion-styles '(orderless basic))
    (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package vertico
  :config
  (vertico-mode))

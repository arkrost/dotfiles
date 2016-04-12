(when (display-graphic-p)
  (tool-bar-mode -1)
  (scroll-bar-mode -1))
(menu-bar-mode -1)
(set-default-font "Hack-11")

(setq make-backup-files nil) ; disable backup
(setq ring-bell-function 'ignore) ; disable beep

(defalias 'yes-or-no-p 'y-or-n-p)

(global-linum-mode 1)
(electric-pair-mode 1)

(setq inhibit-splash-screen t)
(setq inhibit-startup-message t)

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(setq use-package-always-ensure t)

(use-package gruvbox-theme
  :config (load-theme 'gruvbox t))

(use-package org
  :mode ("\\.org\\'" . org-mode))

(use-package racket-mode
  :mode ("\\.rkt\\'" . racket-mode))

(use-package ess
  :mode ("\\.[Rr]\\'" . R-mode)
  :config (setq ess-ask-for-ess-directory nil
		ess-eval-visibly nil
		inferior-R-args "--no-save"))

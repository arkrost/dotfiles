(when (display-graphic-p)
  (tool-bar-mode -1)
  (scroll-bar-mode -1))
(menu-bar-mode -1)
(set-default-font "Hack-11")

(setq make-backup-files nil) ; disable backup
(setq ring-bell-function 'ignore) ; disable beep

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(use-package gruvbox-theme
  :ensure t
  :init (load-theme 'gruvbox t))

(use-package ess
  :ensure t
  :mode ("\\.[Rr]\\'" . R-mode)
  :config (setq ess-ask-for-ess-directory nil
		ess-eval-visibly nil
		inferior-R-args "--no-save"))

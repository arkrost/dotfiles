(setq-default 
 auto-save-default nil
 make-backup-files nil
 
 custom-file "~/.emacs.d/custom.el"

 inhibit-startup-screen t

 ns-right-command-modifier 'control)

(defalias 'yes-or-no-p 'y-or-n-p)

(global-linum-mode)

(blink-cursor-mode 0)
(tool-bar-mode 0)
(scroll-bar-mode 0)

(global-set-key (kbd "s-w") 'kill-this-buffer)

(define-fringe-bitmap 'left-curly-arrow [0 64 64 70 126 6 0 0])
(define-fringe-bitmap 'right-curly-arrow [0 2 2 98 126 96 0 0])
(define-fringe-bitmap 'left-arrow [0 0 96 126 96 0 0])
(define-fringe-bitmap 'right-arrow [0 0 6 126 6 0 0])

(defvar gnu '("gnu" . "https://elpa.gnu.org/packages/"))
(defvar melpa '("melpa" . "https://melpa.org/packages/"))

(setq package-archives nil)
(add-to-list 'package-archives melpa t)
(add-to-list 'package-archives gnu t)

(package-initialize)
(when (not (package-installed-p 'use-package))
  (package-refresh-contents)
  (package-install 'use-package)
  (package-initialize))

(eval-when-compile
  (require 'use-package))
(setq use-package-always-ensure t)

(use-package benchmark-init
  :ensure t
  :config
  ;; To disable collection of benchmark data after init is done.
  (add-hook 'after-init-hook 'benchmark-init/deactivate))

(use-package diminish)

(use-package base16-theme
  :init
  (setq-default base16-distinct-fringe-background nil)
  :config
  (load-theme 'base16-one-light t))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package smartparens
  :diminish smartparens-mode
  :config
  (smartparens-global-mode))

(use-package parinfer
  :disabled t)

(use-package swiper
  :diminish ivy-mode
  :bind ("C-s" . 'swiper)
  :init
  (setq-default ivy-height 6)
  :config
  (ivy-mode))

(use-package counsel-projectile
  :bind (("s-p" . counsel-projectile-switch-project)
	 ("s-e" . counsel-projectile-find-file)
	 ("s-f" . counsel-projectile-grep))
  :config
  (counsel-projectile-mode))

(use-package groovy-mode)

(use-package clojure-mode)
(use-package cider)

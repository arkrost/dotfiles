(setq-default 
 auto-save-default nil
 make-backup-files nil
 
 custom-file "~/.emacs.d/custom.el"

 inhibit-startup-screen t
 truncate-lines t

 ns-right-command-modifier 'control)

(defalias 'yes-or-no-p 'y-or-n-p)

(global-linum-mode)

(blink-cursor-mode 0)
(tool-bar-mode 0)
(scroll-bar-mode 0)

(set-default-font "Iosevka 16")
(set-frame-size nil 120 40)
(set-frame-position nil 320 40)

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

(use-package diminish)

(use-package base16-theme
  :config
  (load-theme 'base16-one-light t))

(use-package all-the-icons-dired
  :hook (dired-mode . all-the-icons-dired-mode))

(use-package spaceline-all-the-icons
  :init
  (setq-default
   spaceline-highlight-face-func (lambda () 'spaceline-evil-visual)
   spaceline-all-the-icons-separator-type 'none)
  :config
  (spaceline-all-the-icons-theme))

(use-package projectile)

(use-package swiper
  :diminish ivy-mode
  :bind ("C-s" . 'swiper)
  :init
  (setq-default ivy-height 6)
  :config
  (ivy-mode))

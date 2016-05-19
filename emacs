;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
(package-initialize)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(auto-save-default nil)
 '(blink-cursor-mode nil)
 '(column-number-mode t)
 '(custom-enabled-themes (quote (wombat)))
 '(custom-file nil)
 '(custom-safe-themes t)
 '(electric-pair-mode t)
 '(eshell-prompt-function (lambda nil (concat (eshell/pwd) " ")))
 '(inhibit-startup-screen t)
 '(initial-major-mode (quote text-mode))
 '(initial-scratch-message nil)
 '(ivy-height 4)
 '(ivy-mode t)
 '(make-backup-files nil)
 '(menu-bar-mode nil)
 '(package-archives (quote (("melpa" . "https://melpa.org/packages/"))))
 '(package-selected-packages
   (quote
    (writeroom-mode smart-mode-line rainbow-delimiters gruvbox-theme diminish counsel)))
 '(ring-bell-function (quote ignore))
 '(scroll-bar-mode nil)
 '(show-paren-delay 0)
 '(show-paren-mode t)
 '(sml/theme (quote respectful))
 '(tool-bar-mode nil))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:height 140 :family "Hack"))))
 '(eshell-prompt ((t (:foreground "#8787af"))))
 '(show-paren-match ((t (:weight bold :slant italic)))))

(defalias 'yes-or-no-p 'y-or-n-p)

(diminish 'ivy-mode)

(add-hook 'prog-mode-hook 'rainbow-delimiters-mode)

(global-set-key (kbd "C-s") 'swiper)
(global-set-key (kbd "M-x") 'counsel-M-x)
(global-set-key (kbd "M-y") 'counsel-yank-pop)
(global-set-key (kbd "C-x C-f") 'counsel-find-file)
(global-set-key (kbd "C-h f") 'counsel-describe-function)
(global-set-key (kbd "C-h v") 'counsel-describe-variable)

(sml/setup)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; IDO
;; http://www.emacswiki.org/emacs/InteractivelyDoThings

(require 'ido)
(ido-mode t)
(setq ido-enable-flex-matching t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SMEX
;; http://github.com/nonsequitur/smex/

(require 'smex)
(smex-initialize)
(global-set-key (kbd "M-x") 'smex)
(global-set-key (kbd "M-X") 'smex-major-mode-commands)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Text scaling (zoom)

(defun text-scale-reset ()
  "Disables text scaling (zoom)"
  (interactive)
  (text-scale-set 0))

(global-set-key (kbd "s-f =") 'text-scale-increase)
(global-set-key (kbd "s-f -") 'text-scale-decrease)
(global-set-key (kbd "s-f 0") 'text-scale-reset)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Bars
(menu-bar-mode 0)
(tool-bar-mode 0)
(scroll-bar-mode 0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Look and feel

(load-theme 'wombat t)
(set-default-font "Inconsolata-14")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Presets
(setq make-backup-files nil) ; prevent backup creation
(global-linum-mode 1) ; show line number

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Windows
(global-set-key (kbd "s-<up>") 'windmove-up)
(global-set-key (kbd "s-<down>") 'windmove-down)
(global-set-key (kbd "s-<left>") 'windmove-left)
(global-set-key (kbd "s-<right>") 'windmove-right)
(global-set-key (kbd "s-<tab>") 'other-window)

(global-set-key (kbd "s-=") 'enlarge-window)
(global-set-key (kbd "s--") 'shrink-window)
(global-set-key (kbd "s-+") 'enlarge-window-horizontally)
(global-set-key (kbd "s-_") 'shrink-window-horizontally)
(global-set-key (kbd "s-b") 'balance-windows)

(global-set-key (kbd "s-w") 'delete-window)
(global-set-key (kbd "s-o") 'delete-other-windows)

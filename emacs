(require 'package)
(add-to-list 'package-archives
  '("melpa" . "https://melpa.org/packages/"))
(package-initialize)

;; Look & Feel
(load-theme 'gruvbox t)
(scroll-bar-mode -1)
(tool-bar-mode -1)
(menu-bar-mode -1)
(set-default-font "Hack-11")

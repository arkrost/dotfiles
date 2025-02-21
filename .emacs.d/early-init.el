; disable package.el
(setq package-enable-at-startup nil)

; UI configuration
(setq frame-inhibit-implied-resize t)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(fullscreen . maximized) default-frame-alist)
(push '(font . "IBM Plex Mono Light 14") default-frame-alist)
(push '(background-color . "#181818") default-frame-alist)

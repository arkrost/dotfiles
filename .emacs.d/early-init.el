; disable package.el
(setq package-enable-at-startup nil)

; UI configuration
(setq frame-inhibit-implied-resize t)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(fullscreen . maximized) default-frame-alist)
(push '(background-color . "#181818") default-frame-alist)

; Font configuration

;;;; 1) Remap face weights globally (so themes using :weight still

;; Emacs maps symbolic weights (normal/bold/etc) via `font-weight-table`.
;; The lookup scans the table in order and returns the *first* match, so we
;; can remap by making earlier buckets contain the symbols we want. :contentReference[oaicite:1]{index=1}
(let ((tbl font-weight-table))
  (dotimes (i (length tbl))
    (let* ((entry (aref tbl i))
           (n     (aref entry 0)))
      (cond
       ;; Make NORMAL/REGULAR/UNSPECIFIED/BOOK resolve to the LIGHT bucket.
       ((= n 40)
        (aset tbl i (vconcat entry [normal regular unspecified book])))

       ;; Make BOLD resolve to the REGULAR bucket.
       ;; (Regular/normal is the bucket at numeric 80 in Emacs’ default table.) :contentReference[oaicite:2]{index=2}
       ((= n 55)
        (aset tbl i (vconcat entry [bold])))))))


;;;; 2) Set the base font (IBM Plex Mono, size 16)

;; Using default-frame-alist (and initial-frame-alist) ensures the first GUI
;; frame is created with the right font from the start. :contentReference[oaicite:3]{index=3}
(defconst my/fixed-font "IBM Plex Mono-16:weight=normal")

(add-to-list 'default-frame-alist `(font . ,my/fixed-font))
(add-to-list 'initial-frame-alist `(font . ,my/fixed-font))


;;;; 3) Use Symbols Nerd Font for Nerd Fonts glyphs (PUA range)

;; Nerd Fonts icons live in the Unicode Private Use Area, commonly E000–F8FF.
;; `set-fontset-font` can assign a font for that range. :contentReference[oaicite:4]{index=4}
(set-fontset-font t '(#xE000 . #xF8FF)
                  (font-spec :family "Symbols Nerd Font")
                  nil
                  'prepend)

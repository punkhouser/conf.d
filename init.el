;;; init.el --- Minimal Common Lisp setup: SLIME + Evil -*- lexical-binding: t; -*-

;; --- Package management ---
(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                          ("gnu"   . "https://elpa.gnu.org/packages/")))
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

(dolist (pkg '(evil evil-collection slime solarized-theme))
  (unless (package-installed-p pkg)
    (package-install pkg)))

;; --- Sane defaults ---
(setq inhibit-startup-screen t)
(setq make-backup-files nil)
(setq auto-save-default nil)
(menu-bar-mode -1)
(when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
(show-paren-mode 1)
(electric-pair-mode 1)
(global-display-line-numbers-mode 1)
(setq column-number-mode t)
(setq-default indent-tabs-mode nil)
(fset 'yes-or-no-p 'y-or-n-p)
(global-auto-revert-mode 1)
(display-time)

;; Load theme
(load-theme 'solarized-light t)
;;(set-frame-font "DejaVu Sans Mono-14")

;; --- Evil mode ---
;; these three need to be set *before* evil loads
(setq evil-want-integration t)
(setq evil-want-keybinding nil)
(setq evil-want-C-u-scroll t)
(require 'evil)
(evil-mode 1)

(require 'evil-collection)
(evil-collection-init)   ; sane evil keybindings inside the SLIME REPL & buffers
                          ; (without this, evil + SLIME fight each other)

;; --- SLIME ---
(require 'slime)
(setq inferior-lisp-program "sbcl")   ; assumes `sbcl` is on your PATH
(setq slime-contribs '(slime-fancy))  ; better REPL, completion, inspector, etc.

(evil-ex-define-cmd "EvalFile" #'slime-compile-and-load-file)
(add-hook 'after-init-hook 'slime)

;;; init.el ends here
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

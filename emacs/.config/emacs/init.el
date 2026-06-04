;;; init.el --- Juju's Emacs config -*- lexical-binding: t; -*-

;; --- Package manager + use-package ---
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))
(setq use-package-always-ensure t)

;; --- Keep machine-written customizations out of init.el ---
(setq custom-file (locate-user-emacs-file "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file))

;; --- UI basics ---
(setq inhibit-startup-message t)
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(blink-cursor-mode -1)
(global-hl-line-mode 1)

;; Relative line numbers (Neovim relativenumber muscle memory)
(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode 1)

;; Font + a little breathing room around the frame
(add-to-list 'default-frame-alist '(font . "Iosevka-10"))
(add-to-list 'default-frame-alist '(internal-border-width . 5))

;; Keep the cursor away from the window edges (like scrolloff)
(setq scroll-margin 8)

;; Spaces, not tabs
(setq-default indent-tabs-mode nil
              tab-width 2)

;; No backup / autosave clutter
(setq make-backup-files nil
      auto-save-default nil)

;; --- Theme: Gruber Darker ---
(use-package gruber-darker-theme
  :config
  (load-theme 'gruber-darker t))

;;; init.el ends here

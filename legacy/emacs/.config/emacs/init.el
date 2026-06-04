;;; init.el --- Juju's Emacs config -*- lexical-binding: t; -*-

;; --- Package manager ---
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))
(setq use-package-always-ensure t)

;; --- UI basics ---
(setq inhibit-startup-message t)
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(blink-cursor-mode -1)
(global-hl-line-mode 1)

;; Line numbers (relative, like Neovim relativenumber)
(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode 1)

;; Font
(add-to-list 'default-frame-alist '(font . "Iosevka-10"))

;; Padding
(add-to-list 'default-frame-alist '(internal-border-width . 5))

;; --- Editing defaults ---
(setq-default indent-tabs-mode nil)
(setq-default tab-width 2)

;; No backup or auto-save files
(setq make-backup-files nil)
(setq auto-save-default nil)

;; Scroll margin (keeps cursor centered, like scrolloff=999)
(setq scroll-margin 999)

;; Case-insensitive search (like ignorecase)
(setq case-fold-search t)

;; Split behavior (like splitright + splitbelow)
(setq split-width-threshold 0)
(setq split-height-threshold nil)

;; Shorter update delay
(setq idle-update-delay 0.25)

;; --- Minibuffer completion (fido-vertical-mode) ---
(fido-vertical-mode 1)
(define-key icomplete-minibuffer-map (kbd "TAB") 'icomplete-forward-completions)
(define-key icomplete-minibuffer-map (kbd "<tab>") 'icomplete-forward-completions)
(define-key icomplete-minibuffer-map (kbd "S-TAB") 'icomplete-backward-completions)
(define-key icomplete-minibuffer-map (kbd "<backtab>") 'icomplete-backward-completions)

;; --- Custom file ---
(setq custom-file (locate-user-emacs-file "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file))

;; --- Theme ---
(load-theme 'juju t)

;; --- Whitespace display (like Neovim listchars) ---
(setq-default whitespace-style '(face spaces tabs trailing space-mark tab-mark))
(setq whitespace-display-mappings
      '((space-mark 32 [183])
        (tab-mark 9 [187 32])))
(global-whitespace-mode 1)

;; Subtle whitespace faces (applied after theme)
(with-eval-after-load 'whitespace
  (set-face-attribute 'whitespace-space nil :foreground "#333333" :background 'unspecified)
  (set-face-attribute 'whitespace-tab nil :foreground "#333333" :background 'unspecified)
  (set-face-attribute 'whitespace-trailing nil :foreground "#E84F4F" :background 'unspecified))

;; --- Tree-sitter ---
(use-package treesit-auto
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

;; --- Completion (corfu + cape) ---
(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-cycle t)
  :init
  (global-corfu-mode))

;; Corfu popup faces (applied after theme)
(with-eval-after-load 'corfu
  (set-face-attribute 'corfu-default nil :background "#101010" :foreground "#FFFFFF")
  (set-face-attribute 'corfu-current nil :background "#9B64FB" :foreground "#FFFFFF")
  (set-face-attribute 'corfu-border nil :background "#404040"))

(use-package cape
  :init
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file))

;; --- Snippets (tempel) ---
(use-package tempel
  :bind (("M-+" . tempel-complete)
         ("M-*" . tempel-insert))
  :init
  (defun tempel-setup-capf ()
    (setq-local completion-at-point-functions
                (cons #'tempel-expand completion-at-point-functions)))
  (add-hook 'prog-mode-hook 'tempel-setup-capf))

(use-package tempel-collection)

;; --- LSP (eglot) ---
(use-package eglot
  :ensure nil
  :hook ((python-ts-mode . eglot-ensure)
         (json-ts-mode . eglot-ensure)
         (css-ts-mode . eglot-ensure))
  :config
  (add-to-list 'eglot-server-programs
               '(python-ts-mode . ("pyright-langserver" "--stdio")))
  (add-to-list 'eglot-server-programs
               '(json-ts-mode . ("vscode-json-language-server" "--stdio")))
  (add-to-list 'eglot-server-programs
               '(css-ts-mode . ("vscode-css-language-server" "--stdio"))))

;; --- Which-key (built-in) ---
(use-package which-key
  :ensure nil
  :init (which-key-mode))

;; --- Status line (doom-modeline) ---
(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :custom
  (doom-modeline-icon nil)
  (doom-modeline-buffer-encoding nil)
  (doom-modeline-height 30))

;; --- AI assistant (gptel + Ollama) ---
(use-package gptel
  :defer t
  :config
  (setq gptel-model 'qwen2.5-coder:7b
        gptel-backend (gptel-make-ollama "Ollama"
                        :host "localhost:11434"
                        :stream t
                        :models '(qwen2.5-coder:7b))))

;; --- Multiple cursors ---
(use-package multiple-cursors
  :bind (("C->" . mc/mark-next-like-this)
         ("C-<" . mc/mark-previous-like-this)
         ("C-c C->" . mc/mark-all-like-this)))

;; --- Indent bars ---
(use-package indent-bars
  :hook (prog-mode . indent-bars-mode)
  :custom
  (indent-bars-treesit-support t)
  (indent-bars-color '(highlight :face-bg t :blend 0.2)))

;; --- Rainbow mode (CSS only, M-x rainbow-mode to toggle anywhere) ---
(use-package rainbow-mode
  :hook (css-mode css-ts-mode)
  :commands rainbow-mode)

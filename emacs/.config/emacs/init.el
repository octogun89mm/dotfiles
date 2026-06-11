;;; init.el --- Juju's Emacs config -*- lexical-binding: t; -*-

;; --- Package manager + use-package ---
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))
(setq use-package-always-ensure t)

;; --- Load Secrets ---
(let ((secrets-file (locate-user-emacs-file "secrets.el")))
  (if (and secrets-file (file-exists-p secrets-file))
      (load secrets-file t)))

;; --- Keep machine-written customizations out of init.el ---
(setq custom-file (locate-user-emacs-file "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file))

;; --- UI basics ---
(setq inhibit-startup-message t)
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(blink-cursor-mode 1)
(global-hl-line-mode 1)

;; Relative line numbers (Neovim relativenumber muscle memory)
(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode 1)

;; Font + a little breathing room around the frame
(add-to-list 'default-frame-alist '(font . "Maple Mono NF-10"))
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

;; --- LLM Integration via gptel ---
(use-package gptel
  :bind ("C-c g" . gptel-menu)
  :config
  ;; Local llama.cpp: Connected to the systemd-managed service on :3002
  ;; Only the model actually loaded into the server is listed here.
  (defvar my/llama-cpp
    (gptel-make-openai "llama.cpp"
      :host "localhost:3002"
      :protocol "http"
      :stream t
      :key "no-key"
      :models '(qwen3.6-35b-a3b)))

  ;; OpenRouter
  (defvar my/openrouter
    (gptel-make-openai "OpenRouter"
      :host "openrouter.ai"
      :endpoint "/api/v1/chat/completions"
      :stream t
      :key gptel-key-openrouter
      :models '(deepseek/deepseek-v4-flash openai/gpt-4o)))

  ;; OpenAI
  (defvar my/openai
    (gptel-make-openai "OpenAI"
      :host "api.openai.com"
      :endpoint "/v1/chat/completions"
      :stream t
      :key gptel-key-openai
      :models '(gpt-4o)))

  ;; Set defaults
  (setq gptel-backend my/llama-cpp
        gptel-model 'qwen3.6-35b-a3b))

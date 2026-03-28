#!/usr/bin/env bash
#
# mac-setup: macOS 재설치 후 원커맨드 환경 구성 스크립트
#
# 사용법:
#   bash <(curl -fsSL https://raw.githubusercontent.com/<USER>/mac-setup/main/setup.sh)
#
set -euo pipefail

# ──────────────────────────────────────────────
# Colors & Helpers
# ──────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
error()   { echo -e "${RED}[✗]${NC} $*"; }

section() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}  $*${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

command_exists() { command -v "$1" &>/dev/null; }

# ──────────────────────────────────────────────
# 0. Xcode Command Line Tools
# ──────────────────────────────────────────────
section "Xcode Command Line Tools"
if xcode-select -p &>/dev/null; then
  success "이미 설치됨"
else
  info "설치 중..."
  xcode-select --install
  echo "Xcode CLT 설치가 완료되면 아무 키나 누르세요..."
  read -n 1 -s -r
fi

# ──────────────────────────────────────────────
# 1. Homebrew
# ──────────────────────────────────────────────
section "Homebrew"
if command_exists brew; then
  success "이미 설치됨"
  brew update
else
  info "설치 중..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Apple Silicon PATH 설정
  if [[ $(uname -m) == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
  fi
fi

# ──────────────────────────────────────────────
# 2. Brewfile로 일괄 설치
# ──────────────────────────────────────────────
section "Homebrew 패키지 설치 (Brewfile)"

BREWFILE=$(mktemp)
cat > "$BREWFILE" << 'BREWFILE_CONTENT'
# ── Taps ──
tap "homebrew/cask-fonts"

# ── Terminal & Shell ──
brew "fish"
brew "tmux"
brew "starship"

# ── Editors ──
brew "neovim"

# ── Git ──
brew "git"
brew "git-delta"
brew "gh"
brew "lazygit"

# ── CLI Utilities ──
brew "ripgrep"
brew "fd"
brew "bat"
brew "fzf"
brew "eza"
brew "jq"
brew "yq"
brew "tree"
brew "htop"
brew "watch"
brew "wget"
brew "curl"
brew "httpie"
brew "tldr"
brew "direnv"
brew "gnupg"
brew "age"
brew "sops"

# ── Python ──
brew "uv"

# ── Go ──
brew "go"

# ── Rust ──
brew "rustup"

# ── Node.js (fnm) ──
brew "fnm"

# ── Kubernetes (풀셋) ──
brew "kubectl"
brew "helm"
brew "k9s"
brew "kustomize"
brew "kubectx"       # kubectx + kubens
brew "stern"
brew "k3d"
brew "argocd"
brew "kubeseal"
brew "kubelogin"

# ── Container & Infra ──
brew "docker-compose"
brew "terraform"
brew "ansible"

# ── Network & Debug ──
brew "nmap"
brew "mtr"
brew "dog"           # DNS lookup

# ── Cask: Apps ──
cask "ghostty"
cask "visual-studio-code"
cask "zed"
cask "docker"        # Docker Desktop
cask "raycast"
cask "google-chrome"
cask "firefox"
cask "iterm2"
cask "slack"
cask "notion"
cask "obsidian"
cask "kakaotalk"
cask "rectangle"     # 윈도우 매니저
cask "stats"         # 시스템 모니터링

# ── Fonts ──
cask "font-hack-nerd-font"
cask "font-jetbrains-mono-nerd-font"
cask "font-fira-code-nerd-font"
BREWFILE_CONTENT

info "Brewfile로 설치 시작 (시간이 좀 걸립니다)..."
brew bundle --file="$BREWFILE" || warn "일부 패키지 설치 실패 — 로그를 확인하세요"
rm -f "$BREWFILE"
success "Homebrew 패키지 설치 완료"

# ──────────────────────────────────────────────
# 3. Fish Shell 기본 셸 설정
# ──────────────────────────────────────────────
section "Fish Shell 설정"
FISH_PATH=$(which fish)
if ! grep -qF "$FISH_PATH" /etc/shells 2>/dev/null; then
  info "Fish를 /etc/shells에 추가..."
  echo "$FISH_PATH" | sudo tee -a /etc/shells
fi

if [[ "$SHELL" != "$FISH_PATH" ]]; then
  info "기본 셸을 Fish로 변경..."
  chsh -s "$FISH_PATH"
  success "기본 셸 변경 완료 (재로그인 후 적용)"
else
  success "이미 Fish가 기본 셸"
fi

# Fisher (Fish 플러그인 매니저) 설치
info "Fisher 설치..."
fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher" 2>/dev/null || true

# Fish 플러그인 설치
info "Fish 플러그인 설치..."
fish -c "fisher install PatrickF1/fzf.fish" 2>/dev/null || true
fish -c "fisher install jethrokuan/z" 2>/dev/null || true
fish -c "fisher install danhper/fish-ssh-agent" 2>/dev/null || true
success "Fish 설정 완료"

# ──────────────────────────────────────────────
# 4. Fish Shell 설정 파일
# ──────────────────────────────────────────────
section "Fish config 생성"
FISH_CONFIG_DIR="$HOME/.config/fish"
mkdir -p "$FISH_CONFIG_DIR/conf.d"

cat > "$FISH_CONFIG_DIR/config.fish" << 'FISH_CONFIG'
# ── mac-setup: Fish Shell Configuration ──

if status is-interactive
    # Greeting 비활성화
    set -g fish_greeting ""

    # Starship prompt
    starship init fish | source

    # direnv
    direnv hook fish | source

    # fnm (Node.js)
    fnm env --use-on-cd --shell fish | source

    # Homebrew (Apple Silicon)
    if test -d /opt/homebrew
        eval (/opt/homebrew/bin/brew shellenv)
    end

    # Go
    set -gx GOPATH $HOME/go
    fish_add_path $GOPATH/bin

    # Rust
    fish_add_path $HOME/.cargo/bin

    # Aliases
    alias ls "eza --icons"
    alias ll "eza -la --icons --git"
    alias lt "eza --tree --level=2 --icons"
    alias cat "bat --paging=never"
    alias grep "rg"
    alias find "fd"
    alias vim "nvim"
    alias k "kubectl"
    alias kx "kubectx"
    alias kn "kubens"
    alias lg "lazygit"
    alias dc "docker compose"
    alias g "git"
    alias gs "git status"
    alias gd "git diff"
    alias gl "git log --oneline --graph --decorate -20"
    alias gp "git push"

    # kubectl 자동완성
    kubectl completion fish | source 2>/dev/null
end
FISH_CONFIG

success "Fish config 생성 완료"

# ──────────────────────────────────────────────
# 5. Rust toolchain 설치
# ──────────────────────────────────────────────
section "Rust Toolchain"
if command_exists rustc; then
  success "이미 설치됨: $(rustc --version)"
else
  info "stable 툴체인 설치 중..."
  rustup-init -y --no-modify-path 2>/dev/null
  source "$HOME/.cargo/env" 2>/dev/null || true
  success "Rust 설치 완료"
fi

# ──────────────────────────────────────────────
# 6. Node.js (fnm)
# ──────────────────────────────────────────────
section "Node.js (fnm)"
if fnm list 2>/dev/null | grep -q "lts"; then
  success "이미 LTS 설치됨"
else
  info "Node.js LTS 설치 중..."
  eval "$(fnm env)"
  fnm install --lts
  fnm default lts-latest
  success "Node.js LTS 설치 완료"
fi

# ──────────────────────────────────────────────
# 6-1. Claude Code
# ──────────────────────────────────────────────
section "Claude Code"
if command_exists claude; then
  success "이미 설치됨: $(claude --version 2>/dev/null || echo 'installed')"
else
  info "Claude Code 설치 중..."
  eval "$(fnm env)" 2>/dev/null || true
  npm install -g @anthropic-ai/claude-code
  success "Claude Code 설치 완료"
fi

# ──────────────────────────────────────────────
# 7. Neovim 설정 (kickstart or LazyVim)
# ──────────────────────────────────────────────
section "Neovim 설정"
NVIM_CONFIG="$HOME/.config/nvim"
if [[ -d "$NVIM_CONFIG" ]]; then
  warn "기존 Neovim 설정이 존재합니다. 건너뜁니다."
else
  info "LazyVim starter 설치 중..."
  git clone https://github.com/LazyVim/starter "$NVIM_CONFIG" 2>/dev/null || true
  rm -rf "$NVIM_CONFIG/.git"
  success "LazyVim 설치 완료 (nvim 실행 시 플러그인 자동 설치)"
fi

# ──────────────────────────────────────────────
# 8. Starship 프롬프트 설정
# ──────────────────────────────────────────────
section "Starship 설정"
mkdir -p "$HOME/.config"
cat > "$HOME/.config/starship.toml" << 'STARSHIP_CONFIG'
# mac-setup: Starship Configuration
format = """
$username\
$hostname\
$directory\
$git_branch\
$git_status\
$python\
$golang\
$rust\
$nodejs\
$kubernetes\
$docker_context\
$cmd_duration\
$line_break\
$character"""

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"

[directory]
truncation_length = 3
truncation_symbol = "…/"

[git_branch]
symbol = " "
format = "[$symbol$branch]($style) "

[git_status]
format = '([\[$all_status$ahead_behind\]]($style) )'

[kubernetes]
disabled = false
symbol = "☸ "
format = '[$symbol$context(\($namespace\))]($style) '

[python]
symbol = " "
format = '[${symbol}${pyenv_prefix}(${version} )(\($virtualenv\) )]($style)'

[golang]
symbol = " "

[rust]
symbol = " "

[nodejs]
symbol = " "

[docker_context]
symbol = " "

[cmd_duration]
min_time = 3_000
format = "[$duration]($style) "
STARSHIP_CONFIG
success "Starship 설정 완료"

# ──────────────────────────────────────────────
# 9. tmux 설정
# ──────────────────────────────────────────────
section "tmux 설정"
cat > "$HOME/.tmux.conf" << 'TMUX_CONF'
# mac-setup: tmux Configuration

# Prefix: C-a
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# True color
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",ghostty:RGB,xterm-256color:RGB"

# Mouse
set -g mouse on

# Vi mode
setw -g mode-keys vi
bind -T copy-mode-vi v send-keys -X begin-selection
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"

# Split panes
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Navigate panes (vim-like)
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Resize panes
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Start windows/panes at 1
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

# Status bar
set -g status-position top
set -g status-interval 5
set -g status-style "bg=default,fg=white"
set -g status-left "#[fg=cyan,bold] #S "
set -g status-right "#[fg=yellow]%H:%M #[fg=white]%m/%d"
set -g status-left-length 30

# Reload config
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# TPM (Tmux Plugin Manager)
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# Auto-restore
set -g @continuum-restore 'on'

# TPM bootstrap
if "test ! -d ~/.tmux/plugins/tpm" \
   "run 'git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && ~/.tmux/plugins/tpm/bin/install_plugins'"
TMUX_CONF
success "tmux 설정 완료"

# ──────────────────────────────────────────────
# 10. Ghostty 설정
# ──────────────────────────────────────────────
section "Ghostty 설정"
GHOSTTY_DIR="$HOME/.config/ghostty"
mkdir -p "$GHOSTTY_DIR"
cat > "$GHOSTTY_DIR/config" << 'GHOSTTY_CONF'
# mac-setup: Ghostty Configuration

# Font
font-family = Hack Nerd Font
font-size = 14

# Theme (Tokyo Night)
theme = Tomorrow Night Blue

# Window
window-padding-x = 8
window-padding-y = 8
window-decoration = true
background-opacity = 0.95
macos-option-as-alt = true

# Shell
command = /opt/homebrew/bin/fish

# Cursor
cursor-style = block
cursor-style-blink = false

# Scrollback
scrollback-limit = 10000

# Quick Terminal (macOS)
keybind = global:cmd+grave_accent=toggle_quick_terminal
quick-terminal-position = bottom
quick-terminal-animation-duration = 0.15

# Clipboard
clipboard-read = allow
clipboard-write = allow
copy-on-select = clipboard

# Mouse
mouse-hide-while-typing = true

# Bell
bell-feature = none
GHOSTTY_CONF
success "Ghostty 설정 완료"

# ──────────────────────────────────────────────
# 11. Git 기본 설정
# ──────────────────────────────────────────────
section "Git 설정"
git config --global init.defaultBranch main
git config --global core.editor nvim
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.side-by-side true
git config --global delta.line-numbers true
git config --global merge.conflictstyle diff3
git config --global diff.colorMoved default
git config --global pull.rebase true
git config --global push.autoSetupRemote true
git config --global rerere.enabled true

if [[ -z "$(git config --global user.name)" ]]; then
  warn "Git user.name이 설정되지 않았습니다."
  read -rp "  이름을 입력하세요: " git_name
  git config --global user.name "$git_name"
fi
if [[ -z "$(git config --global user.email)" ]]; then
  warn "Git user.email이 설정되지 않았습니다."
  read -rp "  이메일을 입력하세요: " git_email
  git config --global user.email "$git_email"
fi
success "Git 설정 완료"

# ──────────────────────────────────────────────
# 12. SSH 키 생성
# ──────────────────────────────────────────────
section "SSH 키"
if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
  success "SSH 키가 이미 존재합니다"
else
  info "ED25519 SSH 키 생성 중..."
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N "" -C "$(git config --global user.email)"
  eval "$(ssh-agent -s)" 2>/dev/null
  ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null

  echo ""
  warn "GitHub에 SSH 키를 등록하세요:"
  echo ""
  cat "$HOME/.ssh/id_ed25519.pub"
  echo ""
  info "또는: gh auth login 으로 인증 후 gh ssh-key add ~/.ssh/id_ed25519.pub"
fi

# ──────────────────────────────────────────────
# 13. macOS 시스템 설정
# ──────────────────────────────────────────────
section "macOS 시스템 설정"

# Dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.3
defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock minimize-to-application -bool true

# Finder
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Keyboard
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Trackpad
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true

# Screenshots
defaults write com.apple.screencapture location -string "$HOME/Desktop/Screenshots"
mkdir -p "$HOME/Desktop/Screenshots"
defaults write com.apple.screencapture type -string "png"

# 설정 반영
killall Dock Finder 2>/dev/null || true
success "macOS 시스템 설정 완료"

# ──────────────────────────────────────────────
# 14. 작업 디렉토리 생성
# ──────────────────────────────────────────────
section "작업 디렉토리 구조"
mkdir -p "$HOME/workspace"/{projects,sandbox,scripts}
mkdir -p "$HOME/.local/bin"
success "디렉토리 구조 생성 완료"

# ──────────────────────────────────────────────
# 완료
# ──────────────────────────────────────────────
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ Mac 환경 구성 완료!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${YELLOW}다음 단계:${NC}"
echo -e "  1. 터미널을 재시작하세요 (또는 ${CYAN}exec fish${NC})"
echo -e "  2. ${CYAN}gh auth login${NC} 으로 GitHub 인증"
echo -e "  3. ${CYAN}gh ssh-key add ~/.ssh/id_ed25519.pub${NC} 으로 SSH 키 등록"
echo -e "  4. Neovim 실행하여 플러그인 자동 설치"
echo -e "  5. tmux에서 ${CYAN}prefix + I${NC} 로 TPM 플러그인 설치"
echo ""
echo -e "  ${YELLOW}설치된 항목:${NC}"
echo -e "  • Shell: Fish + Starship + Fisher"
echo -e "  • Editor: Neovim (LazyVim) + Zed + VS Code"
echo -e "  • Terminal: Ghostty + tmux"
echo -e "  • Languages: Python (uv) + Go + Rust + Node.js (fnm)"
echo -e "  • K8s: kubectl, helm, k9s, kustomize, kubectx, stern, k3d, argocd"
echo -e "  • Tools: Docker Desktop, Raycast, Rectangle, lazygit"
echo ""

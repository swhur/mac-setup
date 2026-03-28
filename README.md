# 🖥️ mac-setup

macOS 재설치 후 원커맨드로 개발 환경을 구성하는 자동화 스크립트.

## 사용법

터미널을 열고 아래 명령어 하나만 실행하면 됩니다:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/<YOUR_USERNAME>/mac-setup/main/setup.sh)
```

> GitHub에 이 저장소를 올린 뒤 `<YOUR_USERNAME>`을 자신의 GitHub 아이디로 바꿔주세요.

## 설치 항목

### Shell & Terminal
| 도구 | 설명 |
|------|------|
| Fish | 기본 셸 (+ Fisher 플러그인 매니저) |
| Starship | 크로스쉘 프롬프트 |
| Ghostty | GPU 가속 네이티브 터미널 (Quick Terminal 포함) |
| tmux | 터미널 멀티플렉서 (+ TPM, resurrect, continuum) |

### Editors
| 도구 | 설명 |
|------|------|
| Neovim | LazyVim 스타터 설정 포함 |
| Zed | 고성능 에디터 |
| VS Code | 범용 에디터 |

### Languages & Runtimes
| 도구 | 설명 |
|------|------|
| Python | uv 패키지 매니저 |
| Go | 최신 stable |
| Rust | rustup으로 관리 |
| Node.js | fnm으로 LTS 자동 설치 |

### Kubernetes (풀셋)
kubectl, helm, k9s, kustomize, kubectx/kubens, stern, k3d, argocd-cli, kubeseal, kubelogin

### CLI Utilities
ripgrep, fd, bat, fzf, eza, jq, yq, git-delta, lazygit, gh, httpie, direnv, sops, age, ...

### macOS Apps (Cask)
Docker Desktop, Raycast, Google Chrome, Firefox, iTerm2, Slack, Notion, Obsidian, KakaoTalk, Rectangle, Stats

### 설정 파일
- `~/.config/fish/config.fish` — Fish 쉘 설정 + 에일리어스
- `~/.config/starship.toml` — Starship 프롬프트
- `~/.config/ghostty/config` — Ghostty 터미널 (Hack Nerd Font, Tomorrow Night Blue)
- `~/.tmux.conf` — tmux 설정 (C-a prefix, vi mode)
- `~/.gitconfig` — Git 설정 (delta pager, rebase pull)

### macOS 시스템 설정
- Dock 자동 숨김, 최근 항목 숨김
- Finder에서 숨김 파일/경로바/상태바 표시
- 키 반복 속도 향상 (KeyRepeat: 2)
- 세 손가락 드래그 활성화
- 스크린샷 저장 위치: `~/Desktop/Screenshots`

## 커스터마이즈

스크립트를 포크한 뒤 자유롭게 수정하세요:

- **패키지 추가/제거**: `setup.sh` 안의 Brewfile 섹션 수정
- **dotfiles 분리**: 설정 파일들을 별도 디렉토리로 분리하고 symlink 방식으로 변경 가능
- **private 설정**: API 키 등은 `.env` 파일로 분리하여 `.gitignore`에 추가

## GitHub에 올리기

```bash
# 로컬에서 바로 올리기
cd mac-setup
git init
git add -A
git commit -m "feat: initial mac setup script"
gh repo create mac-setup --public --source=. --push
```

그 다음부터는 새 맥에서:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/<YOUR_USERNAME>/mac-setup/main/setup.sh)
```

## License

MIT

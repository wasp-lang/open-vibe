#!/usr/bin/env bash
# setup.sh — Open Vibe: Dev Environment Installer
# Usage: bash setup.sh [--yes]
# Or:    curl -fsSL https://openvibe.sh/setup.sh | bash
set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────────────────

REQUIRED_NODE_MAJOR=24
REQUIRED_NODE_MINOR=14
REQUIRED_NODE_VERSION="${REQUIRED_NODE_MAJOR}.${REQUIRED_NODE_MINOR}"

# Auto-accept prompts if stdin is not a TTY (piped from curl, run by an AI agent, etc.)
if [ ! -t 0 ]; then
    AUTO_YES=true
else
    AUTO_YES=false
fi

# ─── Colors & Symbols ────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

CHECKMARK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
WARN="${YELLOW}!${NC}"
ARROW="${BLUE}→${NC}"

# ─── State ────────────────────────────────────────────────────────────────────

OS=""
ARCH=""
DISTRO=""
SHELL_RC=""
NEEDS_INSTALL=false
INSTALLED_SOMETHING=false

# ─── Utility Functions ────────────────────────────────────────────────────────

print_header() {
    printf "\n"
    printf "${CYAN}${BOLD}"
    printf "  ╔═══════════════════════════════════════════╗\n"
    printf "  ║       Open Vibe  —  Setup       ║\n"
    printf "  ╚═══════════════════════════════════════════╝\n"
    printf "${NC}\n"
    printf "  ${DIM}This script checks your dev environment and${NC}\n"
    printf "  ${DIM}installs anything you need to get started.${NC}\n\n"
}

print_step()    { printf "  ${ARROW} %b\n" "$1"; }
print_success() { printf "  ${CHECKMARK} %b\n" "$1"; }
print_warning() { printf "  ${WARN} %b\n" "$1"; }
print_error()   { printf "  ${CROSS} %b\n" "$1"; }
print_info()    { printf "  ${DIM}%b${NC}\n" "$1"; }

ask_yes_no() {
    if [ "$AUTO_YES" = true ]; then
        return 0
    fi
    printf "\n  ${BOLD}%b${NC} [Y/n] " "$1"
    read -r response
    case "$response" in
        [nN][oO]|[nN]) return 1 ;;
        *) return 0 ;;
    esac
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Compare versions: returns 0 if $1 >= $2
version_gte() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]
}

# ─── OS Detection ─────────────────────────────────────────────────────────────

detect_os() {
    ARCH="$(uname -m)"
    local kernel
    kernel="$(uname -s)"

    case "$kernel" in
        Darwin)
            OS="macos"
            ;;
        Linux)
            if [ -f /proc/version ] && grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; then
                OS="wsl"
            else
                OS="linux"
            fi
            # Detect distro
            if [ -f /etc/os-release ]; then
                DISTRO="$(. /etc/os-release && echo "${ID:-unknown}")"
            else
                DISTRO="unknown"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            OS="windows"
            ;;
        *)
            OS="unknown"
            ;;
    esac

    # Detect shell rc file
    case "${SHELL:-/bin/bash}" in
        */zsh)  SHELL_RC="$HOME/.zshrc" ;;
        */bash) SHELL_RC="$HOME/.bashrc" ;;
        *)      SHELL_RC="$HOME/.profile" ;;
    esac
}

# ─── Dependency Checks ───────────────────────────────────────────────────────

NODE_VERSION=""
NPM_VERSION=""
WASP_VERSION=""
DOCKER_VERSION=""
CLAUDE_VERSION=""

check_node() {
    if command_exists node; then
        NODE_VERSION="$(node --version 2>/dev/null | sed 's/^v//')"
        if version_gte "$NODE_VERSION" "$REQUIRED_NODE_VERSION"; then
            return 0
        fi
        return 1  # installed but too old
    fi
    return 1
}

check_npm() {
    if command_exists npm; then
        NPM_VERSION="$(npm --version 2>/dev/null)"
        return 0
    fi
    return 1
}

check_wasp() {
    if command_exists wasp; then
        WASP_VERSION="$(wasp version 2>/dev/null | head -1)"
        return 0
    fi
    return 1
}

check_docker() {
    if command_exists docker; then
        DOCKER_VERSION="$(docker --version 2>/dev/null | sed 's/Docker version //' | cut -d',' -f1)"
        return 0
    fi
    return 1
}

check_claude_code() {
    if command_exists claude; then
        CLAUDE_VERSION="$(claude --version 2>/dev/null | head -1)"
        return 0
    fi
    return 1
}

print_status_table() {
    printf "\n  ${BOLD}%-20s %-10s %s${NC}\n" "Tool" "Status" "Version"
    printf "  ${DIM}%-20s %-10s %s${NC}\n" "────────────────────" "──────────" "───────────────"

    if check_node; then
        printf "  %-20b %-10b %s\n" "Node.js (>= $REQUIRED_NODE_VERSION)" "$CHECKMARK" "v${NODE_VERSION}"
    elif [ -n "$NODE_VERSION" ]; then
        printf "  %-20b %-10b %s\n" "Node.js (>= $REQUIRED_NODE_VERSION)" "${YELLOW}▲${NC}" "v${NODE_VERSION} ${YELLOW}(upgrade needed)${NC}"
    else
        printf "  %-20b %-10b %s\n" "Node.js (>= $REQUIRED_NODE_VERSION)" "$CROSS" "not found"
    fi

    if check_npm; then
        printf "  %-20b %-10b %s\n" "npm" "$CHECKMARK" "v${NPM_VERSION}"
    else
        printf "  %-20b %-10b %s\n" "npm" "$CROSS" "not found"
    fi

    if check_wasp; then
        printf "  %-20b %-10b %s\n" "Wasp CLI" "$CHECKMARK" "${WASP_VERSION}"
    else
        printf "  %-20b %-10b %s\n" "Wasp CLI" "$CROSS" "not found"
    fi

    if check_claude_code; then
        printf "  %-20b %-10b %s\n" "Claude Code ${DIM}(optional)${NC}" "$CHECKMARK" "${CLAUDE_VERSION}"
    else
        printf "  %-20b %-10b %s\n" "Claude Code ${DIM}(optional)${NC}" "${DIM}—${NC}" "${DIM}not found${NC}"
    fi

    if check_docker; then
        printf "  %-20b %-10b %s\n" "Docker ${DIM}(optional)${NC}" "$CHECKMARK" "v${DOCKER_VERSION}"
    else
        printf "  %-20b %-10b %s\n" "Docker ${DIM}(optional)${NC}" "${DIM}—${NC}" "${DIM}not found${NC}"
    fi

    printf "\n"
}

# ─── Installation Functions ──────────────────────────────────────────────────

install_homebrew() {
    print_step "Installing Homebrew (macOS package manager)..."
    print_info "This may ask for your password.\n"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH for Apple Silicon Macs
    if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        if ! grep -q 'homebrew.*shellenv' "$SHELL_RC" 2>/dev/null; then
            printf '\n# Homebrew\neval "$(/opt/homebrew/bin/brew shellenv)"\n' >> "$SHELL_RC"
        fi
    fi
    INSTALLED_SOMETHING=true
}

install_node() {
    print_step "Installing Node.js ${REQUIRED_NODE_MAJOR}..."

    case "$OS" in
        macos)
            if ! command_exists brew; then
                if ask_yes_no "Homebrew is needed to install Node.js. Install Homebrew?"; then
                    install_homebrew
                else
                    print_error "Cannot install Node.js without Homebrew on macOS."
                    print_info "Install Node.js manually: https://nodejs.org/en/download"
                    return 1
                fi
            fi
            brew install "node@${REQUIRED_NODE_MAJOR}"
            # node@22 is keg-only, add to PATH
            local brew_prefix
            brew_prefix="$(brew --prefix)"
            local node_bin="${brew_prefix}/opt/node@${REQUIRED_NODE_MAJOR}/bin"
            if [ -d "$node_bin" ]; then
                export PATH="${node_bin}:$PATH"
                if ! grep -q "node@${REQUIRED_NODE_MAJOR}/bin" "$SHELL_RC" 2>/dev/null; then
                    printf '\n# Node.js %s\nexport PATH="%s:$PATH"\n' "$REQUIRED_NODE_MAJOR" "$node_bin" >> "$SHELL_RC"
                    print_info "Added Node.js to PATH in ${SHELL_RC}"
                fi
            fi
            ;;
        linux|wsl)
            print_info "Installing via nvm (Node Version Manager)..."
            export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
            curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
            # Load nvm in current shell
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            nvm install "$REQUIRED_NODE_MAJOR"
            nvm alias default "$REQUIRED_NODE_MAJOR"
            nvm use "$REQUIRED_NODE_MAJOR"
            ;;
    esac

    INSTALLED_SOMETHING=true

    # Verify
    if check_node; then
        print_success "Node.js v${NODE_VERSION} installed"
    else
        print_error "Node.js installation may have failed. Please check manually."
        return 1
    fi
}

install_wasp() {
    print_step "Installing Wasp CLI..."
    npm i -g @wasp.sh/wasp-cli@latest
    INSTALLED_SOMETHING=true

    if check_wasp; then
        print_success "Wasp CLI installed (${WASP_VERSION})"
    else
        print_error "Wasp CLI installation may have failed."
        print_info "Try manually: npm i -g @wasp.sh/wasp-cli@latest"
        return 1
    fi
}

install_claude_code() {
    print_step "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
    # Reload PATH so claude is available in this session
    hash -r 2>/dev/null
    INSTALLED_SOMETHING=true

    if check_claude_code; then
        print_success "Claude Code installed (${CLAUDE_VERSION})"
    else
        print_error "Claude Code installation may have failed."
        print_info "Try manually: curl -fsSL https://claude.ai/install.sh | bash"
        return 1
    fi
}

install_docker() {
    case "$OS" in
        macos)
            if ! command_exists brew; then
                print_warning "Homebrew is needed to install Docker Desktop."
                print_info "Install Docker Desktop manually: https://www.docker.com/products/docker-desktop/"
                return 0
            fi
            print_step "Installing Docker Desktop..."
            brew install --cask docker
            print_info "You may need to open Docker Desktop from Applications to finish setup."
            INSTALLED_SOMETHING=true
            ;;
        wsl)
            printf "\n"
            print_info "Docker on WSL works best via Docker Desktop for Windows."
            print_info "Download it here: https://www.docker.com/products/docker-desktop/"
            printf "\n"
            print_info "After installing Docker Desktop:"
            print_info "  1. Open Docker Desktop Settings"
            print_info "  2. Go to Resources > WSL Integration"
            print_info "  3. Enable integration with your WSL distro"
            print_info "  4. Restart your terminal"
            printf "\n"
            return 0
            ;;
        linux)
            print_step "Installing Docker Engine..."
            curl -fsSL https://get.docker.com | sh
            # Add current user to docker group to avoid needing sudo
            if ! groups "$USER" | grep -q docker 2>/dev/null; then
                sudo usermod -aG docker "$USER"
                print_info "Added your user to the 'docker' group."
                print_info "You may need to log out and back in for this to take effect."
            fi
            INSTALLED_SOMETHING=true
            ;;
    esac
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
    # Parse arguments
    for arg in "$@"; do
        case "$arg" in
            --yes|-y)
                AUTO_YES=true
                ;;
            --help|-h)
                printf "Usage: bash setup.sh [OPTIONS]\n\n"
                printf "Sets up your dev environment for Open Vibe.\n\n"
                printf "Options:\n"
                printf "  --yes, -y    Auto-accept all prompts\n"
                printf "  --help, -h   Show this help message\n"
                exit 0
                ;;
            *)
                printf "Unknown option: %s\n" "$arg"
                printf "Run 'bash setup.sh --help' for usage.\n"
                exit 1
                ;;
        esac
    done

    print_header
    detect_os

    # ── Gate: unsupported OS ──
    if [ "$OS" = "windows" ]; then
        print_error "This script needs to run inside WSL (Windows Subsystem for Linux)."
        printf "\n"
        print_info "To install WSL, open PowerShell as Administrator and run:"
        printf "\n    ${BOLD}wsl --install${NC}\n\n"
        print_info "Then restart your computer, open Ubuntu from the Start menu,"
        print_info "and run this script again inside WSL."
        printf "\n"
        exit 1
    fi

    if [ "$OS" = "unknown" ]; then
        print_error "Unsupported operating system: $(uname -s)"
        print_info "This script supports macOS, Linux, and WSL."
        exit 1
    fi

    # ── Show detected environment ──
    local os_label="$OS"
    [ "$OS" = "macos" ] && os_label="macOS"
    [ "$OS" = "wsl" ] && os_label="WSL (Linux on Windows)"
    [ "$OS" = "linux" ] && os_label="Linux ($DISTRO)"
    print_info "Detected: ${os_label}, ${ARCH}\n"

    # ── Phase 1: Status Report ──
    print_step "${BOLD}Checking your system...${NC}"
    print_status_table

    # ── Phase 2: Install Missing ──
    local anything_missing=false

    # Node.js
    if ! check_node; then
        anything_missing=true
        if [ -n "$NODE_VERSION" ]; then
            if ask_yes_no "Node.js $NODE_VERSION is installed but too old (need >= $REQUIRED_NODE_VERSION). Upgrade?"; then
                install_node
            fi
        else
            if ask_yes_no "Node.js is required. Install Node.js $REQUIRED_NODE_MAJOR?"; then
                install_node
            else
                print_warning "Skipped Node.js. You'll need it before you can continue."
            fi
        fi
    fi

    # npm (should come with Node, but check)
    if ! check_npm; then
        anything_missing=true
        print_warning "npm not found. It should come with Node.js."
        if check_node; then
            print_info "Try reinstalling Node.js, or run: corepack enable"
        fi
    fi

    # Wasp CLI
    if ! check_wasp; then
        anything_missing=true
        if check_node && check_npm; then
            if ask_yes_no "Wasp CLI is required. Install it?"; then
                install_wasp
            else
                print_warning "Skipped Wasp CLI. You'll need it before you can continue."
            fi
        else
            print_warning "Wasp CLI requires Node.js and npm. Install those first."
        fi
    fi

    # Claude Code (optional — any AI coding agent works)
    if ! check_claude_code; then
        printf "\n"
        print_info "This course works with any AI coding agent (Claude Code, Codex, Copilot, Open Code, etc.)."
        print_info "Claude Code requires a Claude Pro or Max subscription (\$20 or \$100/month)."
        print_info "Sign up first if you haven't: ${NC}${CYAN}https://claude.ai/pricing${NC}"
        if ask_yes_no "Install Claude Code? (skip if using a different agent)"; then
            install_claude_code
        else
            print_warning "Skipped Claude Code. Make sure you have an AI coding agent installed."
        fi
    fi

    # Docker (optional)
    if ! check_docker; then
        printf "\n"
        print_info "Docker is ${BOLD}optional${NC}${DIM} — it runs a local database for your app."
        print_info "You can always install it later if you need it."
        if ask_yes_no "Install Docker? (optional)"; then
            install_docker
        else
            print_info "Skipped Docker. No worries — you can install it later."
        fi
    fi

    # ── Phase 3: Final Verification ──
    if [ "$INSTALLED_SOMETHING" = true ]; then
        printf "\n"
        print_step "${BOLD}Verifying installation...${NC}"
        print_status_table
    fi

    if [ "$anything_missing" = false ]; then
        printf "  ${GREEN}${BOLD}Everything looks good!${NC}\n"
    fi

    # ── Phase 4: Next Steps ──
    local all_required_ok=true
    check_node || all_required_ok=false
    check_npm || all_required_ok=false
    check_wasp || all_required_ok=false

    if [ "$all_required_ok" = true ]; then
        printf "\n"
        printf "  ${GREEN}${BOLD}╔═══════════════════════════════════════════╗${NC}\n"
        printf "  ${GREEN}${BOLD}║          You're ready to start!           ║${NC}\n"
        printf "  ${GREEN}${BOLD}╚═══════════════════════════════════════════╝${NC}\n"
        printf "\n"
        printf "  ${BOLD}Next steps:${NC}\n\n"
        if [ "$INSTALLED_SOMETHING" = true ]; then
            printf "  ${DIM}0.${NC} Restart your terminal (to pick up PATH changes)\n\n"
        fi
        printf "  ${DIM}1.${NC} Open your AI coding agent and tell it to fetch:\n"
        printf "     ${CYAN}https://openvibe.sh/llms.txt${NC}\n\n"
        printf "     ${DIM}Works with Claude Code, Codex, Copilot, Open Code, or any coding agent.${NC}\n"
        printf "     ${DIM}If your agent can't fetch URLs, open the link in your browser and paste the contents.${NC}\n\n"
        printf "  ${DIM}Happy building!${NC}\n\n"
    else
        printf "\n"
        print_warning "${BOLD}Some required tools are still missing.${NC}"
        print_info "Re-run this script after installing them, or install manually:\n"
        check_node || print_info "  Node.js: https://nodejs.org/en/download"
        check_wasp || print_info "  Wasp CLI: npm i -g @wasp.sh/wasp-cli@latest"
        print_info "  AI coding agent: Claude Code, Codex, Copilot, Open Code, or similar"
        printf "\n"
    fi
}

main "$@"

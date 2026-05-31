# ~/.zshrc — FALLBACK shell config.
#
# The primary, daily-driver shell is Den (~/.denrc + ~/.config/den.jsonc). This
# file only exists so a plain `zsh` session is still usable. Environment, $PATH
# and aliases are shared with Den via env.sh / aliases.sh so there is a single
# source of truth; everything zsh-specific (oh-my-zsh, the prompt) lives here.

export DOTFILES="$HOME/.dotfiles"

# oh-my-zsh is optional — only load it if present. No theme (Den owns the prompt;
# in this fallback we set a minimal native zsh prompt below) and only the git
# plugin (autosuggestions/syntax-highlighting/autocomplete are Den-native now).
if [ -d "$HOME/.oh-my-zsh" ]; then
  export ZSH="$HOME/.oh-my-zsh"
  ZSH_THEME=""
  plugins=(git)
  source "$ZSH/oh-my-zsh.sh"
fi

# Shared environment, PATH and aliases (same files Den sources).
source "$DOTFILES/env.sh"
source "$DOTFILES/aliases.sh"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Pantry shell integration (auto-install on cd, adds global bin to PATH).
command -v pantry >/dev/null && eval "$(pantry dev:shellcode)"

# Minimal native prompt — starship was removed; Den owns the real prompt.
setopt PROMPT_SUBST
PROMPT='%F{cyan}%~%f %F{green}$(git branch --show-current 2>/dev/null)%f ❯ '

# --- Den (opt-in) ---
# To launch Den automatically for interactive zsh sessions, uncomment below — or,
# preferably, point your terminal app's "command" setting directly at `den`.
# [[ $- == *i* && -z "$DEN_ACTIVE" ]] && command -v den >/dev/null && DEN_ACTIVE=1 exec den
